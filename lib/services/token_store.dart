import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'auth_browser.dart';

/// Persists the OIDC token set. On web it uses `localStorage` (via
/// [AuthBrowser]); on native platforms it writes a JSON file in the app
/// documents directory.
class TokenStore {
  final AuthBrowser _browser;
  TokenStore(this._browser);

  static const _lsKey = 'sv_tokens';
  static const _fileName = 'shiftviewer_tokens.json';

  Future<Map<String, dynamic>> read() async {
    try {
      if (kIsWeb) {
        final s = _browser.storageGet(_lsKey);
        if (s == null || s.isEmpty) return {};
        return jsonDecode(s) as Map<String, dynamic>;
      }
      final f = await _file();
      if (await f.exists()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
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
        await (await _file()).writeAsString(s);
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
        final f = await _file();
        if (await f.exists()) await f.delete();
      }
    } catch (e) {
      debugPrint('TokenStore.clear failed: $e');
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }
}
