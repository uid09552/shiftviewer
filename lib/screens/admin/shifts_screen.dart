import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_helpers.dart';
import '../../models/models.dart';
import 'admin_common.dart';

/// Colours offered for a shift, the web UI's palette.
const shiftPalette = [
  '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899',
  '#14B8A6', '#F97316', '#6366F1', '#84CC16', '#06B6D4', '#64748B',
];

/// The shifts, in roster order; tap one to edit its name, colour and the
/// times and staffing it runs with on each weekday.
class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen>
    with AdminApiState<ShiftsScreen> {
  List<Shift> _shifts = [];
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
      final list = await api.shifts();
      if (mounted) setState(() => _shifts = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open([Shift? shift]) async {
    final nextOrder = _shifts.isEmpty
        ? 1
        : _shifts.map((s) => s.order).reduce((a, b) => a > b ? a : b) + 1;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShiftEditScreen(shift: shift, nextOrder: nextOrder),
    ));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.dateLocale;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.admShifts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.add),
        label: Text(l10n.admAddShift),
      ),
      body: AdminLoadState(
        loading: _loading,
        error: _error,
        onRetry: _load,
        builder: () => _shifts.isEmpty
            ? AdminEmpty(l10n.admNoShifts)
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: _shifts.length,
                itemBuilder: (_, i) {
                  final s = _shifts[i];
                  final days = s.weekdayTimes.toList()
                    ..sort((a, b) => a.weekday.compareTo(b.weekday));
                  final names = days
                      .map((t) => weekdayShort(locale, t.weekday))
                      .join(' ');
                  final first = days.isEmpty ? null : days.first;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: s.displayColor,
                      foregroundColor: ThemeData.estimateBrightnessForColor(
                                  s.displayColor) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      child: Text(s.shortName, style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(s.name),
                    subtitle: Text(first == null
                        ? l10n.admNoWeekdays
                        : '${_hm(first.startTime)}–${_hm(first.endTime)} · $names'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(s),
                  );
                },
              ),
      ),
    );
  }
}

/// "07:00:00" → "07:00".
String _hm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

/// Short weekday name for the API's 0 = Monday … 6 = Sunday.
String weekdayShort(String locale, int weekday) =>
    DateFormat.E(locale).format(DateTime(2024, 1, 1 + weekday));

/// One weekday's row in the editor; [enabled] false means the shift does not
/// run that day.
class _DayDraft {
  bool enabled;
  TimeOfDay start;
  TimeOfDay end;
  int min;
  int? max;
  int freeDays;

  _DayDraft({
    required this.enabled,
    required this.start,
    required this.end,
    required this.min,
    required this.max,
    required this.freeDays,
  });

  static TimeOfDay _parse(String t, TimeOfDay fallback) {
    final p = t.split(':');
    if (p.length < 2) return fallback;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    return h == null || m == null ? fallback : TimeOfDay(hour: h, minute: m);
  }

  factory _DayDraft.from(WeekdayTime? t) => _DayDraft(
    enabled: t != null,
    start: _parse(t?.startTime ?? '', const TimeOfDay(hour: 7, minute: 0)),
    end: _parse(t?.endTime ?? '', const TimeOfDay(hour: 15, minute: 0)),
    min: t?.minEmployees ?? 1,
    max: t?.maxEmployees,
    freeDays: t?.freeDaysAfterShift ?? 0,
  );

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  WeekdayTime toWeekdayTime(int weekday) => WeekdayTime(
    weekday: weekday,
    startTime: _fmt(start),
    endTime: _fmt(end),
    minEmployees: min,
    maxEmployees: max,
    freeDaysAfterShift: freeDays,
  );

  /// Whether this row differs from what the server has.
  bool differsFrom(WeekdayTime? t) {
    if (!enabled) return t != null;
    if (t == null) return true;
    final w = toWeekdayTime(t.weekday);
    return _hm(t.startTime) != w.startTime ||
        _hm(t.endTime) != w.endTime ||
        t.minEmployees != min ||
        t.maxEmployees != max ||
        t.freeDaysAfterShift != freeDays;
  }
}

