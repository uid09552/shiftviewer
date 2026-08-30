import '../models/models.dart';
import 'shift_data_controller.dart';

/// Turning confirmed shift plans into calendar entries, an iCalendar feed and a
/// Google Calendar link.
///
/// Everything here is pure: it takes plans plus the shift/workstation lookups
/// and produces strings. The platform side of getting those strings to a
/// calendar app lives in `calendar_delivery.dart`.

/// One confirmed shift, in the shape a calendar wants it.
class CalendarEntry {
  /// The plan this came from. Its id seeds the iCalendar UID, so re-importing
  /// a range updates the events already there instead of duplicating them.
  final String planId;

  final String title;

  /// The shift's `#RRGGBB` colour, so a preview can look like the calendar.
  final String colorHex;

  /// Workstation name, or empty when none is assigned.
  final String location;
  final String description;

  /// Local wall-clock start. For an [allDay] entry this is midnight.
  final DateTime start;

  /// Local wall-clock end, exclusive. A shift whose end time is not after its
  /// start runs past midnight and ends on the following day.
  final DateTime end;

  /// Set when the shift has no times configured for that weekday: the day is
  /// still worth showing, just without an hour attached.
  final bool allDay;

  const CalendarEntry({
    required this.planId,
    required this.title,
    required this.colorHex,
    required this.location,
    required this.description,
    required this.start,
    required this.end,
    required this.allDay,
  });

  /// The date the shift belongs to, whatever time it ends at.
  DateTime get day => DateTime(start.year, start.month, start.day);
}

/// What [buildCalendarEntries] made of a range, including what it left out.
class CalendarExportSelection {
  final List<CalendarEntry> entries;

  /// Days the employee is rostered but not present (sick, day off, …). These
  /// are not work, so they are not exported.
  final int absences;

  const CalendarExportSelection({
    required this.entries,
    this.absences = 0,
  });

  bool get isEmpty => entries.isEmpty;
  int get length => entries.length;

  /// First and last day covered, or null when there is nothing to export.
  (DateTime, DateTime)? get span => entries.isEmpty
      ? null
      : (entries.first.day, entries.last.day);
}

/// Collects the confirmed shifts of [employeeId] between [from] and [to]
/// (inclusive) from [data], newest last.
///
/// Only real work is exported: a plan without a shift, or one the roster marks
/// the employee absent for, is a day off rather than an appointment. When
/// [employeeId] is null every employee's plans are taken, which is what the
/// "all employees" scope in the calendar means.
CalendarExportSelection buildCalendarEntries(
  ShiftDataController data, {
  required DateTime from,
  required DateTime to,
  required String? employeeId,
}) {
  final start = dateKey(from);
  final end = dateKey(to);
  final entries = <CalendarEntry>[];
  var absences = 0;

  for (var day = start;
      !day.isAfter(end);
      day = DateTime(day.year, day.month, day.day + 1)) {
    // A copy: the controller hands out its own list — the empty days share one
    // unmodifiable const list — and sorting it in place would throw and reorder
    // the roster behind the calendar's back.
    final plans = [...data.allPlansForDay(day)]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final plan in plans) {
      if (employeeId != null && plan.employeeId != employeeId) continue;
      if (plan.shiftId == null) continue;
      if (!plan.isPresent) {
        absences++;
        continue;
      }
      final shift = data.shiftById(plan.shiftId);
      if (shift == null) continue;
      entries.add(_entryFor(
        plan: plan,
        day: day,
        shift: shift,
        workstation: data.workstationById(plan.workstationId),
        employee: data.employeeById(plan.employeeId),
        // The employee's own export doesn't need their name on every event;
        // an all-employees export does, or the entries are indistinguishable.
        withEmployeeName: employeeId == null,
      ));
    }
  }

  return CalendarExportSelection(entries: entries, absences: absences);
}

