// The wish window as the user sees it: a badge saying whether wishes are open,
// limited to a date range, or deactivated — and a planner that follows it.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/models/models.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/widgets/wish_planner_view.dart';
import 'package:shiftviewer/widgets/wish_window_status.dart';

const _base = 'https://example.test/api/v1';

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// A server that only has to answer the calls one month of planning makes.
http.Client _fakeApi(Map<String, dynamic> wishSettings) =>
    MockClient((request) async {
      final path = request.url.path.replaceFirst('/api/v1', '');
      final body = switch (path) {
        '/employees' => [
            {'id': 'e1', 'name': 'Ada', 'email': 'ada@example.test'}
          ],
        '/confirmed-shift-plans' => {'data': []},
        '/wish-settings' => wishSettings,
        _ => <dynamic>[],
      };
      return http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json'});
    });

Future<ShiftDataController> _loaded(Map<String, dynamic> wishSettings) async {
  final data = ShiftDataController(
    const AppSettings(baseUrl: _base),
    httpClientFactory: () => _fakeApi(wishSettings),
  );
  await data.refresh(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
  data.selectEmployee('e1');
  return data;
}

void main() {
  testWidgets('names the three wish window states', (tester) async {
    await tester.pumpWidget(_host(const Column(children: [
      WishWindowChip(settings: WishSettings(mode: WishMode.enabled)),
      WishWindowChip(settings: WishSettings(mode: WishMode.disabled)),
      WishWindowChip(settings: WishSettings(mode: WishMode.dateRange)),
    ])));

    expect(find.text('Wishes open'), findsOneWidget);
    // A range without both bounds accepts nothing, so it reads as deactivated —
    // once for the disabled chip, once for the incomplete range.
    expect(find.text('Wishes deactivated'), findsNWidgets(2));
  });

  testWidgets('spells out the dates of a range window', (tester) async {
    await tester.pumpWidget(_host(WishWindowChip(
      settings: WishSettings(
        mode: WishMode.dateRange,
        windowStart: DateTime(2026, 6, 1),
        windowEnd: DateTime(2026, 6, 30),
      ),
    )));

    expect(find.text('Wishes Jun 1, 2026 – Jun 30, 2026'), findsOneWidget);
  });

  testWidgets('translates the window state', (tester) async {
    await tester.pumpWidget(_host(
      const WishWindowChip(settings: WishSettings(mode: WishMode.disabled)),
      locale: const Locale('de'),
    ));

    expect(find.text('Wünsche deaktiviert'), findsOneWidget);
  });

  testWidgets('the planner shows the window it is planning inside',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final data = await _loaded(const {
      'mode': 'date_range',
      'window_start': '2026-06-01',
      'window_end': '2026-06-15',
      'updated_at': '2026-05-01T00:00:00Z',
    });

    await tester.pumpWidget(
        _host(WishPlannerView(visibleMonth: DateTime(2026, 6, 15), data: data)));
    await tester.pumpAndSettle();

    expect(find.text('Wishes Jun 1, 2026 – Jun 15, 2026'), findsOneWidget);
  });

  testWidgets('a deactivated window replaces the planner hint', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final data = await _loaded(const {
      'mode': 'disabled',
      'updated_at': '2026-05-01T00:00:00Z',
    });

    await tester.pumpWidget(
        _host(WishPlannerView(visibleMonth: DateTime(2026, 6, 15), data: data)));
    await tester.pumpAndSettle();

    expect(find.text('Shift wishes are deactivated right now.'), findsOneWidget);
    expect(find.textContaining('Tap a day to wish'), findsNothing);
  });
}
