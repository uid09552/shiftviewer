import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/shift_data_controller.dart';
import 'admin_common.dart';
import 'audit_log_screen.dart';
import 'capabilities_screen.dart';
import 'employees_screen.dart';
import 'fairness_screen.dart';
import 'holidays_screen.dart';
import 'optimizer_screen.dart';
import 'planner_settings_screen.dart';
import 'roster_screen.dart';
import 'rotations_screen.dart';
import 'shifts_screen.dart';
import 'users_screen.dart';
import 'wish_settings_screen.dart';
import 'workstations_screen.dart';

/// The management area for shift-planner and shift-admin: today's overview on
/// top, then every planning and configuration screen. Admin-only entries are
/// left out for planners, as the web UI does.
class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen>
    with AdminApiState<ManagementScreen> {
  _Overview? _overview;
  Object? _error;
  bool _loading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = dateKey(DateTime.now());
      final results = await Future.wait([
        api.employees(),
        api.shifts(),
        api.workstations(),
        api.plans(today, today),
        api.closures(from: today, to: today),
      ]);
      // The activity feed and the latest run are extras: a tenant that hides
      // either still gets its overview.
      final activity = await api
          .auditLogs(limit: 5)
          .then<List<AuditLogEntry>>((p) => p.entries)
          .catchError((_) => <AuditLogEntry>[]);
      final tasks = await api.planningTasks().catchError(
        (_) => <PlanningTask>[],
      );
      if (!mounted) return;
      setState(() {
        _overview = _Overview(
          employees: results[0] as List<Employee>,
          shifts: results[1] as List<Shift>,
          workstations: results[2] as List<Workstation>,
          todayPlans: results[3] as List<ConfirmedShiftPlan>,
          closures: results[4] as List<WorkstationClosure>,
          activity: activity,
          latestTask: tasks.isEmpty ? null : tasks.first,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAdmin = context.watch<AuthController>().isAdmin;

    final sections = [
      _Section(l10n.admSectionPlanning, [
        _Entry(Icons.edit_calendar, l10n.admRoster, l10n.admRosterHint,
            () => const RosterScreen()),
        _Entry(Icons.repeat, l10n.admRotations, l10n.admRotationsHint,
            () => const RotationsScreen()),
        _Entry(Icons.auto_awesome, l10n.admOptimizer, l10n.admOptimizerHint,
            () => const OptimizerScreen()),
        _Entry(Icons.balance, l10n.admFairness, l10n.admFairnessHint,
            () => const FairnessScreen()),
      ]),
      _Section(l10n.admSectionConfiguration, [
        _Entry(Icons.badge_outlined, l10n.admEmployees, l10n.admEmployeesHint,
            () => const EmployeesScreen()),
        _Entry(Icons.schedule, l10n.admShifts, l10n.admShiftsHint,
            () => const ShiftsScreen()),
        _Entry(Icons.place_outlined, l10n.admWorkstations,
            l10n.admWorkstationsHint, () => const WorkstationsScreen()),
        _Entry(Icons.workspace_premium_outlined, l10n.admCapabilities,
            l10n.admCapabilitiesHint, () => const CapabilitiesScreen()),
        _Entry(Icons.celebration_outlined, l10n.admHolidays,
            l10n.admHolidaysHint, () => const HolidaysScreen()),
        _Entry(Icons.tune, l10n.admPlannerSettings,
            l10n.admPlannerSettingsHint, () => const PlannerSettingsScreen()),
        if (isAdmin)
          _Entry(Icons.star_outline, l10n.admWishSettings,
              l10n.admWishSettingsHint, () => const WishSettingsScreen()),
        if (isAdmin)
          _Entry(Icons.manage_accounts_outlined, l10n.admUsers,
              l10n.admUsersHint, () => const UsersScreen()),
        _Entry(Icons.history, l10n.admAuditLog, l10n.admAuditLogHint,
            () => const AuditLogScreen()),
      ]),
    ];

    final q = _filter.trim().toLowerCase();
    final visibleSections = q.isEmpty
        ? sections
        : [
            for (final s in sections)
              _Section(
                s.title,
                s.entries
                    .where((e) =>
                        e.title.toLowerCase().contains(q) ||
                        e.subtitle.toLowerCase().contains(q))
                    .toList(),
              ),
          ].where((s) => s.entries.isNotEmpty).toList();

    Widget entryTile(_Entry e) => ListTile(
          leading: Icon(e.icon),
          title: Text(e.title),
          subtitle: Text(e.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(e.build()),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admManagement),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const Key('managementList'),
          children: [
            _overviewCard(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.admSearchManagement,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            if (visibleSections.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(l10n.admNoMatches)),
              )
            else
              for (final s in visibleSections) ...[
                AdminSectionHeader(s.title),
                for (final e in s.entries) entryTile(e),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _overviewCard(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final o = _overview;

    Widget body;
    if (_error != null) {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Text(adminErrorText(l10n, _error!)),
      );
    } else if (_loading && o == null) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (o == null) {
      body = const SizedBox.shrink();
    } else {
      final understaffed = o.understaffed;
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Stat(l10n.admEmployees, '${o.employees.length}'),
                _Stat(l10n.admShifts, '${o.shifts.length}'),
                _Stat(l10n.admWorkstations, '${o.workstations.length}'),
                _Stat(l10n.statWorking, '${o.workingToday}'),
                _Stat(l10n.statAbsent, '${o.absentToday}'),
              ],
            ),
            const SizedBox(height: 12),
            if (understaffed.isEmpty)
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.admAllStationsCovered)),
                ],
              )
            else ...[
              Text(l10n.admUnderstaffedToday,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final u in understaffed)
                Text('• ${u.$1.name}: ${u.$2} / ${u.$1.minEmployees}',
                    style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (o.latestTask != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.admLatestRun(
                      taskStatusLabel(l10n, o.latestTask!.status),
                      o.latestTask!.createdAt == null
                          ? '—'
                          : DateFormat.yMMMd(context.dateLocale)
                              .add_Hm()
                              .format(o.latestTask!.createdAt!.toLocal()),
                    )),
                  ),
                ],
              ),
            ],
            if (o.activity.isNotEmpty) ...[
              const Divider(height: 24),
              Text(l10n.admRecentActivity, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final a in o.activity)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${humanizeAction(a.action)}'
                    '${a.subjectName == null ? '' : ' · ${a.subjectName}'}'
                    ' — ${a.actor ?? '—'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(l10n.admToday, style: theme.textTheme.titleMedium),
          ),
          body,
        ],
      ),
    );
  }
}

