// Every management screen renders at phone size against a fake backend, and
// the main flows open without layout errors.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/models/admin_models.dart';
import 'package:shiftviewer/models/models.dart';
import 'package:shiftviewer/screens/admin/audit_log_screen.dart';
import 'package:shiftviewer/screens/admin/capabilities_screen.dart';
import 'package:shiftviewer/screens/admin/employees_screen.dart';
import 'package:shiftviewer/screens/admin/fairness_screen.dart';
import 'package:shiftviewer/screens/admin/management_screen.dart';
import 'package:shiftviewer/screens/admin/optimizer_screen.dart';
import 'package:shiftviewer/screens/admin/planner_settings_screen.dart';
import 'package:shiftviewer/screens/admin/roster_screen.dart';
import 'package:shiftviewer/screens/admin/rotations_screen.dart';
import 'package:shiftviewer/screens/admin/shifts_screen.dart';
import 'package:shiftviewer/screens/admin/users_screen.dart';
import 'package:shiftviewer/screens/admin/wish_settings_screen.dart';
import 'package:shiftviewer/screens/admin/workstations_screen.dart';
import 'package:shiftviewer/services/admin_api.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/auth_browser.dart';
import 'package:shiftviewer/services/auth_service.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/services/token_store.dart';

final _today = DateTime.now();
final _monday = DateTime(_today.year, _today.month, _today.day - (_today.weekday - 1));
String _d(DateTime d) => AdminApi.day(d);

final _shiftJson = {
  'id': 's1',
  'name': 'Early',
  'short_name': 'F',
  'color': '#3B82F6',
  'order': 1,
  'weekday_times': [
    for (var w = 0; w < 5; w++)
      {'weekday': w, 'start_time': '06:00:00', 'end_time': '14:00:00', 'min_employees': 2},
  ],
};
final _employeeJson = {
  'id': 'e1',
  'name': 'Anna Admin-Beispiel mit sehr langem Namen',
  'email': 'anna@example.org',
  'monthly_working_hours': 160,
};
final _workstationJson = {
  'id': 'w1',
  'name': 'ICU',
  'available': true,
  'active_shift_ids': ['s1'],
  'priority': 'high',
  'min_employees': 2,
};

