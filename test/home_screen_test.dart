// The home screen is one view at a time, switched from the bottom bar. These
// checks run against an unconfigured controller so nothing hits the network.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/screens/home_screen.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/auth_service.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';

/// Settings with no API URL, so [ShiftDataController.refresh] reports "not
/// configured" instead of making a request.
class _OfflineSettings extends SettingsController {
  @override
  AppSettings get settings => const AppSettings(baseUrl: '');
}

Widget _host() {
  final settings = _OfflineSettings();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(value: settings),
      ChangeNotifierProvider(
        create: (_) => ShiftDataController(settings.settings),
      ),
      ChangeNotifierProvider(create: (_) => AuthController(settings)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ),
  );
}

void main() {
  testWidgets('offers all four views and switches between them',
      (tester) async {
    // A phone-sized viewport: the tightest layout the views must survive.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();

    for (final label in ['Month', 'Week', 'Day', 'Wishes']) {
      expect(find.text(label), findsOneWidget);
    }

    // The day view is up first: today's roster, not a calendar.
    expect(find.text('No shifts scheduled'), findsOneWidget);

    // The wish planner replaces it entirely.
    await tester.tap(find.text('Wishes'));
    await tester.pumpAndSettle();
    expect(find.text('Pick an employee to plan their shift wishes.'),
        findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Mon'), findsOneWidget);
  });

  testWidgets('the month and week views explain the selected day below',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    // Today is selected on arrival, so its legend is already up under the grid.
    final today = DateFormat.MMMMEEEEd('en').format(DateTime.now());
    expect(find.text(today), findsOneWidget);
    expect(find.text('0 working'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text(today), findsOneWidget, reason: 'the week view too');

    // The legend is a summary; its button leads to the full day view.
    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.open_in_full), findsNothing);
    expect(find.text('No shifts scheduled'), findsOneWidget);
  });

  testWidgets('reports a missing API URL rather than failing silently',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(find.text('Not configured. Open settings to set the API URL.'),
        findsOneWidget);
  });
}
