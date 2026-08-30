// Tapping a shift or a person in the day view opens a sheet of numbers. These
// checks cover the arithmetic behind those numbers, and that the sheets still
// stand up when the `/analysis/*` endpoints refuse to answer.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/day_insights.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/widgets/day_detail.dart';

const _base = 'https://example.test/api/v1';

/// Mon 1 – Sun 7 June 2026.
final _from = DateTime(2026, 6, 1);
final _to = DateTime(2026, 6, 7);
final _monday = DateTime(2026, 6, 1);

/// Runs Mon–Fri 06:00–14:00, wants 2 people and tolerates 3.
final _early = {
  'id': 'early',
  'name': 'Early',
  'short_name': 'E',
  'color': '#FF0000',
  'order': 1,
  'weekday_times': [
    for (int weekday = 0; weekday < 5; weekday++)
      {
        'weekday': weekday,
        'start_time': '06:00',
        'end_time': '14:00',
        'min_employees': 2,
        'max_employees': 3,
        'free_days_after_shift': 0,
      },
  ],
};

/// Runs every day 22:00–06:00 — eight hours over midnight.
final _night = {
  'id': 'night',
  'name': 'Night',
  'short_name': 'N',
  'color': '#0000FF',
  'order': 2,
  'weekday_times': [
    for (int weekday = 0; weekday < 7; weekday++)
      {
        'weekday': weekday,
        'start_time': '22:00',
        'end_time': '06:00',
        'min_employees': 1,
        'free_days_after_shift': 2,
      },
  ],
};

Map<String, dynamic> _plan(
  String id,
  String employeeId,
  String date, {
  String? shiftId,
  String? workstationId,
  bool present = true,
  String? absenceType,
}) => {
  'id': id,
  'employee_id': employeeId,
  'shift_id': shiftId,
  'workstation_id': workstationId,
  'date': date,
  'is_present': present,
  'absence_type': absenceType,
  'creation_type': 'manual',
};

/// Monday: Ada and Bo on early at w1, Cy on early at w2 but off sick, Dee on
/// night. Tuesday: Ada on early again, so the week pattern has two bars.
final _plans = [
  _plan('p1', 'e1', '2026-06-01', shiftId: 'early', workstationId: 'w1'),
  _plan('p2', 'e2', '2026-06-01', shiftId: 'early', workstationId: 'w1'),
  _plan(
    'p3',
    'e3',
    '2026-06-01',
    shiftId: 'early',
    workstationId: 'w2',
    present: false,
    absenceType: 'sick',
  ),
  _plan('p4', 'e4', '2026-06-01', shiftId: 'night'),
  _plan('p5', 'e1', '2026-06-02', shiftId: 'early', workstationId: 'w1'),
];

final _wishes = [
  // Ada got the early shift she asked for; Bo asked for night and did not.
  {
    'id': 'w1',
    'employee_id': 'e1',
    'shift_id': 'early',
    'wish_date': '2026-06-01',
  },
  {
    'id': 'w2',
    'employee_id': 'e2',
    'shift_id': 'night',
    'wish_date': '2026-06-01',
  },
];

/// The staffing figures the analysis endpoints report for Monday.
final _staffing = [
  {
    'date': '2026-06-01',
    'employees_working': 3,
    'employees': [
      {
        'employee_id': 'e1',
        'employee_name': 'Ada Lovelace',
        'shift_id': 'early',
        'shift_name': 'Early',
        'workstation_id': 'w1',
        'workstation_name': 'Triage',
      },
    ],
    'per_shift': [
      {'shift_id': 'early', 'shift_name': 'Early', 'employees_working': 2},
      {'shift_id': 'night', 'shift_name': 'Night', 'employees_working': 1},
    ],
  },
];

/// Records every analysis path the client asks for, so a test can assert the
/// sheet only pays for the day it is showing.
final analysisCalls = <String>[];