Object? _route(http.Request req) {
  final p = req.url.path.replaceFirst('/api/v1', '');
  if (req.method != 'GET') return {'id': 'x'};
  return switch (p) {
    '/employees' => {'data': [_employeeJson], 'total': 1},
    '/employees/e1' => _employeeJson,
    '/employees/e1/capabilities' => [
      {'id': 'c1', 'name': 'ICU nursing', 'level': 2, 'skill_group': 'Nursing'},
    ],
    '/employees/e1/available-shifts' => [_shiftJson],
    '/employees/e1/confirmed-shift-plans' => [
      {'id': 'l1', 'employee_id': 'e1', 'date': _d(_today.add(const Duration(days: 3))), 'is_present': false, 'absence_type': 'day_off'},
      {'id': 'l2', 'employee_id': 'e1', 'date': _d(_today.add(const Duration(days: 4))), 'is_present': false, 'absence_type': 'day_off'},
    ],
    '/unavailabilities' => [
      {'id': 'u1', 'employee_id': 'e1', 'unavailable_date': _d(_today.subtract(const Duration(days: 20)))},
    ],
    '/employees/e1/personal-limits' => {
      'employee_id': 'e1',
      'max_nights_per_month': null,
      'max_weekends_per_month': null,
      'no_night_shifts': false,
      'preferred_days_off': <int>[],
      'updated_at': null,
    },
    '/holidays' => {'state': 'by', 'enabled': true, 'holidays': <Object>[]},
    '/shifts' => [_shiftJson],
    '/workstations' => [_workstationJson],
    '/workstations/w1/required-capabilities' => [
      {'id': 'c1', 'name': 'ICU nursing'},
    ],
    '/workstations/w1/unavailabilities' => [
      {'id': 'cl1', 'workstation_id': 'w1', 'unavailable_from': _d(_today), 'unavailable_to': _d(_today.add(const Duration(days: 2)))},
    ],
    '/workstation-unavailabilities' => <Object>[],
    '/capabilities' => [
      {'id': 'c1', 'name': 'ICU nursing', 'level': 2, 'skill_group': 'Nursing'},
      {'id': 'c2', 'name': 'Forklift', 'level': 1, 'skill_group': null},
    ],
    '/confirmed-shift-plans' => {
      'total': 2,
      'data': [
        {'id': 'p1', 'employee_id': 'e1', 'shift_id': 's1', 'workstation_id': 'w1', 'date': _d(_monday), 'is_present': true},
        {'id': 'p2', 'employee_id': 'e1', 'date': _d(_monday.add(const Duration(days: 1))), 'is_present': false, 'absence_type': 'sick'},
      ],
    },
    '/shift-wishes' => [
      {'id': 'wi1', 'employee_id': 'e1', 'shift_id': 's1', 'wish_date': _d(_monday)},
    ],
    '/wish-settings' => {'mode': 'date_range', 'window_start': '2026-10-01', 'window_end': '2026-10-31'},
    '/planner-settings' => {
      'night_shift_recovery_days': 2,
      'min_rest_hours': 11,
      'max_consecutive_days': 6,
      'max_working_days_per_week': 5,
      'equality_weight': 50000,
      'priority_weights': {'high': 10000, 'medium': 1000, 'low': 100},
      'monthly_hours_target_weight': 1000,
      'solver_time_limit_seconds': 120,
      'solver_num_workers': 8,
      'weekly_min_hours': null,
      'weekly_max_hours': null,
      'weekly_hours_target_weight': 1000,
      'preference_weight': 300,
      'wish_weight': 20000,
      'skill_downgrade_weight': 200,
      'fatigue_weight': 100,
      'night_shift_fatigue_multiplier': 2,
      'shift_continuity_weight': 500,
      'shift_continuity_week_bonus': 2000,
      'min_staffing_mode': 'soft',
      'keep_fixed_assignments': true,
      'updated_at': '2026-09-01T10:00:00Z',
    },
    '/rotation-patterns' => [
      {'id': 'r1', 'name': 'Ward A', 'slots': ['s1', 's1', null, null]},
    ],
    '/planner/tasks' => {
      'tasks': [
        {'id': 't1', 'status': 'done', 'result_id': 'res1', 'created_at': '2026-09-17T08:00:00Z'},
        {'id': 't2', 'status': 'error', 'error_message': 'infeasible', 'created_at': '2026-09-16T08:00:00Z'},
      ],
    },
    '/planner/optimized-shifts/res1' => {
      'id': 'res1',
      'creation_date': '2026-09-17T08:00:00Z',
      'result': {
        'status': 'OPTIMAL',
        'objective_value': 1234,
        'planning_period': {'start_date': '2026-10-01', 'end_date': '2026-10-07'},
        'employee_plans': [
          {
            'employee_id': 'e1',
            'employee_name': 'Anna',
            'daily_plan': [
              for (var i = 1; i <= 7; i++)
                {'date': '2026-10-0$i', 'status': i < 4 ? 'assigned' : 'free', 'shift_id': i < 4 ? 's1' : null, 'shift_name': 'Early'},
            ],
          },
        ],
      },
    },
    '/analysis/fairness' => {
      'employees': [
        {'employee_id': 'e1', 'employee_name': 'Anna', 'shifts': 12, 'hours': 96, 'target_hours': 160, 'night_shifts': 3, 'weekend_days': 4, 'weekends': 2, 'wishes_asked': 2, 'wishes_granted': 1, 'days_absent': 1},
      ],
    },
    '/audit-logs' => {
      'total': 1,
      'data': [
        {'id': 'a1', 'actor': 'planner', 'action': 'workstation.update', 'entity_type': 'workstation', 'entity_id': 'w1', 'changes': jsonEncode(_workstationJson), 'created_at': '2026-09-17T08:00:00Z'},
      ],
    },
    '/audit-logs/facets' => {'actions': ['workstation.update'], 'entity_types': ['workstation'], 'actors': ['planner']},
    '/users' => [
      {'id': 'k1', 'username': 'anna', 'email': 'anna@example.org', 'first_name': 'Anna', 'last_name': 'A', 'enabled': true, 'roles': ['shift-planner']},
    ],
    _ => <Object>[],
  };
}

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

String _adminJwt() {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({
    'realm_access': {'roles': ['shift-admin']},
  })}.sig';
}

class _Settings extends SettingsController {
  @override
  AppSettings get settings => const AppSettings(baseUrl: 'https://host/api/v1');
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final settings = _Settings();
  final auth = AuthController(
    settings,
    tokenStore: _MemoryTokenStore({
      'access_token': _adminJwt(),
      'refresh_token': 'r',
      'expiry_epoch_ms':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    }),
    appAuth: FlutterAppAuth(),
  );
  await tester.runAsync(auth.initialize);

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(value: settings),
      ChangeNotifierProvider(
        create: (_) => ShiftDataController(
          settings.settings,
          httpClientFactory: () => MockClient((req) async => http.Response(
                jsonEncode(_route(req)),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )),
        ),
      ),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('management hub shows admin entries and the overview', (t) async {
    await _pump(t, const ManagementScreen());
    expect(find.text('Verwaltung'), findsOneWidget);
    expect(find.text('Heute unterbesetzt'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Benutzer'), 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('managementList')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Wunschzeitraum'), findsOneWidget);
  });