CalendarEntry _entryFor({
  required ConfirmedShiftPlan plan,
  required DateTime day,
  required Shift shift,
  required Workstation? workstation,
  required Employee? employee,
  required bool withEmployeeName,
}) {
  final times = shift.timesFor(day);
  final ws = workstation?.name ?? '';

  final DateTime start;
  final DateTime end;
  final bool allDay;
  if (times == null) {
    // No hours configured for this weekday — record the day itself. An all-day
    // event's end is exclusive, hence the following midnight.
    start = day;
    end = DateTime(day.year, day.month, day.day + 1);
    allDay = true;
  } else {
    start = _at(day, times.startTime);
    var candidate = _at(day, times.endTime);
    // A night shift ends the next morning; anything not after the start is one.
    if (!candidate.isAfter(start)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    end = candidate;
    allDay = false;
  }

  final title = [
    shift.name.isEmpty ? shift.shortName : shift.name,
    if (withEmployeeName && (employee?.name.isNotEmpty ?? false)) employee!.name,
  ].join(' · ');

  final description = [
    if (employee != null && employee.name.isNotEmpty) employee.name,
    if (ws.isNotEmpty) ws,
    if (times != null) '${times.startTime}–${times.endTime}',
  ].join(' · ');

  return CalendarEntry(
    planId: plan.id,
    title: title,
    colorHex: shift.color,
    location: ws,
    description: description,
    start: start,
    end: end,
    allDay: allDay,
  );
}

/// Applies an `HH:MM` / `HH:MM:SS` shift time to [day]. An unparseable time
/// lands on midnight rather than throwing — the entry is still worth having.
DateTime _at(DateTime day, String time) {
  final parts = time.split(':');
  final hour = parts.isEmpty ? 0 : int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(day.year, day.month, day.day, hour, minute);
}

/// Serialises [entries] as an RFC 5545 calendar, ready to be imported.
///
/// Timed events are written as *floating* local times (no `Z`, no `TZID`):
/// a roster is wall-clock local by nature, and Google Calendar reads floating
/// times in the importing calendar's own time zone — which is the one the
/// employee works in. [now] is the DTSTAMP, injectable so tests get a fixed
/// document.
String buildIcs(
  List<CalendarEntry> entries, {
  String? calendarName,
  DateTime? now,
}) {
  final stamp = _icsUtc(now ?? DateTime.now());
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//shiftviewer//Shift Viewer//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    if (calendarName != null && calendarName.isNotEmpty)
      'X-WR-CALNAME:${_escape(calendarName)}',
  ];

  for (final e in entries) {
    lines.addAll([
      'BEGIN:VEVENT',
      // Stable per plan, so a second import of the same range is an update.
      'UID:shiftviewer-${e.planId}@shiftviewer',
      'DTSTAMP:$stamp',
      'LAST-MODIFIED:$stamp',
      if (e.allDay) ...[
        'DTSTART;VALUE=DATE:${_icsDate(e.start)}',
        'DTEND;VALUE=DATE:${_icsDate(e.end)}',
      ] else ...[
        'DTSTART:${_icsLocal(e.start)}',
        'DTEND:${_icsLocal(e.end)}',
      ],
      'SUMMARY:${_escape(e.title)}',
      if (e.location.isNotEmpty) 'LOCATION:${_escape(e.location)}',
      if (e.description.isNotEmpty) 'DESCRIPTION:${_escape(e.description)}',
      'TRANSP:OPAQUE',
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');

  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// A `calendar.google.com` link that opens the new-event form prefilled with
/// [entry] — the quickest route into Google Calendar for a single shift, and
/// the only one that needs no file.
///
/// Times go over as UTC because the link format has no way to say "local".
Uri googleCalendarUrl(CalendarEntry entry) {
  final dates = entry.allDay
      ? '${_icsDate(entry.start)}/${_icsDate(entry.end)}'
      : '${_icsUtc(entry.start.toUtc())}/${_icsUtc(entry.end.toUtc())}';
  return Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': entry.title,
    'dates': dates,
    if (entry.description.isNotEmpty) 'details': entry.description,
    if (entry.location.isNotEmpty) 'location': entry.location,
  });
}

/// File name for a range export, e.g. `shifts-2026-09-01-2026-09-30.ics`.
String icsFileName(CalendarExportSelection selection) {
  final span = selection.span;
  if (span == null) return 'shifts.ics';
  final from = _icsDateDashed(span.$1);
  final to = _icsDateDashed(span.$2);
  return from == to ? 'shifts-$from.ics' : 'shifts-$from-$to.ics';
}

String _two(int v) => v.toString().padLeft(2, '0');

String _icsDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}'
    '${_two(d.month)}${_two(d.day)}';

String _icsDateDashed(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String _icsLocal(DateTime d) =>
    '${_icsDate(d)}T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';

String _icsUtc(DateTime d) => '${_icsLocal(d.toUtc())}Z';

/// RFC 5545 text escaping: backslash, semicolon, comma and newlines.
String _escape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\r\n', '\\n')
    .replaceAll('\n', '\\n');

/// Folds a content line to the 75-octet limit, continuing with a leading
/// space. Counted in UTF-8 bytes and split between runes, so a multi-byte
/// character is never cut in half.
String _fold(String line) {
  // Fast path: pure ASCII, so characters and octets are the same count.
  if (line.length <= 75 && line.codeUnits.every((u) => u < 0x80)) return line;
  final out = StringBuffer();
  var bytes = 0;
  for (final rune in line.runes) {
    final size = _utf8Len(rune);
    if (bytes + size > 75) {
      out.write('\r\n ');
      bytes = 1; // The continuation space counts towards the new line.
    }
    out.writeCharCode(rune);
    bytes += size;
  }
  return out.toString();
}

int _utf8Len(int rune) {
  if (rune < 0x80) return 1;
  if (rune < 0x800) return 2;
  if (rune < 0x10000) return 3;
  return 4;
}
