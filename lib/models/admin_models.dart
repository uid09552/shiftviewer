import 'dart:convert';

/// Models for the management screens (shift-planner / shift-admin), mirroring
/// the backend's request/response DTOs. Like `models.dart`, only the fields the
/// app uses are modelled and unknown fields are ignored on decode.

DateTime? _date(Object? raw) =>
    raw is String && raw.isNotEmpty ? DateTime.tryParse(raw) : null;

int _int(Object? raw, [int fallback = 0]) =>
    (raw as num?)?.toInt() ?? fallback;

double _double(Object? raw, [double fallback = 0]) =>
    (raw as num?)?.toDouble() ?? fallback;

/// The realm roles the backend knows, in the order the users screen lists them.
enum ShiftRole {
  admin('shift-admin'),
  planner('shift-planner'),
  viewer('shift-viewer');

  final String wire;
  const ShiftRole(this.wire);

  static ShiftRole? parse(String raw) {
    for (final r in values) {
      if (r.wire == raw) return r;
    }
    return null;
  }
}

/// A single employee's absence preference or hard absence —
/// `GET /unavailabilities`.
class Unavailability {
  final String id;
  final String employeeId;
  final DateTime date;
  final String? shiftId;
  final bool isSoftPreference;

  const Unavailability({
    required this.id,
    required this.employeeId,
    required this.date,
    this.shiftId,
    this.isSoftPreference = false,
  });

  factory Unavailability.fromJson(Map<String, dynamic> json) => Unavailability(
    id: json['id'] as String? ?? '',
    employeeId: json['employee_id'] as String? ?? '',
    date: DateTime.parse(json['unavailable_date'] as String),
    shiftId: json['shift_id'] as String?,
    isSoftPreference: json['is_soft_preference'] as bool? ?? false,
  );
}

/// A period a workstation is closed, inclusive at both ends.
class WorkstationClosure {
  final String id;
  final String workstationId;
  final DateTime from;
  final DateTime to;

  const WorkstationClosure({
    required this.id,
    required this.workstationId,
    required this.from,
    required this.to,
  });

  factory WorkstationClosure.fromJson(Map<String, dynamic> json) =>
      WorkstationClosure(
        id: json['id'] as String? ?? '',
        workstationId: json['workstation_id'] as String? ?? '',
        from: DateTime.parse(json['unavailable_from'] as String),
        to: DateTime.parse(json['unavailable_to'] as String),
      );

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(from) && !d.isAfter(to);
  }
}

/// Workstation priority weights inside [PlannerSettings].
class PriorityWeights {
  final int high;
  final int medium;
  final int low;

  const PriorityWeights({
    required this.high,
    required this.medium,
    required this.low,
  });

  factory PriorityWeights.fromJson(Map<String, dynamic>? json) =>
      PriorityWeights(
        high: _int(json?['high'], 10000),
        medium: _int(json?['medium'], 1000),
        low: _int(json?['low'], 100),
      );

  Map<String, dynamic> toJson() => {'high': high, 'medium': medium, 'low': low};

  @override
  bool operator ==(Object other) =>
      other is PriorityWeights &&
      other.high == high &&
      other.medium == medium &&
      other.low == low;

  @override
  int get hashCode => Object.hash(high, medium, low);
}

/// The optimizer's knobs for this tenant — `GET/PUT /planner-settings`.
///
/// Held as a JSON map so a field the app does not know yet survives a save
/// unchanged instead of being reset.
class PlannerSettings {
  final Map<String, dynamic> values;

  const PlannerSettings(this.values);

  factory PlannerSettings.fromJson(Map<String, dynamic> json) =>
      PlannerSettings(Map<String, dynamic>.from(json));

  num? number(String key) => values[key] as num?;

  int integer(String key) => _int(values[key]);

  PriorityWeights get priorityWeights => PriorityWeights.fromJson(
    values['priority_weights'] as Map<String, dynamic>?,
  );

  String get minStaffingMode => values['min_staffing_mode'] as String? ?? 'soft';

  /// How `max_nights_per_month`/`max_weekends_per_month` personal limits hold:
  /// `hard` (default) never exceeds them; `soft` exceeds them only to fill a
  /// shift that would otherwise stay short. `no_night_shifts` is always hard.
  String get personalLimitsMode =>
      values['personal_limits_mode'] as String? ?? 'hard';

