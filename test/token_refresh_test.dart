// An access token running out mid-session must renew itself, not bounce the
// user back to the sign-in page. Only a refresh token the server refuses ends
// the session.

import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/services/api_client.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/auth_browser.dart';
import 'package:shiftviewer/services/auth_service.dart';
import 'package:shiftviewer/services/token_store.dart';

/// Keeps the token set in memory, so the tests never touch the app documents
/// directory (which does not exist under `flutter test`).
class _MemoryTokenStore extends TokenStore {
  _MemoryTokenStore([Map<String, dynamic>? initial])
      : data = initial ?? {},
        super(AuthBrowser());

  Map<String, dynamic> data;
  var cleared = false;

  @override
  Future<Map<String, dynamic>> read() async => Map.of(data);

  @override
  Future<void> write(Map<String, dynamic> values) async =>
      data = Map.of(values);

  @override
  Future<void> clear() async {
    cleared = true;
    data = {};
  }
}

/// Stands in for the native AppAuth bridge: answers the refresh with whatever
/// the test lined up, and counts how often it was asked.
class _FakeAppAuth extends FlutterAppAuth {
  /// Thrown from [token] instead of answering a renewal, when set.
  Object? error;

  var tokenCalls = 0;

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    tokenCalls++;
    // A real refresh is a round trip; yielding lets parallel callers pile up
    // so a missing single-flight guard shows as more than one call.
    await Future<void>.delayed(Duration.zero);
    if (error != null) throw error!;
    return TokenResponse(
      'fresh-access',
      'fresh-refresh',
      DateTime.now().add(const Duration(minutes: 30)),
      null,
      'Bearer',
      null,
      null,
    );
  }
}

Map<String, dynamic> _storedTokens({required Duration expiresIn}) => {
      'access_token': 'stale-access',
      'id_token': null,
      'refresh_token': 'stored-refresh',
      'expiry_epoch_ms':
          DateTime.now().add(expiresIn).millisecondsSinceEpoch,
    };

/// An authenticated controller holding a token that is still valid, so each
/// test can decide for itself when the renewal happens.
Future<(AuthController, _FakeAppAuth, _MemoryTokenStore)> _signedIn() async {
  final store = _MemoryTokenStore(
    _storedTokens(expiresIn: const Duration(hours: 1)),
  );
  final appAuth = _FakeAppAuth();
  final auth = AuthController(
    SettingsController(),
    tokenStore: store,
    appAuth: appAuth,
  );
  await auth.initialize();
  expect(auth.status, AuthStatus.authenticated);
  return (auth, appAuth, store);
}

void main() {
  group('AuthController renewal', () {
    test('an expired access token is renewed at startup, without a re-login',
        () async {
      final store = _MemoryTokenStore(
        _storedTokens(expiresIn: const Duration(seconds: -10)),
      );
      final appAuth = _FakeAppAuth();
      final auth = AuthController(
        SettingsController(),
        tokenStore: store,
        appAuth: appAuth,
      );
      addTearDown(auth.dispose);

      await auth.initialize();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.accessToken, 'fresh-access');
      expect(appAuth.tokenCalls, 1);
      expect(store.data['refresh_token'], 'fresh-refresh');
    });

    test('a refused refresh token ends the session', () async {
      final (auth, appAuth, store) = await _signedIn();
      addTearDown(auth.dispose);
      appAuth.error = Exception('invalid_grant: token is not active');

      final token = await auth.validAccessToken(forceRefresh: true);

      expect(token, isNull);
      expect(auth.status, AuthStatus.unauthenticated);
      expect(store.cleared, isTrue);
    });

    test('a network failure keeps the session and its tokens', () async {
      final (auth, appAuth, store) = await _signedIn();
      addTearDown(auth.dispose);
      appAuth.error = Exception('Connection closed before full header');

      final token = await auth.validAccessToken(forceRefresh: true);

      // Nothing to hand out right now, but the session survives: the next
      // attempt can still renew it.
      expect(token, isNull);
      expect(auth.status, AuthStatus.authenticated);
      expect(store.cleared, isFalse);
      expect(store.data['refresh_token'], 'stored-refresh');

      appAuth.error = null;
      expect(await auth.validAccessToken(forceRefresh: true), 'fresh-access');
    });

    test('parallel renewals share one token request', () async {
      final (auth, appAuth, _) = await _signedIn();
      addTearDown(auth.dispose);

      final tokens = await Future.wait([
        auth.validAccessToken(forceRefresh: true),
        auth.validAccessToken(forceRefresh: true),
        auth.validAccessToken(forceRefresh: true),
      ]);

      expect(tokens, everyElement('fresh-access'));
      expect(appAuth.tokenCalls, 1);
    });

    test('a session with no refresh token left goes back to sign-in', () async {
      final store = _MemoryTokenStore({
        'access_token': 'stale-access',
        'refresh_token': null,
        'expiry_epoch_ms':
            DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      });
      final auth = AuthController(
        SettingsController(),
        tokenStore: store,
        appAuth: _FakeAppAuth(),
      );
      addTearDown(auth.dispose);
      await auth.initialize();

      expect(await auth.validAccessToken(forceRefresh: true), isNull);
      expect(auth.status, AuthStatus.unauthenticated);
    });
  });

  group('ShiftApiClient auth retry', () {
    const settings = AppSettings(baseUrl: 'https://example.test/api/v1');

    test('a 401 is retried once with a renewed token', () async {
      final sent = <String?>[];
      final client = MockClient((request) async {
        final auth = request.headers['Authorization'];
        sent.add(auth);
        if (auth == 'Bearer fresh') {
          return http.Response(jsonEncode([]), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('', 401);
      });

      var forced = false;
      final api = ShiftApiClient(
        settings,
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async {
          forced |= forceRefresh;
          return forceRefresh ? 'fresh' : 'stale';
        },
      );

      await api.listShifts();

      expect(forced, isTrue);
      expect(sent, ['Bearer stale', 'Bearer fresh']);
    });

    test('writes are retried too, body and all', () async {
      final bodies = <String>[];
      final client = MockClient((request) async {
        bodies.add(request.body);
        if (request.headers['Authorization'] == 'Bearer fresh') {
          return http.Response(
            jsonEncode({
              'id': 'w1',
              'employee_id': 'e1',
              'shift_id': 's1',
              'wish_date': '2026-06-01',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 401);
      });

      final api = ShiftApiClient(
        settings,
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async =>
            forceRefresh ? 'fresh' : 'stale',
      );

      final wish = await api.createShiftWish(
        employeeId: 'e1',
        shiftId: 's1',
        date: DateTime(2026, 6, 1),
      );

      expect(wish.id, 'w1');
      expect(bodies, hasLength(2));
      expect(jsonDecode(bodies.last)['employee_id'], 'e1');
    });

    test('no renewal to be had means no second request', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('', 401);
      });

      final api = ShiftApiClient(
        settings,
        client: client,
        // The session is over: the provider has nothing left to hand out.
        tokenProvider: ({bool forceRefresh = false}) async => null,
      );

      await expectLater(
        api.listShifts(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect(requests, 1);
    });
  });
}
