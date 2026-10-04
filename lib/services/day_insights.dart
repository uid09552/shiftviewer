import '../models/models.dart';
import 'shift_data_controller.dart';

/// Turning the loaded roster — plus whatever `/analysis/*` adds on top — into
/// the numbers the insight sheets show.
///
/// Everything here is pure: it reads a [ShiftDataController] and a
/// [DayAnalysis] and returns plain values, so the arithmetic can be tested
/// without a widget or a socket. The analysis parts are all nullable, because
/// a tenant may refuse them and the roster alone still answers most of it.

/// How a shift's actual head count compares with what the roster asks for.
enum Coverage {
  /// Fewer people present than the weekday's `min_employees`.
  under,

  /// At or above the minimum, and within the maximum when there is one.
  met,

  /// More people than the weekday's `max_employees` allows.
  over,

  /// The shift sets no bounds for this weekday, so there is nothing to miss.
  unknown,
}

/// One workstation's load inside a shift on a day.
class WorkstationLoad {
  /// Null for the "no workstation assigned" bucket.
  final String? id;
  final String name;

  /// The station's own record, when it is one the roster knows.
  final Workstation? station;

  /// People this shift rosters here, and how many of them are present.
  final int rostered;
  final int present;

  /// The server's own count for the whole day, across every shift — null when
  /// analysis is unavailable. It can exceed [rostered], which counts this
  /// shift only.
  final int? plannedEmployees;

  /// Hours the server has booked on this station for the day, or null.
  final double? plannedHours;

  const WorkstationLoad({
    required this.id,
    required this.name,
    required this.station,
    required this.rostered,
    required this.present,
    this.plannedEmployees,
    this.plannedHours,
  });

  /// Below the station's own `min_employees`, counting only who is present.
  bool get understaffed => station != null && present < station!.minEmployees;

  /// Above the station's `max_employees`, when it sets one.
  bool get overstaffed =>
      station?.maxEmployees != null && present > station!.maxEmployees!;
}

/// Everything worth saying about one shift on one day.
class ShiftInsight {
  final DateTime day;

  /// Null for the bucket of people rostered without a shift.
  final Shift? shift;

  /// The shift's configuration for this weekday, or null when it does not run.
  final WeekdayTime? times;

  /// Plans on the day for this shift, and the present/absent split.
  final int rostered;
  final int present;
  final int absent;

  /// Absent people by `absence_type`, biggest bucket first.
  final List<MapEntry<String, int>> absencesByType;

  /// The head count `/analysis/staffing-per-day` reports for this shift, or
  /// null when analysis is unavailable. It counts only people present, so it
  /// normally equals [present].
  final int? serverCount;

  /// Everyone working that day, all shifts included — the denominator for
  /// this shift's share.
  final int dayTotal;

  final List<WorkstationLoad> workstations;

  /// Hours this shift books on the day: the shift length times the people
  /// present, which is what the roster promises.
  final double plannedHours;

  /// Wishes placed for this shift on this day, and how many of those people
  /// ended up rostered for it.
  final int wishes;
  final int wishesGranted;

  /// Head count for this shift on each day of the day's week, Monday first.
  /// Days outside the loaded range read as zero.
  final List<int> weekPattern;

  /// False when nothing could be read from `/analysis/*`; the roster-derived
  /// numbers are still valid.
  final bool analysisReachable;

  const ShiftInsight({
    required this.day,
    required this.shift,
    required this.times,
    required this.rostered,
    required this.present,
    required this.absent,
    required this.absencesByType,
    required this.serverCount,
    required this.dayTotal,
    required this.workstations,
    required this.plannedHours,
    required this.wishes,
    required this.wishesGranted,
    required this.weekPattern,
    required this.analysisReachable,
  });

  int get minRequired => times?.minEmployees ?? 0;
  int? get maxAllowed => times?.maxEmployees;

  /// How many more people the weekday's minimum asks for; 0 when it is met.
  int get missing => (minRequired - present).clamp(0, minRequired);

