import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import 'app_settings.dart';
import 'auth_browser.dart';
import 'token_store.dart';

/// A non-2xx answer from the OIDC token endpoint. The status code is what
/// separates a refused refresh token (4xx — the session is over) from a
/// server or network hiccup (5xx — worth trying again).
class TokenEndpointException implements Exception {
  final int statusCode;
  final String body;
  const TokenEndpointException(this.statusCode, this.body);
  @override
  String toString() => 'HTTP $statusCode: $body';
}

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

/// Drives the OIDC Authorization Code + PKCE flow and holds the resulting
/// tokens. Two implementations behind one API:
///
/// * **Web** — full-page browser redirect to Keycloak, callback handled at load.
/// * **Native (Android/iOS)** — `flutter_appauth`, which opens a system browser
///   tab and returns tokens inline (PKCE handled by AppAuth).
///
/// Both use a public client (no client secret); the PKCE code_verifier is the
/// proof of possession.
class AuthController extends ChangeNotifier {
  final SettingsController settingsController;
  final AuthBrowser _browser;
  final TokenStore _tokens;
  final http.Client _http;
  final FlutterAppAuth _appAuth;

  AuthController(
    this.settingsController, {
    AuthBrowser? browser,
    TokenStore? tokenStore,
    http.Client? httpClient,
    FlutterAppAuth? appAuth,
  })  : _browser = browser ?? AuthBrowser(),
        _tokens = tokenStore ?? TokenStore(browser ?? AuthBrowser()),
        _http = httpClient ?? http.Client(),
        _appAuth = appAuth ?? const FlutterAppAuth();

  // Web-only PKCE redirect scratch storage.
  static const _kVerifier = 'sv_pkce_verifier';
  static const _kState = 'sv_oauth_state';

  AuthStatus _status = AuthStatus.initializing;
  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  DateTime? _expiry;
  String? _error;

  /// The renewal currently running, so parallel API calls all wait on one
  /// token request instead of racing (and invalidating each other's rotated
  /// refresh token).
  Future<bool>? _refreshInFlight;

  /// Renews the session shortly before the access token runs out.
  Timer? _refreshTimer;

  /// An access token this close to its expiry is treated as already gone, so
  /// a request in flight can't be overtaken by it.
  static const _expirySkew = Duration(seconds: 30);

  /// How long before expiry the proactive renewal runs.
  static const _refreshAhead = Duration(seconds: 60);

  /// Delay before retrying a renewal that failed for a transient reason.
  static const _refreshRetryDelay = Duration(seconds: 30);

  AuthStatus get status => _status;
  String? get accessToken => _accessToken;
  String? get errorMessage => _error;

  /// Email of the signed-in user, read from the id/access token claims.
  /// Falls back to `preferred_username` when no `email` claim is present.
  String? get userEmail {
    final claims = _decodeJwt(_idToken) ?? _decodeJwt(_accessToken);
    if (claims == null) return null;
    return (claims['email'] ?? claims['preferred_username']) as String?;
  }

  /// Realm roles on the access token (`realm_access.roles`), which is where
  /// the backend reads them too. Only the `shift-*` roles matter to the app.
  Set<String> get roles {
    final claims = _decodeJwt(_accessToken) ??
        _decodeJwt(_settings.bearerToken.trim());
    final realm = claims?['realm_access'];
    final list = realm is Map ? realm['roles'] : null;
    return list is List ? list.map((e) => '$e').toSet() : const {};
  }

  /// `shift-planner` or `shift-admin`: may use the management screens.
  bool get canManage =>
      roles.contains('shift-planner') || roles.contains('shift-admin');

  /// `shift-admin`: may also change the wish window and manage users.
  bool get isAdmin => roles.contains('shift-admin');

  Map<String, dynamic>? _decodeJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      return jsonDecode(utf8.decode(base64.decode(payload)))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Login is available on web and native (Android/iOS); other platforms fall
  /// back to the stub browser and can't run the redirect.
  bool get isLoginSupported => kIsWeb || _browser.isSupported || _isNative;

  bool get _isNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  AppSettings get _settings => settingsController.settings;

  bool get _accessTokenValid =>
      _accessToken != null &&
      _expiry != null &&
      DateTime.now().isBefore(_expiry!.subtract(_expirySkew));

