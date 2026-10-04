import 'package:intl/intl.dart';

import '../models/admin_models.dart';
import '../models/models.dart';
import 'api_client.dart';

/// The management endpoints the web UI offers shift-planner and shift-admin:
/// master data, roster editing, rotations, the optimizer, analysis, the audit
/// log and user management.
///
/// Wraps a [ShiftApiClient] so auth, token renewal and error handling stay in
/// one place. The server enforces roles; the app only hides what it would
/// refuse.
class AdminApi {
  final ShiftApiClient client;

  AdminApi(this.client);

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');
  static String day(DateTime d) => _fmt.format(d);

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List;
    }
    return const [];
  }

  List<T> _decode<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
      _list(data).map((e) => f(e as Map<String, dynamic>)).toList();

  void close() => client.close();

  // ── Employees ───────────────────────────────────────────────────────────

  Future<List<Employee>> employees() async => _decode(
    await client.getJson('/employees', {'limit': '1000', 'offset': '0'}),
    Employee.fromJson,
  );

  Future<Employee> employee(String id) async =>
      Employee.fromJson(await client.getJson('/employees/$id'));

  Future<Employee> createEmployee({
    required String name,
    required String email,
    required double monthlyHours,
  }) async => Employee.fromJson(
    await client.sendJson('POST', '/employees', {
      'name': name,
      'email': email,
      'monthly_working_hours': monthlyHours,
    }),
  );

  Future<void> updateEmployee(
    String id, {
    required String name,
    required String email,
    required double monthlyHours,
  }) => client.sendJson('PUT', '/employees/$id', {
    'name': name,
    'email': email,
    'monthly_working_hours': monthlyHours,
  });

  Future<void> deleteEmployee(String id) =>
      client.sendJson('DELETE', '/employees/$id');

  Future<List<Capability>> employeeCapabilities(String id) async => _decode(
    await client.getJson('/employees/$id/capabilities'),
    Capability.fromJson,
  );

  Future<List<Shift>> employeeShifts(String id) async => _decode(
    await client.getJson('/employees/$id/available-shifts'),
    Shift.fromJson,
  );

  Future<void> addEmployeeCapability(String id, String capabilityId) =>
      client.sendJson('POST', '/employees/$id/capabilities', {
        'capability_id': capabilityId,
      });

  Future<void> removeEmployeeCapability(String id, String capabilityId) =>
      client.sendJson('DELETE', '/employees/$id/capabilities/$capabilityId');

  Future<void> addEmployeeShift(String id, String shiftId) =>
      client.sendJson('POST', '/employees/$id/available-shifts', {
        'shift_id': shiftId,
      });

  Future<void> removeEmployeeShift(String id, String shiftId) =>
      client.sendJson('DELETE', '/employees/$id/available-shifts/$shiftId');

  // ── Unavailability / leave ──────────────────────────────────────────────

  Future<List<Unavailability>> unavailabilities(String employeeId) async =>
      _decode(
        await client.getJson('/unavailabilities', {'employee_id': employeeId}),
        Unavailability.fromJson,
      );

  Future<Unavailability> createUnavailability(
    String employeeId,
    DateTime date,
  ) async => Unavailability.fromJson(
    await client.sendJson('POST', '/unavailabilities', {
      'employee_id': employeeId,
      'unavailable_date': day(date),
    }),
  );

  Future<void> deleteUnavailability(String id) =>
      client.sendJson('DELETE', '/unavailabilities/$id');

  // ── Confirmed plans (roster editing) ────────────────────────────────────

  Future<List<ConfirmedShiftPlan>> plans(DateTime from, DateTime to) async {
    final out = <ConfirmedShiftPlan>[];
    const pageSize = 1000;
    for (var offset = 0; ; offset += pageSize) {
      final data = await client.getJson('/confirmed-shift-plans', {
        'from_date': day(from),
        'to_date': day(to),
        'limit': '$pageSize',
        'offset': '$offset',
      });
      final page = _decode(data, ConfirmedShiftPlan.fromJson);
      out.addAll(page);
      final total = data is Map<String, dynamic>
          ? (data['total'] as num?)?.toInt()
          : null;
      if (page.length < pageSize || total == null || out.length >= total) {
        return out;
      }
    }
  }

  Future<List<ConfirmedShiftPlan>> employeePlans(
    String employeeId, {
    DateTime? from,
    DateTime? to,
  }) async => _decode(
    await client.getJson('/employees/$employeeId/confirmed-shift-plans', {
      if (from != null) 'from_date': day(from),
      if (to != null) 'to_date': day(to),
    }),
    ConfirmedShiftPlan.fromJson,
  );

  /// A working day ([shiftId] set) or an absence ([absenceType] set).
  Future<ConfirmedShiftPlan> createPlan(
    String employeeId,
    DateTime date, {
    String? shiftId,
    String? workstationId,
    String? absenceType,
  }) async => ConfirmedShiftPlan.fromJson(
    await client.sendJson('POST', '/employees/$employeeId/confirmed-shift-plans', {
      'date': day(date),
      'shift_id': ?shiftId,
      'workstation_id': ?workstationId,
      'is_present': absenceType == null,
      'absence_type': ?absenceType,
      'creation_type': 'manual',
    }),
  );

  Future<ConfirmedShiftPlan> updatePlan(
    String planId,
    Map<String, dynamic> changes,
  ) async => ConfirmedShiftPlan.fromJson(
    await client.sendJson('PUT', '/confirmed-shift-plans/$planId', changes),
  );

  Future<void> deletePlan(String planId) =>
      client.sendJson('DELETE', '/confirmed-shift-plans/$planId');

  // ── Shifts ──────────────────────────────────────────────────────────────

  Future<List<Shift>> shifts() async =>
      _decode(await client.getJson('/shifts'), Shift.fromJson)
        ..sort((a, b) => a.order.compareTo(b.order));

  Future<Shift> saveShift({
    String? id,
    required String name,
    required String shortName,
    required String color,
    required int order,
  }) async {
    final body = {
      'name': name,
      'short_name': shortName,
      'color': color,
      'order': order,
    };
    final data = id == null
        ? await client.sendJson('POST', '/shifts', body)
        : await client.sendJson('PUT', '/shifts/$id', body);
    return Shift.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteShift(String id) => client.sendJson('DELETE', '/shifts/$id');

  Future<void> setWeekdayTime(String shiftId, WeekdayTime t) =>
      client.sendJson('POST', '/shifts/$shiftId/weekday-times', {
        'weekday': t.weekday,
        'start_time': t.startTime,
        'end_time': t.endTime,
        'min_employees': t.minEmployees,
        'max_employees': t.maxEmployees,
        'free_days_after_shift': t.freeDaysAfterShift,
      });

  Future<void> deleteWeekdayTime(String shiftId, int weekday) =>
      client.sendJson('DELETE', '/shifts/$shiftId/weekday-times/$weekday');

  // ── Workstations ────────────────────────────────────────────────────────

  Future<List<Workstation>> workstations() async =>
      _decode(await client.getJson('/workstations'), Workstation.fromJson);

  Future<Workstation> saveWorkstation({
    String? id,
    required String name,
    required bool available,
    required List<String> activeShiftIds,
    required String priority,
    required int minEmployees,
    int? maxEmployees,
  }) async {
    final body = {
      'name': name,
      'available': available,
      'active_shift_ids': activeShiftIds,
      'priority': priority,
      'min_employees': minEmployees,
      'max_employees': maxEmployees,
    };
    final data = id == null
        ? await client.sendJson('POST', '/workstations', body)
        : await client.sendJson('PUT', '/workstations/$id', body);
    return Workstation.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteWorkstation(String id) =>
      client.sendJson('DELETE', '/workstations/$id');

  Future<List<Capability>> requiredCapabilities(String workstationId) async =>
      _decode(
        await client.getJson('/workstations/$workstationId/required-capabilities'),
        Capability.fromJson,
      );

  Future<void> addRequiredCapability(String workstationId, String capId) =>
      client.sendJson(
        'POST',
        '/workstations/$workstationId/required-capabilities',
        {'capability_id': capId},
      );

  Future<void> removeRequiredCapability(String workstationId, String capId) =>
      client.sendJson(
        'DELETE',
        '/workstations/$workstationId/required-capabilities/$capId',
      );

  Future<List<WorkstationClosure>> closures({
    String? workstationId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (workstationId != null) {
      return _decode(
        await client.getJson('/workstations/$workstationId/unavailabilities'),
        WorkstationClosure.fromJson,
      );
    }
    return _decode(
      await client.getJson('/workstation-unavailabilities', {
        if (from != null) 'from_date': day(from),
        if (to != null) 'to_date': day(to),
      }),
      WorkstationClosure.fromJson,
    );
  }

  Future<void> addClosure(String workstationId, DateTime from, DateTime to) =>
      client.sendJson('POST', '/workstations/$workstationId/unavailabilities', {
        'unavailable_from': day(from),
        'unavailable_to': day(to),
      });

  Future<void> deleteClosure(String workstationId, String closureId) =>
      client.sendJson(
        'DELETE',
        '/workstations/$workstationId/unavailabilities/$closureId',
      );

  // ── Capabilities ────────────────────────────────────────────────────────

  Future<List<Capability>> capabilities() async =>
      _decode(await client.getJson('/capabilities'), Capability.fromJson);

  Future<void> saveCapability({
    String? id,
    required String name,
    required int level,
    String? skillGroup,
  }) {
    final body = {'name': name, 'level': level, 'skill_group': skillGroup};
    return id == null
        ? client.sendJson('POST', '/capabilities', body)
        : client.sendJson('PUT', '/capabilities/$id', body);
  }

  Future<void> deleteCapability(String id) =>
      client.sendJson('DELETE', '/capabilities/$id');

  // ── Settings ────────────────────────────────────────────────────────────

  Future<PlannerSettings> plannerSettings() async =>
      PlannerSettings.fromJson(await client.getJson('/planner-settings'));

  Future<PlannerSettings> savePlannerSettings(PlannerSettings s) async =>
      PlannerSettings.fromJson(
        await client.sendJson('PUT', '/planner-settings', s.toRequest()),
      );

  /// Writes the wish window. [schedule] is only sent when given: the server
  /// leaves an existing recurring rule untouched when the key is absent, so
  /// omitting it is how a caller that does not manage schedules saves safely.
  Future<WishSettings> saveWishSettings(
    WishMode mode,
    DateTime? start,
    DateTime? end, {
    WishSchedule? schedule,
  }) async => WishSettings.fromJson(
    await client.sendJson('PUT', '/wish-settings', {
      'mode': mode.wireValue,
      'window_start': start == null ? null : day(start),
      'window_end': end == null ? null : day(end),
      if (schedule != null) 'schedule': schedule.toRequest(),
    }),
  );

  // ── Rotations ───────────────────────────────────────────────────────────

  Future<List<RotationPattern>> patterns() async => _decode(
    await client.getJson('/rotation-patterns'),
    RotationPattern.fromJson,
  );

  Future<void> savePattern({
    String? id,
    required String name,
    required List<String?> slots,
  }) {
    final body = {'name': name, 'slots': slots};
    return id == null
        ? client.sendJson('POST', '/rotation-patterns', body)
        : client.sendJson('PUT', '/rotation-patterns/$id', body);
  }

  Future<void> deletePattern(String id) =>
      client.sendJson('DELETE', '/rotation-patterns/$id');

  Future<ApplyResult> applyPattern(
    String patternId, {
    required List<String> employeeIds,
    required DateTime from,
    required DateTime to,
    required int offsetStep,
    required bool replaceExisting,
    required bool dryRun,
  }) async => ApplyResult.fromJson(
    await client.sendJson('POST', '/rotation-patterns/$patternId/apply', {
      'employee_ids': employeeIds,
      'start_date': day(from),
      'end_date': day(to),
      'offset_step': offsetStep,
      'replace_existing': replaceExisting,
      'dry_run': dryRun,
    }),
  );

  Future<int> clearFixed(List<String> employeeIds, DateTime from, DateTime to) async {
    final data = await client.sendJson('POST', '/shift-assignments/clear', {
      'employee_ids': employeeIds,
      'from_date': day(from),
      'to_date': day(to),
    });
    return (data is Map ? (data['deleted'] as num?)?.toInt() : null) ?? 0;
  }

  // ── Optimizer ───────────────────────────────────────────────────────────

  Future<String> triggerPlan({
    required DateTime from,
    required DateTime to,
    List<String>? employeeIds,
  }) async {
    final data = await client.sendJson('POST', '/planner/plan', {
      'start_date': day(from),
      'end_date': day(to),
      if (employeeIds != null && employeeIds.isNotEmpty)
        'employee_ids': employeeIds,
    });
    return (data as Map<String, dynamic>)['task_id'] as String;
  }

  Future<List<PlanningTask>> planningTasks() async {
    final data = await client.getJson('/planner/tasks');
    final list = data is Map<String, dynamic> ? data['tasks'] : data;
    return _decode(list, PlanningTask.fromJson)
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ));
  }

  Future<void> deletePlanningTask(String id) =>
      client.sendJson('DELETE', '/planner/tasks/$id');

  Future<List<OptimizedResult>> optimizedResults({int limit = 20}) async =>
      _decode(
        await client.getJson('/planner/optimized-shifts', {
          'limit': '$limit',
          'offset': '0',
        }),
        OptimizedResult.fromJson,
      );

  Future<OptimizedResult> optimizedResult(String id) async =>
      OptimizedResult.fromJson(
        await client.getJson('/planner/optimized-shifts/$id'),
      );

  Future<void> deleteOptimizedResult(String id) =>
      client.sendJson('DELETE', '/planner/optimized-shifts/$id');

  /// Overwrites the confirmed plans of the result's period with it. Returns
  /// how many plan rows were written.
  Future<int> takeAsPlan(String resultId, {List<String>? employeeIds}) async {
    final data = await client.sendJson(
      'POST',
      '/planner/optimized-shifts/$resultId/take-as-plan',
      {
        if (employeeIds != null && employeeIds.isNotEmpty)
          'employee_ids': employeeIds,
      },
    );
    return (data is Map ? (data['created'] as num?)?.toInt() : null) ?? 0;
  }

  Future<PlanValidationReport> validatePlan(String resultId) async =>
      PlanValidationReport.fromJson(
        await client.postAgent('/plan/validate', {'result_id': resultId}),
      );

  // ── Analysis ────────────────────────────────────────────────────────────

  Future<List<EmployeeFairness>> fairness(DateTime from, DateTime to) async {
    final data = await client.getJson('/analysis/fairness', {
      'from_date': day(from),
      'to_date': day(to),
    });
    final rows = data is Map<String, dynamic> ? data['employees'] : data;
    return _decode(rows, EmployeeFairness.fromJson);
  }

  // ── Audit log ───────────────────────────────────────────────────────────

  Future<AuditLogPage> auditLogs({
    String? action,
    String? entityType,
    String? entityId,
    String? actor,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await client.getJson('/audit-logs', {
      'action': ?action,
      'entity_type': ?entityType,
      'entity_id': ?entityId,
      'actor': ?actor,
      'limit': '$limit',
      'offset': '$offset',
    });
    final entries = _decode(data, AuditLogEntry.fromJson);
    final total = data is Map<String, dynamic>
        ? (data['total'] as num?)?.toInt() ?? entries.length
        : entries.length;
    return AuditLogPage(entries, total);
  }

  Future<AuditFacets> auditFacets() async =>
      AuditFacets.fromJson(await client.getJson('/audit-logs/facets'));

  // ── Organization users (shift-admin only) ───────────────────────────────

  Future<List<OrganizationUser>> users() async =>
      _decode(await client.getJson('/users'), OrganizationUser.fromJson);

  Future<void> createUser({
    required String username,
    String? email,
    String? firstName,
    String? lastName,
    String? password,
    bool temporaryPassword = true,
    required List<ShiftRole> roles,
  }) => client.sendJson('POST', '/users', {
    'username': username,
    'email': ?email,
    'first_name': ?firstName,
    'last_name': ?lastName,
    'password': ?password,
    'temporary_password': temporaryPassword,
    'roles': roles.map((r) => r.wire).toList(),
  });

  Future<OrganizationUser> updateUserRoles(
    String userId,
    List<ShiftRole> roles,
  ) async => OrganizationUser.fromJson(
    await client.sendJson('PUT', '/users/$userId/roles', {
      'roles': roles.map((r) => r.wire).toList(),
    }),
  );

  Future<void> removeUser(String userId) =>
      client.sendJson('DELETE', '/users/$userId');

  // ── Personal limits ─────────────────────────────────────────────────────

  /// Every employee who has limits saved, keyed by employee id. Employees
  /// without a saved row are simply absent, so a missing key means "none set".
  Future<Map<String, PersonalLimits>> allPersonalLimits() async {
    final list = _decode(
      await client.getJson('/personal-limits'),
      PersonalLimits.fromJson,
    );
    return {for (final l in list) l.employeeId: l};
  }

  Future<PersonalLimits> personalLimits(String employeeId) async =>
      PersonalLimits.fromJson(
        await client.getJson('/employees/$employeeId/personal-limits'),
      );

  /// Replaces the limits as a whole — see [PersonalLimits.toRequest].
  Future<PersonalLimits> savePersonalLimits(PersonalLimits limits) async =>
      PersonalLimits.fromJson(
        await client.sendJson(
          'PUT',
          '/employees/${limits.employeeId}/personal-limits',
          limits.toRequest(),
        ),
      );

  // ── Fixed assignments ───────────────────────────────────────────────────

  /// Fixed assignments in `[from, to]` — what rotation patterns wrote — for
  /// everyone, or only [employeeIds]. The server caps the range at a year.
  Future<List<ShiftAssignment>> shiftAssignments(
    DateTime from,
    DateTime to, {
    List<String>? employeeIds,
  }) async => _decode(
    await client.getJson('/shift-assignments', {
      'from_date': day(from),
      'to_date': day(to),
      if (employeeIds != null && employeeIds.isNotEmpty)
        'employee_ids': employeeIds.join(','),
    }),
    ShiftAssignment.fromJson,
  );

  // ── Holidays ────────────────────────────────────────────────────────────

  Future<HolidayCalendar> holidays(DateTime from, DateTime to) =>
      client.holidays(from, to);

  /// Fetches the holiday API again. [year] defaults to this year and the next.
  /// Answers 503 when holidays are switched off or the source is unreachable.
  Future<HolidayCalendar> syncHolidays({int? year}) async {
    final data = await client.sendJson(
      'POST',
      '/holidays/sync',
      null,
      year == null ? null : {'year': '$year'},
    );
    return data is Map<String, dynamic>
        ? HolidayCalendar.fromJson(data)
        : HolidayCalendar.none;
  }

  /// Which backend this is talking to; see [BackendInfo].
  Future<BackendInfo> info() => client.info();
}
