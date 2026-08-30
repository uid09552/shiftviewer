import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/shift_data_controller.dart';
import 'day_paint_selection.dart';

/// A single-week strip (Mon–Sun). Selecting a day calls [onDaySelected]; long
/// pressing one — and dragging across the rest — calls [onDaysPainted], which
/// opens the shift wish editor for everything the finger touched.
class WeekView extends StatelessWidget {
  final DateTime visibleWeek; // any day within the week to show
  final DateTime? selectedDay;
  final ShiftDataController data;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<Set<DateTime>>? onDaysPainted;

  const WeekView({
    super.key,
    required this.visibleWeek,
    required this.selectedDay,
    required this.data,
    required this.onDaySelected,
    this.onDaysPainted,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart =
        visibleWeek.subtract(Duration(days: visibleWeek.weekday - 1));
    final today = dateKey(DateTime.now());

    final strip = Row(
      children: [
        for (int d = 0; d < 7; d++)
          Expanded(
            child: _buildDay(
              context,
              DateTime(weekStart.year, weekStart.month, weekStart.day + d),
              today,
            ),
          ),
      ],
    );

    return onDaysPainted == null
        ? strip
        : DayPaintArea(onCommit: onDaysPainted!, child: strip);
  }

  Widget _buildDay(BuildContext context, DateTime day, DateTime today) {
    final theme = Theme.of(context);
    final isToday = dateKey(day) == today;
    final isSelected =
        selectedDay != null && dateKey(day) == dateKey(selectedDay!);
    final plans = data.plansForDay(day);
    final wish = data.wishForDay(day);
    final wishShift = wish == null ? null : data.shiftById(wish.shiftId);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: PaintableDay(
        day: dateKey(day),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Material(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onDaySelected(day),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: isToday
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Column(
                children: [
                  Text(DateFormat.E(context.dateLocale).format(day),
                      style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text('${day.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      )),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final p in plans)
                          _shiftChip(
                              context,
                              data.shiftById(p.shiftId)?.shortName,
                              data.shiftById(p.shiftId)?.displayColor,
                              p.isPresent),
                        if (wish != null) _wishChip(context, wishShift),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The wished shift, drawn as an outlined chip so it never reads as rostered.
  Widget _wishChip(BuildContext context, Shift? shift) {
    final theme = Theme.of(context);
    final c = shift?.displayColor ?? theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 9, color: c),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              shift?.shortName ?? '?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftChip(
      BuildContext context, String? label, Color? color, bool present) {
    final c = color ?? Theme.of(context).colorScheme.outline;
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: present ? c.withValues(alpha: 0.85) : c.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label ?? (present ? '?' : '—'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: present ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
