import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../services/shift_data_controller.dart';
import 'admin_common.dart';

/// Every employee, searchable; tap one to edit their profile, the shifts they
/// can work, their capabilities and their leave.
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen>
    with AdminApiState<EmployeesScreen> {
  List<Employee> _employees = [];
  String _filter = '';
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
      final list = await api.employees();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) setState(() => _employees = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open([Employee? employee]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EmployeeEditScreen(employee: employee)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _filter.toLowerCase();
    final visible = _employees
        .where((e) =>
            q.isEmpty ||
            e.name.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.admEmployees)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.admAddEmployee),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
          Expanded(
            child: AdminLoadState(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () => visible.isEmpty
                  ? AdminEmpty(l10n.admNoEmployees)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: visible.length,
                        itemBuilder: (_, i) {
                          final e = visible[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(e.name.isEmpty
                                  ? '?'
                                  : e.name.characters.first.toUpperCase()),
                            ),
                            title: Text(e.name),
                            subtitle: Text(
                              [
                                if (e.email.isNotEmpty) e.email,
                                l10n.admHoursPerMonth(
                                    e.monthlyWorkingHours.toStringAsFixed(0)),
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(e),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The kinds of leave a planner can enter from an employee's page.
enum LeaveKind { unavailable, vacation, sick }

/// One day of leave and where it is stored: an unavailability, or an absence
/// on the confirmed roster.
class _LeaveDay {
  final String id;
  final DateTime date;
  final LeaveKind kind;

  _LeaveDay(this.id, this.date, this.kind);
}

/// Consecutive leave days of one kind, shown and deleted as one range.
class _LeaveGroup {
  final LeaveKind kind;
  final List<_LeaveDay> days;

  _LeaveGroup(this.kind, this.days);

  DateTime get start => days.first.date;
  DateTime get end => days.last.date;
}

String leaveKindLabel(AppLocalizations l10n, LeaveKind k) => switch (k) {
  LeaveKind.unavailable => l10n.absenceUnavailable,
  LeaveKind.vacation => l10n.absenceDayOff,
  LeaveKind.sick => l10n.absenceSick,
};

/// Create or edit one employee. Shifts, capabilities and leave need the
/// employee to exist, so they appear once it has been saved.
class EmployeeEditScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeEditScreen({super.key, this.employee});

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen>
    with AdminApiState<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _hours;

  Employee? _employee;
  List<Shift> _allShifts = [];
  List<Capability> _allCaps = [];
  Set<String> _shiftIds = {};
  Set<String> _capIds = {};
  List<_LeaveDay> _leave = [];
  PersonalLimits? _limits;
  bool _limitsSaving = false;
  bool _loading = false;
  bool _saving = false;
  final Set<String> _pending = {};

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _name = TextEditingController(text: _employee?.name ?? '');
    _email = TextEditingController(text: _employee?.email ?? '');
    _hours = TextEditingController(
      text: _employee == null
          ? '160'
          : _employee!.monthlyWorkingHours.toStringAsFixed(
              _employee!.monthlyWorkingHours % 1 == 0 ? 0 : 1),
    );
    if (_employee != null) _loadDetails();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final id = _employee!.id;
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        api.shifts(),
        api.capabilities(),
        api.employeeShifts(id),
        api.employeeCapabilities(id),
        api.unavailabilities(id),
        api.employeePlans(id),
      ]);
      // A tenant that has never saved limits for this employee, or has the
      // endpoint restricted, still gets the rest of the page.
      final limits = await api
          .personalLimits(id)
          .catchError((_) => PersonalLimits.emptyFor(id));
      final leave = <_LeaveDay>[
        for (final Unavailability u in r[4] as List)
          _LeaveDay(u.id, dateKey(u.date), LeaveKind.unavailable),
        for (final ConfirmedShiftPlan p in r[5] as List)
          if (!p.isPresent && (p.absenceType == 'day_off' || p.absenceType == 'sick'))
            _LeaveDay(
              p.id,
              dateKey(p.date),
              p.absenceType == 'sick' ? LeaveKind.sick : LeaveKind.vacation,
            ),
      ]..sort((a, b) => a.date.compareTo(b.date));
      if (!mounted) return;
      setState(() {
        _allShifts = r[0] as List<Shift>;
        _allCaps = (r[1] as List<Capability>)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _shiftIds = {for (final s in r[2] as List<Shift>) s.id};
        _capIds = {for (final c in r[3] as List<Capability>) c.id};
        _leave = leave;
        _limits = limits;
      });
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final hours = double.parse(_hours.text.replaceAll(',', '.'));
    setState(() => _saving = true);
    try {
      if (_employee == null) {
        final created = await api.createEmployee(
          name: _name.text.trim(),
          email: _email.text.trim(),
          monthlyHours: hours,
        );
        _employee = created;
        await _loadDetails();
      } else {
        await api.updateEmployee(
          _employee!.id,
          name: _name.text.trim(),
          email: _email.text.trim(),
          monthlyHours: hours,
        );
      }
      if (mounted) showAdminMessage(context, context.l10n.admSaved);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admDeleteEmployee,
      message: l10n.admDeleteEmployeeMessage(_employee!.name),
    );
    if (!ok) return;
    try {
      await api.deleteEmployee(_employee!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  Future<void> _toggle(String key, bool on, Future<void> Function() add,
      Future<void> Function() remove, Set<String> target, String id) async {
    setState(() {
      _pending.add(key);
      on ? target.add(id) : target.remove(id);
    });
    try {
      await (on ? add() : remove());
    } catch (e) {
      if (mounted) {
        setState(() => on ? target.remove(id) : target.add(id));
        showAdminError(context, e);
      }
    } finally {
      if (mounted) setState(() => _pending.remove(key));
    }
  }

  /// Applies [change] to the personal limits and saves the whole object right
  /// away — the endpoint replaces it as a whole, so every field has to be
  /// resent on every change. Rolls back on failure, like the shift/capability
  /// toggles above.
  Future<void> _updateLimits(
    PersonalLimits Function(PersonalLimits) change,
  ) async {
    final before = _limits;
    if (before == null) return;
    final after = change(before);
    setState(() {
      _limits = after;
      _limitsSaving = true;
    });
    try {
      final saved = await api.savePersonalLimits(after);
      if (mounted) setState(() => _limits = saved);
    } catch (e) {
      if (mounted) {
        setState(() => _limits = before);
        showAdminError(context, e);
      }
    } finally {
      if (mounted) setState(() => _limitsSaving = false);
    }
  }

  /// Nights/weekends/preferred-days-off beyond the ward's own rules. Each
  /// control saves on its own, like the shift and capability chips above.
  Widget _personalLimitsSection(BuildContext context) {
    final l10n = context.l10n;
    final limits = _limits;
    if (limits == null) return const SizedBox.shrink();
    // Jan 1 2024 was a Monday, so adding the index names Mon..Sun in order.
    final monday = DateTime(2024, 1, 1);
    String weekdayLabel(int i) =>
        DateFormat.E(context.dateLocale).format(monday.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntStepper(
            label: l10n.admMaxNightsPerMonth,
            value: limits.maxNightsPerMonth ?? 0,
            min: 0,
            max: 31,
            format: (x) => x == 0 ? l10n.admNoLimit : '$x',
            onChanged: (x) => _updateLimits((l) => l.copyWith(
              maxNightsPerMonth: x == 0 ? null : x,
              clearMaxNights: x == 0,
            )),
          ),
          IntStepper(
            label: l10n.admMaxWeekendsPerMonth,
            value: limits.maxWeekendsPerMonth ?? 0,
            min: 0,
            max: 5,
            format: (x) => x == 0 ? l10n.admNoLimit : '$x',
            onChanged: (x) => _updateLimits((l) => l.copyWith(
              maxWeekendsPerMonth: x == 0 ? null : x,
              clearMaxWeekends: x == 0,
            )),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.admNoNightShifts),
            subtitle: Text(l10n.admNoNightShiftsHint),
            value: limits.noNightShifts,
            onChanged: (v) =>
                _updateLimits((l) => l.copyWith(noNightShifts: v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.admPreferredDaysOff,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (int i = 0; i < 7; i++)
                FilterChip(
                  label: Text(weekdayLabel(i)),
                  selected: limits.preferredDaysOff.contains(i),
                  onSelected: (on) => _updateLimits((l) => l.copyWith(
                    preferredDaysOff: on
                        ? [...l.preferredDaysOff, i]
                        : l.preferredDaysOff.where((d) => d != i).toList(),
                  )),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<_LeaveGroup> get _groups {
    final groups = <_LeaveGroup>[];
    for (final d in _leave) {
      final open = groups.isEmpty ? null : groups.last;
      if (open != null &&
          open.kind == d.kind &&
          d.date.difference(open.end).inDays == 1) {
        open.days.add(d);
      } else {
        groups.add(_LeaveGroup(d.kind, [d]));
      }
    }
    return groups;
  }

  Future<void> _addLeave() async {
    final result = await showDialog<(LeaveKind, DateTimeRange)>(
      context: context,
      builder: (_) => const _LeaveDialog(),
    );
    if (result == null) return;
    final (kind, range) = result;
    final id = _employee!.id;
    setState(() => _loading = true);
    try {
      for (final day in daysBetween(range.start, range.end)) {
        if (kind == LeaveKind.unavailable) {
          await api.createUnavailability(id, day);
        } else {
          await api.createPlan(id, day,
              absenceType: kind == LeaveKind.sick ? 'sick' : 'day_off');
        }
      }
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
    await _loadDetails();
  }

  Future<void> _deleteLeave(_LeaveGroup g) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admRemoveLeave,
      message: l10n.admRemoveLeaveMessage(
        leaveKindLabel(l10n, g.kind),
        formatRange(context, g.start, g.end),
      ),
    );
    if (!ok) return;
    setState(() => _loading = true);
    try {
      for (final d in g.days) {
        if (d.kind == LeaveKind.unavailable) {
          await api.deleteUnavailability(d.id);
        } else {
          await api.deletePlan(d.id);
        }
      }
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
    await _loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final e = _employee;
    final today = dateKey(DateTime.now());
    final groups = _groups;
    final upcoming = groups.where((g) => !g.end.isBefore(today)).toList();
    final past = groups.where((g) => g.end.isBefore(today)).toList().reversed;

    Widget leaveTile(_LeaveGroup g) => ListTile(
      dense: true,
      leading: Icon(switch (g.kind) {
        LeaveKind.sick => Icons.sick_outlined,
        LeaveKind.vacation => Icons.beach_access_outlined,
        LeaveKind.unavailable => Icons.block,
      }),
      title: Text(formatRange(context, g.start, g.end)),
      subtitle: Text(
          '${leaveKindLabel(l10n, g.kind)} · ${l10n.admDayCount(g.days.length)}'),
      trailing: IconButton(
        tooltip: l10n.delete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _deleteLeave(g),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(e?.name ?? l10n.admAddEmployee),
        actions: [
          if (e != null)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        key: const Key('employeeEditorList'),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: l10n.admName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.admEmail,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hours,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.admMonthlyHours,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        double.tryParse((v ?? '').replaceAll(',', '.')) == null
                            ? l10n.admEnterNumber
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (e == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.admSaveFirstHint,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            )
          else ...[
            AdminSectionHeader(l10n.sectionAvailableShifts),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in _allShifts)
                    FilterChip(
                      avatar: ColorDot(s.displayColor),
                      label: Text(s.name),
                      selected: _shiftIds.contains(s.id),
                      onSelected: _pending.contains('s${s.id}')
                          ? null
                          : (on) => _toggle(
                                's${s.id}',
                                on,
                                () => api.addEmployeeShift(e.id, s.id),
                                () => api.removeEmployeeShift(e.id, s.id),
                                _shiftIds,
                                s.id,
                              ),
                    ),
                ],
              ),
            ),
            AdminSectionHeader(l10n.sectionCapabilities),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _allCaps.isEmpty
                  ? Text(l10n.noCapabilities)
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final c in _allCaps)
                          FilterChip(
                            label: Text(c.skillGroup == null
                                ? c.name
                                : '${c.name} · ${c.level}'),
                            selected: _capIds.contains(c.id),
                            onSelected: _pending.contains('c${c.id}')
                                ? null
                                : (on) => _toggle(
                                      'c${c.id}',
                                      on,
                                      () => api.addEmployeeCapability(e.id, c.id),
                                      () => api.removeEmployeeCapability(
                                          e.id, c.id),
                                      _capIds,
                                      c.id,
                                    ),
                          ),
                      ],
                    ),
            ),
            AdminSectionHeader(l10n.admPersonalLimits,
                subtitle: l10n.admPersonalLimitsHint,
                trailing: _limitsSaving
                    ? const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null),
            _personalLimitsSection(context),
            AdminSectionHeader(
              l10n.admLeave,
              subtitle: l10n.admLeaveHint,
              trailing: TextButton.icon(
                onPressed: _loading ? null : _addLeave,
                icon: const Icon(Icons.add),
                label: Text(l10n.admAdd),
              ),
            ),
            if (upcoming.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.admNoUpcomingLeave,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ),
            for (final g in upcoming) leaveTile(g),
            if (past.isNotEmpty)
              ExpansionTile(
                title: Text(l10n.admPastLeave(past.length)),
                children: [for (final g in past) leaveTile(g)],
              ),
          ],
        ],
      ),
    );
  }
}

class _LeaveDialog extends StatefulWidget {
  const _LeaveDialog();

  @override
  State<_LeaveDialog> createState() => _LeaveDialogState();
}

class _LeaveDialogState extends State<_LeaveDialog> {
  LeaveKind _kind = LeaveKind.vacation;
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.admAddLeave),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<LeaveKind>(
            showSelectedIcon: false,
            segments: [
              for (final k in LeaveKind.values)
                ButtonSegment(value: k, label: Text(leaveKindLabel(l10n, k))),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(_range == null
                ? l10n.admPickDates
                : formatRange(context, _range!.start, _range!.end)),
            onPressed: () async {
              final r = await pickDateRange(context, initial: _range);
              if (r != null) setState(() => _range = r);
            },
          ),
          if (_kind == LeaveKind.unavailable) ...[
            const SizedBox(height: 12),
            Text(l10n.admUnavailableHint,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _range == null
              ? null
              : () => Navigator.pop(context, (_kind, _range!)),
          child: Text(l10n.admAdd),
        ),
      ],
    );
  }
}
