import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/shift_data_controller.dart';

/// A single-week strip (Mon–Sun). Selecting a day calls [onDaySelected].
class WeekView extends StatelessWidget {
  final DateTime visibleWeek; // any day within the week to show
  final DateTime? selectedDay;
  final ShiftDataController data;
  final ValueChanged<DateTime> onDaySelected;

  const WeekView({
    super.key,
    required this.visibleWeek,
    required this.selectedDay,
    required this.data,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart =
        visibleWeek.subtract(Duration(days: visibleWeek.weekday - 1));
    final today = dateKey(DateTime.now());

    return Row(
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
  }

  Widget _buildDay(BuildContext context, DateTime day, DateTime today) {
    final theme = Theme.of(context);
    final isToday = dateKey(day) == today;
    final isSelected =
        selectedDay != null && dateKey(day) == dateKey(selectedDay!);
    final plans = data.plansForDay(day);

    return Padding(
      padding: const EdgeInsets.all(3),
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
                Text(DateFormat.E().format(day),
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
                        _shiftChip(context, data.shiftById(p.shiftId)?.shortName,
                            data.shiftById(p.shiftId)?.displayColor, p.isPresent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
