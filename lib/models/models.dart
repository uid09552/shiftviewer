import 'package:flutter/material.dart';

/// Data models mirroring the Hospital Shift Management API
/// (see backend/api/openapi.yaml). Only the fields the viewer needs are
/// modelled; unknown fields are ignored on decode.

/// Parses a `#RRGGBB` hex string into a [Color]. Falls back to grey.
Color parseHexColor(String? hex) {
  if (hex == null) return const Color(0xFF9E9E9E);
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? const Color(0xFF9E9E9E) : Color(parsed);
}

class WeekdayTime {
  final int weekday; // 0 = Monday ... 6 = Sunday
  final String startTime;
  final String endTime;
  final int minEmployees;
  final int? maxEmployees;

  /// Rest days the optimizer keeps free after this shift; 0 = none.
  final int freeDaysAfterShift;

  const WeekdayTime({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.minEmployees,
    this.maxEmployees,
    this.freeDaysAfterShift = 0,
  });

  factory WeekdayTime.fromJson(Map<String, dynamic> json) => WeekdayTime(
    weekday: (json['weekday'] as num?)?.toInt() ?? 0,
    startTime: json['start_time'] as String? ?? '',
    endTime: json['end_time'] as String? ?? '',
    minEmployees: (json['min_employees'] as num?)?.toInt() ?? 0,
    maxEmployees: (json['max_employees'] as num?)?.toInt(),
    freeDaysAfterShift: (json['free_days_after_shift'] as num?)?.toInt() ?? 0,
  );

  /// Length of the shift in hours, night shifts included — an end time not
  /// after the start belongs to the next morning. Zero when either time is
  /// unparseable.
  double get hours {
    final start = _minutesOfDay(startTime);
    final end = _minutesOfDay(endTime);
    if (start == null || end == null) return 0;
    final span = end > start ? end - start : end + 24 * 60 - start;
    return span / 60;
  }
}