  Coverage get coverage {
    if (times == null) return Coverage.unknown;
    if (present < minRequired) return Coverage.under;
    final max = maxAllowed;
    if (max != null && present > max) return Coverage.over;
    if (minRequired == 0 && max == null) return Coverage.unknown;
    return Coverage.met;
  }

  /// This shift's share of the day's head count, 0..1. Zero when nobody works.
  double get shareOfDay => dayTotal == 0 ? 0 : present / dayTotal;
}

/// Everything worth saying about one employee, on a day and over the loaded
/// range.
class EmployeeInsight {
  /// The full record when `/employees/{id}` answered, otherwise the list entry.
  final Employee? employee;

  /// True while the fuller record is still being read, so the sheet can show
  /// the roster half immediately.
  final bool detailPending;

  final DateTime day;

  /// The employee's plan for [day], when the roster has one.
  final ConfirmedShiftPlan? planForDay;

  /// The range the totals below are counted over — whatever is loaded.
  final DateTime? from;
  final DateTime? to;

  final int rosteredDays;
  final int workedDays;
  final int absentDays;
  final List<MapEntry<String, int>> absencesByType;

  /// Days worked per shift, most days first.
  final List<MapEntry<String, int>> daysByShift;

  /// Hours the roster books for them across the range.
  final double plannedHours;

  final int wishes;
  final int wishesGranted;

  const EmployeeInsight({
    required this.employee,
    required this.detailPending,
    required this.day,
    required this.planForDay,
    required this.from,
    required this.to,
    required this.rosteredDays,
    required this.workedDays,
    required this.absentDays,
    required this.absencesByType,
    required this.daysByShift,
    required this.plannedHours,
    required this.wishes,
    required this.wishesGranted,
  });

  /// Share of the employee's monthly hours the loaded range already books,
  /// or null when the roster does not say what their month should hold.
  double? get monthlyLoad {
    final target = employee?.monthlyWorkingHours ?? 0;
    return target <= 0 ? null : plannedHours / target;
  }

  /// How many of the placed wishes the roster honoured, 0..1; null when none
  /// were placed.
  double? get wishHitRate => wishes == 0 ? null : wishesGranted / wishes;
}

/// Builds the insight for [shiftId] on [day]. Pass [analysis] when the
/// `/analysis/*` numbers have arrived; without it everything roster-derived is
/// still filled in.
ShiftInsight buildShiftInsight(
  ShiftDataController data, {
  required DateTime day,
  required String? shiftId,
  DayAnalysis? analysis,
}) {
  final key = dateKey(day);
  final shift = data.shiftById(shiftId);
  final plans = data
      .allPlansForDay(key)
      .where((p) => p.shiftId == shiftId)
      .toList();

  final present = plans.where((p) => p.isPresent).toList();
  final absences = <String, int>{};
  for (final p in plans.where((p) => !p.isPresent)) {
    final type = p.absenceType ?? 'unknown';
    absences[type] = (absences[type] ?? 0) + 1;
  }

  // Group the present people by workstation; the unassigned bucket sorts last.
  final byWorkstation = <String?, List<ConfirmedShiftPlan>>{};
  for (final p in plans) {
    byWorkstation.putIfAbsent(p.workstationId, () => []).add(p);
  }
  final wsKeys = byWorkstation.keys.toList()
    ..sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      final na = data.workstationById(a)?.name ?? '';
      final nb = data.workstationById(b)?.name ?? '';
      return na.compareTo(nb);
    });

  final loads = <WorkstationLoad>[
    for (final id in wsKeys)
      WorkstationLoad(
        id: id,
        name: data.workstationById(id)?.name ?? '',
        station: data.workstationById(id),
        rostered: byWorkstation[id]!.length,
        present: byWorkstation[id]!.where((p) => p.isPresent).length,
        plannedEmployees: id == null ? null : analysis?.headcountFor(id),
        plannedHours: id == null ? null : analysis?.hoursFor(id),
      ),
  ];

  final wishes = data.wishesForDay(key).where((w) => w.shiftId == shiftId);
  final rosteredIds = {for (final p in present) p.employeeId};

  final times = shift?.timesFor(key);
  final dayPresent = data.allPlansForDay(key).where((p) => p.isPresent).length;

  return ShiftInsight(
    day: key,
    shift: shift,
    times: times,
    rostered: plans.length,
    present: present.length,
    absent: plans.length - present.length,
    absencesByType: _ranked(absences),
    serverCount: shiftId == null
        ? null
        : analysis?.staffing?.countForShift(shiftId),
    dayTotal: analysis?.staffing?.employeesWorking ?? dayPresent,
    workstations: loads,
    plannedHours: (times?.hours ?? 0) * present.length,
    wishes: wishes.length,
    wishesGranted: wishes
        .where((w) => rosteredIds.contains(w.employeeId))
        .length,
    weekPattern: _weekPattern(data, key, shiftId),
    analysisReachable: analysis?.reachable ?? false,
  );
}

