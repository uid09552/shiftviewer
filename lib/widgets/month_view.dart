import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/shift_data_controller.dart';

/// A month grid (Mon–Sun) with shift markers. Selecting a day calls [onDaySelected].
class MonthView extends StatelessWidget {
  final DateTime visibleMonth; // any day within the month to show
  final DateTime? selectedDay;
  final ShiftDataController data;
  final ValueChanged<DateTime> onDaySelected;

  const MonthView({
    super.key,
    required this.visibleMonth,
    required this.selectedDay,
    required this.data,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    // Weekday: Mon=1..Sun=7 -> leading blanks before the 1st.
    final leading = firstOfMonth.weekday - 1;
    final gridStart = firstOfMonth.subtract(Duration(days: leading));
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    // Only render the weeks the month actually spans (4–6) for more room per row.
    final weeks = ((leading + daysInMonth) / 7).ceil();
    final today = dateKey(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekdayHeader(),
        for (int week = 0; week < weeks; week++)
          Expanded(
            child: Row(
              children: [
                for (int d = 0; d < 7; d++)
                  Expanded(
                    child: _buildDayCell(
                      context,
                      gridStart.add(Duration(days: week * 7 + d)),
                      today,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, DateTime today) {
    final theme = Theme.of(context);
    final inMonth = day.month == visibleMonth.month;
    final isToday = dateKey(day) == today;
    final isSelected = selectedDay != null && dateKey(day) == dateKey(selectedDay!);
    final plans = data.plansForDay(day);

    // Distinct shift colours for the day's markers (max 4 dots shown).
    final colors = <Color>[];
    for (final p in plans) {
      final shift = data.shiftById(p.shiftId);
      if (shift != null && !colors.contains(shift.displayColor)) {
        colors.add(shift.displayColor);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onDaySelected(day),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: inMonth
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _MarkerDots(colors: colors, extra: plans.length),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = DateFormat.E().dateSymbols.STANDALONESHORTWEEKDAYS;
    // Dart intl weekday order is Sun..Sat; reorder to Mon..Sun.
    final ordered = [
      labels[1], labels[2], labels[3], labels[4], labels[5], labels[6], labels[0],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final l in ordered)
            Expanded(
              child: Center(
                child: Text(
                  l,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkerDots extends StatelessWidget {
  final List<Color> colors;
  final int extra;
  const _MarkerDots({required this.colors, required this.extra});

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox(height: 8);
    final shown = colors.take(4).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in shown)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
      ],
    );
  }
}
