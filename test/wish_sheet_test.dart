// The sheet a painted selection opens: it shows what was picked and offers to
// widen the edit to the whole week or month.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/widgets/shift_wish_sheet.dart';

const _base = 'https://example.test/api/v1';

/// Mon 1 – Wed 3 June 2026, the days a drag across three cells would produce.
final _painted = [DateTime(2026, 6, 1), DateTime(2026, 6, 2), DateTime(2026, 6, 3)];

/// Early runs Mon–Fri, so a week-wide edit has to leave the weekend out.
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

/// The wish window the fake server reports; wide open unless a test narrows it.
const _openWindow = {'mode': 'enabled', 'updated_at': '2026-05-01T00:00:00Z'};

http.Client _fakeApi(Map<String, dynamic> wishSettings) {
  var nextId = 0;
  return MockClient((request) async {
    final path = request.url.path.replaceFirst('/api/v1', '');
    Object? body;
    if (request.method == 'GET') {
      body = switch (path) {
        '/shifts' => [_earlyShift],
        '/employees' => [
            {'id': 'e1', 'name': 'Ada', 'email': 'ada@example.test'}
          ],
        '/confirmed-shift-plans' => {'data': []},
        '/wish-settings' => wishSettings,
        _ => <dynamic>[],
      };
    } else if (request.method == 'POST') {
      body = {
        'id': 'w${nextId++}',
        ...jsonDecode(request.body) as Map<String, dynamic>,
      };
    } else {
      return http.Response('', 204);
    }
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });
}

Future<ShiftDataController> _loaded(
    {Map<String, dynamic> wishSettings = _openWindow}) async {
  final data = ShiftDataController(
    const AppSettings(baseUrl: _base),
    httpClientFactory: () => _fakeApi(wishSettings),
  );
  await data.refresh(_painted.first, _painted.last);
  data.selectEmployee('e1');
  return data;
}

Widget _host(ShiftDataController data) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showShiftWishSheet(context, days: _painted, data: data),
            child: const Text('open'),
          ),
        ),
      ),
    );

Future<void> _openSheet(WidgetTester tester, ShiftDataController data) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(data));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers the painted days, the week and the month',
      (tester) async {
    await _openSheet(tester, await _loaded());

    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    // The selection covers Mon–Wed.
    expect(find.textContaining('Mon, Jun 1'), findsOneWidget);

    // Widening to the week shows how much of it the shift can actually cover.
    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(find.text('Runs on 5 of 7 days'), findsOneWidget);
  });

  testWidgets('applying to the week wishes for every day the shift runs',
      (tester) async {
    final data = await _loaded();
    await _openSheet(tester, data);

    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Early'));
    await tester.pumpAndSettle();

    expect(
      data.wishesInRange(DateTime(2026, 6, 1), DateTime(2026, 6, 7)).length,
      5,
    );
    expect(find.textContaining('Early wished for 5 days'), findsOneWidget);
    expect(find.textContaining('2 days skipped'), findsOneWidget);
  });

  testWidgets('a single day keeps the plain one-day sheet', (tester) async {
    final data = await _loaded();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showShiftWishSheet(context,
                days: [DateTime(2026, 6, 2)], data: data),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('This day'), findsOneWidget);
    expect(find.text('Tuesday, June 2, 2026'), findsOneWidget);
    // One day: the tile shows the shift's hours rather than a day tally.
    expect(find.text('06:00 – 14:00'), findsOneWidget);
  });

  testWidgets('a deactivated window says so instead of opening the editor',
      (tester) async {
    final data = await _loaded(wishSettings: const {
      'mode': 'disabled',
      'updated_at': '2026-05-01T00:00:00Z',
    });

    await _openSheet(tester, data);

    expect(find.text('This day'), findsNothing, reason: 'no editor at all');
    expect(find.text('Shift wishes are deactivated right now.'), findsOneWidget);
  });

  testWidgets('a date range window only offers the days it covers',
      (tester) async {
    // Open for Mon 1 – Tue 2 June only, so the painted Wed 3 is out.
    final data = await _loaded(wishSettings: const {
      'mode': 'date_range',
      'window_start': '2026-06-01',
      'window_end': '2026-06-02',
      'updated_at': '2026-05-01T00:00:00Z',
    });

    await _openSheet(tester, data);
    expect(find.text('Shift wishes can only be placed for Jun 1, 2026 – Jun 2, 2026'
        '.'), findsOneWidget);
    // Three days painted, two of them inside the window.
    expect(find.text('Runs on 2 of 3 days'), findsOneWidget);

    await tester.tap(find.text('Early'));
    await tester.pumpAndSettle();

    expect(data.wishesInRange(DateTime(2026, 6, 1), DateTime(2026, 6, 3)).length,
        2);
    expect(find.textContaining('1 day outside the wish window'), findsOneWidget);
  });
}
