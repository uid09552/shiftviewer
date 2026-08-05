import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/shift_data_controller.dart';

/// Detail panel shown below the calendar for the currently selected day.
///
/// Groups every confirmed plan on the day by shift, then by workstation, and
/// lists the employees (with presence / absence) working each.
class DayDetail extends StatelessWidget {
  final DateTime? day;
  final ShiftDataController data;

  const DayDetail({super.key, required this.day, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (day == null) {
      return _centeredHint(theme, 'Select a day to see its shifts');
    }

    final plans = data.allPlansForDay(day!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(Icons.event_note, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(DateFormat.yMMMMEEEEd().format(day!),
                    style: theme.textTheme.titleMedium),
              ),
              Text('${plans.length} working',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: plans.isEmpty
              ? _centeredHint(theme, 'No shifts scheduled')
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _buildShiftGroups(context),
                ),
        ),
      ],
    );
  }

  Widget _centeredHint(ThemeData theme, String text) => Center(
        child: Text(text,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline)),
      );

  List<Widget> _buildShiftGroups(BuildContext context) {
    final plans = data.allPlansForDay(day!);

    // Group by shift id (null shift id = off/absent bucket).
    final byShift = <String?, List<ConfirmedShiftPlan>>{};
    for (final p in plans) {
      byShift.putIfAbsent(p.shiftId, () => []).add(p);
    }

    // Order: real shifts by their `order`, the "off" bucket last.
    final keys = byShift.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final oa = data.shiftById(a)?.order ?? 999;
        final ob = data.shiftById(b)?.order ?? 999;
        return oa.compareTo(ob);
      });

    return [for (final k in keys) _shiftCard(context, k, byShift[k]!)];
  }

  Widget _shiftCard(
      BuildContext context, String? shiftId, List<ConfirmedShiftPlan> plans) {
    final theme = Theme.of(context);
    final shift = data.shiftById(shiftId);
    final color = shift?.displayColor ?? theme.colorScheme.outline;
    final times = shift?.timesFor(day!);

    // Group this shift's plans by workstation (null = unassigned, shown last).
    final byWs = <String?, List<ConfirmedShiftPlan>>{};
    for (final p in plans) {
      byWs.putIfAbsent(p.workstationId, () => []).add(p);
    }
    final wsKeys = byWs.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final na = data.workstationById(a)?.name ?? '';
        final nb = data.workstationById(b)?.name ?? '';
        return na.compareTo(nb);
      });

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shift header.
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 24,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(shift?.name ?? 'Off / not scheduled',
                      style: theme.textTheme.titleSmall),
                ),
                if (times != null)
                  Text('${times.startTime}–${times.endTime}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(width: 8),
                Text('${plans.length}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          for (final wsId in wsKeys)
            _workstationBlock(context, shiftId, wsId, byWs[wsId]!),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _workstationBlock(BuildContext context, String? shiftId,
      String? workstationId, List<ConfirmedShiftPlan> plans) {
    final theme = Theme.of(context);
    final ws = data.workstationById(workstationId);
    // Only label the workstation row for real shifts (the off bucket has none).
    final showWs = shiftId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showWs)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
            child: Row(
              children: [
                Icon(Icons.desktop_windows_outlined,
                    size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 6),
                Text(ws?.name ?? 'Unassigned',
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.outline)),
              ],
            ),
          ),
        for (final p in plans..sort(_byEmployeeName))
          _employeeRow(context, p),
      ],
    );
  }

  int _byEmployeeName(ConfirmedShiftPlan a, ConfirmedShiftPlan b) {
    final na = data.employeeById(a.employeeId)?.name ?? '';
    final nb = data.employeeById(b.employeeId)?.name ?? '';
    return na.compareTo(nb);
  }

  Widget _employeeRow(BuildContext context, ConfirmedShiftPlan plan) {
    final theme = Theme.of(context);
    final employee = data.employeeById(plan.employeeId);
    final name = employee?.name ?? plan.employeeId;
    final selected = plan.employeeId == data.selectedEmployeeId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 3, 14, 3),
      child: Row(
        children: [
          Icon(
            plan.isPresent ? Icons.person : Icons.person_off_outlined,
            size: 16,
            color: plan.isPresent
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (!plan.isPresent)
            _badge(
              context,
              plan.absenceType ?? 'absent',
              theme.colorScheme.error,
            ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}