  bool get keepFixedAssignments =>
      values['keep_fixed_assignments'] as bool? ?? true;

  DateTime? get updatedAt => _date(values['updated_at']);

  PlannerSettings copyWith(Map<String, dynamic> changes) =>
      PlannerSettings({...values, ...changes});

  /// What `PUT` takes: everything but the server-kept timestamp.
  Map<String, dynamic> toRequest() =>
      Map<String, dynamic>.from(values)..remove('updated_at');
}

/// A named rhythm; one slot per day of the cycle, a shift id or null (off).
class RotationPattern {
  final String id;
  final String name;
  final List<String?> slots;

  const RotationPattern({
    required this.id,
    required this.name,
    required this.slots,
  });

  factory RotationPattern.fromJson(Map<String, dynamic> json) =>
      RotationPattern(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((e) => e as String?)
            .toList(),
      );
}

/// How one day of a rotation preview relates to what is already fixed.
enum ApplyCellStatus { newCell, same, replace, conflict, absent }

class ApplyCell {
  final DateTime date;
  final String? shiftId;
  final ApplyCellStatus status;
  final String? existingShiftId;
  final bool hasExisting;

  const ApplyCell({
    required this.date,
    required this.shiftId,
    required this.status,
    this.existingShiftId,
    this.hasExisting = false,
  });

  factory ApplyCell.fromJson(Map<String, dynamic> json) {
    final existing = json['existing'] as Map<String, dynamic>?;
    return ApplyCell(
      date: DateTime.parse(json['date'] as String),
      shiftId: json['shift_id'] as String?,
      status: switch (json['status']) {
        'same' => ApplyCellStatus.same,
        'replace' => ApplyCellStatus.replace,
        'conflict' => ApplyCellStatus.conflict,
        'absent' => ApplyCellStatus.absent,
        _ => ApplyCellStatus.newCell,
      },
      existingShiftId: existing?['shift_id'] as String?,
      hasExisting: existing != null,
    );
  }
}

class ApplyRow {
  final String employeeId;
  final String employeeName;
  final List<ApplyCell> cells;

  const ApplyRow({
    required this.employeeId,
    required this.employeeName,
    required this.cells,
  });

