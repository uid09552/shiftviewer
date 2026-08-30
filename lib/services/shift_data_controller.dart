import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'api_client.dart';
import 'app_settings.dart';

/// Normalises a [DateTime] to a date-only key (midnight, no time zone shifts).
DateTime dateKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Why an operation failed. The controller reports the reason rather than a
/// ready-made sentence so the widget layer can translate it.
enum FailureReason {
  /// No API base URL configured yet.
  notConfigured,

  /// A wish was attempted without an employee to attach it to.
  noEmployeeSelected,

  /// The server already holds a wish for that employee and date.
  wishConflict,

  /// The tenant's wish window is shut, so no wish may be placed or withdrawn
  /// on any date.
  wishesClosed,

  /// Anything else — [DataFailure.detail] carries the server's own words.
  request,
}

/// A failed load or write, in a form the UI can turn into a localized message.
@immutable
class DataFailure {
  final FailureReason reason;

  /// Server/exception text for [FailureReason.request]; null otherwise.
  final String? detail;
  final int? statusCode;

  const DataFailure(this.reason, {this.detail, this.statusCode});

  factory DataFailure.from(Object error) {
    if (error is ApiException) {
      return DataFailure(
        FailureReason.request,
        detail: error.message,
        statusCode: error.statusCode,
      );
    }
    return DataFailure(FailureReason.request, detail: error.toString());
  }
}

/// What a bulk wish operation managed to do.
@immutable
class WishBatchResult {
  /// Days that now carry the wish, or had theirs withdrawn.
  final int applied;

  /// Days left alone because the shift does not run on that weekday.
  final int skipped;

  /// Days left alone because they fall outside the tenant's wish window.
  final int blocked;

  /// What stopped the run, when something did. Days handled before it keep
  /// their change — the count says how many.
  final DataFailure? failure;

  const WishBatchResult({
    this.applied = 0,
    this.skipped = 0,
    this.blocked = 0,
    this.failure,
  });
}

/// Loads shifts, employees, workstations and confirmed shift plans for a
/// visible date range and exposes them to the calendar/detail UI.
///
/// The calendar highlights one [selectedEmployeeId]'s shifts, while the day
/// detail shows every employee working that day.
class ShiftDataController extends ChangeNotifier {
  AppSettings _settings;
  String? _accessToken;

  /// Supplies the transport for every request, so tests can stand in for the
  /// network. Null means a real client per call, as in production.
  final http.Client Function()? _httpClientFactory;

