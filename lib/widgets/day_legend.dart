import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/shift_data_controller.dart';
import 'shift_insights_sheet.dart';

/// What the colours on [day] mean: one row per shift rostered that day, with
/// its swatch, hours and headcount.
///
/// It sits under the month grid and the week strip and reads as their legend —
/// the same colours, spelled out — while doubling as the detail panel for the
/// date just tapped. The full roster stays one tap further away in the day
/// view, which [onOpenDay] jumps to.
class DayLegend extends StatelessWidget {
  final DateTime day;
  final ShiftDataController data;

  /// Opens the day view; no button is shown when null.
  final VoidCallback? onOpenDay;

  const DayLegend({
    super.key,
    required this.day,
    required this.data,
    this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = data.allPlansForDay(day);
    final wish = data.wishForDay(day);
    final groups = _byShift(plans);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, plans.length),
            if (groups.isEmpty && wish == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Text(
                  context.l10n.noShiftsScheduled,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            else ...[
              for (final group in groups)
                _shiftRow(context, group.key, group.value),
              if (_offToday) _offRow(context),
              if (wish != null) _wishRow(context, wish),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  /// Whether the selected employee is rostered nowhere on this day.
  bool get _offToday {
    final employeeId = data.selectedEmployeeId;
    if (employeeId == null) return false;
    return !data.allPlansForDay(day).any((p) => p.employeeId == employeeId);
  }

  /// The day's plans grouped by shift, in roster order, with the "off" bucket
  /// (no shift assigned) last.
  List<MapEntry<String?, List<ConfirmedShiftPlan>>> _byShift(
    List<ConfirmedShiftPlan> plans,
  ) {
    final grouped = <String?, List<ConfirmedShiftPlan>>{};
    for (final p in plans) {
      grouped.putIfAbsent(p.shiftId, () => []).add(p);
    }
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return (data.shiftById(a)?.order ?? 999).compareTo(
          data.shiftById(b)?.order ?? 999,
        );
      });
    return [for (final k in keys) MapEntry(k, grouped[k]!)];
  }

  Widget _header(BuildContext context, int working) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, onOpenDay == null ? 16 : 4, 4),
      child: Row(
        children: [
          Icon(Icons.event_note, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              DateFormat.MMMMEEEEd(context.dateLocale).format(day),
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            l10n.workingCount(working),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (onOpenDay != null)
            IconButton(
              tooltip: l10n.openDayView,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.open_in_full, size: 16),
              onPressed: onOpenDay,
            ),
        ],
      ),
    );
  }

  Widget _shiftRow(
    BuildContext context,
    String? shiftId,
    List<ConfirmedShiftPlan> plans,
  ) {
    final theme = Theme.of(context);
    final shift = data.shiftById(shiftId);
    final color = shift?.displayColor ?? theme.colorScheme.outline;
    final times = shift?.timesFor(day);
    final mine = _planOf(plans, data.selectedEmployeeId);
    final workstation = mine == null
        ? null
        : data.workstationById(mine.workstationId);

    return Material(
      // The selected employee's own shift is the one they came to check, so it
      // is tinted to stand out from the rest of the legend.
      color: mine == null ? Colors.transparent : color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () => showShiftInsightsSheet(
          context,
          data: data,
          day: day,
          shiftId: shiftId,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(
            children: [
              _swatch(context, color, shift?.shortName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift?.name ?? context.l10n.offNotScheduled,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: mine == null
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (times != null)
                      Text(
                        '${times.startTime} – ${times.endTime}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              if (mine != null) _mineMarker(context, mine, workstation),
              const SizedBox(width: 8),
              Text(
                '${plans.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Where the selected employee stands on this shift: present or away, and at
  /// which workstation when the roster says.
  Widget _mineMarker(
    BuildContext context,
    ConfirmedShiftPlan plan,
    Workstation? workstation,
  ) {
    final theme = Theme.of(context);
    final absent = !plan.isPresent;
    final label = absent
        ? absenceLabel(context.l10n, plan.absenceType)
        : workstation?.name;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          absent ? Icons.person_off_outlined : Icons.person,
          size: 16,
          color: absent ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: absent
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The selected employee has nothing rostered — worth saying outright, since
  /// the rows above are then all about other people.
  Widget _offRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 18,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Text(
            context.l10n.offNoShift,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wishRow(BuildContext context, ShiftWish wish) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final shift = data.shiftById(wish.shiftId);
    final color = shift?.displayColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Icon(Icons.star_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.wishFor(shift?.name ?? l10n.unknownShift),
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// The colour chip carrying the shift's short name — the same colour the
  /// calendar cell above paints, which is what makes this a legend.
  Widget _swatch(BuildContext context, Color color, String? shortName) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      width: 34,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        shortName ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: onColor,
        ),
      ),
    );
  }

  ConfirmedShiftPlan? _planOf(
    List<ConfirmedShiftPlan> plans,
    String? employeeId,
  ) {
    if (employeeId == null) return null;
    for (final p in plans) {
      if (p.employeeId == employeeId) return p;
    }
    return null;
  }
}
