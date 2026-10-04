import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n_helpers.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/shift_data_controller.dart';
import 'admin_common.dart';

/// Whether, and for which dates, employees may place shift wishes. Only
/// shift-admin may change it; anyone else sees it read-only.
class WishSettingsScreen extends StatefulWidget {
  const WishSettingsScreen({super.key});

  @override
  State<WishSettingsScreen> createState() => _WishSettingsScreenState();
}

class _WishSettingsScreenState extends State<WishSettingsScreen>
    with AdminApiState<WishSettingsScreen> {
  WishMode _mode = WishMode.enabled;
  DateTime? _start;
  DateTime? _end;
  WishSchedule _schedule = WishSchedule.off;
  bool _loading = true;
  bool _saving = false;
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
      final s = await api.client.getWishSettings();
      if (!mounted) return;
      setState(() {
        _mode = s.mode;
        _start = s.windowStart;
        _end = s.windowEnd;
        _schedule = s.schedule ?? WishSchedule.off;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved =
          await api.saveWishSettings(_mode, _start, _end, schedule: _schedule);
      if (!mounted) return;
      setState(() => _schedule = saved.schedule ?? WishSchedule.off);
      showAdminMessage(context, context.l10n.admSaved);
      // The calendar reads the window too; let it pick up the new one.
      final data = context.read<ShiftDataController>();
      if (data.loadedFrom != null && data.loadedTo != null) {
        data.refresh(data.loadedFrom!, data.loadedTo!);
      }
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canEdit = context.watch<AuthController>().isAdmin;
    final rangeMissing =
        _mode == WishMode.dateRange && (_start == null || _end == null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.admWishSettings)),
      bottomNavigationBar: canEdit && !_loading && _error == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _saving || rangeMissing ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.save),
                ),
              ),
            )
          : null,
      body: AdminLoadState(
        loading: _loading,
        error: _error,
        onRetry: _load,
        builder: () => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(canEdit ? l10n.admWishSettingsIntro : l10n.admWishSettingsReadOnly),
            ),
            RadioGroup<WishMode>(
              groupValue: _mode,
              onChanged: (m) {
                if (canEdit && m != null) setState(() => _mode = m);
              },
              child: Column(
                children: [
                  RadioListTile<WishMode>(
                    value: WishMode.enabled,
                    enabled: canEdit,
                    title: Text(l10n.admWishModeEnabled),
                    subtitle: Text(l10n.admWishModeEnabledHint),
                  ),
                  RadioListTile<WishMode>(
                    value: WishMode.dateRange,
                    enabled: canEdit,
                    title: Text(l10n.admWishModeRange),
                    subtitle: Text(l10n.admWishModeRangeHint),
                  ),
                  RadioListTile<WishMode>(
                    value: WishMode.disabled,
                    enabled: canEdit,
                    title: Text(l10n.admWishModeDisabled),
                    subtitle: Text(l10n.admWishModeDisabledHint),
                  ),
                ],
              ),
            ),
            if (_mode == WishMode.dateRange)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_start == null || _end == null
                      ? l10n.admPickDates
                      : formatRange(context, _start!, _end!)),
                  onPressed: !canEdit
                      ? null
                      : () async {
                          final r = await pickDateRange(
                            context,
                            initial: _start == null || _end == null
                                ? null
                                : DateTimeRange(start: _start!, end: _end!),
                          );
                          if (r != null) {
                            setState(() {
                              _start = r.start;
                              _end = r.end;
                            });
                          }
                        },
                ),
              ),
            AdminSectionHeader(l10n.admWishScheduleTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l10n.admWishScheduleHint,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            SwitchListTile(
              title: Text(l10n.admWishScheduleTitle),
              value: _schedule.enabled,
              onChanged: !canEdit
                  ? null
                  : (v) =>
                      setState(() => _schedule = _schedule.copyWith(enabled: v)),
            ),
            if (_schedule.enabled) ..._scheduleFields(context, canEdit),
            if (_schedule.nextChangeAt != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  _schedule.nextChangeOpens == true
                      ? l10n.admWishScheduleNextChangeOpens(
                          DateFormat.yMMMd(context.dateLocale)
                              .add_Hm()
                              .format(_schedule.nextChangeAt!.toLocal()))
                      : l10n.admWishScheduleNextChangeCloses(
                          DateFormat.yMMMd(context.dateLocale)
                              .add_Hm()
                              .format(_schedule.nextChangeAt!.toLocal())),
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _scheduleFields(BuildContext context, bool canEdit) {
    final l10n = context.l10n;
    final s = _schedule;
    final timeParts = s.time.split(':');
    final timeOfDay = TimeOfDay(
      hour: int.tryParse(timeParts.isNotEmpty ? timeParts[0] : '') ?? 8,
      minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '') ?? 0,
    );
    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    return [
      ListTile(
        title: Text(l10n.admWishScheduleUnit),
        trailing: DropdownButton<ScheduleUnit>(
          value: s.unit,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(
                value: ScheduleUnit.days, child: Text(l10n.admWishScheduleUnitDays)),
            DropdownMenuItem(
                value: ScheduleUnit.weeks,
                child: Text(l10n.admWishScheduleUnitWeeks)),
            DropdownMenuItem(
                value: ScheduleUnit.months,
                child: Text(l10n.admWishScheduleUnitMonths)),
          ],
          onChanged: !canEdit
              ? null
              : (u) => u == null
                  ? null
                  : setState(() => _schedule = s.copyWith(unit: u)),
        ),
      ),
      IntStepper(
        label: l10n.admWishScheduleUnit,
        value: s.interval,
        min: 1,
        max: s.unit.maxInterval,
        onChanged: !canEdit
            ? (_) {}
            : (v) => setState(() => _schedule = s.copyWith(interval: v)),
      ),
      if (s.unit == ScheduleUnit.weeks)
        ListTile(
          title: Text(l10n.admWishScheduleWeekday),
          trailing: DropdownButton<int>(
            value: s.weekday,
            underline: const SizedBox.shrink(),
            items: [
              for (int i = 0; i < 7; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(DateFormat.E(context.dateLocale)
                      .format(DateTime(2024, 1, 1 + i))),
                ),
            ],
            onChanged: !canEdit
                ? null
                : (v) => v == null
                    ? null
                    : setState(() => _schedule = s.copyWith(weekday: v)),
          ),
        ),
      if (s.unit == ScheduleUnit.months)
        IntStepper(
          label: l10n.admWishScheduleDayOfMonth,
          value: s.dayOfMonth,
          min: 1,
          max: 31,
          onChanged: !canEdit
              ? (_) {}
              : (v) => setState(() => _schedule = s.copyWith(dayOfMonth: v)),
        ),
      ListTile(
        title: Text(l10n.admWishScheduleTime),
        trailing: TextButton(
          onPressed: !canEdit
              ? null
              : () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: timeOfDay,
                  );
                  if (picked != null) {
                    setState(
                        () => _schedule = s.copyWith(time: fmtTime(picked)));
                  }
                },
          child: Text(timeOfDay.format(context)),
        ),
      ),
      IntStepper(
        label: l10n.admWishScheduleOpenDays,
        value: s.openDays,
        min: 1,
        max: 366,
        onChanged: !canEdit
            ? (_) {}
            : (v) => setState(() => _schedule = s.copyWith(openDays: v)),
      ),
    ];
  }
}