/// `HH:MM`/`HH:MM:SS` as minutes since midnight, or null when it is neither.
int? _minutesOfDay(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

class Shift {
  final String id;
  final String name;
  final String shortName;
  final String color;
  final int order;
  final List<WeekdayTime> weekdayTimes;

  const Shift({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.order,
    required this.weekdayTimes,
  });

  Color get displayColor => parseHexColor(color);

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    shortName: json['short_name'] as String? ?? '',
    color: json['color'] as String? ?? '#9E9E9E',
    order: (json['order'] as num?)?.toInt() ?? 0,
    weekdayTimes: (json['weekday_times'] as List<dynamic>? ?? [])
        .map((e) => WeekdayTime.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Times configured for a given [DateTime]'s weekday, if any.
  WeekdayTime? timesFor(DateTime date) {
    final wd = date.weekday - 1; // DateTime: Mon=1..Sun=7 -> 0..6
    for (final t in weekdayTimes) {
      if (t.weekday == wd) return t;
    }
    return null;
  }
}

class Employee {
  final String id;
  final String name;
  final String email;
  final double monthlyWorkingHours;
  final List<Shift> availableShifts;
  final List<Capability> capabilities;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.monthlyWorkingHours,
    this.availableShifts = const [],
    this.capabilities = const [],
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    monthlyWorkingHours:
        (json['monthly_working_hours'] as num?)?.toDouble() ?? 0,
    availableShifts: (json['available_shifts'] as List<dynamic>? ?? [])
        .map((e) => Shift.fromJson(e as Map<String, dynamic>))
        .toList(),
    capabilities: (json['capabilities'] as List<dynamic>? ?? [])
        .map((e) => Capability.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Capability {
  final String id;
  final String name;

  /// Ordinal skill level inside [skillGroup]; 1 when the API says nothing.
  final int level;

  /// Groups capabilities into substitutable tiers of one skill, or null when
  /// this capability stands alone and never substitutes for another.
  final String? skillGroup;

  const Capability({
    required this.id,
    required this.name,
    this.level = 1,
    this.skillGroup,
  });

  factory Capability.fromJson(Map<String, dynamic> json) => Capability(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    level: (json['level'] as num?)?.toInt() ?? 1,
    skillGroup: json['skill_group'] as String?,
  );
}

class Workstation {
  final String id;
  final String name;
  final bool available;

  /// Shifts this workstation is staffed in. The API sends `active_shift_ids`;
  /// an older singular `active_shift_id` is still accepted.
  final List<String> activeShiftIds;

  /// `high` / `medium` / `low` — how hard the optimizer tries to staff it.
  final String priority;

  /// Staffing bounds per shift; [maxEmployees] null means no ceiling.
  final int minEmployees;
  final int? maxEmployees;

  const Workstation({
    required this.id,
    required this.name,
    required this.available,
    this.activeShiftIds = const [],
    this.priority = 'medium',
    this.minEmployees = 0,
    this.maxEmployees,
  });

  factory Workstation.fromJson(Map<String, dynamic> json) {
    final ids = json['active_shift_ids'];
    final single = json['active_shift_id'] as String?;
    return Workstation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      available: json['available'] as bool? ?? true,
      activeShiftIds: ids is List
          ? ids.whereType<String>().toList()
          : [?single],
      priority: json['priority'] as String? ?? 'medium',
      minEmployees: (json['min_employees'] as num?)?.toInt() ?? 0,
      maxEmployees: (json['max_employees'] as num?)?.toInt(),
    );
  }

  /// Whether this workstation is staffed in [shiftId]. A workstation that
  /// names no shifts is taken to serve all of them, which is how the roster
  /// reads a station left unrestricted.
  bool servesShift(String? shiftId) =>
      activeShiftIds.isEmpty ||
      (shiftId != null && activeShiftIds.contains(shiftId));
}

/// An employee's request to work a given shift on a given date.
///
/// Wishes live next to the roster: the optimizer rewards fulfilling them, so a
/// wish is a preference, never a guarantee. The API allows at most one wish per
/// employee and date.
class ShiftWish {
  final String id;
  final String employeeId;
  final String shiftId;
  final DateTime date;

  const ShiftWish({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    required this.date,
  });

  factory ShiftWish.fromJson(Map<String, dynamic> json) => ShiftWish(
    id: json['id'] as String? ?? '',
    employeeId: json['employee_id'] as String? ?? '',
    shiftId: json['shift_id'] as String? ?? '',
    date: DateTime.parse(json['wish_date'] as String),
  );
}

/// A confirmed shift plan entry — the actual roster for an employee on a date.
class ConfirmedShiftPlan {
  final String id;
  final String employeeId;
  final String? shiftId;
  final String? workstationId;
  final DateTime date;
  final bool isPresent;
  final String? absenceType;
  final String creationType;

  const ConfirmedShiftPlan({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    required this.workstationId,
    required this.date,
    required this.isPresent,
    required this.absenceType,
    required this.creationType,
  });

  factory ConfirmedShiftPlan.fromJson(Map<String, dynamic> json) =>
      ConfirmedShiftPlan(
        id: json['id'] as String? ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        shiftId: json['shift_id'] as String?,
        workstationId: json['workstation_id'] as String?,
        date: DateTime.parse(json['date'] as String),
        isPresent: json['is_present'] as bool? ?? true,
        absenceType: json['absence_type'] as String?,
        creationType: json['creation_type'] as String? ?? 'manual',
      );
}

/// One person the roster has working on a given day, with the shift and
/// workstation names the server already resolved — `GET /analysis/staffing-per-day`.
class WorkingEmployee {
  final String employeeId;
  final String employeeName;
  final String? shiftId;
  final String? shiftName;
  final String? workstationId;
  final String? workstationName;

  const WorkingEmployee({
    required this.employeeId,
    required this.employeeName,
    this.shiftId,
    this.shiftName,
    this.workstationId,
    this.workstationName,
  });

  factory WorkingEmployee.fromJson(Map<String, dynamic> json) =>
      WorkingEmployee(
        employeeId: json['employee_id'] as String? ?? '',
        employeeName: json['employee_name'] as String? ?? '',
        shiftId: json['shift_id'] as String?,
        shiftName: json['shift_name'] as String?,
        workstationId: json['workstation_id'] as String?,
        workstationName: json['workstation_name'] as String?,
      );
}

/// A day's head count for one shift, as the server counts it.
class ShiftDailyStaffing {
  final String shiftId;
  final String shiftName;
  final int employeesWorking;

  const ShiftDailyStaffing({
    required this.shiftId,
    required this.shiftName,
    required this.employeesWorking,
  });

  factory ShiftDailyStaffing.fromJson(Map<String, dynamic> json) =>
      ShiftDailyStaffing(
        shiftId: json['shift_id'] as String? ?? '',
        shiftName: json['shift_name'] as String? ?? '',
        employeesWorking: (json['employees_working'] as num?)?.toInt() ?? 0,
      );
}

/// Who works on one day and how many, split per shift —
/// `GET /analysis/staffing-per-day`.
///
/// The head count includes everyone marked present, workstation or not, so it
/// is the day's total rather than the sum of the per-workstation breakdowns.
class DailyStaffing {
  final DateTime date;
  final int employeesWorking;
  final List<WorkingEmployee> employees;
  final List<ShiftDailyStaffing> perShift;

  const DailyStaffing({
    required this.date,
    required this.employeesWorking,
    this.employees = const [],
    this.perShift = const [],
  });

  factory DailyStaffing.fromJson(Map<String, dynamic> json) => DailyStaffing(
    date: DateTime.parse(json['date'] as String),
    employeesWorking: (json['employees_working'] as num?)?.toInt() ?? 0,
    employees: (json['employees'] as List<dynamic>? ?? [])
        .map((e) => WorkingEmployee.fromJson(e as Map<String, dynamic>))
        .toList(),
    perShift: (json['per_shift'] as List<dynamic>? ?? [])
        .map((e) => ShiftDailyStaffing.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// The head count the server reports for [shiftId], or null when the shift
  /// does not appear in the split at all.
  int? countForShift(String shiftId) {
    for (final s in perShift) {
      if (s.shiftId == shiftId) return s.employeesWorking;
    }
    return null;
  }
}

/// Planned hours booked on one workstation on one day —
/// `GET /analysis/planned-hours-per-day-per-workstation`.
class WorkstationDailyHours {
  final DateTime date;
  final String workstationId;
  final String workstationName;
  final double plannedHours;

  const WorkstationDailyHours({
    required this.date,
    required this.workstationId,
    required this.workstationName,
    required this.plannedHours,
  });

  factory WorkstationDailyHours.fromJson(Map<String, dynamic> json) =>
      WorkstationDailyHours(
        date: DateTime.parse(json['date'] as String),
        workstationId: json['workstation_id'] as String? ?? '',
        workstationName: json['workstation_name'] as String? ?? '',
        plannedHours: (json['planned_hours'] as num?)?.toDouble() ?? 0,
      );
}

/// Head count planned on one workstation on one day —
/// `GET /analysis/planned-employees-per-day-per-workstation`.
class WorkstationDailyEmployees {
  final DateTime date;
  final String workstationId;
  final String workstationName;
  final int plannedEmployees;

  const WorkstationDailyEmployees({
    required this.date,
    required this.workstationId,
    required this.workstationName,
    required this.plannedEmployees,
  });

  factory WorkstationDailyEmployees.fromJson(Map<String, dynamic> json) =>
      WorkstationDailyEmployees(
        date: DateTime.parse(json['date'] as String),
        workstationId: json['workstation_id'] as String? ?? '',
        workstationName: json['workstation_name'] as String? ?? '',
        plannedEmployees: (json['planned_employees'] as num?)?.toInt() ?? 0,
      );
}

/// What the three analysis endpoints report for a single day.
///
/// Each part is optional on purpose: a tenant may restrict analysis, and the
/// day's own roster still answers most questions without it.
class DayAnalysis {
  final DateTime date;

  /// Head count and per-shift split, or null when the endpoint said nothing.
  final DailyStaffing? staffing;
  final List<WorkstationDailyHours> hours;
  final List<WorkstationDailyEmployees> headcount;

  /// False when every analysis call was refused, so the UI can say the numbers
  /// are unavailable rather than show zeros as if they were real.
  final bool reachable;

  const DayAnalysis({
    required this.date,
    this.staffing,
    this.hours = const [],
    this.headcount = const [],
    this.reachable = true,
  });

  /// The result for a day nothing could be loaded for.
  factory DayAnalysis.empty(DateTime date) =>
      DayAnalysis(date: date, reachable: false);

  double? hoursFor(String workstationId) {
    for (final h in hours) {
      if (h.workstationId == workstationId) return h.plannedHours;
    }
    return null;
  }

  int? headcountFor(String workstationId) {
    for (final h in headcount) {
      if (h.workstationId == workstationId) return h.plannedEmployees;
    }
    return null;
  }
}

/// Whether shift wishes may be placed at all, per `GET /wish-settings`.
enum WishMode {
  /// Wishes may be placed for any date.
  enabled,

  /// No wish may be placed or withdrawn, whatever the caller's role.
  disabled,

  /// Only dates inside `[windowStart, windowEnd]` accept wishes.
  dateRange;

  static WishMode parse(String? raw) => switch (raw) {
    'disabled' => WishMode.disabled,
    'date_range' => WishMode.dateRange,
    _ => WishMode.enabled,
  };

  String get wireValue => switch (this) {
    WishMode.enabled => 'enabled',
    WishMode.disabled => 'disabled',
    WishMode.dateRange => 'date_range',
  };
}

/// The tenant's shift-wish window: whether, and for which dates, wishes may be
/// placed at all.
///
/// The server enforces this for every role — `shift-admin` included — on both
/// creating and deleting a wish, so the app mirrors it to keep the user from
/// asking for something that will be refused.
class WishSettings {
  final WishMode mode;

  /// First/last date wishes may be placed for, inclusive. Only meaningful for
  /// [WishMode.dateRange]; the server keeps them across mode changes.
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final DateTime? updatedAt;

  /// The recurring rule that opens and closes the window on its own, or null
  /// when this deployment never reported one.
  final WishSchedule? schedule;

  const WishSettings({
    required this.mode,
    this.windowStart,
    this.windowEnd,
    this.updatedAt,
    this.schedule,
  });

  /// What the app assumes before the real settings arrive: wishing is offered
  /// and the server has the final say.
  static const WishSettings open = WishSettings(mode: WishMode.enabled);

  factory WishSettings.fromJson(Map<String, dynamic> json) => WishSettings(
    mode: WishMode.parse(json['mode'] as String?),
    windowStart: _parseDate(json['window_start']),
    windowEnd: _parseDate(json['window_end']),
    updatedAt: _parseDate(json['updated_at']),
    schedule: json['schedule'] is Map<String, dynamic>
        ? WishSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
        : null,
  );

  static DateTime? _parseDate(Object? raw) =>
      raw is String && raw.isNotEmpty ? DateTime.tryParse(raw) : null;

  /// Whether a wish may be placed or withdrawn for [day].
  ///
  /// A [WishMode.dateRange] window missing one of its bounds cannot be
  /// satisfied — the server requires both — so nothing is offered for it.
  bool allows(DateTime day) {
    switch (mode) {
      case WishMode.enabled:
        return true;
      case WishMode.disabled:
        return false;
      case WishMode.dateRange:
        final start = windowStart;
        final end = windowEnd;
        if (start == null || end == null) return false;
        final d = DateTime(day.year, day.month, day.day);
        return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
            !d.isAfter(DateTime(end.year, end.month, end.day));
    }
  }

  /// Whether any date at all can be wished for.
  bool get isOpen =>
      mode != WishMode.disabled &&
      (mode != WishMode.dateRange ||
          (windowStart != null && windowEnd != null));
}

/// One public holiday of the configured state, per `GET /holidays`.
///
/// A holiday runs on its shifts' Sunday times and counts as a weekend day for
/// the planner, so the calendar marks it: a day that looks like a normal
/// Tuesday is planned like a Sunday.
class Holiday {
  final DateTime date;
  final String name;

  /// State code the holiday belongs to, e.g. `by`. Empty when not reported.
  final String state;

  const Holiday({required this.date, required this.name, this.state = ''});

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
    date: DateTime.parse(json['date'] as String),
    name: json['name'] as String? ?? '',
    state: json['state'] as String? ?? '',
  );
}

/// The holidays stored for a range, with the state they belong to and whether
/// the feature is switched on for this deployment at all.
class HolidayCalendar {
  final String state;
  final bool enabled;
  final List<Holiday> holidays;

  const HolidayCalendar({
    this.state = '',
    this.enabled = false,
    this.holidays = const [],
  });

  /// What the app assumes before the first read: no holidays, so nothing is
  /// marked. The server stays the authority on how a day is planned.
  static const HolidayCalendar none = HolidayCalendar();

  factory HolidayCalendar.fromJson(Map<String, dynamic> json) =>
      HolidayCalendar(
        state: json['state'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        holidays: (json['holidays'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Holiday.fromJson)
            .toList(),
      );

  /// Holidays keyed by midnight-of-day, for a per-cell lookup while painting
  /// a calendar.
  Map<DateTime, Holiday> get byDate => {
    for (final h in holidays)
      DateTime(h.date.year, h.date.month, h.date.day): h,
  };
}

/// How often a [WishSchedule] recurs.
enum ScheduleUnit {
  days,
  weeks,
  months;

  static ScheduleUnit parse(String? raw) => switch (raw) {
    'weeks' => ScheduleUnit.weeks,
    'months' => ScheduleUnit.months,
    _ => ScheduleUnit.days,
  };

  String get wireValue => name;

  /// The largest interval the server accepts for this unit.
  int get maxInterval => switch (this) {
    ScheduleUnit.days => 365,
    ScheduleUnit.weeks => 52,
    ScheduleUnit.months => 24,
  };
}

/// A recurring rule that opens the wish window by itself: at each occurrence
/// the server switches the window to `enabled`, and back to `disabled`
/// [openDays] later. A manual change holds until the next switch.
///
/// Times are UTC — that is what the server stores and acts on.
class WishSchedule {
  final bool enabled;
  final ScheduleUnit unit;

  /// Every N units; at most [ScheduleUnit.maxInterval].
  final int interval;

  /// 0 = Monday. Only used when [unit] is [ScheduleUnit.weeks].
  final int weekday;

  /// Clamped to the month's last day. Only used when [unit] is
  /// [ScheduleUnit.months].
  final int dayOfMonth;

  /// `HH:mm:ss`, UTC.
  final String time;

  /// How long the window stays open after each occurrence.
  final int openDays;

  /// First possible occurrence; anchors the interval. The server defaults it
  /// to today on save.
  final DateTime? startDate;

  /// Next time (UTC) the schedule flips the window; null while it is off.
  /// Server-reported, never sent back.
  final DateTime? nextChangeAt;

  /// Whether that next switch opens the window rather than closing it.
  final bool? nextChangeOpens;

  const WishSchedule({
    this.enabled = false,
    this.unit = ScheduleUnit.weeks,
    this.interval = 1,
    this.weekday = 0,
    this.dayOfMonth = 1,
    this.time = '08:00:00',
    this.openDays = 7,
    this.startDate,
    this.nextChangeAt,
    this.nextChangeOpens,
  });

  /// What an admin who has never set a schedule starts from: off, but with
  /// sensible values already filled in so switching it on needs one tap.
  static const WishSchedule off = WishSchedule();

  factory WishSchedule.fromJson(Map<String, dynamic> json) => WishSchedule(
    enabled: json['enabled'] as bool? ?? false,
    unit: ScheduleUnit.parse(json['unit'] as String?),
    interval: (json['interval'] as num?)?.toInt() ?? 1,
    weekday: (json['weekday'] as num?)?.toInt() ?? 0,
    dayOfMonth: (json['day_of_month'] as num?)?.toInt() ?? 1,
    time: json['time'] as String? ?? '08:00:00',
    openDays: (json['open_days'] as num?)?.toInt() ?? 7,
    startDate: _parseDateOrNull(json['start_date']),
    nextChangeAt: _parseDateOrNull(json['next_change_at']),
    nextChangeOpens: json['next_change_opens'] as bool?,
  );

  /// What `PUT /wish-settings` takes. The server-reported `next_change_*`
  /// fields are left out — they are derived, not settable.
  Map<String, dynamic> toRequest() => {
    'enabled': enabled,
    'unit': unit.wireValue,
    'interval': interval,
    'weekday': weekday,
    'day_of_month': dayOfMonth,
    'time': time,
    'open_days': openDays,
    if (startDate != null)
      'start_date':
          '${startDate!.year.toString().padLeft(4, '0')}-'
          '${startDate!.month.toString().padLeft(2, '0')}-'
          '${startDate!.day.toString().padLeft(2, '0')}',
  };

  WishSchedule copyWith({
    bool? enabled,
    ScheduleUnit? unit,
    int? interval,
    int? weekday,
    int? dayOfMonth,
    String? time,
    int? openDays,
    DateTime? startDate,
  }) => WishSchedule(
    enabled: enabled ?? this.enabled,
    unit: unit ?? this.unit,
    // An interval carried over from another unit may exceed the new maximum.
    interval: (interval ?? this.interval).clamp(1, (unit ?? this.unit).maxInterval),
    weekday: weekday ?? this.weekday,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    time: time ?? this.time,
    openDays: openDays ?? this.openDays,
    startDate: startDate ?? this.startDate,
    nextChangeAt: nextChangeAt,
    nextChangeOpens: nextChangeOpens,
  );
}

DateTime? _parseDateOrNull(Object? raw) =>
    raw is String && raw.isNotEmpty ? DateTime.tryParse(raw) : null;