/// One shift's slice of a day's head count, for the day-context bar chart.
class ShiftSlice {
  /// Null for people rostered without a shift.
  final String? shiftId;
  final String name;
  final int count;

  const ShiftSlice({
    required this.shiftId,
    required this.name,
    required this.count,
  });
}

/// How a day's present head count splits across the shifts, in roster order.
///
/// The counts come from the roster; where `/analysis/staffing-per-day` has its
/// own number for a shift that one wins, since it is what the server reports
/// everywhere else. Shifts the server knows and the loaded roster does not are
/// appended rather than dropped.
List<ShiftSlice> dayShiftSplit(
  ShiftDataController data,
  DateTime rawDay, {
  DayAnalysis? analysis,
  String unassignedLabel = '',
}) {
  final day = dateKey(rawDay);
  final local = <String?, int>{};
  for (final p in data.allPlansForDay(day)) {
    if (!p.isPresent) continue;
    local[p.shiftId] = (local[p.shiftId] ?? 0) + 1;
  }

  final slices =
      <ShiftSlice>[
        for (final id in local.keys)
          ShiftSlice(
            shiftId: id,
            name: id == null
                ? unassignedLabel
                : data.shiftById(id)?.name ?? unassignedLabel,
            count:
                (id == null ? null : analysis?.staffing?.countForShift(id)) ??
                local[id]!,
          ),
      ]..sort((a, b) {
        if (a.shiftId == null) return 1;
        if (b.shiftId == null) return -1;
        final oa = data.shiftById(a.shiftId)?.order ?? 999;
        final ob = data.shiftById(b.shiftId)?.order ?? 999;
        return oa != ob ? oa.compareTo(ob) : a.name.compareTo(b.name);
      });

  for (final s
      in analysis?.staffing?.perShift ?? const <ShiftDailyStaffing>[]) {
    if (local.containsKey(s.shiftId)) continue;
    slices.add(
      ShiftSlice(
        shiftId: s.shiftId,
        name: s.shiftName,
        count: s.employeesWorking,
      ),
    );
  }
  return slices;
}

