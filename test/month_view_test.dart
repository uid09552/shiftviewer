// The month grid keeps a fixed row height rather than stretching over whatever
// the window offers, and still fits a six-week month into a short one.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';
import 'package:shiftviewer/widgets/month_view.dart';
import 'package:shiftviewer/widgets/weekday_header.dart';

/// May 2026 starts on a Friday and runs 31 days, so it spans six week rows —
/// the tallest a month gets.
final _sixWeekMonth = DateTime(2026, 5, 1);

Widget _host(DateTime month) => MaterialApp(
      locale: const Locale('en'),
      home: Scaffold(
        body: MonthView(
          visibleMonth: month,
          selectedDay: null,
          data: ShiftDataController(const AppSettings(baseUrl: '')),
          onDaySelected: (_) {},
        ),
      ),
    );

/// The grid itself, which is smaller than the box it is laid out in.
Size _gridSize(WidgetTester tester) => tester.getSize(
      find
          .ancestor(
            of: find.byType(WeekdayHeader),
            matching: find.byType(Column),
          )
          .first,
    );

void main() {
  testWidgets('keeps its size instead of filling a tall window',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_sixWeekMonth));

    final grid = _gridSize(tester);
    // Six rows of 52 plus the weekday labels — nowhere near the ~1400 on offer.
    expect(grid.height, lessThan(360));
    // And it stays calendar-shaped rather than spanning the full width.
    expect(grid.width, lessThanOrEqualTo(76 * 7));
  });

  testWidgets('shrinks to fit a window too short for its full size',
      (tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // An overflow would be reported as a test failure here.
    await tester.pumpWidget(_host(_sixWeekMonth));

    expect(_gridSize(tester).height, lessThanOrEqualTo(300));
    expect(find.text('15'), findsOneWidget);
  });
}
