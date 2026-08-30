// Long press to pick one day, keep dragging to pick a run of them.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftviewer/widgets/day_paint_selection.dart';

final _week = [for (int d = 1; d <= 7; d++) DateTime(2026, 6, d)];

/// A row of seven 100x100 day cells, the shape the calendars paint over.
Widget _grid(void Function(Set<DateTime>) onCommit, {VoidCallback? onTapDay}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 700,
          height: 100,
          child: DayPaintArea(
            onCommit: onCommit,
            child: Row(
              children: [
                for (final day in _week)
                  Expanded(
                    child: PaintableDay(
                      day: day,
                      child: GestureDetector(
                        onTap: onTapDay,
                        child: Container(
                          color: Colors.grey,
                          alignment: Alignment.center,
                          child: Text('${day.day}'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a long press without moving picks the day under the finger',
      (tester) async {
    Set<DateTime>? committed;
    await tester.pumpWidget(_grid((days) => committed = days));

    await tester.longPress(find.text('3'));
    await tester.pumpAndSettle();

    expect(committed, {DateTime(2026, 6, 3)});
  });

  testWidgets('dragging on from the long press picks every day passed over',
      (tester) async {
    Set<DateTime>? committed;
    await tester.pumpWidget(_grid((days) => committed = days));

    final gesture = await tester.startGesture(tester.getCenter(find.text('2')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    for (final day in ['3', '4', '5']) {
      await gesture.moveTo(tester.getCenter(find.text(day)));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(committed, {
      DateTime(2026, 6, 2),
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
      DateTime(2026, 6, 5),
    });
  });

  testWidgets('a plain tap still reaches the cell below', (tester) async {
    var committed = 0;
    var tapped = 0;
    await tester.pumpWidget(
      _grid((_) => committed++, onTapDay: () => tapped++),
    );

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
    expect(committed, 0);
  });
}
