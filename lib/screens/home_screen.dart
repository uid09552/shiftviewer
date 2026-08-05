import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/shift_data_controller.dart';
import '../widgets/day_detail.dart';
import '../widgets/month_view.dart';
import '../widgets/week_view.dart';
import 'settings_screen.dart';

enum CalendarMode { month, week }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarMode _mode = CalendarMode.month;
  DateTime _anchor = DateTime.now(); // day used to derive visible month/week
  DateTime? _selectedDay = dateKey(DateTime.now());
  String _lastSettingsKey = '';
  bool _preselectDone = false;

  @override
  void initState() {
    super.initState();
    // Load once settings are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefresh());
  }

  /// Keeps the data controller aligned with the latest settings, then reloads
  /// the currently visible range.
  Future<void> _maybeRefresh() async {
    final settings = context.read<SettingsController>().settings;
    final data = context.read<ShiftDataController>();
    data.updateSettings(settings);
    // Refresh the token (may trigger a silent refresh) before loading data.
    final token = await context.read<AuthController>().validAccessToken();
    data.updateAccessToken(token);
    final range = _visibleRange();
    await data.refresh(range.$1, range.$2);
    if (mounted) _maybePreselectEmployee();
  }

  /// Once employees are loaded, preselect the one whose email matches the
  /// signed-in user's token email. Runs at most once; the user can change it.
  void _maybePreselectEmployee() {
    if (_preselectDone) return;
    final data = context.read<ShiftDataController>();
    if (data.employees.isEmpty) return;
    _preselectDone = true;
    if (data.selectedEmployeeId != null) return;
    final email = context.read<AuthController>().userEmail?.trim().toLowerCase();
    if (email == null || email.isEmpty) return;
    Employee? match;
    for (final e in data.employees) {
      if (e.email.trim().toLowerCase() == email) {
        match = e;
        break;
      }
    }
    if (match != null) data.selectEmployee(match.id);
  }

  /// The inclusive [from, to] range currently on screen, padded to whole weeks
  /// for the month grid so leading/trailing days are covered.
  (DateTime, DateTime) _visibleRange() {
    if (_mode == CalendarMode.week) {
      final start = _anchor.subtract(Duration(days: _anchor.weekday - 1));
      return (dateKey(start), dateKey(start.add(const Duration(days: 6))));
    }
    final first = DateTime(_anchor.year, _anchor.month, 1);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    return (dateKey(gridStart), dateKey(gridStart.add(const Duration(days: 41))));
  }

  void _step(int direction) {
    setState(() {
      _anchor = _mode == CalendarMode.month
          ? DateTime(_anchor.year, _anchor.month + direction, 1)
          : _anchor.add(Duration(days: 7 * direction));
    });
    _maybeRefresh();
  }

  void _goToday() {
    setState(() {
      _anchor = DateTime.now();
      _selectedDay = dateKey(DateTime.now());
    });
    _maybeRefresh();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) _maybeRefresh();
  }

  String get _title {
    if (_mode == CalendarMode.week) {
      final start = _anchor.subtract(Duration(days: _anchor.weekday - 1));
      final end = start.add(const Duration(days: 6));
      final sameMonth = start.month == end.month;
      return sameMonth
          ? '${DateFormat.MMMM().format(start)} ${start.year} · W${_weekOfYear(start)}'
          : '${DateFormat.MMM().format(start)} – ${DateFormat.MMM().format(end)} ${end.year}';
    }
    return DateFormat.yMMMM().format(_anchor);
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final days = date.difference(firstDay).inDays;
    return ((days + firstDay.weekday - 1) / 7).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    // Re-sync data if credentials changed while listening.
    final key = settings.settings.toJson().toString();
    if (key != _lastSettingsKey) {
      _lastSettingsKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeRefresh();
      });
    }

    final data = context.watch<ShiftDataController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Viewer'),
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: _goToday,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _maybeRefresh,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _employeeSelector(context, data),
          _toolbar(context),
          if (data.loading) const LinearProgressIndicator(minHeight: 2),
          if (data.error != null) _errorBanner(context, data.error!),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _mode == CalendarMode.month
                  ? MonthView(
                      visibleMonth: _anchor,
                      selectedDay: _selectedDay,
                      data: data,
                      onDaySelected: (d) => setState(() => _selectedDay = d),
                    )
                  : WeekView(
                      visibleWeek: _anchor,
                      selectedDay: _selectedDay,
                      data: data,
                      onDaySelected: (d) => setState(() => _selectedDay = d),
                    ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: DayDetail(day: _selectedDay, data: data),
          ),
        ],
      ),
    );
  }

  Widget _employeeSelector(BuildContext context, ShiftDataController data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Employee',
          prefixIcon: Icon(Icons.person_outline),
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: data.selectedEmployeeId,
            isExpanded: true,
            isDense: true,
            hint: const Text('All employees'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All employees'),
              ),
              for (final e in data.employees)
                DropdownMenuItem<String?>(
                  value: e.id,
                  child: Text(e.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged:
                data.employees.isEmpty ? null : (v) => data.selectEmployee(v),
          ),
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _step(-1),
          ),
          Expanded(
            child: Text(
              _title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _step(1),
          ),
          const SizedBox(width: 8),
          SegmentedButton<CalendarMode>(
            segments: const [
              ButtonSegment(
                  value: CalendarMode.month,
                  icon: Icon(Icons.calendar_month),
                  label: Text('Month')),
              ButtonSegment(
                  value: CalendarMode.week,
                  icon: Icon(Icons.calendar_view_week),
                  label: Text('Week')),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              setState(() => _mode = s.first);
              _maybeRefresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: scheme.onErrorContainer)),
          ),
          TextButton(onPressed: _openSettings, child: const Text('Settings')),
        ],
      ),
    );
  }
}