  factory ApplyRow.fromJson(Map<String, dynamic> json) => ApplyRow(
    employeeId: json['employee_id'] as String? ?? '',
    employeeName: json['employee_name'] as String? ?? '',
    cells: (json['cells'] as List<dynamic>? ?? [])
        .map((e) => ApplyCell.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// What applying a rotation did, or with `dry_run` would do.
class ApplyResult {
  final bool dryRun;
  final int written;
  final int replaced;
  final int unchanged;
  final int conflicts;
  final int onAbsence;
  final List<ApplyRow> rows;

  const ApplyResult({
    required this.dryRun,
    required this.written,
    required this.replaced,
    required this.unchanged,
    required this.conflicts,
    required this.onAbsence,
    required this.rows,
  });

  factory ApplyResult.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>? ?? const {};
    return ApplyResult(
      dryRun: json['dry_run'] as bool? ?? false,
      written: _int(s['written']),
      replaced: _int(s['replaced']),
      unchanged: _int(s['unchanged']),
      conflicts: _int(s['conflicts']),
      onAbsence: _int(s['on_absence']),
      rows: (json['rows'] as List<dynamic>? ?? [])
          .map((e) => ApplyRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// An optimizer run as the task list reports it.
class PlanningTask {
  final String id;

  /// `scheduled`, `done` or `error`.
  final String status;
  final String? resultId;
  final String? errorMessage;
  final DateTime? createdAt;

  const PlanningTask({
    required this.id,
    required this.status,
    this.resultId,
    this.errorMessage,
    this.createdAt,
  });

  bool get isRunning => status == 'scheduled';

  factory PlanningTask.fromJson(Map<String, dynamic> json) => PlanningTask(
    id: json['id'] as String? ?? '',
    status: json['status'] as String? ?? '',
    resultId: json['result_id'] as String?,
    errorMessage: json['error_message'] as String?,
    createdAt: _date(json['created_at']),
  );
}

/// One day of one employee in a proposed plan.
class ProposedDay {
  final DateTime date;

  /// `assigned` or `free`.
  final String status;
  final String? shiftId;
  final String? shiftName;
  final String? workstationName;

  const ProposedDay({
    required this.date,
    required this.status,
    this.shiftId,
    this.shiftName,
    this.workstationName,
  });

  factory ProposedDay.fromJson(Map<String, dynamic> json) => ProposedDay(
    date: DateTime.parse(json['date'] as String),
    status: json['status'] as String? ?? '',
    shiftId: json['shift_id'] as String?,
    shiftName: json['shift_name'] as String?,
    workstationName: json['workstation_name'] as String?,
  );
}

class ProposedEmployeePlan {
  final String employeeId;
  final String employeeName;
  final List<ProposedDay> days;

  const ProposedEmployeePlan({
    required this.employeeId,
    required this.employeeName,
    required this.days,
  });

  factory ProposedEmployeePlan.fromJson(Map<String, dynamic> json) =>
      ProposedEmployeePlan(
        employeeId: json['employee_id'] as String? ?? '',
        employeeName: json['employee_name'] as String? ?? '',
        days: (json['daily_plan'] as List<dynamic>? ?? [])
            .map((e) => ProposedDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get assignedDays => days.where((d) => d.status == 'assigned').length;
}

/// A stored optimizer result — a proposed plan not yet confirmed.
class OptimizedResult {
  final String id;
  final DateTime? createdAt;
  final String status;
  final double objectiveValue;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? message;
  final List<ProposedEmployeePlan> employeePlans;

  const OptimizedResult({
    required this.id,
    this.createdAt,
    required this.status,
    required this.objectiveValue,
    this.periodStart,
    this.periodEnd,
    this.message,
    this.employeePlans = const [],
  });

  factory OptimizedResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? const {};
    final period = result['planning_period'] as Map<String, dynamic>?;
    return OptimizedResult(
      id: json['id'] as String? ?? '',
      createdAt: _date(json['creation_date']),
      status: result['status'] as String? ?? '',
      objectiveValue: _double(result['objective_value']),
      periodStart: _date(period?['start_date']),
      periodEnd: _date(period?['end_date']),
      message: result['message'] as String?,
      employeePlans: (result['employee_plans'] as List<dynamic>? ?? [])
          .map((e) => ProposedEmployeePlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get assignmentCount =>
      employeePlans.fold(0, (sum, p) => sum + p.assignedDays);
}

/// One rule a proposed plan breaks, all its breaches collapsed.
class ValidationFinding {
  final String rule;

  /// `error` or `warning`.
  final String severity;
  final String title;
  final String detail;
  final int count;
  final List<String> examples;

  const ValidationFinding({
    required this.rule,
    required this.severity,
    required this.title,
    required this.detail,
    required this.count,
    required this.examples,
  });

  factory ValidationFinding.fromJson(Map<String, dynamic> json) =>
      ValidationFinding(
        rule: json['rule'] as String? ?? '',
        severity: json['severity'] as String? ?? 'warning',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        count: _int(json['count']),
        examples: (json['examples'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
      );
}

/// The assistant's check of a proposed plan — `POST /agent/plan/validate`.
class PlanValidationReport {
  /// `valid`, `issues` or `invalid`.
  final String verdict;
  final String headline;
  final String summary;
  final List<ValidationFinding> findings;

  const PlanValidationReport({
    required this.verdict,
    required this.headline,
    required this.summary,
    required this.findings,
  });

  factory PlanValidationReport.fromJson(Map<String, dynamic> json) =>
      PlanValidationReport(
        verdict: json['verdict'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        findings: (json['findings'] as List<dynamic>? ?? [])
            .map((e) => ValidationFinding.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One person's share of the confirmed roster — `GET /analysis/fairness`.
class EmployeeFairness {
  final String employeeId;
  final String employeeName;
  final int shifts;
  final double hours;
  final double? targetHours;
  final int nightShifts;
  final int weekendDays;
  final int weekends;
  final int wishesAsked;
  final int wishesGranted;
  final int daysAbsent;

  const EmployeeFairness({
    required this.employeeId,
    required this.employeeName,
    required this.shifts,
    required this.hours,
    this.targetHours,
    required this.nightShifts,
    required this.weekendDays,
    required this.weekends,
    required this.wishesAsked,
    required this.wishesGranted,
    required this.daysAbsent,
  });

  factory EmployeeFairness.fromJson(Map<String, dynamic> json) =>
      EmployeeFairness(
        employeeId: json['employee_id'] as String? ?? '',
        employeeName: json['employee_name'] as String? ?? '',
        shifts: _int(json['shifts']),
        hours: _double(json['hours']),
        targetHours: (json['target_hours'] as num?)?.toDouble(),
        nightShifts: _int(json['night_shifts']),
        weekendDays: _int(json['weekend_days']),
        weekends: _int(json['weekends']),
        wishesAsked: _int(json['wishes_asked']),
        wishesGranted: _int(json['wishes_granted']),
        daysAbsent: _int(json['days_absent']),
      );

  /// Hours over (+) or under (−) target, one decimal; null without a target.
  double? get targetDelta {
    final t = targetHours;
    return t == null ? null : ((hours - t) * 10).round() / 10;
  }
}

/// One audit log entry. [changes] is the entity's state after the action, as
/// JSON text, or null.
class AuditLogEntry {
  final String id;
  final String? actor;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? changes;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    this.actor,
    required this.action,
    this.entityType,
    this.entityId,
    this.changes,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
    id: json['id'] as String? ?? '',
    actor: json['actor'] as String?,
    action: json['action'] as String? ?? '',
    entityType: json['entity_type'] as String?,
    entityId: json['entity_id'] as String?,
    changes: json['changes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  /// [changes] decoded; the raw text when it is not JSON, null when empty.
  Object? get state {
    final raw = changes;
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  bool get isDelete =>
      action.endsWith('.delete') || action.endsWith('.remove_from_organization');

  /// The name the entry is about, read from its state when it carries one.
  String? get subjectName {
    final s = state;
    if (s is! Map) return null;
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final person = [text(s['first_name']), text(s['last_name'])]
        .whereType<String>()
        .join(' ');
    return text(s['name']) ??
        (person.isEmpty ? null : person) ??
        text(s['username']) ??
        text(s['email']);
  }
}

/// A page of audit entries plus the total the filters match.
class AuditLogPage {
  final List<AuditLogEntry> entries;
  final int total;

  const AuditLogPage(this.entries, this.total);
}

/// The values the audit log's filters can take.
class AuditFacets {
  final List<String> actions;
  final List<String> entityTypes;
  final List<String> actors;

  const AuditFacets({
    this.actions = const [],
    this.entityTypes = const [],
    this.actors = const [],
  });

  factory AuditFacets.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) =>
        (json[key] as List<dynamic>? ?? []).map((e) => '$e').toList();
    return AuditFacets(
      actions: list('actions'),
      entityTypes: list('entity_types'),
      actors: list('actors'),
    );
  }
}

/// A member of the caller's organization (Keycloak-backed).
class OrganizationUser {
  final String id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool enabled;
  final List<ShiftRole> roles;

  const OrganizationUser({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.enabled = true,
    this.roles = const [],
  });

  factory OrganizationUser.fromJson(Map<String, dynamic> json) =>
      OrganizationUser(
        id: json['id'] as String? ?? '',
        username: json['username'] as String?,
        email: json['email'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        enabled: json['enabled'] as bool? ?? true,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((e) => ShiftRole.parse('$e'))
            .whereType<ShiftRole>()
            .toList(),
      );

  String get displayName {
    final full = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    if (full.isNotEmpty) return full;
    return username ?? email ?? id;
  }
}

/// What one employee may be planned for beyond the ward's rules, per
/// `GET /employees/{id}/personal-limits`.
///
/// Every numeric limit is optional: null means "no personal limit", and the
/// ward's own rules decide. An employee who has never had limits saved comes
/// back with every field empty and [updatedAt] null.
class PersonalLimits {
  final String employeeId;

  /// Night shifts per calendar month; null = no personal limit.
  final int? maxNightsPerMonth;

  /// Weekends (Saturday and/or Sunday worked) per calendar month; null = none.
  final int? maxWeekendsPerMonth;

  /// Never on a night shift. Always a hard rule, whatever
  /// `personal_limits_mode` says.
  final bool noNightShifts;

  /// Weekdays they would rather have off, 0 = Monday … 6 = Sunday. Soft: the
  /// planner weighs them with `preference_weight`.
  final List<int> preferredDaysOff;

  /// null until the limits are first saved.
  final DateTime? updatedAt;

  const PersonalLimits({
    required this.employeeId,
    this.maxNightsPerMonth,
    this.maxWeekendsPerMonth,
    this.noNightShifts = false,
    this.preferredDaysOff = const [],
    this.updatedAt,
  });

  /// The empty set, for an employee the server has nothing saved for.
  static PersonalLimits emptyFor(String employeeId) =>
      PersonalLimits(employeeId: employeeId);

  factory PersonalLimits.fromJson(Map<String, dynamic> json) => PersonalLimits(
    employeeId: json['employee_id'] as String? ?? '',
    maxNightsPerMonth: (json['max_nights_per_month'] as num?)?.toInt(),
    maxWeekendsPerMonth: (json['max_weekends_per_month'] as num?)?.toInt(),
    noNightShifts: json['no_night_shifts'] as bool? ?? false,
    preferredDaysOff: (json['preferred_days_off'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .where((d) => d >= 0 && d <= 6)
        .toList(),
    updatedAt: _date(json['updated_at']),
  );

  /// What `PUT` takes. Nulls are sent explicitly: the endpoint replaces the
  /// limits as a whole, so an omitted field would clear rather than keep it.
  Map<String, dynamic> toRequest() => {
    'max_nights_per_month': maxNightsPerMonth,
    'max_weekends_per_month': maxWeekendsPerMonth,
    'no_night_shifts': noNightShifts,
    'preferred_days_off': (preferredDaysOff.toSet().toList()..sort()),
  };

  /// Whether anything at all is restricted here — what the UI uses to decide
  /// between "none set" and a summary.
  bool get isEmpty =>
      maxNightsPerMonth == null &&
      maxWeekendsPerMonth == null &&
      !noNightShifts &&
      preferredDaysOff.isEmpty;

  PersonalLimits copyWith({
    int? maxNightsPerMonth,
    bool clearMaxNights = false,
    int? maxWeekendsPerMonth,
    bool clearMaxWeekends = false,
    bool? noNightShifts,
    List<int>? preferredDaysOff,
  }) => PersonalLimits(
    employeeId: employeeId,
    maxNightsPerMonth:
        clearMaxNights ? null : (maxNightsPerMonth ?? this.maxNightsPerMonth),
    maxWeekendsPerMonth: clearMaxWeekends
        ? null
        : (maxWeekendsPerMonth ?? this.maxWeekendsPerMonth),
    noNightShifts: noNightShifts ?? this.noNightShifts,
    preferredDaysOff: preferredDaysOff ?? this.preferredDaysOff,
    updatedAt: updatedAt,
  );
}

/// One fixed assignment — what a rotation pattern writes — per
/// `GET /shift-assignments`. A null [shiftId] is a fixed day off.
class ShiftAssignment {
  final String id;
  final String employeeId;
  final String? shiftId;
  final DateTime date;

  const ShiftAssignment({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    required this.date,
  });

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) =>
      ShiftAssignment(
        id: json['id'] as String? ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        shiftId: json['shift_id'] as String?,
        date: DateTime.parse(json['date'] as String),
      );

  /// A fixed day off rather than a fixed shift.
  bool get isDayOff => shiftId == null;
}

/// Version, commit and build date of the backend this app is talking to, per
/// `GET /info`. Fields the deployment could not determine come back empty.
class BackendInfo {
  final String name;
  final String version;
  final String commit;
  final DateTime? buildDate;

  const BackendInfo({
    this.name = '',
    this.version = '',
    this.commit = '',
    this.buildDate,
  });

  factory BackendInfo.fromJson(Map<String, dynamic> json) => BackendInfo(
    name: json['name'] as String? ?? '',
    version: json['version'] as String? ?? '',
    commit: json['commit'] as String? ?? '',
    buildDate: _date(json['build_date']),
  );

  /// First seven characters of the commit, as git shows it; empty when the
  /// build did not record one.
  String get shortCommit =>
      commit.length <= 7 ? commit : commit.substring(0, 7);
}
