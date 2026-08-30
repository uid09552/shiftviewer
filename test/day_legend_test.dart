// The panel under the month grid and week strip: what the tapped date's
// colours mean.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/widgets/day_legend.dart';

const _base = 'https://example.test/api/v1';

final _busyDay = DateTime(2026, 6, 10);
final _quietDay = DateTime(2026, 6, 11);

/// Two shifts, so the legend has more than one colour to explain.
List<Map<String, dynamic>> get _shifts => [
      _shift('early', 'Early', 'E', '#D32F2F', 1, '06:00', '14:00'),
      _shift('late', 'Late', 'L', '#1976D2', 2, '14:00', '22:00'),
    ];

Map<String, dynamic> _shift(String id, String name, String short, String color,
        int order, String from, String to) =>
    {
      'id': id,
      'name': name,
      'short_name': short,
      'color': color,
      'order': order,
      'weekday_times': [
        for (int weekday = 0; weekday < 7; weekday++)
          {
            'weekday': weekday,
            'start_time': from,
            'end_time': to,
            'min_employees': 1,
          },
      ],
    };

/// Ada works Early at Triage on the busy day; Bob works Late, unassigned.
final _plans = [
  {
    'id': 'p1',
    'employee_id': 'e1',
    'shift_id': 'early',
    'workstation_id': 'ws1',
    'date': '2026-06-10',
    'is_present': true,
    'creation_type': 'manual',
  },
  {
    'id': 'p2',
    'employee_id': 'e2',
    'shift_id': 'late',
    'date': '2026-06-10',
    'is_present': true,
    'creation_type': 'manual',
  },
];

http.Client _fakeApi() => MockClient((request) async {
      final path = request.url.path.replaceFirst('/api/v1', '');
      final body = switch (path) {
        '/shifts' => _shifts,
        '/employees' => [
            {'id': 'e1', 'name': 'Ada', 'email': 'ada@example.test'},
            {'id': 'e2', 'name': 'Bob', 'email': 'bob@example.test'},
          ],
        '/workstations' => [
            {'id': 'ws1', 'name': 'Triage', 'available': true}
          ],
        '/confirmed-shift-plans' => {'data': _plans},
        _ => <dynamic>[],
      };
      return http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json'});
    });

Future<ShiftDataController> _loaded({String? employeeId}) async {
  final data = ShiftDataController(
    const AppSettings(baseUrl: _base),
    httpClientFactory: _fakeApi,
  );
  await data.refresh(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
  if (employeeId != null) data.selectEmployee(employeeId);
  return data;
}

Future<void> _pump(WidgetTester tester, ShiftDataController data, DateTime day,
    {VoidCallback? onOpenDay}) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Column(
        children: [
          const Spacer(),
          DayLegend(day: day, data: data, onOpenDay: onOpenDay),
        ],
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('names every shift on the day, with swatch, hours and headcount',
      (tester) async {
    await _pump(tester, await _loaded(), _busyDay);

    expect(find.text('Wednesday, June 10'), findsOneWidget);
    expect(find.text('2 working'), findsOneWidget);
    // Each shift's short name doubles as its colour swatch, as on the grid.
    expect(find.text('E'), findsOneWidget);
    expect(find.text('Early'), findsOneWidget);
    expect(find.text('06:00 – 14:00'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('Late'), findsOneWidget);
    expect(find.text('14:00 – 22:00'), findsOneWidget);
  });

  testWidgets('points out the selected employee’s own shift and workstation',
      (tester) async {
    await _pump(tester, await _loaded(employeeId: 'e1'), _busyDay);

    expect(find.text('Triage'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('says so when the selected employee is off that day',
      (tester) async {
    // Bob is on Late, so pick the employee who is not: Ada is off on the 11th.
    await _pump(tester, await _loaded(employeeId: 'e1'), _quietDay);

    expect(find.text('No shifts scheduled'), findsOneWidget);
    expect(find.text('Early'), findsNothing);
  });

  testWidgets('flags an employee with no shift on an otherwise busy day',
      (tester) async {
    final data = await _loaded(employeeId: 'e3');

    await _pump(tester, data, _busyDay);

    expect(find.text('Early'), findsOneWidget, reason: 'other people work');
    expect(find.text('Off — no shift'), findsOneWidget);
  });

  testWidgets('offers the way through to the full day view', (tester) async {
    var opened = 0;
    await _pump(tester, await _loaded(), _busyDay, onOpenDay: () => opened++);

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });
}
