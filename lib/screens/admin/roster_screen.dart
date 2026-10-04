import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../services/admin_api.dart';
import '../../services/shift_data_controller.dart';
import 'admin_common.dart';

/// Absence types a planner can put on a day, in the web UI's order.
const rosterAbsenceTypes = ['sick', 'day_off', 'holiday', 'free'];

/// The confirmed roster for one week, one row per employee, every cell
/// editable: tap a day to give it a shift and workstation, mark an absence, or
/// clear it. The web UI's Schedule page, sized for a phone.
class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen>
    with AdminApiState<RosterScreen> {

  DateTime _weekStart = _monday(DateTime.now());
  List<Employee> _employees = [];
  List<Shift> _shifts = [];
  List<Workstation> _workstations = [];
  List<WorkstationClosure> _closures = [];
  final Map<String, ConfirmedShiftPlan> _plans = {};
  final Map<String, ShiftWish> _wishes = {};
  String _filter = '';
  bool _loading = true;
  Object? _error;

  static DateTime _monday(DateTime d) =>
      dateKey(d.subtract(Duration(days: d.weekday - 1)));

  static String _key(String employeeId, DateTime day) =>
      '$employeeId|${AdminApi.day(day)}';

  List<DateTime> get _days =>
      [for (var i = 0; i < 7; i++) _weekStart.add(Duration(days: i))];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        api.employees(),
        api.shifts(),
        api.workstations(),
      ]);
      _employees = (r[0] as List<Employee>)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _shifts = r[1] as List<Shift>;
      _workstations = r[2] as List<Workstation>;
      await _loadWeek();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWeek() async {
    final from = _weekStart;
    final to = _weekStart.add(const Duration(days: 6));
    final r = await Future.wait([
      api.plans(from, to),
      api.client.listShiftWishes(from, to).catchError((_) => <ShiftWish>[]),
      api.closures(from: from, to: to).catchError(
        (_) => <WorkstationClosure>[],
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _plans
        ..clear()
        ..addEntries((r[0] as List<ConfirmedShiftPlan>)
            .map((p) => MapEntry(_key(p.employeeId, p.date), p)));
      _wishes
        ..clear()
        ..addEntries((r[1] as List<ShiftWish>)
            .map((w) => MapEntry(_key(w.employeeId, w.date), w)));
      _closures = r[2] as List<WorkstationClosure>;
    });
  }

  Future<void> _step(int weeks) async {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * weeks));
      _loading = true;
    });
    try {
      await _loadWeek();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Shift? _shift(String? id) {
    for (final s in _shifts) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _edit(Employee employee, DateTime day) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CellEditor(
        api: api,
        employee: employee,
        day: day,
        plan: _plans[_key(employee.id, day)],
        wish: _wishes[_key(employee.id, day)],
        shifts: _shifts,
        workstations: _workstations,
        closures: _closures,
      ),
    );
    if (changed == true && mounted) {
      try {
        await _loadWeek();
      } catch (e) {
        if (mounted) showAdminError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.dateLocale;
    final end = _weekStart.add(const Duration(days: 6));
    final visible = _filter.isEmpty
        ? _employees
        : _employees
            .where((e) => e.name.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admRoster),
        actions: [
          IconButton(
            tooltip: l10n.today,
            icon: const Icon(Icons.today),
            onPressed: () {
              final target = _monday(DateTime.now());
              _step(target.difference(_weekStart).inDays ~/ 7);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.previous,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _step(-1),
              ),
              Expanded(
                child: Text(
                  formatRange(context, _weekStart, end),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.next,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _step(1),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.admSearchEmployees,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filter = v.trim()),
            ),
          ),
          if (_loading && _employees.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: AdminLoadState(
              loading: _loading && _employees.isEmpty,
              error: _error,
              onRetry: _loadAll,
              builder: () => Column(
                children: [
                  _headerRow(context, locale),
                  const Divider(height: 1),
                  Expanded(
                    child: visible.isEmpty
                        ? AdminEmpty(l10n.admNoEmployees)
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) => _row(context, visible[i]),
                          ),
                  ),
                  _legend(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _nameWidth = 104;

  Widget _headerRow(BuildContext context, String locale) {
    final theme = Theme.of(context);
    final today = dateKey(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: _nameWidth),
          for (final d in _days)
            Expanded(
              child: Column(
                children: [
                  Text(DateFormat.E(locale).format(d),
                      style: theme.textTheme.labelSmall),
                  Text(
                    '${d.day}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: d == today ? FontWeight.bold : null,
                      color: d == today ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Employee e) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _nameWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
          for (final d in _days) Expanded(child: _cell(context, e, d)),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, Employee e, DateTime day) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = _plans[_key(e.id, day)];
    final wish = _wishes[_key(e.id, day)];
    Color? bg;
    Color? fg;
    String text = '';
    if (plan != null && plan.isPresent) {
      final shift = _shift(plan.shiftId);
      bg = shift?.displayColor ?? theme.colorScheme.secondaryContainer;
      fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? Colors.white
          : Colors.black;
      text = shift?.shortName ?? '?';
    } else if (plan != null) {
      bg = plan.absenceType == 'sick'
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHighest;
      fg = plan.absenceType == 'sick'
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.onSurfaceVariant;
      text = absenceShort(l10n, plan.absenceType);
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: bg ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: bg == null
              ? BorderSide(color: theme.colorScheme.outlineVariant)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _edit(e, day),
          child: SizedBox(
            height: 36,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (wish != null)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: wish.shiftId == plan?.shiftId
                          ? Colors.amber
                          : theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        l10n.admRosterLegend,
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

/// A one-to-three letter tag for an absence in a roster cell.
String absenceShort(AppLocalizations l10n, String? type) => switch (type) {
  'sick' => l10n.admAbsenceShortSick,
  'day_off' => l10n.admAbsenceShortDayOff,
  'holiday' => l10n.admAbsenceShortHoliday,
  _ => l10n.admAbsenceShortFree,
};

/// Edits one employee's day: a shift and workstation, an absence, or nothing.
/// Pops true when something was written.
class _CellEditor extends StatefulWidget {
  final AdminApi api;
  final Employee employee;
  final DateTime day;
  final ConfirmedShiftPlan? plan;
  final ShiftWish? wish;
  final List<Shift> shifts;
  final List<Workstation> workstations;
  final List<WorkstationClosure> closures;

  const _CellEditor({
    required this.api,
    required this.employee,
    required this.day,
    required this.plan,
    required this.wish,
    required this.shifts,
    required this.workstations,
    required this.closures,
  });

  @override
  State<_CellEditor> createState() => _CellEditorState();
}

class _CellEditorState extends State<_CellEditor> {
  String? _shiftId;
  String? _workstationId;
  String? _absence;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null) {
      if (p.isPresent) {
        _shiftId = p.shiftId;
        _workstationId = p.workstationId;
      } else {
        _absence = p.absenceType ?? 'free';
      }
    }
  }

  bool _closed(Workstation w) =>
      !w.available ||
      widget.closures.any((c) => c.workstationId == w.id && c.covers(widget.day));

  bool get _dirty {
    final p = widget.plan;
    if (p == null) return _shiftId != null || _absence != null;
    if (p.isPresent) {
      return _absence != null ||
          _shiftId != p.shiftId ||
          _workstationId != p.workstationId;
    }
    return _shiftId != null || _absence != (p.absenceType ?? 'free');
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showAdminError(context, e);
      }
    }
  }

  Future<void> _save() => _run(() async {
    final api = widget.api;
    final p = widget.plan;
    final working = _absence == null;
    // Switching between a working day and an absence changes what the row
    // is, so it is replaced rather than patched.
    if (p != null && p.isPresent == working) {
      await api.updatePlan(p.id, working
          ? {'shift_id': _shiftId, 'workstation_id': _workstationId}
          : {'is_present': false, 'absence_type': _absence});
      return;
    }
    if (p != null) await api.deletePlan(p.id);
    await api.createPlan(
      widget.employee.id,
      widget.day,
      shiftId: working ? _shiftId : null,
      workstationId: working ? _workstationId : null,
      absenceType: working ? null : _absence,
    );
  });

  Future<void> _clear() => _run(() => widget.api.deletePlan(widget.plan!.id));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.dateLocale;
    final wish = widget.wish;
    Shift? wished;
    for (final s in widget.shifts) {
      if (s.id == wish?.shiftId) wished = s;
    }
    final stations = widget.workstations
        .where((w) => _shiftId == null || w.servesShift(_shiftId))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.employee.name, style: theme.textTheme.titleLarge),
              Text(DateFormat.yMMMMEEEEd(locale).format(widget.day)),
              if (wished != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(l10n.admWishedFor(wished.name)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(l10n.admShift, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in widget.shifts)
                    ChoiceChip(
                      avatar: ColorDot(s.displayColor),
                      label: Text(s.timesFor(widget.day) == null
                          ? '${s.name} (${l10n.admNotOnThisDay})'
                          : s.name),
                      selected: _shiftId == s.id && _absence == null,
                      onSelected: (_) => setState(() {
                        _shiftId = s.id;
                        _absence = null;
                        final ws = _workstationId;
                        if (ws != null &&
                            !widget.workstations.any(
                                (w) => w.id == ws && w.servesShift(s.id))) {
                          _workstationId = null;
                        }
                      }),
                    ),
                ],
              ),
              if (_absence == null && _shiftId != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: stations.any((w) => w.id == _workstationId)
                      ? _workstationId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.admWorkstation,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.noWorkstation)),
                    for (final w in stations)
                      DropdownMenuItem(
                        value: w.id,
                        enabled: !_closed(w),
                        child: Text(
                          _closed(w) ? '${w.name} (${l10n.admClosed})' : w.name,
                          style: _closed(w)
                              ? TextStyle(color: theme.disabledColor)
                              : null,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _workstationId = v),
                ),
              ],
              const SizedBox(height: 16),
              Text(l10n.admAbsence, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final t in rosterAbsenceTypes)
                    ChoiceChip(
                      label: Text(absenceLabel(l10n, t)),
                      selected: _absence == t,
                      onSelected: (_) => setState(() {
                        _absence = t;
                        _shiftId = null;
                        _workstationId = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                children: [
                  if (widget.plan != null)
                    TextButton.icon(
                      onPressed: _busy ? null : _clear,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.admClearDay),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed: _busy || !_dirty ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
