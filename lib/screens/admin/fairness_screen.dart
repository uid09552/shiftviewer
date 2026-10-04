import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import 'admin_common.dart';

enum _Preset { thisMonth, lastMonth, thisQuarter, last3Months, custom }

enum _Col { name, shifts, hours, target, nights, weekend, wishes, absent }

/// Who has had what: nights, weekends, hours against target and wishes per
/// person, from the confirmed roster.
class FairnessScreen extends StatefulWidget {
  const FairnessScreen({super.key});

  @override
  State<FairnessScreen> createState() => _FairnessScreenState();
}

class _FairnessScreenState extends State<FairnessScreen>
    with AdminApiState<FairnessScreen> {
  _Preset _preset = _Preset.thisMonth;
  late DateTimeRange _range = _rangeFor(_Preset.thisMonth);
  List<EmployeeFairness> _rows = [];
  bool _onlyWorking = true;
  _Col _sort = _Col.nights;
  bool _asc = false;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static DateTimeRange _rangeFor(_Preset p) {
    final now = DateTime.now();
    final q = (now.month - 1) ~/ 3 * 3 + 1;
    return switch (p) {
      _Preset.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0),
      ),
      _Preset.thisQuarter => DateTimeRange(
        start: DateTime(now.year, q, 1),
        end: DateTime(now.year, q + 3, 0),
      ),
      _Preset.last3Months => DateTimeRange(
        start: DateTime(now.year, now.month - 2, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      _ => DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await api.fairness(_range.start, _range.end);
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(_Preset p) async {
    if (p == _Preset.custom) {
      final r = await pickDateRange(context, initial: _range);
      if (r == null) return;
      setState(() {
        _preset = p;
        _range = r;
      });
    } else {
      setState(() {
        _preset = p;
        _range = _rangeFor(p);
      });
    }
    _load();
  }

  static Comparable? _value(EmployeeFairness r, _Col c) => switch (c) {
    _Col.name => r.employeeName.toLowerCase(),
    _Col.shifts => r.shifts,
    _Col.hours => r.hours,
    _Col.target => r.targetDelta,
    _Col.nights => r.nightShifts,
    _Col.weekend => r.weekendDays,
    _Col.wishes => r.wishesAsked == 0 ? null : r.wishesGranted / r.wishesAsked,
    _Col.absent => r.daysAbsent,
  };

  List<EmployeeFairness> get _sorted {
    final rows = _rows.where((r) => !_onlyWorking || r.shifts > 0).toList();
    rows.sort((a, b) {
      final x = _value(a, _sort);
      final y = _value(b, _sort);
      if (x == null && y == null) return a.employeeName.compareTo(b.employeeName);
      if (x == null) return 1;
      if (y == null) return -1;
      final o = x.compareTo(y) * (_asc ? 1 : -1);
      return o != 0 ? o : a.employeeName.compareTo(b.employeeName);
    });
    return rows;
  }

  String _presetLabel(AppLocalizations l10n, _Preset p) => switch (p) {
    _Preset.thisMonth => l10n.admThisMonth,
    _Preset.lastMonth => l10n.admLastMonth,
    _Preset.thisQuarter => l10n.admThisQuarter,
    _Preset.last3Months => l10n.admLast3Months,
    _Preset.custom => l10n.admCustom,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.admFairness)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                for (final p in _Preset.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_presetLabel(l10n, p)),
                      selected: _preset == p,
                      onSelected: (_) => _pick(p),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(formatRange(context, _range.start, _range.end),
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(l10n.admOnlyWorking),
                Switch(
                  value: _onlyWorking,
                  onChanged: (v) => setState(() => _onlyWorking = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: AdminLoadState(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () => _rows.every((r) => r.shifts == 0)
                  ? AdminEmpty(l10n.admFairnessEmpty, icon: Icons.balance)
                  : ListView(
                      children: [
                        _spreadCard(context),
                        _table(context),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spreadCard(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final working = _rows.where((r) => r.shifts > 0).toList();
    String spread(Iterable<num> values) {
      final v = [for (final x in values) x.toDouble()];
      if (v.isEmpty) return '—';
      final min = v.reduce(math.min);
      final max = v.reduce(math.max);
      final avg = v.fold(0.0, (s, x) => s + x) / v.length;
      return l10n.admSpread(_fmt(min), _fmt(max), _fmt(avg));
    }

    final deltas = working.map((r) => r.targetDelta).whereType<double>();
    final asked = _rows.fold(0, (s, r) => s + r.wishesAsked);
    final granted = _rows.fold(0, (s, r) => s + r.wishesGranted);

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line(l10n.admColNights, spread(working.map((r) => r.nightShifts))),
            line(l10n.admColWeekend, spread(working.map((r) => r.weekendDays))),
            line(l10n.admColHours, spread(working.map((r) => r.hours))),
            line(l10n.admColTarget, spread(deltas)),
            line(l10n.admColWishes, asked == 0 ? '—' : '$granted / $asked'),
            const SizedBox(height: 6),
            Text(l10n.admFairnessWorkingNote(working.length, _rows.length),
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static String _fmt(num v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _table(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cols = [
      (_Col.name, l10n.employee, false),
      (_Col.shifts, l10n.admColShifts, true),
      (_Col.hours, l10n.admColHours, true),
      (_Col.target, l10n.admColTarget, true),
      (_Col.nights, l10n.admColNights, true),
      (_Col.weekend, l10n.admColWeekend, true),
      (_Col.wishes, l10n.admColWishes, true),
      (_Col.absent, l10n.admColAbsent, true),
    ];
    final sortIndex = cols.indexWhere((c) => c.$1 == _sort);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: sortIndex,
        sortAscending: _asc,
        columnSpacing: 20,
        columns: [
          for (final c in cols)
            DataColumn(
              label: Text(c.$2),
              numeric: c.$3,
              onSort: (_, _) => setState(() {
                if (_sort == c.$1) {
                  _asc = !_asc;
                } else {
                  _sort = c.$1;
                  _asc = c.$1 == _Col.name;
                }
              }),
            ),
        ],
        rows: [
          for (final r in _sorted)
            DataRow(cells: [
              DataCell(Text(r.employeeName)),
              DataCell(Text('${r.shifts}')),
              DataCell(Text(_fmt(r.hours))),
              DataCell(Text(
                r.targetDelta == null
                    ? '—'
                    : '${r.targetDelta! > 0 ? '+' : ''}${_fmt(r.targetDelta!)}',
                style: TextStyle(
                  color: r.targetDelta == null || r.targetDelta!.abs() < 8
                      ? null
                      : theme.colorScheme.error,
                ),
              )),
              DataCell(Text('${r.nightShifts}')),
              DataCell(Text('${r.weekendDays}')),
              DataCell(Text(r.wishesAsked == 0
                  ? '—'
                  : '${r.wishesGranted} / ${r.wishesAsked}')),
              DataCell(Text('${r.daysAbsent}')),
            ]),
        ],
      ),
    );
  }
}
