import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'auth_browser.dart';
import 'secret_store.dart';

/// Persists the OIDC token set. On web it uses `localStorage` (via
/// [AuthBrowser]); on native platforms it lives in the platform keystore (via
/// [SecretStore]) — the refresh token is a long-lived credential and must not
/// sit in a plain file.
class TokenStore {
  final AuthBrowser _browser;
  final SecretStore _secrets;
  TokenStore(this._browser, {SecretStore? secrets})
      : _secrets = secrets ?? PlatformSecretStore();

  static const _lsKey = 'sv_tokens';
  static const _fileName = 'shiftviewer_tokens.json';

  Future<Map<String, dynamic>> read() async {
    try {
      if (kIsWeb) {
        final s = _browser.storageGet(_lsKey);
        if (s == null || s.isEmpty) return {};
        return jsonDecode(s) as Map<String, dynamic>;
      }
      final stored = await _secrets.read(_lsKey);
      if (stored != null && stored.isNotEmpty) {
        return jsonDecode(stored) as Map<String, dynamic>;
      }
      return await _migrateLegacyFile();
    } catch (e) {
      debugPrint('TokenStore.read failed: $e');
    }
    return {};
  }

  Future<void> write(Map<String, dynamic> data) async {
    final s = jsonEncode(data);
    try {
      if (kIsWeb) {
        _browser.storageSet(_lsKey, s);
      } else {
        await _secrets.write(_lsKey, s);
      }
    } catch (e) {
      debugPrint('TokenStore.write failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      if (kIsWeb) {
        _browser.storageRemove(_lsKey);
      } else {
        await _secrets.delete(_lsKey);
        await _deleteLegacyFile();
      }
    } catch (e) {
      debugPrint('TokenStore.clear failed: $e');
    }
  }

  /// Tokens written by earlier versions sat in a plain JSON file. Move them
  /// into the keystore on first read and remove the file.
  Future<Map<String, dynamic>> _migrateLegacyFile() async {
    final f = await _file();
    if (!await f.exists()) return {};
    final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    await _secrets.write(_lsKey, jsonEncode(data));
    await f.delete();
    return data;
  }

  Future<void> _deleteLegacyFile() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }
}