  /// Startup: complete a pending web callback, or restore/refresh a stored
  /// session, or land on the login gate.
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        final qp = _browser.currentUri().queryParameters;
        if (qp.containsKey('error')) {
          _browser.replaceUrl('/');
          _fail(qp['error_description'] ?? qp['error']!);
          return;
        }
        if (qp.containsKey('code') && qp.containsKey('state')) {
          await _handleWebCallback(qp['code']!, qp['state']!);
          return;
        }
      }

      await _restoreTokens();
      if (_accessTokenValid) {
        _scheduleProactiveRefresh();
        _setStatus(AuthStatus.authenticated);
      } else if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        final ok = await _refresh();
        _setStatus(ok ? AuthStatus.authenticated : AuthStatus.unauthenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _fail('Startup auth error: $e');
    }
  }

  /// Starts the login flow (redirect on web, AppAuth on native).
  Future<void> login() async {
    if (!_settings.isOidcConfigured) {
      _fail('OIDC is not configured. Open settings to set the issuer/client.');
      return;
    }
    if (kIsWeb) {
      await _webLogin();
    } else if (_isNative) {
      await _nativeLogin();
    } else {
      _fail('Login is not supported on this platform.');
    }
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _expiry = null;
    await _tokens.clear();
    _setStatus(AuthStatus.unauthenticated);
  }

  /// A currently-valid access token, renewing it from the refresh token first
  /// when the cached one has run out.
  ///
  /// [forceRefresh] renews even when the cached token still looks valid — the
  /// API client passes it after a 401, which is the server's word that the
  /// token is no good whatever its stated expiry says.
  ///
  /// Returns null only when the session genuinely cannot be continued (no
  /// refresh token, or the server refused it), which is the point at which the
  /// user is sent back to the sign-in page. A renewal that failed for a
  /// transient reason also yields null, but leaves the session in place so the
  /// next attempt can succeed.
  Future<String?> validAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _accessTokenValid) return _accessToken;
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      // Nothing left to renew with, so the session really is over.
      if (_status == AuthStatus.authenticated) await logout();
      return null;
    }
    if (await _refresh()) return _accessToken;
    return null;
  }

  // ---- native (flutter_appauth) ----

  Future<void> _nativeLogin() async {
    _setStatus(AuthStatus.authenticating);
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _settings.oidcClientId,
          _settings.oidcRedirectUri,
          issuer: _settings.oidcIssuer,
          scopes: _settings.scopeList,
          // Dev backend is served over plain HTTP (e.g. http://10.0.2.2).
          allowInsecureConnections: false,
        ),
      );
      debugPrint('[auth] nativeLogin result: '
          'accessToken=${result.accessToken != null}, '
          'refreshToken=${result.refreshToken != null}, '
          'expiry=${result.accessTokenExpirationDateTime}');
      _applyTokenResponse(
        access: result.accessToken,
        id: result.idToken,
        refresh: result.refreshToken,
        expiry: result.accessTokenExpirationDateTime,
      );
      await _saveTokens();
      _setStatus(AuthStatus.authenticated);
      debugPrint('[auth] nativeLogin -> authenticated');
    } on FlutterAppAuthUserCancelledException catch (e) {
      debugPrint('[auth] nativeLogin cancelled: code=${e.code} message=${e.message}');
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, st) {
      debugPrint('[auth] nativeLogin FAILED: ${e.runtimeType}: $e');
      debugPrint('$st');
      _fail('Login failed: $e');
    }
  }

  Future<bool> _nativeRefresh() async {
    try {
      final result = await _appAuth.token(
        TokenRequest(
          _settings.oidcClientId,
          _settings.oidcRedirectUri,
          issuer: _settings.oidcIssuer,
          refreshToken: _refreshToken,
          grantType: 'refresh_token',
          scopes: _settings.scopeList,
          allowInsecureConnections: true,
        ),
      );
      _applyTokenResponse(
        access: result.accessToken,
        id: result.idToken,
        refresh: result.refreshToken,
        expiry: result.accessTokenExpirationDateTime,
      );
      await _saveTokens();
      notifyListeners();
      return true;
    } catch (e) {
      return _refreshFailed(e);
    }
  }

  // ---- web (redirect) ----

  Future<void> _webLogin() async {
    if (!_browser.isSupported) {
      _fail('Login is only available in the web build of this app.');
      return;
    }
    final verifier = _randomUrlString(64);
    final challenge = _s256Challenge(verifier);
    final state = _randomUrlString(24);
    _browser.storageSet(_kVerifier, verifier);
    _browser.storageSet(_kState, state);

    final authUri = Uri.parse(_settings.authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _settings.oidcClientId,
        'redirect_uri': _settings.oidcRedirectUri,
        'scope': _settings.oidcScopes,
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );

    _setStatus(AuthStatus.authenticating);
    _browser.redirect(authUri.toString());
  }

  Future<void> _handleWebCallback(String code, String state) async {
    final storedState = _browser.storageGet(_kState);
    final verifier = _browser.storageGet(_kVerifier);
    _browser.replaceUrl('/');

    if (storedState == null || storedState != state) {
      _fail('State mismatch — possible CSRF, login aborted.');
      return;
    }
    if (verifier == null) {
      _fail('Missing PKCE verifier — please try signing in again.');
      return;
    }

    // Public client + PKCE: the code_verifier proves possession, no secret.
    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': _settings.oidcRedirectUri,
      'client_id': _settings.oidcClientId,
      'code_verifier': verifier,
    };
    try {
      final res = await _postToken(body);
      _applyTokenJson(res);
      await _saveTokens();
      _browser.storageRemove(_kVerifier);
      _browser.storageRemove(_kState);
      _setStatus(AuthStatus.authenticated);
    } catch (e) {
      _fail('Token exchange failed: $e');
    }
  }

  Future<bool> _webRefresh() async {
    final body = {
      'grant_type': 'refresh_token',
      'refresh_token': _refreshToken!,
      'client_id': _settings.oidcClientId,
    };
    try {
      final res = await _postToken(body);
      _applyTokenJson(res);
      await _saveTokens();
      notifyListeners();
      return true;
    } catch (e) {
      return _refreshFailed(e);
    }
  }

  Future<Map<String, dynamic>> _postToken(Map<String, String> body) async {
    final res = await _http
        .post(
          Uri.parse(_settings.tokenEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TokenEndpointException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---- shared token handling ----

  /// Renews the token set, joining the renewal already running when there is
  /// one. Several calls failing at once (a screen full of requests hitting an
  /// expired token together) must produce a single token request: with refresh
  /// token rotation, parallel ones would invalidate each other.
  Future<bool> _refresh() {
    final running = _refreshInFlight;
    if (running != null) return running;
    final future = (kIsWeb ? _webRefresh() : _nativeRefresh())
        .whenComplete(() => _refreshInFlight = null);
    return _refreshInFlight = future;
  }

  /// OAuth error codes that mean the refresh token itself was refused, in the
  /// text AppAuth wraps the server's answer in.
  static final RegExp _refusedGrant = RegExp(
    r'invalid_grant|invalid_token|invalid_client|unauthorized_client|'
    r'session not active|token is not active',
    caseSensitive: false,
  );

  /// Decides what a failed renewal means.
  ///
  /// A refused refresh token ends the session, and only then is the user sent
  /// back to the sign-in page. A network blip or a server error is not the
  /// user's fault and says nothing about the session: the tokens are kept and
  /// a retry is armed, so a flaky connection never costs a login.
  Future<bool> _refreshFailed(Object error) async {
    final refused = _isRefused(error);
    debugPrint('[auth] refresh failed '
        '(${refused ? 'refused, signing out' : 'transient, keeping session'}): '
        '$error');
    if (refused) {
      await logout();
    } else if (_status == AuthStatus.authenticated) {
      _armRefreshTimer(_refreshRetryDelay);
    }
    return false;
  }

  bool _isRefused(Object error) {
    if (error is TokenEndpointException) {
      // 4xx is the server rejecting the grant; 5xx is the server having a bad
      // day, which the next attempt may well survive.
      return error.statusCode >= 400 && error.statusCode < 500;
    }
    return _refusedGrant.hasMatch(error.toString());
  }

  /// Renews shortly before the access token runs out, so a session that is
  /// only sitting idle never lands on an expired token in the first place.
  void _scheduleProactiveRefresh() {
    if (_refreshToken == null || _refreshToken!.isEmpty || _expiry == null) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      return;
    }
    final due = _expiry!.subtract(_refreshAhead).difference(DateTime.now());
    _armRefreshTimer(due.isNegative ? Duration.zero : due);
  }

  void _armRefreshTimer(Duration delay) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () {
      if (_status == AuthStatus.authenticated) _refresh();
    });
  }

  void _applyTokenJson(Map<String, dynamic> json) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 300;
    _applyTokenResponse(
      access: json['access_token'] as String?,
      id: json['id_token'] as String?,
      refresh: json['refresh_token'] as String?,
      expiry: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  void _applyTokenResponse({
    String? access,
    String? id,
    String? refresh,
    DateTime? expiry,
  }) {
    if (access != null) _accessToken = access;
    if (id != null) _idToken = id;
    if (refresh != null) _refreshToken = refresh;
    _expiry = expiry ?? DateTime.now().add(const Duration(minutes: 5));
    _scheduleProactiveRefresh();
  }

  Future<void> _saveTokens() async {
    await _tokens.write({
      'access_token': _accessToken,
      'id_token': _idToken,
      'refresh_token': _refreshToken,
      'expiry_epoch_ms': _expiry?.millisecondsSinceEpoch,
    });
  }

  Future<void> _restoreTokens() async {
    final data = await _tokens.read();
    _accessToken = _emptyToNull(data['access_token'] as String?);
    _idToken = _emptyToNull(data['id_token'] as String?);
    _refreshToken = _emptyToNull(data['refresh_token'] as String?);
    final ms = data['expiry_epoch_ms'] as int?;
    _expiry = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    if (s != AuthStatus.error) _error = null;
    debugPrint('[auth] status -> $s');
    notifyListeners();
  }

  void _fail(String message) {
    _error = message;
    _status = AuthStatus.error;
    debugPrint('[auth] FAIL: $message');
    notifyListeners();
  }

  String? _emptyToNull(String? v) => (v == null || v.isEmpty) ? null : v;

  String _randomUrlString(int bytes) {
    final rnd = Random.secure();
    final data = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return base64UrlEncode(data).replaceAll('=', '');
  }

  String _s256Challenge(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _http.close();
    super.dispose();
  }
}
