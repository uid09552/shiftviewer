// The wish planner is a view of one employee's wishes, so it asks for an
// employee before it shows a grid — in whichever language is selected.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftviewer/l10n/app_localizations.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/widgets/wish_planner_view.dart';

Widget _host(Locale locale, ShiftDataController data) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: WishPlannerView(visibleMonth: DateTime(2026, 8, 15), data: data),
      ),
    );

void main() {
  testWidgets('prompts for an employee before planning wishes',
      (tester) async {
    final data = ShiftDataController(const AppSettings());

    await tester.pumpWidget(_host(const Locale('en'), data));
    expect(find.text('Pick an employee to plan their shift wishes.'),
        findsOneWidget);
  });

  testWidgets('renders in German when the German locale is selected',
      (tester) async {
    final data = ShiftDataController(const AppSettings());

    await tester.pumpWidget(_host(const Locale('de'), data));
    expect(find.text('Wähle einen Mitarbeiter, um dessen Dienstwünsche zu planen.'),
        findsOneWidget);
  });
}