http.Client _fakeApi({bool analysis = true}) => MockClient((request) async {
  final path = request.url.path.replaceFirst('/api/v1', '');
  if (path.startsWith('/analysis/')) {
    analysisCalls.add(path);
    if (!analysis) return http.Response('forbidden', 403);
  }
  final body = switch (path) {
    '/shifts' => [_early, _night],
    '/employees' => [
      {
        'id': 'e1',
        'name': 'Ada Lovelace',
        'email': 'ada@example.test',
        'monthly_working_hours': 160.0,
      },
      {
        'id': 'e2',
        'name': 'Bo Peep',
        'email': 'bo@example.test',
        'monthly_working_hours': 80.0,
      },
      {'id': 'e3', 'name': 'Cy Young', 'email': 'cy@example.test'},
      {'id': 'e4', 'name': 'Dee Dee', 'email': 'dee@example.test'},
    ],
    '/employees/e1' => {
      'id': 'e1',
      'name': 'Ada Lovelace',
      'email': 'ada@example.test',
      'monthly_working_hours': 160.0,
      'capabilities': [
        {'id': 'c1', 'name': 'MRT', 'level': 3, 'skill_group': 'imaging'},
        {'id': 'c2', 'name': 'First aid'},
      ],
      'available_shifts': [_early],
    },
    '/workstations' => [
      {
        'id': 'w1',
        'name': 'Triage',
        'available': true,
        'active_shift_ids': ['early'],
        'priority': 'high',
        'min_employees': 3,
        'max_employees': 4,
      },
      {
        'id': 'w2',
        'name': 'Ward',
        'available': false,
        'active_shift_ids': ['early'],
        'priority': 'medium',
        'min_employees': 1,
      },
    ],
    '/confirmed-shift-plans' => {'data': _plans},
    '/shift-wishes' => _wishes,
    '/wish-settings' => {'mode': 'enabled'},
    '/analysis/staffing-per-day' => _staffing,
    '/analysis/planned-hours-per-day-per-workstation' => [
      {
        'date': '2026-06-01',
        'workstation_id': 'w1',
        'workstation_name': 'Triage',
        'planned_hours': 16.0,
      },
    ],
    '/analysis/planned-employees-per-day-per-workstation' => [
      {
        'date': '2026-06-01',
        'workstation_id': 'w1',
        'workstation_name': 'Triage',
        'planned_employees': 2,
      },
    ],
    _ => <dynamic>[],
  };
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
});

Future<ShiftDataController> _loaded({bool analysis = true}) async {
  analysisCalls.clear();
  final data = ShiftDataController(
    const AppSettings(baseUrl: _base),
    httpClientFactory: () => _fakeApi(analysis: analysis),
  );
  await data.refresh(_from, _to);
  return data;
}

Widget _dayHost(ShiftDataController data, {String locale = 'en'}) =>
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DayShiftList(day: _monday, data: data),
      ),
    );

/// `MapEntry` has no value equality, so ranked counts are compared as strings.
List<String> _pairs(List<MapEntry<String, int>> entries) => [
  for (final e in entries) '${e.key}=${e.value}',
];