/// One row of the management list. [build] is a factory rather than a built
/// [Widget] so unselected screens are never constructed.
class _Entry {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() build;

  const _Entry(this.icon, this.title, this.subtitle, this.build);
}

class _Section {
  final String title;
  final List<_Entry> entries;

  const _Section(this.title, this.entries);
}

class _Overview {
  final List<Employee> employees;
  final List<Shift> shifts;
  final List<Workstation> workstations;
  final List<ConfirmedShiftPlan> todayPlans;
  final List<WorkstationClosure> closures;
  final List<AuditLogEntry> activity;
  final PlanningTask? latestTask;

  _Overview({
    required this.employees,
    required this.shifts,
    required this.workstations,
    required this.todayPlans,
    required this.closures,
    required this.activity,
    required this.latestTask,
  });

  int get workingToday => todayPlans.where((p) => p.isPresent).length;
  int get absentToday => todayPlans.where((p) => !p.isPresent).length;

  /// Open workstations below their minimum today, with the head count.
  List<(Workstation, int)> get understaffed {
    final today = DateTime.now();
    final out = <(Workstation, int)>[];
    for (final w in workstations) {
      if (!w.available || w.minEmployees <= 0) continue;
      if (closures.any((c) => c.workstationId == w.id && c.covers(today))) {
        continue;
      }
      final count = todayPlans
          .where((p) => p.isPresent && p.workstationId == w.id)
          .length;
      if (count < w.minEmployees) out.add((w, count));
    }
    return out;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// "employee.update" → "Employee update".
String humanizeAction(String action) {
  final text = action.replaceAll(RegExp(r'[._]'), ' ');
  return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// An optimizer task's status in the app's language.
String taskStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'scheduled' || 'running' => l10n.admTaskRunning,
  'done' || 'completed' => l10n.admTaskDone,
  'error' || 'failed' => l10n.admTaskFailed,
  _ => status,
};
