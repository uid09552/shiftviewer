import 'package:flutter/material.dart';

import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../services/shift_data_controller.dart';
import 'admin_common.dart';

/// Every workstation; tap one to edit its staffing, the shifts it runs in, the
/// capabilities it requires and the periods it is closed.
class WorkstationsScreen extends StatefulWidget {
  const WorkstationsScreen({super.key});

  @override
  State<WorkstationsScreen> createState() => _WorkstationsScreenState();
}

class _WorkstationsScreenState extends State<WorkstationsScreen>
    with AdminApiState<WorkstationsScreen> {
  List<Workstation> _stations = [];
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
      final list = await api.workstations();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) setState(() => _stations = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open([Workstation? w]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkstationEditScreen(workstation: w)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.admWorkstations)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.add),
        label: Text(l10n.admAddWorkstation),
      ),
      body: AdminLoadState(
        loading: _loading,
        error: _error,
        onRetry: _load,
        builder: () => _stations.isEmpty
            ? AdminEmpty(l10n.admNoWorkstations)
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: _stations.length,
                itemBuilder: (_, i) {
                  final w = _stations[i];
                  return ListTile(
                    leading: Icon(
                      w.available ? Icons.place : Icons.location_off_outlined,
                      color: w.available ? null : theme.disabledColor,
                    ),
                    title: Text(w.name),
                    subtitle: Text([
                      priorityLabel(l10n, w.priority),
                      w.maxEmployees == null
                          ? l10n.staffingNeedsMin(w.minEmployees)
                          : l10n.staffingNeedsRange(w.minEmployees, w.maxEmployees!),
                      if (!w.available) l10n.admInactive,
                    ].join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(w),
                  );
                },
              ),
      ),
    );
  }
}

class WorkstationEditScreen extends StatefulWidget {
  final Workstation? workstation;

  const WorkstationEditScreen({super.key, this.workstation});

  @override
  State<WorkstationEditScreen> createState() => _WorkstationEditScreenState();
}

class _WorkstationEditScreenState extends State<WorkstationEditScreen>
    with AdminApiState<WorkstationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late bool _available;
  late String _priority;
  late int _min;
  int? _max;
  late Set<String> _shiftIds;
  Set<String> _capIds = {};
  List<Shift> _shifts = [];
  List<Capability> _caps = [];
  List<WorkstationClosure> _closures = [];
  Workstation? _station;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.workstation;
    _station = w;
    _name = TextEditingController(text: w?.name ?? '');
    _available = w?.available ?? true;
    _priority = w?.priority ?? 'medium';
    _min = w?.minEmployees ?? 1;
    _max = w?.maxEmployees;
    _shiftIds = {...?w?.activeShiftIds};
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final id = _station?.id;
      final r = await Future.wait([
        api.shifts(),
        api.capabilities(),
        if (id != null) api.requiredCapabilities(id),
        if (id != null) api.closures(workstationId: id),
      ]);
      if (!mounted) return;
      setState(() {
        _shifts = r[0] as List<Shift>;
        _caps = (r[1] as List<Capability>)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (id != null) {
          _capIds = {for (final c in r[2] as List<Capability>) c.id};
          _closures = (r[3] as List<WorkstationClosure>)
            ..sort((a, b) => a.from.compareTo(b.from));
        }
      });
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final isNew = _station == null;
      final saved = await api.saveWorkstation(
        id: _station?.id,
        name: _name.text.trim(),
        available: _available,
        activeShiftIds: _shiftIds.toList(),
        priority: _priority,
        minEmployees: _min,
        maxEmployees: _max,
      );
      // A new station gets the capabilities picked before it existed.
      if (isNew) {
        for (final c in _capIds) {
          await api.addRequiredCapability(saved.id, c);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAdminError(context, e);
      }
    }
  }

  Future<void> _toggleCap(String capId, bool on) async {
    setState(() => on ? _capIds.add(capId) : _capIds.remove(capId));
    final id = _station?.id;
    if (id == null) return;
    try {
      on
          ? await api.addRequiredCapability(id, capId)
          : await api.removeRequiredCapability(id, capId);
    } catch (e) {
      if (mounted) {
        setState(() => on ? _capIds.remove(capId) : _capIds.add(capId));
        showAdminError(context, e);
      }
    }
  }

  Future<void> _addClosure() async {
    final range = await pickDateRange(context);
    if (range == null || _station == null) return;
    try {
      await api.addClosure(_station!.id, dateKey(range.start), dateKey(range.end));
      await _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  Future<void> _deleteClosure(WorkstationClosure c) async {
    try {
      await api.deleteClosure(_station!.id, c.id);
      await _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admDeleteWorkstation,
      message: l10n.admDeleteWorkstationMessage(_station!.name),
    );
    if (!ok) return;
    try {
      await api.deleteWorkstation(_station!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = dateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_station?.name ?? l10n.admAddWorkstation),
        actions: [
          if (_station != null)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.save),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextFormField(
                controller: _name,
                // The backend keeps a workstation's name once it exists.
                readOnly: _station != null,
                decoration: InputDecoration(
                  labelText: l10n.admName,
                  helperText: _station != null ? l10n.admNameFixed : null,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
            ),
            SwitchListTile(
              title: Text(l10n.admActive),
              subtitle: Text(l10n.admActiveHint),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.admPriority, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final p in ['high', 'medium', 'low'])
                        ButtonSegment(value: p, label: Text(priorityLabel(l10n, p))),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (s) => setState(() => _priority = s.first),
                  ),
                ],
              ),
            ),
            IntStepper(
              label: l10n.admMinStaff,
              hint: l10n.admPerShift,
              value: _min,
              max: 99,
              onChanged: (v) => setState(() {
                _min = v;
                if (_max != null && _max! < v) _max = v;
              }),
            ),
            IntStepper(
              label: l10n.admMaxStaff,
              hint: l10n.admPerShift,
              value: _max ?? 0,
              max: 99,
              format: (v) => v == 0 ? '∞' : '$v',
              onChanged: (v) =>
                  setState(() => _max = v == 0 ? null : (v < _min ? _min : v)),
            ),
            AdminSectionHeader(l10n.admRunsInShifts, subtitle: l10n.admRunsInShiftsHint),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in _shifts)
                    FilterChip(
                      avatar: ColorDot(s.displayColor),
                      label: Text(s.name),
                      selected: _shiftIds.contains(s.id),
                      onSelected: (on) => setState(
                          () => on ? _shiftIds.add(s.id) : _shiftIds.remove(s.id)),
                    ),
                ],
              ),
            ),
            AdminSectionHeader(l10n.admRequiredCapabilities),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _caps.isEmpty
                  ? Text(l10n.noCapabilities)
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final c in _caps)
                          FilterChip(
                            label: Text(c.name),
                            selected: _capIds.contains(c.id),
                            onSelected: (on) => _toggleCap(c.id, on),
                          ),
                      ],
                    ),
            ),
            if (_station != null) ...[
              AdminSectionHeader(
                l10n.admClosures,
                subtitle: l10n.admClosuresHint,
                trailing: TextButton.icon(
                  onPressed: _addClosure,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.admAdd),
                ),
              ),
              if (_closures.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.admNoClosures,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ),
              for (final c in _closures)
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.event_busy,
                    color: c.to.isBefore(today) ? theme.disabledColor : null,
                  ),
                  title: Text(formatRange(context, c.from, c.to)),
                  trailing: IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteClosure(c),
                  ),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