class ShiftEditScreen extends StatefulWidget {
  final Shift? shift;
  final int nextOrder;

  const ShiftEditScreen({super.key, this.shift, this.nextOrder = 1});

  @override
  State<ShiftEditScreen> createState() => _ShiftEditScreenState();
}

class _ShiftEditScreenState extends State<ShiftEditScreen>
    with AdminApiState<ShiftEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _short;
  late final TextEditingController _order;
  late String _color;
  late final List<_DayDraft> _days;
  bool _saving = false;

  WeekdayTime? _existing(int weekday) {
    for (final t in widget.shift?.weekdayTimes ?? const <WeekdayTime>[]) {
      if (t.weekday == weekday) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    _name = TextEditingController(text: s?.name ?? '');
    _short = TextEditingController(text: s?.shortName ?? '');
    _order = TextEditingController(text: '${s?.order ?? widget.nextOrder}');
    _color = s?.color.toUpperCase() ?? shiftPalette.first;
    _days = [for (var d = 0; d < 7; d++) _DayDraft.from(_existing(d))];
    if (s == null) {
      for (var d = 0; d < 5; d++) {
        _days[d].enabled = true;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _short.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await api.saveShift(
        id: widget.shift?.id,
        name: _name.text.trim(),
        shortName: _short.text.trim(),
        color: _color,
        order: int.tryParse(_order.text.trim()) ?? widget.nextOrder,
      );
      for (var d = 0; d < 7; d++) {
        final before = _existing(d);
        final draft = _days[d];
        if (!draft.differsFrom(before)) continue;
        if (draft.enabled) {
          await api.setWeekdayTime(saved.id, draft.toWeekdayTime(d));
        } else {
          await api.deleteWeekdayTime(saved.id, d);
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

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admDeleteShift,
      message: l10n.admDeleteShiftMessage(widget.shift!.name),
    );
    if (!ok) return;
    try {
      await api.deleteShift(widget.shift!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) => showTimePicker(
    context: context,
    initialTime: initial,
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.dateLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shift?.name ?? l10n.admAddShift),
        actions: [
          if (widget.shift != null)
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
          padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _short,
                    decoration: InputDecoration(
                      labelText: l10n.admShortName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    controller: _order,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.admOrder,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.admColor, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in {...shiftPalette, _color})
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: parseHexColor(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: _color == c
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.sectionWeekPattern, style: theme.textTheme.titleSmall),
            Text(l10n.admWeekdayTimesHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            for (var d = 0; d < 7; d++) _dayCard(context, locale, d),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(BuildContext context, String locale, int d) {
    final l10n = context.l10n;
    final draft = _days[d];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat.EEEE(locale).format(DateTime(2024, 1, 1 + d))),
              value: draft.enabled,
              onChanged: (v) => setState(() => draft.enabled = v),
            ),
            if (draft.enabled) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await _pickTime(draft.start);
                        if (t != null) setState(() => draft.start = t);
                      },
                      child: Text('${l10n.admStart} ${_DayDraft._fmt(draft.start)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await _pickTime(draft.end);
                        if (t != null) setState(() => draft.end = t);
                      },
                      child: Text('${l10n.admEnd} ${_DayDraft._fmt(draft.end)}'),
                    ),
                  ),
                ],
              ),
              IntStepper(
                label: l10n.admMinStaff,
                value: draft.min,
                max: 99,
                onChanged: (v) => setState(() {
                  draft.min = v;
                  if (draft.max != null && draft.max! < v) draft.max = v;
                }),
              ),
              IntStepper(
                label: l10n.admMaxStaff,
                value: draft.max ?? 0,
                max: 99,
                format: (v) => v == 0 ? '∞' : '$v',
                onChanged: (v) => setState(
                    () => draft.max = v == 0 ? null : (v < draft.min ? draft.min : v)),
              ),
              IntStepper(
                label: l10n.admRestDaysAfter,
                value: draft.freeDays,
                max: 7,
                onChanged: (v) => setState(() => draft.freeDays = v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
