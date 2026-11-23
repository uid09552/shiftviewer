/// ISO-8601 week numbering — the "KW" printed on German calendars.
///
/// Weeks start on Monday, and week 1 is the week holding the year's first
/// Thursday (equivalently, 4 January). Days at the turn of the year can
/// therefore belong to the previous or next year's weeks: Monday 29 December
/// 2025 is in week 1 of 2026, and Monday 4 January 2021 is week 1 of 2021,
/// not week 2.
library;

/// The ISO week number (1–53) of [date].
int isoWeekNumber(DateTime date) => _isoWeek(date).$2;

/// The year [date]'s ISO week belongs to, which differs from the calendar year
/// for a few days around New Year.
int isoWeekYear(DateTime date) => _isoWeek(date).$1;

(int, int) _isoWeek(DateTime date) {
  // Work on a UTC calendar date so a daylight-saving switch can't shorten a
  // day and make the division below round the wrong way.
  final day = DateTime.utc(date.year, date.month, date.day);
  // The Thursday of the same Monday-based week decides both the year and the
  // week: it always lies in the ISO year the week belongs to.
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final firstOfYear = DateTime.utc(thursday.year, 1, 1);
  final dayOfYear = thursday.difference(firstOfYear).inDays;
  return (thursday.year, dayOfYear ~/ 7 + 1);
}
