import 'dart:math' as math;

import '../models/models.dart';

/// Rotation patterns as typed ("F F S S N N - -") and checked against the
/// planner's own rules before anyone applies one. The solver keeps fixed
/// assignments first but cannot keep one that breaks a hard rule, so a
/// pattern that does is better flagged while it is being written.
///
/// Mirrors `rotation-rules.ts` in the web UI.

/// Tokens that mean "day off".
const _off = {'-', '–', '/', 'x', 'off', 'frei'};

class ParsedSequence {
  final List<String?> slots;

  /// Tokens that matched no shift.
  final List<String> unknown;

  const ParsedSequence(this.slots, this.unknown);
}

/// Text → slots, matching short names first, then full names.
ParsedSequence parseSequence(String text, List<Shift> shifts) {
  final byShort = {for (final s in shifts) s.shortName.toLowerCase(): s.id};
  final byName = {for (final s in shifts) s.name.toLowerCase(): s.id};
  final slots = <String?>[];
  final unknown = <String>[];
  for (final token in text.split(RegExp(r'[\s,;]+')).where((t) => t.isNotEmpty)) {
    final key = token.toLowerCase();
    if (_off.contains(key)) {
      slots.add(null);
    } else if (byShort.containsKey(key) || byName.containsKey(key)) {
      slots.add(byShort[key] ?? byName[key]);
    } else {
      unknown.add(token);
    }
  }
  return ParsedSequence(slots, unknown);
}

/// Slots back to the typed form.
String formatSequence(List<String?> slots, List<Shift> shifts) {
  final short = {for (final s in shifts) s.id: s.shortName};
  return slots.map((id) => id == null ? '-' : (short[id] ?? '?')).join(' ');
}

/// The planner settings a pattern is checked against.
class PatternRules {
  final int maxConsecutiveDays;
  final int maxWorkingDaysPerWeek;
  final int minRestHours;
  final int nightShiftRecoveryDays;

  const PatternRules({
    this.maxConsecutiveDays = 0,
    this.maxWorkingDaysPerWeek = 0,
    this.minRestHours = 0,
    this.nightShiftRecoveryDays = 0,
  });
}

sealed class PatternIssue {
  const PatternIssue();
}

/// [run] is null for a cycle without any day off — an endless run.
class ConsecutiveIssue extends PatternIssue {
  final int? run;
  final int max;
  const ConsecutiveIssue(this.run, this.max);
}

class WeeklyIssue extends PatternIssue {
  final int days;
  final int max;
  const WeeklyIssue(this.days, this.max);
}

class RestIssue extends PatternIssue {
  final int day;
  final String from;
  final String to;
  final double hours;
  final int min;
  const RestIssue(this.day, this.from, this.to, this.hours, this.min);
}

class RecoveryIssue extends PatternIssue {
  final int day;
  final String shift;
  final int days;
  const RecoveryIssue(this.day, this.shift, this.days);
}

/// What in this rhythm the rules forbid. The cycle repeats, so every check
/// wraps around its end. Rest uses each shift's Monday times (or its first
/// configured day), since a cycle does not follow the week.
List<PatternIssue> checkPattern(
  List<String?> slots,
  List<Shift> shifts,
  PatternRules rules,
) {
  final n = slots.length;
  if (n == 0 || slots.every((s) => s == null)) return const [];
  final byId = {for (final s in shifts) s.id: s};
  String? at(int i) => slots[((i % n) + n) % n];
  final issues = <PatternIssue>[];

  if (rules.maxConsecutiveDays > 0) {
    if (slots.every((s) => s != null)) {
      issues.add(ConsecutiveIssue(null, rules.maxConsecutiveDays));
    } else {
      var run = 0;
      var longest = 0;
      for (var i = 0; i < 2 * n; i++) {
        run = at(i) != null ? run + 1 : 0;
        longest = math.max(longest, run);
      }
      if (longest > rules.maxConsecutiveDays) {
        issues.add(ConsecutiveIssue(longest, rules.maxConsecutiveDays));
      }
    }
  }

  if (rules.maxWorkingDaysPerWeek > 0) {
    var most = 0;
    for (var start = 0; start < n; start++) {
      var days = 0;
      for (var i = start; i < start + 7; i++) {
        if (at(i) != null) days++;
      }
      most = math.max(most, days);
    }
    if (most > rules.maxWorkingDaysPerWeek) {
      issues.add(WeeklyIssue(most, rules.maxWorkingDaysPerWeek));
    }
  }

  for (var i = 0; i < n; i++) {
    final shift = byId[at(i)];
    final time = shift == null ? null : _typicalTime(shift);
    if (shift == null || time == null) continue;

    final recovery = math.max(
      time.freeDaysAfterShift,
      _crossesMidnight(time) ? rules.nightShiftRecoveryDays : 0,
    );
    if (recovery > 0) {
      for (var k = 1; k <= recovery; k++) {
        if (at(i + k) != null) {
          issues.add(RecoveryIssue(i + 1, shift.shortName, recovery));
          break;
        }
      }
      continue; // the recovery rule is the stricter one
    }

    final next = byId[at(i + 1)];
    final nextTime = next == null ? null : _typicalTime(next);
    if (next == null || nextTime == null || rules.minRestHours <= 0) continue;
    final end = _minutes(time.endTime) + (_crossesMidnight(time) ? 24 * 60 : 0);
    final rest = (24 * 60 + _minutes(nextTime.startTime) - end) / 60;
    if (rest < rules.minRestHours) {
      issues.add(RestIssue(
        i + 1,
        shift.shortName,
        next.shortName,
        (rest * 10).round() / 10,
        rules.minRestHours,
      ));
    }
  }
  return issues;
}

WeekdayTime? _typicalTime(Shift shift) {
  for (final t in shift.weekdayTimes) {
    if (t.weekday == 0) return t;
  }
  return shift.weekdayTimes.isEmpty ? null : shift.weekdayTimes.first;
}

bool _crossesMidnight(WeekdayTime t) =>
    _minutes(t.endTime) <= _minutes(t.startTime);

int _minutes(String v) {
  final p = v.split(':');
  if (p.length < 2) return 0;
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}
