// ISO-8601 week numbers, especially around New Year where a naive
// "days since 1 January / 7" count goes wrong.

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftviewer/services/iso_week.dart';

void main() {
  void expectWeek(DateTime day, int year, int week) {
    expect(
      (isoWeekYear(day), isoWeekNumber(day)),
      (year, week),
      reason: '$day',
    );
  }

  test('a year starting on Friday: its first days belong to last year', () {
    // 1 Jan 2021 was a Friday.
    expectWeek(DateTime(2021, 1, 1), 2020, 53);
    expectWeek(DateTime(2021, 1, 3), 2020, 53);
    expectWeek(DateTime(2021, 1, 4), 2021, 1);
    expectWeek(DateTime(2021, 1, 10), 2021, 1);
    expectWeek(DateTime(2021, 1, 11), 2021, 2);
  });

  test('a year starting on Thursday: the last days of December join it', () {
    // 1 Jan 2026 is a Thursday, so Mon 29 Dec 2025 opens 2026's week 1.
    expectWeek(DateTime(2025, 12, 28), 2025, 52);
    expectWeek(DateTime(2025, 12, 29), 2026, 1);
    expectWeek(DateTime(2026, 1, 1), 2026, 1);
    expectWeek(DateTime(2026, 1, 4), 2026, 1);
    expectWeek(DateTime(2026, 1, 5), 2026, 2);
  });

  test('a 53-week year ends with week 53', () {
    expectWeek(DateTime(2026, 12, 28), 2026, 53);
    expectWeek(DateTime(2027, 1, 3), 2026, 53);
    expectWeek(DateTime(2027, 1, 4), 2027, 1);
  });

  test('a year starting on Monday', () {
    expectWeek(DateTime(2024, 1, 1), 2024, 1);
    expectWeek(DateTime(2024, 12, 29), 2024, 52);
    expectWeek(DateTime(2024, 12, 30), 2025, 1);
  });

  test('mid-year weeks, across a daylight-saving switch', () {
    expectWeek(DateTime(2026, 3, 29), 2026, 13); // DST starts in Europe
    expectWeek(DateTime(2026, 3, 30), 2026, 14);
    expectWeek(DateTime(2026, 11, 23), 2026, 48);
  });

  test('the time of day does not matter', () {
    expectWeek(DateTime(2021, 1, 3, 23, 59), 2020, 53);
    expectWeek(DateTime(2021, 1, 4, 0, 1), 2021, 1);
  });
}