/// Present head count for [shiftId] on each day of [day]'s week, Monday first.
List<int> _weekPattern(
  ShiftDataController data,
  DateTime day,
  String? shiftId,
) {
  final monday = day.subtract(Duration(days: day.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      data
          .allPlansForDay(monday.add(Duration(days: i)))
          .where((p) => p.shiftId == shiftId && p.isPresent)
          .length,
  ];
}

/// Builds the insight for [employeeId] on [day]. [detail] is the fuller record
/// from `/employees/{id}`; without it the list entry is used and
/// [EmployeeInsight.detailPending] says the capabilities are still coming.
EmployeeInsight buildEmployeeInsight(
  ShiftDataController data, {
  required DateTime day,
  required String employeeId,
  Employee? detail,
  bool detailPending = false,
}) {
  final key = dateKey(day);
  final from = data.loadedFrom;
  final to = data.loadedTo;

  ConfirmedShiftPlan? planForDay;
  for (final p in data.allPlansForDay(key)) {
    if (p.employeeId == employeeId) {
      planForDay = p;
      break;
    }
  }

  var rostered = 0;
  var worked = 0;
  var hours = 0.0;
  final absences = <String, int>{};
  final byShift = <String, int>{};

  if (from != null && to != null) {
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      for (final p in data.allPlansForDay(d)) {
        if (p.employeeId != employeeId) continue;
        rostered++;
        if (!p.isPresent) {
          final type = p.absenceType ?? 'unknown';
          absences[type] = (absences[type] ?? 0) + 1;
          continue;
        }
        if (p.shiftId == null) continue;
        worked++;
        byShift[p.shiftId!] = (byShift[p.shiftId!] ?? 0) + 1;
        hours += data.shiftById(p.shiftId)?.timesFor(d)?.hours ?? 0;
      }
    }
  }

  // Wishes are counted for the same range, and one counts as granted when the
  // roster put that employee on the shift they asked for.
  var wishes = 0;
  var granted = 0;
  if (from != null && to != null) {
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      for (final w in data.wishesForDay(d)) {
        if (w.employeeId != employeeId) continue;
        wishes++;
        final got = data
            .allPlansForDay(d)
            .any(
              (p) =>
                  p.employeeId == employeeId &&
                  p.shiftId == w.shiftId &&
                  p.isPresent,
            );
        if (got) granted++;
      }
    }
  }

  return EmployeeInsight(
    employee: detail ?? data.employeeById(employeeId),
    detailPending: detailPending,
    day: key,
    planForDay: planForDay,
    from: from,
    to: to,
    rosteredDays: rostered,
    workedDays: worked,
    absentDays: absences.values.fold(0, (a, b) => a + b),
    absencesByType: _ranked(absences),
    daysByShift: _ranked(byShift),
    plannedHours: hours,
    wishes: wishes,
    wishesGranted: granted,
  );
}

/// Counts as a list, biggest first, ties broken by name so the order is
/// stable across rebuilds.
List<MapEntry<String, int>> _ranked(Map<String, int> counts) =>
    counts.entries.toList()..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });

/// Every plan the loaded range holds for [employeeId], oldest day first.
///
/// The insight sheets show counts built the same way; this returns the rows
/// behind those counts so a long press can list them.
List<ConfirmedShiftPlan> employeePlansInRange(
  ShiftDataController data,
  String employeeId, {
  bool Function(ConfirmedShiftPlan plan)? where,
}) {
  final from = data.loadedFrom;
  final to = data.loadedTo;
  if (from == null || to == null) return const [];

  final out = <ConfirmedShiftPlan>[];
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    for (final p in data.allPlansForDay(d)) {
      if (p.employeeId != employeeId) continue;
      if (where != null && !where(p)) continue;
      out.add(p);
    }
  }
  return out;
}

/// One wish of [employeeId]'s in the loaded range, and whether the roster
/// ended up putting them on the shift they asked for.
class WishOutcome {
  final ShiftWish wish;
  final bool granted;

  const WishOutcome({required this.wish, required this.granted});
}

/// Every wish [employeeId] placed inside the loaded range, oldest day first,
/// each with the outcome the employee sheet's hit rate is built from.
List<WishOutcome> employeeWishesInRange(
  ShiftDataController data,
  String employeeId,
) {
  final from = data.loadedFrom;
  final to = data.loadedTo;
  if (from == null || to == null) return const [];

  final out = <WishOutcome>[];
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    for (final w in data.wishesForDay(d)) {
      if (w.employeeId != employeeId) continue;
      out.add(
        WishOutcome(
          wish: w,
          granted: data
              .allPlansForDay(d)
              .any(
                (p) =>
                    p.employeeId == employeeId &&
                    p.shiftId == w.shiftId &&
                    p.isPresent,
              ),
        ),
      );
    }
  }
  return out;
}

/// Hours the roster books for [plan] on its own day; 0 for an absence or a
/// shift that does not run that weekday.
double plannedHoursFor(ShiftDataController data, ConfirmedShiftPlan plan) {
  if (!plan.isPresent) return 0;
  return data.shiftById(plan.shiftId)?.timesFor(plan.date)?.hours ?? 0;
}
