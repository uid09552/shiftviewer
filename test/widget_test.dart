// Smoke test: the app enforces authentication and shows the login gate first.

import 'package:flutter_test/flutter_test.dart';

import 'package:shiftviewer/main.dart';

void main() {
  testWidgets('App shows the login gate before the calendar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftViewerApp());

    // Settings load does real file I/O and auth init runs on the real event
    // loop; runAsync lets those complete before we assert on the rendered gate.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    // Login gate is shown; the calendar (Month/Week) is not reachable yet.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Month'), findsNothing);
  });
}