void main() {
  group('shift insight', () {
    test('splits the roster into present, absent and their reasons', () async {
      final data = await _loaded();
      final insight = buildShiftInsight(data, day: _monday, shiftId: 'early');

      expect(insight.rostered, 3);
      expect(insight.present, 2);
      expect(insight.absent, 1);
      expect(_pairs(insight.absencesByType), ['sick=1']);
    });

    test('reads coverage against the weekday minimum and maximum', () async {
      final data = await _loaded();
      final early = buildShiftInsight(data, day: _monday, shiftId: 'early');

      // Two present against a minimum of two: met, with nothing missing.
      expect(early.minRequired, 2);
      expect(early.maxAllowed, 3);
      expect(early.coverage, Coverage.met);
      expect(early.missing, 0);
    });

    test('counts a shift the weekday minimum outruns as short', () async {
      final data = await _loaded();
      // Sunday: the early shift does not run, the night shift does and nobody
      // is on it.
      final night = buildShiftInsight(
        data,
        day: DateTime(2026, 6, 7),
        shiftId: 'night',
      );

      expect(night.present, 0);
      expect(night.coverage, Coverage.under);
      expect(night.missing, 1);
    });

    test(
      'a shift that does not run that weekday has nothing to miss',
      () async {
        final data = await _loaded();
        final early = buildShiftInsight(
          data,
          day: DateTime(2026, 6, 7),
          shiftId: 'early',
        );

        expect(early.times, isNull);
        expect(early.coverage, Coverage.unknown);
      },
    );

    test('books the weekday hours for everyone present', () async {
      final data = await _loaded();
      final early = buildShiftInsight(data, day: _monday, shiftId: 'early');
      // 06:00–14:00 is eight hours, two people turned up.
      expect(early.plannedHours, 16);

      // A night shift crosses midnight and is still eight hours.
      final night = buildShiftInsight(data, day: _monday, shiftId: 'night');
      expect(night.plannedHours, 8);
    });

    test('groups the shift by workstation, unassigned last', () async {
      final data = await _loaded();
      final analysis = await data.analysisForDay(_monday);
      final early = buildShiftInsight(
        data,
        day: _monday,
        shiftId: 'early',
        analysis: analysis,
      );

      expect(early.workstations.map((w) => w.id), ['w1', 'w2']);
      final triage = early.workstations.first;
      expect(triage.present, 2);
      expect(triage.plannedHours, 16.0);
      expect(triage.plannedEmployees, 2);
      // Triage wants three people and has two of them.
      expect(triage.understaffed, isTrue);

      final ward = early.workstations.last;
      expect(ward.present, 0, reason: 'Cy is rostered there but off sick');
      expect(ward.station!.available, isFalse);
    });

    test(
      'counts wishes for the shift and which of them were granted',
      () async {
        final data = await _loaded();
        final early = buildShiftInsight(data, day: _monday, shiftId: 'early');
        expect(early.wishes, 1);
        expect(early.wishesGranted, 1);

        final night = buildShiftInsight(data, day: _monday, shiftId: 'night');
        expect(night.wishes, 1, reason: "Bo asked for the night shift");
        expect(night.wishesGranted, 0, reason: 'but was not rostered on it');
      },
    );

    test('lays the shift out across its own week, Monday first', () async {
      final data = await _loaded();
      final early = buildShiftInsight(data, day: _monday, shiftId: 'early');
      expect(early.weekPattern, [2, 1, 0, 0, 0, 0, 0]);
    });

    test('takes the day head count from the server when it answers', () async {
      final data = await _loaded();
      final analysis = await data.analysisForDay(_monday);
      final early = buildShiftInsight(
        data,
        day: _monday,
        shiftId: 'early',
        analysis: analysis,
      );

      expect(early.analysisReachable, isTrue);
      expect(early.serverCount, 2);
      expect(early.dayTotal, 3);
      expect(early.shareOfDay, closeTo(2 / 3, 0.001));
    });

    test('falls back to the roster when analysis is refused', () async {
      final data = await _loaded(analysis: false);
      final analysis = await data.analysisForDay(_monday);
      final early = buildShiftInsight(
        data,
        day: _monday,
        shiftId: 'early',
        analysis: analysis,
      );

      expect(analysis.reachable, isFalse);
      expect(early.serverCount, isNull);
      // Everything the roster knows is still there.
      expect(early.present, 2);
      expect(early.dayTotal, 3, reason: 'counted from the loaded plans');
      expect(early.workstations.first.plannedHours, isNull);
    });

    test('fetches a day once and answers the rest from the cache', () async {
      final data = await _loaded();
      await data.analysisForDay(_monday);
      await data.analysisForDay(_monday);
      // Three endpoints, one round of calls.
      expect(analysisCalls.length, 3);
    });

    test('splits the day across every shift, in roster order', () async {
      final data = await _loaded();
      final analysis = await data.analysisForDay(_monday);
      final slices = dayShiftSplit(data, _monday, analysis: analysis);

      expect(slices.map((s) => s.shiftId), ['early', 'night']);
      expect(slices.map((s) => s.count), [2, 1]);
    });
  });

  group('employee insight', () {
    test('totals the loaded range, not just the day', () async {
      final data = await _loaded();
      final ada = buildEmployeeInsight(data, day: _monday, employeeId: 'e1');

      expect(ada.from, DateTime(2026, 6, 1));
      expect(ada.to, DateTime(2026, 6, 7));
      expect(ada.rosteredDays, 2);
      expect(ada.workedDays, 2);
      expect(ada.absentDays, 0);
      expect(ada.plannedHours, 16, reason: 'two early shifts of eight hours');
      expect(_pairs(ada.daysByShift), ['early=2']);
    });

    test('names the absence and keeps it out of the worked days', () async {
      final data = await _loaded();
      final cy = buildEmployeeInsight(data, day: _monday, employeeId: 'e3');

      expect(cy.rosteredDays, 1);
      expect(cy.workedDays, 0);
      expect(cy.absentDays, 1);
      expect(_pairs(cy.absencesByType), ['sick=1']);
      expect(cy.plannedHours, 0);
    });

    test('measures the range against the monthly target', () async {
      final data = await _loaded();
      final detail = await data.employeeDetail('e1');
      final ada = buildEmployeeInsight(
        data,
        day: _monday,
        employeeId: 'e1',
        detail: detail,
      );

      expect(ada.monthlyLoad, closeTo(16 / 160, 0.0001));
      // The single-employee read is the only place capabilities come from.
      expect(
        ada.employee!.capabilities.map((c) => c.name),
        containsAll(['MRT', 'First aid']),
      );
      expect(ada.employee!.capabilities.first.level, 3);
      expect(ada.employee!.availableShifts.single.id, 'early');
    });

    test('has no monthly load when the roster sets no target', () async {
      final data = await _loaded();
      final cy = buildEmployeeInsight(data, day: _monday, employeeId: 'e3');
      expect(cy.monthlyLoad, isNull);
    });

    test('scores wishes against what was actually rostered', () async {
      final data = await _loaded();
      expect(
        buildEmployeeInsight(data, day: _monday, employeeId: 'e1').wishHitRate,
        1.0,
      );
      expect(
        buildEmployeeInsight(data, day: _monday, employeeId: 'e2').wishHitRate,
        0.0,
      );
    });
  });

  group('the day view opens them', () {
    testWidgets('tapping a shift header opens its statistics', (tester) async {
      final data = await _loaded();
      await tester.pumpWidget(_dayHost(data));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Early'));
      await tester.pumpAndSettle();

      // The sheet's own headings, not the list underneath.
      expect(find.text('Fully staffed'), findsOneWidget);
      expect(find.text('WORKSTATIONS'), findsOneWidget);
      expect(find.text('Sick · 1'), findsOneWidget);
      expect(find.text('1 wish for this shift'), findsOneWidget);
    });

    testWidgets('tapping a person opens their own sheet', (tester) async {
      final data = await _loaded();
      await tester.pumpWidget(_dayHost(data));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ada Lovelace'));
      await tester.pumpAndSettle();

      expect(find.text('ada@example.test'), findsOneWidget);
      expect(find.text('CAPABILITIES'), findsOneWidget);
      expect(find.text('MRT · Level 3'), findsOneWidget);
    });

    testWidgets('both sheets survive a narrow phone', (tester) async {
      // Overflows throw in a widget test, so a plain pump is the assertion.
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final data = await _loaded();
      await tester.pumpWidget(_dayHost(data));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Early'));
      await tester.pumpAndSettle();
      expect(find.text('WORKSTATIONS'), findsOneWidget);
      await tester.tapAt(const Offset(180, 20)); // dismiss the sheet
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ada Lovelace'));
      await tester.pumpAndSettle();
      expect(find.text('CAPABILITIES'), findsOneWidget);
    });

    testWidgets('reads in German too', (tester) async {
      final data = await _loaded();
      await tester.pumpWidget(_dayHost(data, locale: 'de'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Early'));
      await tester.pumpAndSettle();
      expect(find.text('Vollständig besetzt'), findsOneWidget);
      expect(find.text('ARBEITSPLÄTZE'), findsOneWidget);
      expect(find.text('Krank · 1'), findsOneWidget);
    });

    testWidgets('the sheet still opens when analysis is refused', (
      tester,
    ) async {
      final data = await _loaded(analysis: false);
      await tester.pumpWidget(_dayHost(data));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Early'));
      await tester.pumpAndSettle();

      expect(find.text('Fully staffed'), findsOneWidget);
      expect(
        find.textContaining('Server statistics are unavailable'),
        findsOneWidget,
      );
    });
  });
}
