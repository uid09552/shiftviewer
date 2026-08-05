import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'app_settings.dart';

/// Normalises a [DateTime] to a date-only key (midnight, no time zone shifts).
DateTime dateKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Loads shifts, employees, workstations and confirmed shift plans for a
/// visible date range and exposes them to the calendar/detail UI.
///
/// The calendar highlights one [selectedEmployeeId]'s shifts, while the day
/// detail shows every employee working that day.
class ShiftDataController extends ChangeNotifier {
  AppSettings _settings;
  String? _accessToken;
  ShiftDataController(this._settings);

  bool _loading = false;
  String? _error;
  Map<String, Shift> _shiftsById = {};
  Map<String, Employee> _employeesById = {};
  Map<String, Workstation> _workstationsById = {};
  List<Employee> _employees = [];
  Map<DateTime, List<ConfirmedShiftPlan>> _plansByDate = {};
  String? _selectedEmployeeId;

  bool get loading => _loading;
  String? get error => _error;
  bool get isConfigured => _settings.isConfigured;

  List<Employee> get employees => List.unmodifiable(_employees);
  String? get selectedEmployeeId => _selectedEmployeeId;
  Employee? get selectedEmployee => _employeesById[_selectedEmployeeId];

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

  /// Fetches shifts, employees, workstations and all confirmed plans covering
  /// [from]..[to].
  Future<void> refresh(DateTime from, DateTime to) async {
    if (!_settings.isConfigured) {
      _error = 'Not configured. Open settings to set the API URL.';
      _plansByDate = {};
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    final client = ShiftApiClient(_settings, accessToken: _accessToken);
    try {
      final results = await Future.wait([
        client.listShifts(),
        client.listEmployees(),
        client.listWorkstations(),
        client.confirmedShiftPlans(from, to),
      ]);
      final shifts = results[0] as List<Shift>;
      final employees = results[1] as List<Employee>;
      final workstations = results[2] as List<Workstation>;
      final plans = results[3] as List<ConfirmedShiftPlan>;

      _shiftsById = {for (final s in shifts) s.id: s};
      _employees = employees..sort((a, b) => a.name.compareTo(b.name));
      _employeesById = {for (final e in employees) e.id: e};
      _workstationsById = {for (final w in workstations) w.id: w};

      final grouped = <DateTime, List<ConfirmedShiftPlan>>{};
      for (final p in plans) {
        grouped.putIfAbsent(dateKey(p.date), () => []).add(p);
      }
      _plansByDate = grouped;

      // Drop a selection that no longer exists.
      if (_selectedEmployeeId != null &&
          !_employeesById.containsKey(_selectedEmployeeId)) {
        _selectedEmployeeId = null;
      }
    } on ApiException catch (e) {
      _error = e.statusCode != null ? '${e.message} (${e.statusCode})' : e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      client.close();
      _loading = false;
      notifyListeners();
    }
  }
}
