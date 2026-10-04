// The planner/admin area: who gets it, what its API calls send, and the rules
// it checks rotation patterns against.

import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/models/admin_models.dart';
import 'package:shiftviewer/models/models.dart';
import 'package:shiftviewer/screens/admin/audit_log_screen.dart';
import 'package:shiftviewer/services/admin_api.dart';
import 'package:shiftviewer/services/api_client.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/auth_browser.dart';
import 'package:shiftviewer/services/auth_service.dart';
import 'package:shiftviewer/services/rotation_rules.dart';
import 'package:shiftviewer/services/token_store.dart';

class _MemoryTokenStore extends TokenStore {
  _MemoryTokenStore(this.data) : super(AuthBrowser());

  Map<String, dynamic> data;

  @override
  Future<Map<String, dynamic>> read() async => Map.of(data);

  @override
  Future<void> write(Map<String, dynamic> values) async => data = Map.of(values);

  @override
  Future<void> clear() async => data = {};
}

/// An unsigned JWT carrying [roles] as Keycloak realm roles.
String _jwt(List<String> roles) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.'
      '${part({
        'email': 'p@example.org',
        'realm_access': {'roles': ['offline_access', ...roles]},
      })}.sig';
}

Future<AuthController> _signedInAs(List<String> roles) async {
  final auth = AuthController(
    SettingsController(),
    tokenStore: _MemoryTokenStore({
      'access_token': _jwt(roles),
      'id_token': null,
      'refresh_token': 'r',
      'expiry_epoch_ms':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    }),
    appAuth: FlutterAppAuth(),
  );
  await auth.initialize();
  return auth;
}

Shift _shift(String id, String short, String start, String end) => Shift(
  id: id,
  name: id,
  shortName: short,
  color: '#000000',
  order: 0,
  weekdayTimes: [
    for (var d = 0; d < 7; d++)
      WeekdayTime(weekday: d, startTime: start, endTime: end, minEmployees: 1),
  ],
);

AdminApi _api(Future<http.Response> Function(http.Request) handler) => AdminApi(
  ShiftApiClient(
    const AppSettings(baseUrl: 'https://host/api/v1'),
    client: MockClient(handler),
  ),
);

