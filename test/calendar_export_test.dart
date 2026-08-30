// Getting confirmed shifts out of the roster and into a calendar: which plans
// become events, what the iCalendar document says, and what the Google
// Calendar link looks like.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/calendar_export.dart';
import 'package:shiftviewer/services/calendar_handoff.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/widgets/calendar_export_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

const _base = 'https://example.test/api/v1';

/// Mon 1 – Fri 5 June 2026, the week the fixture rosters.
final _from = DateTime(2026, 6, 1);
final _to = DateTime(2026, 6, 5);

/// Runs Mon–Fri, 06:00–14:00.
final _earlyShift = {
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
        'min_employees': 1,
      },
  ],
};

/// Runs every day and crosses midnight — 22:00 to 06:00 the next morning.
final _nightShift = {
  'id': 'night',
  'name': 'Night, late',
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
      },
  ],
};

/// Has no hours configured at all, so it can only be an all-day entry.
final _onCallShift = <String, dynamic>{
  'id': 'oncall',
  'name': 'On call',
  'short_name': 'O',
  'color': '#00FF00',
  'order': 3,
  'weekday_times': <dynamic>[],
};

Map<String, dynamic> _plan(
  String id,
  String employeeId,
  String date, {
  String? shiftId,
  String? workstationId,
  bool present = true,
  String? absenceType,
}) =>
    {
      'id': id,
      'employee_id': employeeId,
      'shift_id': shiftId,
      'workstation_id': workstationId,
      'date': date,
      'is_present': present,
      'absence_type': absenceType,
      'creation_type': 'manual',
    };

/// Ada works Mon early, Tue night and Fri on call; she is off sick on Wed and
/// simply not rostered on Thu. Bo shares the Monday early shift.
final _plans = [
  _plan('p1', 'e1', '2026-06-01', shiftId: 'early', workstationId: 'w1'),
  _plan('p2', 'e1', '2026-06-02', shiftId: 'night'),
  _plan('p3', 'e1', '2026-06-03',
      shiftId: 'early', present: false, absenceType: 'sick'),
  _plan('p4', 'e1', '2026-06-04'),
  _plan('p5', 'e1', '2026-06-05', shiftId: 'oncall'),
  _plan('p6', 'e2', '2026-06-01', shiftId: 'early', workstationId: 'w1'),
];

http.Client _fakeApi() => MockClient((request) async {
      final path = request.url.path.replaceFirst('/api/v1', '');
      final body = switch (path) {
        '/shifts' => [_earlyShift, _nightShift, _onCallShift],
        '/employees' => [
            {'id': 'e1', 'name': 'Ada Lovelace', 'email': 'ada@example.test'},
            {'id': 'e2', 'name': 'Bo Peep', 'email': 'bo@example.test'},
          ],
        '/workstations' => [
            {'id': 'w1', 'name': 'Triage, room 2', 'available': true}
          ],
        '/confirmed-shift-plans' => {'data': _plans},
        '/wish-settings' => {'mode': 'enabled'},
        _ => <dynamic>[],
      };
      return http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json'});
    });

Future<ShiftDataController> _loaded({String? employeeId = 'e1'}) async {
  final data = ShiftDataController(
    const AppSettings(baseUrl: _base),
    httpClientFactory: _fakeApi,
  );
  await data.refresh(_from, _to);
  data.selectEmployee(employeeId);
  return data;
}

CalendarEntry _entryFor(CalendarExportSelection selection, String planId) =>
    selection.entries.firstWhere((e) => e.planId == planId);