  ShiftDataController(
    this._settings, {
    http.Client Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory;

  bool _loading = false;
  DataFailure? _error;
  Map<String, Shift> _shiftsById = {};
  Map<String, Employee> _employeesById = {};
  Map<String, Workstation> _workstationsById = {};
  List<Employee> _employees = [];
  Map<DateTime, List<ConfirmedShiftPlan>> _plansByDate = {};
  Map<DateTime, List<ShiftWish>> _wishesByDate = {};
  WishSettings _wishSettings = WishSettings.open;
  String? _selectedEmployeeId;

  /// The range the loaded plans and wishes cover, so the insight sheets can
  /// say what their per-employee totals are counted over.
  DateTime? _loadedFrom;
  DateTime? _loadedTo;

  /// Per-day analysis, fetched on demand when an insight sheet opens and kept
  /// for the session: the numbers only change when the roster does, and
  /// [refresh] clears them.
  final Map<DateTime, DayAnalysis> _analysisByDay = {};
  final Map<DateTime, Future<DayAnalysis>> _analysisInFlight = {};

  /// Employees re-read one by one, which is the only way to get their
  /// capabilities and available shifts — the list endpoint omits both.
  final Map<String, Employee> _employeeDetails = {};
  final Map<String, Future<Employee?>> _employeeDetailsInFlight = {};

  bool get loading => _loading;
  DataFailure? get error => _error;
  bool get isConfigured => _settings.isConfigured;

  List<Employee> get employees => List.unmodifiable(_employees);

  /// Every known shift, in roster order.
  List<Shift> get shifts =>
      _shiftsById.values.toList()..sort((a, b) => a.order.compareTo(b.order));

  /// The tenant's wish window as last read from `/wish-settings`. Until the
  /// first successful read this is [WishSettings.open] — the server is the
  /// authority, so an unreachable setting must not hide the feature.
  WishSettings get wishSettings => _wishSettings;

  /// Whether any wish may be placed at all right now.
  bool get wishesOpen => _wishSettings.isOpen;

  /// Whether a wish may be placed or withdrawn for [day].
  bool canWishOn(DateTime day) => _wishSettings.allows(day);

  String? get selectedEmployeeId => _selectedEmployeeId;
  Employee? get selectedEmployee => _employeesById[_selectedEmployeeId];

  /// First/last day the loaded roster covers, or null before the first load.
  DateTime? get loadedFrom => _loadedFrom;
  DateTime? get loadedTo => _loadedTo;

  Shift? shiftById(String? id) => id == null ? null : _shiftsById[id];
  Employee? employeeById(String? id) => id == null ? null : _employeesById[id];
  Workstation? workstationById(String? id) =>
      id == null ? null : _workstationsById[id];

  void updateSettings(AppSettings settings) => _settings = settings;
  void updateAccessToken(String? token) => _accessToken = token;

  /// Selects the employee whose shifts the calendar highlights (null = all).
  void selectEmployee(String? employeeId) {
    if (_selectedEmployeeId == employeeId) return;
    _selectedEmployeeId = employeeId;
    notifyListeners();
  }

  /// All confirmed plans on [day], across every employee.
  List<ConfirmedShiftPlan> allPlansForDay(DateTime day) =>
      _plansByDate[dateKey(day)] ?? const [];

  /// Plans on [day] limited to the selected employee (or all when none set).
  /// Used by the calendar markers.
  List<ConfirmedShiftPlan> plansForDay(DateTime day) {
    final all = allPlansForDay(day);
    if (_selectedEmployeeId == null) return all;
    return all.where((p) => p.employeeId == _selectedEmployeeId).toList();
  }

  bool hasPlans(DateTime day) => plansForDay(day).isNotEmpty;

  /// All wishes placed for [day], across every employee.
  List<ShiftWish> wishesForDay(DateTime day) =>
      _wishesByDate[dateKey(day)] ?? const [];

  /// The selected employee's wish for [day] — at most one per API contract.
  ShiftWish? wishForDay(DateTime day) {
    final employeeId = _selectedEmployeeId;
    if (employeeId == null) return null;
    for (final w in wishesForDay(day)) {
      if (w.employeeId == employeeId) return w;
    }
    return null;
  }

  /// The selected employee's wishes falling in `[from, to]`, oldest first.
  /// Empty while no employee is selected — wishes always belong to one.
  List<ShiftWish> wishesInRange(DateTime from, DateTime to) {
    final employeeId = _selectedEmployeeId;
    if (employeeId == null) return const [];
    final start = dateKey(from);
    final end = dateKey(to);
    final found = <ShiftWish>[];
    for (final entry in _wishesByDate.entries) {
      if (entry.key.isBefore(start) || entry.key.isAfter(end)) continue;
      found.addAll(entry.value.where((w) => w.employeeId == employeeId));
    }
    return found..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Shifts the selected employee may wish for: the ones they are available
  /// for, or every shift when the roster does not restrict them.
  List<Shift> get wishableShifts {
    final available = selectedEmployee?.availableShifts ?? const [];
    if (available.isEmpty) return shifts;
    // Prefer the full shift records (colors, times) over the nested copies.
    final resolved = [for (final s in available) _shiftsById[s.id] ?? s]
      ..sort((a, b) => a.order.compareTo(b.order));
    return resolved;
  }

  /// Places the selected employee's wish for [shiftId] on every day in [days],
  /// replacing whatever they wished for on those days.
  ///
  /// Days the shift does not run on are skipped rather than refused, and days
  /// outside the tenant's wish window are left alone as blocked, so a whole
  /// week or month can be filled in one pass; days that already carry the wish
  /// are left untouched instead of being rewritten. The run stops at the first
  /// failure and reports how far it got.
  Future<WishBatchResult> placeWishes(
    Iterable<DateTime> days,
    String shiftId,
  ) async {
    final employeeId = _selectedEmployeeId;
    if (employeeId == null) {
      return const WishBatchResult(
        failure: DataFailure(FailureReason.noEmployeeSelected),
      );
    }
    if (!_wishSettings.isOpen) {
      return const WishBatchResult(
        failure: DataFailure(FailureReason.wishesClosed),
      );
    }
    final shift = shiftById(shiftId);
    final client = _client();
    var applied = 0;
    var skipped = 0;
    var blocked = 0;
    DataFailure? failure;
    try {
      for (final raw in days) {
        final day = dateKey(raw);
        // The window binds every role, so a date outside it would only earn a
        // rejection — don't spend the request.
        if (!_wishSettings.allows(day)) {
          blocked++;
          continue;
        }
        if (shift != null && shift.timesFor(day) == null) {
          skipped++;
          continue;
        }
        final existing = wishForDay(day);
        if (existing != null && existing.shiftId == shiftId) {
          applied++;
          continue;
        }
        // Only one wish per employee and date is allowed, so drop the old one
        // before asking for the new shift.
        if (existing != null) {
          await client.deleteShiftWish(existing.id);
          _forgetWish(existing);
        }
        final created = await client.createShiftWish(
          employeeId: employeeId,
          shiftId: shiftId,
          date: day,
        );
        _wishesByDate.putIfAbsent(dateKey(created.date), () => []).add(created);
        applied++;
      }
    } on ApiException catch (e) {
      failure = e.statusCode == 409
          ? const DataFailure(FailureReason.wishConflict)
          : DataFailure.from(e);
    } catch (e) {
      failure = DataFailure.from(e);
    } finally {
      client.close();
      notifyListeners();
    }
    return WishBatchResult(
      applied: applied,
      skipped: skipped,
      blocked: blocked,
      failure: failure,
    );
  }

  /// Withdraws the selected employee's wishes on every day in [days]. Days
  /// carrying no wish are not counted and cost no request.
  ///
  /// The wish window covers withdrawals too — a wish placed while it was open
  /// cannot be taken back once it closed — so days outside it are reported as
  /// blocked rather than attempted.
  Future<WishBatchResult> removeWishes(Iterable<DateTime> days) async {
    if (_selectedEmployeeId == null) {
      return const WishBatchResult(
        failure: DataFailure(FailureReason.noEmployeeSelected),
      );
    }
    if (!_wishSettings.isOpen) {
      return const WishBatchResult(
        failure: DataFailure(FailureReason.wishesClosed),
      );
    }
    final client = _client();
    var applied = 0;
    var blocked = 0;
    DataFailure? failure;
    try {
      for (final raw in days) {
        final wish = wishForDay(raw);
        if (wish == null) continue;
        if (!_wishSettings.allows(raw)) {
          blocked++;
          continue;
        }
        try {
          await client.deleteShiftWish(wish.id);
        } on ApiException catch (e) {
          // Already gone server-side: treat as done rather than nagging.
          if (e.statusCode != 404) rethrow;
        }
        _forgetWish(wish);
        applied++;
      }
    } catch (e) {
      failure = DataFailure.from(e);
    } finally {
      client.close();
      notifyListeners();
    }
    return WishBatchResult(
      applied: applied,
      blocked: blocked,
      failure: failure,
    );
  }

  void _forgetWish(ShiftWish wish) {
    _wishesByDate[dateKey(wish.date)]?.removeWhere((w) => w.id == wish.id);
  }

  /// Fetches shifts, employees, workstations and all confirmed plans covering
  /// [from]..[to].
  Future<void> refresh(DateTime from, DateTime to) async {
    if (!_settings.isConfigured) {
      _error = const DataFailure(FailureReason.notConfigured);
      _plansByDate = {};
      _wishesByDate = {};
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    _analysisByDay.clear();
    _analysisInFlight.clear();
    notifyListeners();

    final client = _client();
    try {
      final results = await Future.wait([
        client.listShifts(),
        client.listEmployees(),
        client.listWorkstations(),
        client.confirmedShiftPlans(from, to),
        client.listShiftWishes(from, to),
        _loadWishSettings(client),
      ]);
      final shifts = results[0] as List<Shift>;
      final employees = results[1] as List<Employee>;
      final workstations = results[2] as List<Workstation>;
      final plans = results[3] as List<ConfirmedShiftPlan>;
      final wishes = results[4] as List<ShiftWish>;
      _wishSettings = results[5] as WishSettings;

      _shiftsById = {for (final s in shifts) s.id: s};
      _employees = employees..sort((a, b) => a.name.compareTo(b.name));
      _employeesById = {for (final e in employees) e.id: e};
      _workstationsById = {for (final w in workstations) w.id: w};

      final grouped = <DateTime, List<ConfirmedShiftPlan>>{};
      for (final p in plans) {
        grouped.putIfAbsent(dateKey(p.date), () => []).add(p);
      }
      _plansByDate = grouped;

      final groupedWishes = <DateTime, List<ShiftWish>>{};
      for (final w in wishes) {
        groupedWishes.putIfAbsent(dateKey(w.date), () => []).add(w);
      }
      _wishesByDate = groupedWishes;

      _loadedFrom = dateKey(from);
      _loadedTo = dateKey(to);

      // Drop a selection that no longer exists.
      if (_selectedEmployeeId != null &&
          !_employeesById.containsKey(_selectedEmployeeId)) {
        _selectedEmployeeId = null;
      }
    } catch (e) {
      _error = DataFailure.from(e);
    } finally {
      client.close();
      _loading = false;
      notifyListeners();
    }
  }

  /// Reads the wish window, falling back to the last known one when the
  /// endpoint is unavailable: the calendar must still load, and the server
  /// refuses out-of-window writes regardless of what the app believes.
  Future<WishSettings> _loadWishSettings(ShiftApiClient client) async {
    try {
      return await client.getWishSettings();
    } catch (e) {
      debugPrint('[data] wish settings unavailable: $e');
      return _wishSettings;
    }
  }

  /// The analysis endpoints' view of [day], fetched once and then cached.
  ///
  /// The three calls are independent and any of them may be refused on a
  /// tenant where analysis is restricted, so each failure is absorbed into a
  /// missing field rather than an error: the sheet then shows what the roster
  /// alone can tell, which is most of it.
  Future<DayAnalysis> analysisForDay(DateTime raw) {
    final day = dateKey(raw);
    final cached = _analysisByDay[day];
    if (cached != null) return Future.value(cached);
    final running = _analysisInFlight[day];
    if (running != null) return running;

    final future = _loadAnalysis(day).whenComplete(() {
      _analysisInFlight.remove(day);
    });
    _analysisInFlight[day] = future;
    return future;
  }

  Future<DayAnalysis> _loadAnalysis(DateTime day) async {
    if (!_settings.isConfigured) return DayAnalysis.empty(day);
    final client = _client();
    try {
      final results = await Future.wait([
        _attempt(() => client.staffingPerDay(day, day)),
        _attempt(() => client.plannedHoursPerWorkstation(day, day)),
        _attempt(() => client.plannedEmployeesPerWorkstation(day, day)),
      ]);
      final staffing = (results[0] as List<DailyStaffing>?) ?? const [];
      final analysis = DayAnalysis(
        date: day,
        staffing: staffing.isEmpty ? null : staffing.first,
        hours: (results[1] as List<WorkstationDailyHours>?) ?? const [],
        headcount: (results[2] as List<WorkstationDailyEmployees>?) ?? const [],
        reachable: results.any((r) => r != null),
      );
      _analysisByDay[day] = analysis;
      return analysis;
    } finally {
      client.close();
    }
  }

  /// Runs one analysis call, turning any refusal into null. Analysis is extra
  /// detail on top of the roster — it must never take a sheet down with it.
  Future<T?> _attempt<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('[data] analysis call unavailable: $e');
      return null;
    }
  }

  /// The full record for [employeeId], including capabilities and available
  /// shifts. Falls back to the list entry when the read is refused.
  Future<Employee?> employeeDetail(String employeeId) {
    final cached = _employeeDetails[employeeId];
    if (cached != null) return Future.value(cached);
    final running = _employeeDetailsInFlight[employeeId];
    if (running != null) return running;

    final future = _loadEmployeeDetail(employeeId).whenComplete(() {
      _employeeDetailsInFlight.remove(employeeId);
    });
    _employeeDetailsInFlight[employeeId] = future;
    return future;
  }

  Future<Employee?> _loadEmployeeDetail(String employeeId) async {
    if (!_settings.isConfigured) return _employeesById[employeeId];
    final client = _client();
    try {
      final employee = await client.getEmployee(employeeId);
      _employeeDetails[employeeId] = employee;
      return employee;
    } catch (e) {
      debugPrint('[data] employee detail unavailable: $e');
      return _employeesById[employeeId];
    } finally {
      client.close();
    }
  }

  ShiftApiClient _client() => ShiftApiClient(
    _settings,
    accessToken: _accessToken,
    client: _httpClientFactory?.call(),
  );
}
