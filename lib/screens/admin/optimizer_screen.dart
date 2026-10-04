import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import 'admin_common.dart';
import 'employee_picker.dart';
import 'management_screen.dart' show taskStatusLabel;

/// Starts optimizer runs and lists them; a finished run opens as a proposed
/// plan that can be checked by the assistant and taken over as the roster.
class OptimizerScreen extends StatefulWidget {
  const OptimizerScreen({super.key});

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen>
    with AdminApiState<OptimizerScreen> {
  List<PlanningTask> _tasks = [];
  List<Employee> _employees = [];
  final Set<String> _selected = {};
  late DateTimeRange _range;
  bool _loading = true;
  bool _starting = false;
  Object? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month + 1, 1),
      end: DateTime(now.year, now.month + 2, 0),
    );
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([api.planningTasks(), api.employees()]);
      if (!mounted) return;
      setState(() {
        _tasks = r[0] as List<PlanningTask>;
        _employees = (r[1] as List<Employee>)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
      _schedulePoll();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Keeps the list fresh while a run is in progress, and stops once none is.
  void _schedulePoll() {
    _poll?.cancel();
    if (!_tasks.any((t) => t.isRunning)) return;
    _poll = Timer(const Duration(seconds: 5), () async {
      try {
        final tasks = await api.planningTasks();
        if (!mounted) return;
        final finished = _tasks
            .where((t) => t.isRunning)
            .where((t) => tasks.any((n) => n.id == t.id && !n.isRunning))
            .isNotEmpty;
        setState(() => _tasks = tasks);
        if (finished) showAdminMessage(context, context.l10n.admRunFinished);
      } catch (_) {}
      if (mounted) _schedulePoll();
    });
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await api.triggerPlan(
        from: _range.start,
        to: _range.end,
        employeeIds: _selected.isEmpty ? null : _selected.toList(),
      );
      if (!mounted) return;
      showAdminMessage(context, context.l10n.admRunStarted);
      await _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _delete(PlanningTask t) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admDeleteRun,
      message: l10n.admDeleteRunMessage,
    );
    if (!ok) return;
    try {
      if (t.resultId != null) {
        await api.deleteOptimizedResult(t.resultId!).catchError((_) {});
      }
      await api.deletePlanningTask(t.id);
      _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  Future<void> _openResult(String resultId) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OptimizedResultScreen(resultId: resultId),
    ));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.dateLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admOptimizer),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: AdminLoadState(
        loading: _loading && _tasks.isEmpty,
        error: _error,
        onRetry: _load,
        builder: () => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(l10n.admNewRun, style: theme.textTheme.titleMedium),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text(l10n.admNewRunHint, style: theme.textTheme.bodySmall),
                    ),
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(l10n.admPeriod),
                      subtitle: Text(formatRange(context, _range.start, _range.end)),
                      onTap: () async {
                        final r = await pickDateRange(context, initial: _range);
                        if (r != null) setState(() => _range = r);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(_selected.isEmpty
                          ? l10n.allEmployees
                          : l10n.admPeople(_selected.length)),
                      subtitle: Text(l10n.admRunPeopleHint),
                      onTap: () async {
                        final picked =
                            await pickEmployees(context, _employees, _selected);
                        if (picked != null) {
                          setState(() => _selected
                            ..clear()
                            ..addAll(picked));
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: FilledButton.icon(
                        onPressed: _starting ? null : _start,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.admStartRun),
                      ),
                    ),
                  ],
                ),
              ),
              AdminSectionHeader(l10n.admRuns),
              if (_tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.admNoRuns),
                ),
              for (final t in _tasks)
                ListTile(
                  leading: t.isRunning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          t.status == 'done' ? Icons.check_circle : Icons.error,
                          color: t.status == 'done'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                  title: Text(taskStatusLabel(l10n, t.status)),
                  subtitle: Text([
                    if (t.createdAt != null)
                      DateFormat.yMMMd(locale).add_Hm().format(t.createdAt!.toLocal()),
                    if (t.errorMessage != null && t.errorMessage!.isNotEmpty)
                      t.errorMessage!,
                  ].join('\n')),
                  isThreeLine: t.errorMessage != null && t.errorMessage!.isNotEmpty,
                  onTap: t.resultId == null ? null : () => _openResult(t.resultId!),
                  trailing: t.isRunning
                      ? null
                      : IconButton(
                          tooltip: l10n.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(t),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A proposed plan: who works what on each day of the period. Can be checked
/// by the assistant, taken over as the confirmed roster, or thrown away.
class OptimizedResultScreen extends StatefulWidget {
  final String resultId;

  const OptimizedResultScreen({super.key, required this.resultId});

  @override
  State<OptimizedResultScreen> createState() => _OptimizedResultScreenState();
}

class _OptimizedResultScreenState extends State<OptimizedResultScreen>
    with AdminApiState<OptimizedResultScreen> {
  OptimizedResult? _result;
  Map<String, Shift> _shifts = {};
  PlanValidationReport? _report;
  bool _loading = true;
  bool _busy = false;
  Object? _error;

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
      final r = await Future.wait([
        api.optimizedResult(widget.resultId),
        api.shifts(),
      ]);
      if (!mounted) return;
      setState(() {
        _result = r[0] as OptimizedResult;
        _shifts = {for (final s in r[1] as List<Shift>) s.id: s};
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final report = await api.validatePlan(widget.resultId);
      if (mounted) setState(() => _report = report);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _take() async {
    final l10n = context.l10n;
    final r = _result!;
    final ok = await confirmAction(
      context,
      title: l10n.admTakeAsPlan,
      message: l10n.admTakeAsPlanMessage(
        r.periodStart == null ? '—' : formatRange(context, r.periodStart!, r.periodEnd!),
      ),
      confirmLabel: l10n.admTakeAsPlan,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final n = await api.takeAsPlan(widget.resultId);
      if (mounted) showAdminMessage(context, l10n.admTakenAsPlan(n));
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admDeleteRun,
      message: l10n.admDeleteRunMessage,
    );
    if (!ok) return;
    try {
      await api.deleteOptimizedResult(widget.resultId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admProposedPlan),
        actions: [
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: _result == null ? null : _delete,
          ),
        ],
      ),
      body: AdminLoadState(
        loading: _loading,
        error: _error,
        onRetry: _load,
        builder: () => _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final r = _result!;
    final report = _report;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.periodStart != null && r.periodEnd != null)
                Text(formatRange(context, r.periodStart!, r.periodEnd!),
                    style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.admResultStats(
                r.status,
                r.employeePlans.length,
                r.assignmentCount,
                r.objectiveValue.toStringAsFixed(0),
              )),
              if (r.message != null && r.message!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r.message!, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _verify,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(l10n.admVerify),
                  ),
                  FilledButton.icon(
                    onPressed: _busy || r.employeePlans.isEmpty ? null : _take,
                    icon: const Icon(Icons.done_all),
                    label: Text(l10n.admTakeAsPlan),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (report != null) _reportCard(context, report),
        const SizedBox(height: 12),
        if (r.employeePlans.isEmpty)
          AdminEmpty(l10n.admResultEmpty)
        else
          _grid(context, r),
      ],
    );
  }

  Widget _reportCard(BuildContext context, PlanValidationReport report) {
    final theme = Theme.of(context);
    final (icon, color) = switch (report.verdict) {
      'valid' => (Icons.verified_outlined, theme.colorScheme.primary),
      'invalid' => (Icons.gpp_bad_outlined, theme.colorScheme.error),
      _ => (Icons.report_outlined, Colors.amber.shade800),
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(report.headline,
                      style: theme.textTheme.titleSmall?.copyWith(color: color)),
                ),
              ],
            ),
            for (final f in report.findings) ...[
              const SizedBox(height: 10),
              Text(
                '${f.severity == 'error' ? '⛔' : '⚠️'} ${f.title} (${f.count})',
                style: theme.textTheme.labelLarge,
              ),
              if (f.detail.isNotEmpty) Text(f.detail, style: theme.textTheme.bodySmall),
              for (final ex in f.examples.take(3))
                Text('  • $ex', style: theme.textTheme.bodySmall),
            ],
            if (report.summary.isNotEmpty) ...[
              const Divider(height: 24),
              SelectableText(report.summary, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, OptimizedResult r) {
    final theme = Theme.of(context);
    final locale = context.dateLocale;
    final plans = r.employeePlans.toList()
      ..sort((a, b) => a.employeeName.compareTo(b.employeeName));
    final dates = plans.first.days.map((d) => d.date).toList();

    Widget cell(ProposedDay? d) {
      final s = _shifts[d?.shiftId];
      final assigned = d?.status == 'assigned';
      final bg = assigned
          ? (s?.displayColor ?? theme.colorScheme.secondaryContainer)
          : theme.colorScheme.surfaceContainerHighest;
      return Tooltip(
        message: assigned
            ? [d?.shiftName, d?.workstationName].whereType<String>().join(' · ')
            : '',
        child: Container(
          width: 30,
          height: 26,
          margin: const EdgeInsets.all(1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            assigned ? (s?.shortName ?? d?.shiftName?.characters.first ?? '?') : '',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 120),
              for (final d in dates)
                SizedBox(
                  width: 32,
                  child: Text(
                    '${DateFormat.E(locale).format(d).substring(0, 2)}\n${d.day}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: d.weekday >= 6 ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const SizedBox(width: 40, child: Text('Σ', textAlign: TextAlign.center)),
            ],
          ),
          for (final p in plans)
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(p.employeeName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                for (final date in dates)
                  cell(p.days.where((d) => d.date == date).firstOrNull),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text('${p.assignedDays}', textAlign: TextAlign.center),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