  testWidgets('roster shows the week and opens the day editor', (t) async {
    await _pump(t, const RosterScreen());
    expect(find.text('F'), findsWidgets);
    await t.tap(find.text('F').first);
    await t.pumpAndSettle();
    expect(find.text('Gewünscht: Early'), findsOneWidget);
    expect(find.text('Tag leeren'), findsOneWidget);
  });

  testWidgets('employee list and editor with leave groups', (t) async {
    await _pump(t, const EmployeesScreen());
    await t.tap(find.textContaining('Anna').first);
    await t.pumpAndSettle();
    expect(find.text('ICU nursing · 2'), findsOneWidget);
    await t.scrollUntilVisible(find.textContaining('2 Tage'), 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('employeeEditorList')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.textContaining('2 Tage'), findsOneWidget);
  });

  testWidgets('shift list and editor', (t) async {
    await _pump(t, const ShiftsScreen());
    await t.tap(find.text('Early'));
    await t.pumpAndSettle();
    expect(find.text('Kürzel'), findsOneWidget);
  });

  testWidgets('workstation list and editor', (t) async {
    await _pump(t, const WorkstationsScreen());
    await t.tap(find.text('ICU'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Schließzeiten'), 200,
        scrollable: find.ancestor(
            of: find.text('Aktiv'), matching: find.byType(Scrollable)).last);
    expect(find.text('Schließzeiten'), findsOneWidget);
  });

  testWidgets('capabilities grouped, with the edit dialog', (t) async {
    await _pump(t, const CapabilitiesScreen());
    expect(find.text('Nursing'), findsOneWidget);
    await t.tap(find.text('Forklift'));
    await t.pumpAndSettle();
    expect(find.text('Qualifikation bearbeiten'), findsOneWidget);
  });

  testWidgets('planner settings with levels and expert values', (t) async {
    await _pump(t, const PlannerSettingsScreen());
    expect(find.text('Ausgewogen'), findsWidgets);
    await t.tap(find.byTooltip('Expertenwerte'));
    await t.pumpAndSettle();
    await t.tap(find.text('Wünsche zuerst'));
    await t.pumpAndSettle();
    expect(find.textContaining('Gewünschte Dienste'), findsOneWidget);
  });

  testWidgets('wish window is editable for an admin', (t) async {
    await _pump(t, const WishSettingsScreen());
    expect(find.text('Zeitraum'), findsOneWidget);
    expect(find.text('Speichern'), findsOneWidget);
  });

  testWidgets('users with their roles', (t) async {
    await _pump(t, const UsersScreen());
    await t.tap(find.text('Anna A'));
    await t.pumpAndSettle();
    expect(find.text('Planer'), findsOneWidget);
  });

  testWidgets('audit log entry expands and compares', (t) async {
    await _pump(t, const AuditLogScreen());
    await t.tap(find.textContaining('Workstation update'));
    await t.pumpAndSettle();
    expect(find.text('Mit vorherigem vergleichen'), findsOneWidget);
  });

  testWidgets('rotations list, pattern dialog and apply screen', (t) async {
    await _pump(t, const RotationsScreen());
    expect(find.text('Ward A'), findsOneWidget);
    await t.tap(find.byTooltip('Bearbeiten'));
    await t.pumpAndSettle();
    expect(find.text('Passt zu den Regeln des Planers.'), findsOneWidget);
    await t.tap(find.text('Abbrechen'));
    await t.pumpAndSettle();
    await t.tap(find.text('Anwenden'));
    await t.pumpAndSettle();
    expect(find.text('Versatz'), findsOneWidget);
  });

  testWidgets('optimizer runs and a proposed plan', (t) async {
    await _pump(t, const OptimizerScreen());
    expect(find.text('Fertig'), findsOneWidget);
    expect(find.textContaining('infeasible'), findsOneWidget);
    await t.tap(find.text('Fertig'));
    await t.pumpAndSettle();
    expect(find.text('Als Plan übernehmen'), findsOneWidget);
  });

  testWidgets('fairness table', (t) async {
    await _pump(t, const FairnessScreen());
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('-64'), findsOneWidget);
  });

  test('models decode what the screens rely on', () {
    final r = OptimizedResult.fromJson(
        _route(http.Request('GET', Uri.parse('https://h/api/v1/planner/optimized-shifts/res1')))
            as Map<String, dynamic>);
    expect(r.assignmentCount, 3);
    expect(Shift.fromJson(_shiftJson).weekdayTimes, hasLength(5));
  });
}
