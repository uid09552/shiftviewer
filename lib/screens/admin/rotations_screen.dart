import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../services/admin_api.dart';
import '../../services/rotation_rules.dart';
import 'admin_common.dart';
import 'employee_picker.dart';

/// Rotation patterns: rhythms written once ("F F S S N N - -") and applied to
/// people as fixed shifts and days off, which the optimizer plans first.
class RotationsScreen extends StatefulWidget {
  const RotationsScreen({super.key});

  @override
  State<RotationsScreen> createState() => _RotationsScreenState();
}

class _RotationsScreenState extends State<RotationsScreen>
    with AdminApiState<RotationsScreen> {
  List<RotationPattern> _patterns = [];
  List<Shift> _shifts = [];
  PatternRules _rules = const PatternRules();
  bool _loading = true;
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
      final r = await Future.wait([api.patterns(), api.shifts()]);
      final settings = await api.plannerSettings().catchError(
        (_) => const PlannerSettings({}),
      );
      if (!mounted) return;
      setState(() {
        _patterns = (r[0] as List<RotationPattern>)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _shifts = r[1] as List<Shift>;
        _rules = PatternRules(
          maxConsecutiveDays: settings.integer('max_consecutive_days'),
          maxWorkingDaysPerWeek: settings.integer('max_working_days_per_week'),
          minRestHours: settings.integer('min_rest_hours'),
          nightShiftRecoveryDays: settings.integer('night_shift_recovery_days'),
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([RotationPattern? p]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PatternDialog(
        api: api,
        pattern: p,
        shifts: _shifts,
        rules: _rules,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(RotationPattern p) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admDeletePattern,
      message: l10n.admDeletePatternMessage(p.name),
    );
    if (!ok) return;
    try {
      await api.deletePattern(p.id);
      _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.admRotations)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(l10n.admNewPattern),
      ),
      body: AdminLoadState(
        loading: _loading,
        error: _error,
        onRetry: _load,
        builder: () => _patterns.isEmpty
            ? AdminEmpty(l10n.admNoPatterns, icon: Icons.repeat)
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: _patterns.length,
                itemBuilder: (_, i) {
                  final p = _patterns[i];
                  final working = p.slots.where((s) => s != null).length;
                  return Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                          Text(l10n.admCycle(p.slots.length, working),
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 8),
                          PatternStrip(slots: p.slots, shifts: _shifts),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: l10n.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(p),
                              ),
                              IconButton(
                                tooltip: l10n.admEdit,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(p),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ApplyRotationScreen(
                                        pattern: p, shifts: _shifts),
                                  ),
                                ),
                                icon: const Icon(Icons.playlist_add_check),
                                label: Text(l10n.admApply),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// A pattern's days as coloured tiles.
class PatternStrip extends StatelessWidget {
  final List<String?> slots;
  final List<Shift> shifts;

  const PatternStrip({super.key, required this.slots, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byId = {for (final s in shifts) s.id: s};
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final id in slots)
          Builder(builder: (_) {
            final s = byId[id];
            final bg = s?.displayColor ?? theme.colorScheme.surfaceContainerHighest;
            return Container(
              width: 28,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                s?.shortName ?? (id == null ? '–' : '?'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: s == null
                      ? theme.colorScheme.onSurfaceVariant
                      : ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                ),
              ),
            );
          }),
      ],
    );
  }
}

String patternIssueText(AppLocalizations l10n, PatternIssue issue) =>
    switch (issue) {
      ConsecutiveIssue(run: null, :final max) => l10n.admIssueNoDayOff(max),
      ConsecutiveIssue(:final run, :final max) => l10n.admIssueConsecutive(run!, max),
      WeeklyIssue(:final days, :final max) => l10n.admIssueWeekly(days, max),
      RestIssue(:final day, :final from, :final to, :final hours, :final min) =>
        l10n.admIssueRest(day, from, to, hours.toString(), min),
      RecoveryIssue(:final day, :final shift, :final days) =>
        l10n.admIssueRecovery(day, shift, days),
    };

class _PatternDialog extends StatefulWidget {
  final AdminApi api;
  final RotationPattern? pattern;
  final List<Shift> shifts;
  final PatternRules rules;

  const _PatternDialog({
    required this.api,
    required this.pattern,
    required this.shifts,
    required this.rules,
  });

  @override
  State<_PatternDialog> createState() => _PatternDialogState();
}

class _PatternDialogState extends State<_PatternDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.pattern?.name ?? '');
  late final TextEditingController _sequence = TextEditingController(
    text: widget.pattern == null
        ? ''
        : formatSequence(widget.pattern!.slots, widget.shifts),
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _sequence.dispose();
    super.dispose();
  }

  Future<void> _save(List<String?> slots) async {
    setState(() => _saving = true);
    try {
      await widget.api.savePattern(
        id: widget.pattern?.id,
        name: _name.text.trim(),
        slots: slots,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAdminError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final parsed = parseSequence(_sequence.text, widget.shifts);
    final issues = parsed.unknown.isEmpty
        ? checkPattern(parsed.slots, widget.shifts, widget.rules)
        : const <PatternIssue>[];
    final valid = _name.text.trim().isNotEmpty &&
        parsed.slots.isNotEmpty &&
        parsed.unknown.isEmpty;
    final shortNames = widget.shifts.map((s) => s.shortName).join(', ');

    return AlertDialog(
      title: Text(widget.pattern == null ? l10n.admNewPattern : l10n.admEditPattern),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.pattern == null,
              decoration: InputDecoration(
                labelText: l10n.admName,
                hintText: l10n.admPatternNameHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sequence,
              decoration: InputDecoration(
                labelText: l10n.admPatternSequence,
                hintText: 'F F S S N N - -',
                helperText: l10n.admPatternSequenceHint(shortNames),
                helperMaxLines: 4,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (parsed.slots.isNotEmpty) ...[
              PatternStrip(slots: parsed.slots, shifts: widget.shifts),
              const SizedBox(height: 6),
              Text(
                l10n.admCycle(parsed.slots.length,
                    parsed.slots.where((s) => s != null).length),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (parsed.unknown.isNotEmpty)
              Text(l10n.admUnknownTokens(parsed.unknown.join(', ')),
                  style: TextStyle(color: theme.colorScheme.error)),
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.admPatternIssues,
                  style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600)),
              for (final i in issues)
                Text('• ${patternIssueText(l10n, i)}',
                    style: TextStyle(color: theme.colorScheme.error)),
            ] else if (valid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.admPatternFits,
                    style: TextStyle(color: theme.colorScheme.primary)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving || !valid ? null : () => _save(parsed.slots),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Applies a pattern to picked people over a period: preview first (nothing
/// written), then write. Can also clear the fixed assignments in the period.
class ApplyRotationScreen extends StatefulWidget {
  final RotationPattern pattern;
  final List<Shift> shifts;

  const ApplyRotationScreen({
    super.key,
    required this.pattern,
    required this.shifts,
  });

  @override
  State<ApplyRotationScreen> createState() => _ApplyRotationScreenState();
}

class _ApplyRotationScreenState extends State<ApplyRotationScreen>
    with AdminApiState<ApplyRotationScreen> {
  List<Employee> _employees = [];
  final Set<String> _selected = {};
  late DateTimeRange _range;
  int _stagger = 0;
  bool _replace = false;
  ApplyResult? _preview;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month + 1, 1),
      end: DateTime(now.year, now.month + 2, 0),
    );
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await api.employees();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) setState(() => _employees = list);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  /// People in the order they were listed, which sets the stagger order.
  List<String> get _ids =>
      [for (final e in _employees) if (_selected.contains(e.id)) e.id];

  void _changed(VoidCallback f) => setState(() {
    f();
    _preview = null;
  });

  Future<void> _run({required bool dryRun}) async {
    setState(() => _busy = true);
    try {
      final r = await api.applyPattern(
        widget.pattern.id,
        employeeIds: _ids,
        from: _range.start,
        to: _range.end,
        offsetStep: _stagger,
        replaceExisting: _replace,
        dryRun: dryRun,
      );
      if (!mounted) return;
      if (dryRun) {
        setState(() => _preview = r);
      } else {
        setState(() => _preview = null);
        showAdminMessage(context, context.l10n.admWritten(r.written));
      }
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admClearFixed,
      message: l10n.admClearFixedMessage(_ids.length),
      confirmLabel: l10n.admRemove,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final n = await api.clearFixed(_ids, _range.start, _range.end);
      if (!mounted) return;
      setState(() => _preview = null);
      showAdminMessage(context, l10n.admCleared(n));
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = _preview;
    final none = _selected.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.admApplyTitle(widget.pattern.name))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l10n.admApplyIntro, style: theme.textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PatternStrip(slots: widget.pattern.slots, shifts: widget.shifts),
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(l10n.admPeriod),
            subtitle: Text(formatRange(context, _range.start, _range.end)),
            onTap: () async {
              final r = await pickDateRange(context, initial: _range);
              if (r != null) _changed(() => _range = r);
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text(l10n.admPeople(_selected.length)),
            subtitle: Text(none
                ? l10n.admPickPeople
                : _employees
                    .where((e) => _selected.contains(e.id))
                    .map((e) => e.name)
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            onTap: () async {
              final picked = await pickEmployees(context, _employees, _selected);
              if (picked != null) {
                _changed(() => _selected
                  ..clear()
                  ..addAll(picked));
              }
            },
          ),
          IntStepper(
            label: l10n.admStagger,
            hint: l10n.admStaggerHint,
            value: _stagger,
            max: widget.pattern.slots.length,
            onChanged: (v) => _changed(() => _stagger = v),
          ),
          SwitchListTile(
            title: Text(l10n.admReplaceFixed),
            subtitle: Text(l10n.admReplaceFixedHint),
            value: _replace,
            onChanged: (v) => _changed(() => _replace = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: none || _busy ? null : _clear,
                  icon: const Icon(Icons.layers_clear_outlined),
                  label: Text(l10n.admClearFixed),
                ),
                OutlinedButton.icon(
                  onPressed: none || _busy ? null : () => _run(dryRun: true),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.admPreview),
                ),
                FilledButton.icon(
                  onPressed: p == null || _busy || p.written == 0
                      ? null
                      : () => _run(dryRun: false),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.admWrite(p?.written ?? 0)),
                ),
              ],
            ),
          ),
          if (p != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.admApplySummary(p.written, p.replaced, p.unchanged,
                    p.conflicts, p.onAbsence),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(l10n.admApplyLegend, style: theme.textTheme.bodySmall),
            ),
            _previewGrid(context, p),
          ],
        ],
      ),
    );
  }

  Widget _previewGrid(BuildContext context, ApplyResult p) {
    final theme = Theme.of(context);
    final locale = context.dateLocale;
    final byId = {for (final s in widget.shifts) s.id: s};
    if (p.rows.isEmpty) return const SizedBox.shrink();
    final dates = p.rows.first.cells.map((c) => c.date).toList();

    Widget cell(ApplyCell c) {
      final s = byId[c.shiftId];
      final bg = s?.displayColor ?? theme.colorScheme.surfaceContainerHighest;
      final faded = c.status == ApplyCellStatus.same;
      final conflict = c.status == ApplyCellStatus.conflict;
      return Container(
        width: 30,
        height: 26,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: conflict
              ? Colors.amber.withValues(alpha: 0.5)
              : bg.withValues(alpha: faded ? 0.35 : 1),
          borderRadius: BorderRadius.circular(4),
          border: c.status == ApplyCellStatus.replace
              ? Border.all(color: theme.colorScheme.onSurface, width: 2)
              : null,
        ),
        child: Text(
          s?.shortName ?? '–',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            decoration: c.status == ApplyCellStatus.absent
                ? TextDecoration.lineThrough
                : null,
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
              const SizedBox(width: 110),
              for (final d in dates)
                SizedBox(
                  width: 32,
                  child: Text(
                    '${DateFormat.E(locale).format(d).substring(0, 2)}\n${d.day}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          for (final row in p.rows)
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(row.employeeName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                for (final c in row.cells) cell(c),
              ],
            ),
        ],
      ),
    );
  }
}