void main() {
  group('management access', () {
    test('a planner may manage but is not an admin', () async {
      final auth = await _signedInAs(['shift-planner']);
      addTearDown(auth.dispose);
      expect(auth.canManage, isTrue);
      expect(auth.isAdmin, isFalse);
    });

    test('an admin may manage and is an admin', () async {
      final auth = await _signedInAs(['shift-admin']);
      addTearDown(auth.dispose);
      expect(auth.canManage, isTrue);
      expect(auth.isAdmin, isTrue);
    });

    test('a viewer gets no management area', () async {
      final auth = await _signedInAs(['shift-viewer']);
      addTearDown(auth.dispose);
      expect(auth.canManage, isFalse);
      expect(auth.isAdmin, isFalse);
    });
  });

  group('AdminApi', () {
    test('an absence is created as a manual, not-present plan', () async {
      late Map<String, dynamic> sent;
      late Uri url;
      final api = _api((req) async {
        url = req.url;
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'p1',
            'employee_id': 'e1',
            'date': '2026-09-18',
            'is_present': false,
            'absence_type': 'sick',
          }),
          201,
        );
      });

      await api.createPlan('e1', DateTime(2026, 9, 18), absenceType: 'sick');

      expect(url.path, '/api/v1/employees/e1/confirmed-shift-plans');
      expect(sent, {
        'date': '2026-09-18',
        'is_present': false,
        'absence_type': 'sick',
        'creation_type': 'manual',
      });
    });

    test('the roster is read page by page until the total is reached', () async {
      final offsets = <String>[];
      final api = _api((req) async {
        final offset = int.parse(req.url.queryParameters['offset']!);
        offsets.add('$offset');
        final count = offset == 0 ? 1000 : 5;
        return http.Response(
          jsonEncode({
            'total': 1005,
            'data': [
              for (var i = 0; i < count; i++)
                {'id': '${offset + i}', 'employee_id': 'e', 'date': '2026-09-01'},
            ],
          }),
          200,
        );
      });

      final plans = await api.plans(DateTime(2026, 9, 1), DateTime(2026, 9, 30));

      expect(plans, hasLength(1005));
      expect(offsets, ['0', '1000']);
    });

    test("a refused write carries the server's reason", () async {
      final api = _api((_) async => http.Response(
            jsonEncode({'error': 'Workstation is closed on 2026-09-18'}),
            409,
          ));

      expect(
        () => api.updatePlan('p1', {'workstation_id': 'w1'}),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('closed'))
            .having((e) => e.statusCode, 'status', 409)),
      );
    });

    test('the assistant is addressed beside the API, under /agent', () {
      final client = ShiftApiClient(const AppSettings(baseUrl: 'https://h/api/v1/'));
      expect(client.agentUri('/plan/validate').toString(),
          'https://h/agent/plan/validate');
      expect(
        ShiftApiClient(const AppSettings(baseUrl: 'https://h/other'))
            .agentUri('/x'),
        isNull,
      );
    });
  });

  test('planner settings keep fields the app does not know about', () {
    final s = PlannerSettings.fromJson({
      'min_rest_hours': 11,
      'some_future_knob': 7,
      'updated_at': '2026-09-01T10:00:00Z',
    }).copyWith({'min_rest_hours': 12});

    expect(s.toRequest(), {'min_rest_hours': 12, 'some_future_knob': 7});
  });

  test('an audit diff names the changed fields, ignoring list order', () {
    final changes = diffStates(
      {'name': 'ICU', 'active_shift_ids': ['a', 'b'], 'updated_at': '1'},
      {'name': 'ICU 2', 'active_shift_ids': ['b', 'a'], 'updated_at': '2'},
    );

    expect(changes.map((c) => c.path), ['name']);
    expect(fieldLabel('active_shift_ids'), 'Active shifts');
  });

  group('rotation rules', () {
    final early = _shift('early', 'F', '06:00:00', '14:00:00');
    final late = _shift('late', 'S', '14:00:00', '22:00:00');
    final night = _shift('night', 'N', '22:00:00', '06:00:00');
    final shifts = [early, late, night];
    const rules = PatternRules(
      maxConsecutiveDays: 6,
      maxWorkingDaysPerWeek: 5,
      minRestHours: 11,
      nightShiftRecoveryDays: 2,
    );

    test('reads short names or names, with - for a day off', () {
      final parsed = parseSequence('F f late, N - x', shifts);
      expect(parsed.slots, ['early', 'early', 'late', 'night', null, null]);
      expect(parsed.unknown, isEmpty);
      expect(parseSequence('F Q', shifts).unknown, ['Q']);
      expect(formatSequence(['early', null, 'night'], shifts), 'F - N');
    });

    test('accepts a rhythm that keeps the rules', () {
      final slots = parseSequence('F F S S N - - -', shifts).slots;
      expect(checkPattern(slots, shifts, rules), isEmpty);
    });

    test('names a late before an early, too many days and work after a night', () {
      final slots = parseSequence('S F F F F F N F', shifts).slots;
      final issues = checkPattern(slots, shifts, rules);
      expect(issues.whereType<RestIssue>(), isNotEmpty);
      expect(issues.whereType<WeeklyIssue>(), isNotEmpty);
      expect(issues.whereType<ConsecutiveIssue>(), isNotEmpty);
      expect(issues.whereType<RecoveryIssue>(), isNotEmpty);
    });

    test('checks across the end of the cycle', () {
      final issues =
          checkPattern(parseSequence('F - - - N', shifts).slots, shifts, rules);
      expect(issues, hasLength(1));
      final r = issues.single as RecoveryIssue;
      expect((r.day, r.shift, r.days), (5, 'N', 2));
    });

    test('a cycle without a day off is an endless run', () {
      final issues =
          checkPattern(parseSequence('F F', shifts).slots, shifts, rules);
      expect(issues.whereType<ConsecutiveIssue>().single.run, isNull);
    });
  });
}