Widget _sheetHost(ShiftDataController data, CalendarHandoffService service) =>
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCalendarExportSheet(context,
                data: data, from: _from, to: _to, service: service),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  group('buildCalendarEntries', () {
    test('takes the selected employee\'s worked shifts, in date order',
        () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: data.selectedEmployeeId);

      expect(selection.entries.map((e) => e.planId), ['p1', 'p2', 'p5']);
      // Bo's Monday shift belongs to someone else's calendar.
      expect(selection.entries.any((e) => e.title.contains('Bo')), isFalse);
    });

    test('walks past days with no plans at all', () async {
      // A month grid always reaches into days the roster never touches, and
      // those come back as one shared unmodifiable list — sorting it in place
      // used to throw and take the whole export down.
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from,
          to: _to.add(const Duration(days: 21)),
          employeeId: 'e1');

      expect(selection.entries.map((e) => e.planId), ['p1', 'p2', 'p5']);
    });

    test('counts the absence and drops the day with no shift at all', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');

      // Wed is rostered but not worked; Thu carries no shift id.
      expect(selection.absences, 1);
      expect(selection.entries.map((e) => e.planId), isNot(contains('p3')));
      expect(selection.entries.map((e) => e.planId), isNot(contains('p4')));
    });

    test('gives a day shift its configured hours and a workstation', () async {
      final data = await _loaded();
      final entry =
          _entryFor(buildCalendarEntries(data, from: _from, to: _to, employeeId: 'e1'), 'p1');

      expect(entry.title, 'Early');
      expect(entry.start, DateTime(2026, 6, 1, 6));
      expect(entry.end, DateTime(2026, 6, 1, 14));
      expect(entry.allDay, isFalse);
      expect(entry.location, 'Triage, room 2');
      expect(entry.description, contains('Ada Lovelace'));
    });

    test('carries a night shift over to the next morning', () async {
      final data = await _loaded();
      final entry =
          _entryFor(buildCalendarEntries(data, from: _from, to: _to, employeeId: 'e1'), 'p2');

      expect(entry.start, DateTime(2026, 6, 2, 22));
      expect(entry.end, DateTime(2026, 6, 3, 6));
    });

    test('falls back to an all-day entry when the shift has no hours',
        () async {
      final data = await _loaded();
      final entry =
          _entryFor(buildCalendarEntries(data, from: _from, to: _to, employeeId: 'e1'), 'p5');

      expect(entry.allDay, isTrue);
      expect(entry.start, DateTime(2026, 6, 5));
      // All-day ends are exclusive, so a one-day entry ends the next midnight.
      expect(entry.end, DateTime(2026, 6, 6));
    });

    test('names the employee on every event when exporting all of them',
        () async {
      final data = await _loaded(employeeId: null);
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: null);

      expect(selection.entries.length, 4); // Ada's three plus Bo's Monday.
      expect(_entryFor(selection, 'p6').title, 'Early · Bo Peep');
    });
  });

  group('buildIcs', () {
    test('writes each shift as a VEVENT with a plan-stable UID', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');
      final ics = buildIcs(selection.entries,
          calendarName: 'Ada Lovelace', now: DateTime.utc(2026, 5, 1, 12));
      final lines = ics.split('\r\n');

      expect(lines.first, 'BEGIN:VCALENDAR');
      expect(lines, contains('X-WR-CALNAME:Ada Lovelace'));
      expect(lines, contains('END:VCALENDAR'));
      expect('BEGIN:VEVENT'.allMatches(ics).length, 3);
      expect(lines, contains('UID:shiftviewer-p1@shiftviewer'));
      expect(lines, contains('DTSTAMP:20260501T120000Z'));
    });

    test('writes timed events as floating local wall-clock times', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');
      final lines = buildIcs(selection.entries).split('\r\n');

      // No trailing Z and no TZID: the importing calendar's zone applies.
      expect(lines, contains('DTSTART:20260601T060000'));
      expect(lines, contains('DTEND:20260601T140000'));
      // The night shift ends on the 3rd.
      expect(lines, contains('DTSTART:20260602T220000'));
      expect(lines, contains('DTEND:20260603T060000'));
    });

    test('writes an hourless shift as a date-valued all-day event', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');
      final lines = buildIcs(selection.entries).split('\r\n');

      expect(lines, contains('DTSTART;VALUE=DATE:20260605'));
      expect(lines, contains('DTEND;VALUE=DATE:20260606'));
    });

    test('escapes commas so a workstation name survives the round trip',
        () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');
      final ics = buildIcs(selection.entries);

      expect(ics, contains(r'LOCATION:Triage\, room 2'));
      // The shift name has a comma in it too.
      expect(ics, contains(r'SUMMARY:Night\, late'));
    });

    test('folds a line longer than 75 octets onto a continuation line', () {
      final entry = CalendarEntry(
        planId: 'long',
        title: 'A' * 200,
        colorHex: '#FF0000',
        location: '',
        description: '',
        start: DateTime(2026, 6, 1, 6),
        end: DateTime(2026, 6, 1, 14),
        allDay: false,
      );
      final lines = buildIcs([entry]).split('\r\n');

      expect(lines.every((l) => utf8.encode(l).length <= 75), isTrue);
      // Continuation lines start with a single space, per RFC 5545.
      expect(lines.where((l) => l.startsWith(' A')), isNotEmpty);
      // Unfolding puts the summary back together.
      final unfolded = lines.join('\r\n').replaceAll('\r\n ', '');
      expect(unfolded, contains('SUMMARY:${'A' * 200}'));
    });
  });

  group('googleCalendarUrl', () {
    test('sends the times as UTC, since the link cannot say "local"', () async {
      final data = await _loaded();
      final entry =
          _entryFor(buildCalendarEntries(data, from: _from, to: _to, employeeId: 'e1'), 'p1');
      final url = googleCalendarUrl(entry);

      expect(url.host, 'calendar.google.com');
      expect(url.path, '/calendar/render');
      expect(url.queryParameters['action'], 'TEMPLATE');
      expect(url.queryParameters['text'], 'Early');
      expect(url.queryParameters['location'], 'Triage, room 2');

      final start = DateTime(2026, 6, 1, 6).toUtc();
      final expected = '${start.year}'
          '${start.month.toString().padLeft(2, '0')}'
          '${start.day.toString().padLeft(2, '0')}T'
          '${start.hour.toString().padLeft(2, '0')}'
          '${start.minute.toString().padLeft(2, '0')}00Z';
      expect(url.queryParameters['dates'], startsWith('$expected/'));
    });

    test('sends an all-day shift as plain dates', () async {
      final data = await _loaded();
      final entry =
          _entryFor(buildCalendarEntries(data, from: _from, to: _to, employeeId: 'e1'), 'p5');

      expect(googleCalendarUrl(entry).queryParameters['dates'],
          '20260605/20260606');
    });
  });

  group('icsFileName', () {
    test('spans the exported range', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');

      expect(icsFileName(selection), 'shifts-2026-06-01-2026-06-05.ics');
    });

    test('names a single day once', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _from, employeeId: 'e1');

      expect(icsFileName(selection), 'shifts-2026-06-01.ics');
    });
  });

  group('CalendarHandoffService', () {
    late List<(Uri, LaunchMode)> opened;
    late List<(String, String)> delivered;

    setUp(() {
      opened = [];
      delivered = [];
    });

    CalendarHandoffService service({
      required bool Function(LaunchMode) opens,
      bool delivers = true,
    }) =>
        CalendarHandoffService(
          urlOpener: (url, mode) async {
            opened.add((url, mode));
            return opens(mode);
          },
          icsDeliverer: (ics, fileName) async {
            delivered.add((ics, fileName));
            return delivers;
          },
        );

    Future<CalendarEntry> entry() async =>
        _entryFor(buildCalendarEntries(await _loaded(),
            from: _from, to: _to, employeeId: 'e1'), 'p1');

    test('hands a single shift to the calendar app when it takes the link',
        () async {
      final s = service(opens: (_) => true);
      final result = await s.addToGoogleCalendar(await entry());

      expect(result.outcome, CalendarHandoff.google);
      // The installed app is asked before the browser is.
      expect(opened.single.$2, LaunchMode.externalNonBrowserApplication);
      expect(delivered, isEmpty);
    });

    test('falls back to the browser when no calendar app claims the link',
        () async {
      final s = service(
          opens: (mode) => mode == LaunchMode.externalApplication);
      final result = await s.addToGoogleCalendar(await entry());

      expect(result.outcome, CalendarHandoff.google);
      expect(opened.map((o) => o.$2), [
        LaunchMode.externalNonBrowserApplication,
        LaunchMode.externalApplication,
      ]);
    });

    test('falls back to an ics file when nothing opens the link', () async {
      final s = service(opens: (_) => false);
      final result = await s.addToGoogleCalendar(await entry());

      expect(result.outcome, CalendarHandoff.icsFile);
      expect(result.count, 1);
      expect(delivered.single.$1, contains('UID:shiftviewer-p1@shiftviewer'));
      expect(delivered.single.$2, 'shifts-2026-06-01.ics');
    });

    test('falls back to an ics file when the launcher throws', () async {
      final s = CalendarHandoffService(
        urlOpener: (_, _) async => throw StateError('no activity found'),
        icsDeliverer: (ics, fileName) async {
          delivered.add((ics, fileName));
          return true;
        },
      );

      expect((await s.addToGoogleCalendar(await entry())).outcome,
          CalendarHandoff.icsFile);
      expect(delivered, hasLength(1));
    });

    test('reports a dismissed share sheet as nothing exported', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');
      final s = service(opens: (_) => true, delivers: false);

      expect((await s.exportIcs(selection)).outcome, CalendarHandoff.dismissed);
    });

    test('reports a write failure with its reason', () async {
      final data = await _loaded();
      final selection = buildCalendarEntries(data,
          from: _from, to: _to, employeeId: 'e1');
      final s = CalendarHandoffService(
        urlOpener: (_, _) async => true,
        icsDeliverer: (_, _) async => throw StateError('disk full'),
      );

      final result = await s.exportIcs(selection);
      expect(result.outcome, CalendarHandoff.failed);
      expect(result.detail, contains('disk full'));
    });

    test('an empty range is not an export', () async {
      final s = service(opens: (_) => true);
      final result =
          await s.exportIcs(const CalendarExportSelection(entries: []));

      expect(result.outcome, CalendarHandoff.empty);
      expect(delivered, isEmpty);
    });
  });

  group('export sheet', () {
    testWidgets('shows what the visible range would export', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final data = await _loaded();
      await tester.pumpWidget(_sheetHost(
          data,
          CalendarHandoffService(
            urlOpener: (_, _) async => true,
            icsDeliverer: (_, _) async => true,
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('3 confirmed shifts'), findsOneWidget);
      expect(find.text('1 absence left out'), findsOneWidget);
      expect(find.text('Share calendar file'), findsOneWidget);
      // Several shifts cannot go through the single-event Google link.
      expect(find.text('Add to Google Calendar'), findsNothing);
    });

    testWidgets('exporting reports the file it wrote', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      String? written;
      final data = await _loaded();
      await tester.pumpWidget(_sheetHost(
          data,
          CalendarHandoffService(
            urlOpener: (_, _) async => true,
            icsDeliverer: (ics, fileName) async {
              written = ics;
              return true;
            },
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share calendar file'));
      await tester.pumpAndSettle();

      expect(written, contains('BEGIN:VCALENDAR'));
      expect('BEGIN:VEVENT'.allMatches(written!).length, 3);
      expect(
          find.text('3 shifts exported to shifts-2026-06-01-2026-06-05.ics'),
          findsOneWidget);
    });

    testWidgets('says so when the range holds no confirmed shift',
        (tester) async {
      final data = await _loaded();
      // Thursday: rostered with no shift at all.
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCalendarExportSheet(context,
                  data: data,
                  from: DateTime(2026, 6, 4),
                  to: DateTime(2026, 6, 4)),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('No confirmed shifts in this range.'), findsOneWidget);
    });
  });
}
