import 'dart:convert';
import 'dart:io';

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// User-configurable connection + login settings for the shift API.
@immutable
class AppSettings {
  /// Custom URI scheme for the native OIDC redirect (must match the Android
  /// `appAuthRedirectScheme` manifest placeholder and the Keycloak client).
  static const nativeRedirectScheme = 'org.khmhmh.shiftviewer';
  static const nativeRedirectUri = '$nativeRedirectScheme:/oauth2redirect';

  /// Web redirect (registered in Keycloak; app served on port 8900).
  static const webRedirectUri = 'http://localhost:8900/auth/callback';

  /// Default backend/IdP host (gateway fronting Keycloak + the API).
  static const defaultApiBase = 'https://portainer.mhmhkh.org/api/v1';
  static const defaultIssuer =
      'https://portainer.mhmhkh.org/auth/realms/shift';

  /// Default OAuth scopes: the standard OIDC set, the backend's `shift-org`
  /// scope, and `offline_access` so Keycloak issues an offline refresh token —
  /// a session then survives the SSO session timeout instead of ending with it.
  static const defaultScopes = 'openid profile email shift-org offline_access';

  /// Base URL of the API, e.g. `http://localhost/api/v1`.
  final String baseUrl;

  /// Username for HTTP basic auth (optional).
  final String username;

  /// Password for HTTP basic auth (optional).
  final String password;

  /// Bearer / OIDC access token (optional). Takes precedence over basic auth.
  final String bearerToken;

  /// Employee whose roster is displayed in the calendar (optional).
  final String employeeId;

  // ---- OIDC / PKCE login ----

  /// OIDC issuer (realm) URL, e.g. `http://localhost/auth/realms/shift`.
  final String oidcIssuer;

  /// OAuth client id. Public PKCE client for this app.
  final String oidcClientId;

  /// Redirect URI registered in Keycloak for this app.
  final String oidcRedirectUri;

  /// Space-separated OAuth scopes. Not shown in the UI; see [defaultScopes].
  final String oidcScopes;

  // ---- Appearance ----

  /// UI language as an ISO code (`en`, `de`), or empty to follow the device
  /// locale. Codes outside [supportedLanguageCodes] fall back to the device.
  final String languageCode;

  /// Languages the app ships translations for.
  static const supportedLanguageCodes = ['en', 'de'];

  const AppSettings({
    this.baseUrl = defaultApiBase,
    this.username = '',
    this.password = '',
    this.bearerToken = '',
    this.employeeId = '',
    this.oidcIssuer = defaultIssuer,
    this.oidcClientId = 'shift-app',
    this.oidcRedirectUri = webRedirectUri,
    this.oidcScopes = defaultScopes,
    this.languageCode = '',
  });

  /// First-run defaults. Backend + IdP are served over HTTPS at
  /// [defaultIssuer]/[defaultApiBase]; the redirect is a custom scheme on
  /// native and an HTTP loopback callback on web.
  factory AppSettings.initial() {
    return AppSettings(
      baseUrl: defaultApiBase,
      oidcIssuer: defaultIssuer,
      oidcClientId: 'shift-app',
      oidcRedirectUri: kIsWeb ? webRedirectUri : nativeRedirectUri,
      oidcScopes: defaultScopes,
    );
  }

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  /// Whether enough is set to attempt an OIDC login.
  bool get isOidcConfigured =>
      oidcIssuer.trim().isNotEmpty &&
      oidcClientId.trim().isNotEmpty &&
      oidcRedirectUri.trim().isNotEmpty;

  /// The locale to render in, or null to follow the device.
  Locale? get locale => supportedLanguageCodes.contains(languageCode)
      ? Locale(languageCode)
      : null;

  List<String> get scopeList =>
      oidcScopes.split(' ').where((s) => s.trim().isNotEmpty).toList();

  String get authorizationEndpoint =>
      '${_issuerBase()}/protocol/openid-connect/auth';
  String get tokenEndpoint => '${_issuerBase()}/protocol/openid-connect/token';
  String get endSessionEndpoint =>
      '${_issuerBase()}/protocol/openid-connect/logout';

  String _issuerBase() => oidcIssuer.trim().replaceAll(RegExp(r'/+$'), '');

  AppSettings copyWith({
    String? baseUrl,
    String? username,
    String? password,
    String? bearerToken,
    String? employeeId,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcRedirectUri,
    String? oidcScopes,
    String? languageCode,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      bearerToken: bearerToken ?? this.bearerToken,
      employeeId: employeeId ?? this.employeeId,
      oidcIssuer: oidcIssuer ?? this.oidcIssuer,
      oidcClientId: oidcClientId ?? this.oidcClientId,
      oidcRedirectUri: oidcRedirectUri ?? this.oidcRedirectUri,
      oidcScopes: oidcScopes ?? this.oidcScopes,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'username': username,
        'password': password,
        'bearerToken': bearerToken,
        'employeeId': employeeId,
        'oidcIssuer': oidcIssuer,
        'oidcClientId': oidcClientId,
        'oidcRedirectUri': oidcRedirectUri,
        'oidcScopes': oidcScopes,
        'languageCode': languageCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final def = AppSettings.initial();
    return AppSettings(
      baseUrl: json['baseUrl'] as String? ?? def.baseUrl,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      bearerToken: json['bearerToken'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      oidcIssuer: json['oidcIssuer'] as String? ?? def.oidcIssuer,
      oidcClientId: json['oidcClientId'] as String? ?? def.oidcClientId,
      oidcRedirectUri: json['oidcRedirectUri'] as String? ?? def.oidcRedirectUri,
      oidcScopes: _withOfflineAccess(json['oidcScopes'] as String?, def),
      languageCode: json['languageCode'] as String? ?? '',
    );
  }

  /// Scopes are persisted but never editable in the UI, so a settings file
  /// written before `offline_access` was added would otherwise pin the app to
  /// the old scope set forever. Add it back on read.
  static String _withOfflineAccess(String? stored, AppSettings def) {
    final scopes = stored?.trim();
    if (scopes == null || scopes.isEmpty) return def.oidcScopes;
    if (scopes.split(' ').contains('offline_access')) return scopes;
    return '$scopes offline_access';
  }
}

/// Holds [AppSettings] in memory and persists them to a JSON file in the app
/// documents directory. Notifies listeners on change so the UI can rebuild.
class SettingsController extends ChangeNotifier {
  AppSettings _settings = AppSettings.initial();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  Future<File> _settingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/shiftviewer_settings.json');
  }

  Future<void> load() async {
    try {
      final file = await _settingsFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        _settings = AppSettings.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> save(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    try {
      final file = await _settingsFile();
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }
}
