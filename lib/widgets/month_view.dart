import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/shift_data_controller.dart';
import 'day_paint_selection.dart';
import 'weekday_header.dart';

/// A month grid (Mon–Sun) with shift markers. Selecting a day calls
/// [onDaySelected]; long pressing one — and dragging across more of them —
/// calls [onDaysPainted], which the home screen uses to open the shift wish
/// editor for every day the finger touched.
class MonthView extends StatelessWidget {
  final DateTime visibleMonth; // any day within the month to show
  final DateTime? selectedDay;
  final ShiftDataController data;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<Set<DateTime>>? onDaysPainted;

  const MonthView({
    super.key,
    required this.visibleMonth,
    required this.selectedDay,
    required this.data,
    required this.onDaySelected,
    this.onDaysPainted,
  });

  /// Height of a week row. The grid keeps this size instead of stretching to
  /// whatever the window offers: a date cell holds a number and a few dots, so
  /// a taller row is empty space, not more to read. It only shrinks below this
  /// when the month would otherwise not fit.
  static const double _rowHeight = 52;

  /// Widest a single day cell gets, so the grid stays calendar-shaped on a wide
  /// window rather than stretching into a band of flat, far-apart cells.
  static const double _cellWidth = 76;

  /// What the weekday labels take off the top, used only to work out how much
  /// is left for the rows.
  static const double _headerHeight = 28;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final forRows = constraints.maxHeight - _headerHeight;
        final rowHeight = forRows.isFinite && forRows > 0
            ? math.min(_rowHeight, forRows / weeks)
            : _rowHeight;

        final grid = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WeekdayHeader(),
            for (int week = 0; week < weeks; week++)
              SizedBox(
                height: rowHeight,
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

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _cellWidth * 7),
            child: onDaysPainted == null
                ? grid
                : DayPaintArea(onCommit: onDaysPainted!, child: grid),
          ),
        );
      },
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, DateTime today) {
    final theme = Theme.of(context);
    final inMonth = day.month == visibleMonth.month;
    final isToday = dateKey(day) == today;
    final isSelected = selectedDay != null && dateKey(day) == dateKey(selectedDay!);
    final holiday = data.holidayOn(day);
    final plans = data.plansForDay(day);

    // Distinct shift colours for the day's markers (max 4 dots shown).
    final colors = <Color>[];
    for (final p in plans) {
      final shift = data.shiftById(p.shiftId);
      if (shift != null && !colors.contains(shift.displayColor)) {
        colors.add(shift.displayColor);
      }
    }

    // A star in the wished shift's colour marks the days the selected employee
    // asked for something.
    final wish = data.wishForDay(day);
    final wishColor = wish == null
        ? null
        : data.shiftById(wish.shiftId)?.displayColor ??
            theme.colorScheme.primary;

    final cell = Padding(
      padding: const EdgeInsets.all(2),
      child: PaintableDay(
        day: dateKey(day),
        child: Material(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : holiday != null
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
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
                        color: holiday != null
                            ? theme.colorScheme.error
                            : inMonth
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.outline,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _MarkerDots(colors: colors, wishColor: wishColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return holiday == null
        ? cell
        : Tooltip(message: holiday.name, child: cell);
  }
}

class _MarkerDots extends StatelessWidget {
  final List<Color> colors;

  /// Colour of the wished shift, or null when the day carries no wish.
  final Color? wishColor;

  const _MarkerDots({required this.colors, this.wishColor});

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty && wishColor == null) return const SizedBox(height: 8);
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
        if (wishColor != null)
          Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Icon(Icons.star_rounded, size: 9, color: wishColor),
          ),
      ],
    );
  }
}
