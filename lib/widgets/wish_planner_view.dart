import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/shift_data_controller.dart';
import 'day_paint_selection.dart';
import 'shift_wish_sheet.dart';
import 'weekday_header.dart';
import 'wish_window_status.dart';

/// Wishes-only planner for one month.
///
/// Unlike the calendar views this deliberately hides the confirmed roster: it
/// answers "what did I ask for this month?" and nothing else. Tapping a day
/// opens the wish editor and long pressing across several days opens it for
/// all of them at once; the list below shows the month's wishes in order so
/// they can be reviewed and withdrawn without hunting through the grid.
class WishPlannerView extends StatelessWidget {
  /// Any day inside the month to plan.
  final DateTime visibleMonth;
  final ShiftDataController data;

  const WishPlannerView({
    super.key,
    required this.visibleMonth,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (data.selectedEmployeeId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border_rounded,
                  size: 48, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                l10n.wishPlannerPickEmployee,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final last = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);
    final wishes = data.wishesInRange(first, last);
    final weeks = ((first.weekday - 1 + last.day) / 7).ceil();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _header(context, wishes),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          // Give the grid a height that follows the number of weeks, so it
          // keeps square-ish cells instead of stretching to the viewport.
          child: AspectRatio(
            aspectRatio: 7 / (weeks + 0.7),
            child: DayPaintArea(
              onCommit: (days) => showShiftWishSheet(
                context,
                // Days from the neighbouring months are painted over but not
                // planned here — the toolbar steps to their month.
                days: days.where((d) => d.month == visibleMonth.month),
                data: data,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WeekdayHeader(),
                  for (int week = 0; week < weeks; week++)
                    Expanded(
                      child: Row(
                        children: [
                          for (int d = 0; d < 7; d++)
                            Expanded(
                              child: _dayCell(
                                context,
                                first
                                    .subtract(Duration(days: first.weekday - 1))
                                    .add(Duration(days: week * 7 + d)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (wishes.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              l10n.wishPlannerEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          )
        else ...[
          const Divider(height: 1),
          for (final wish in wishes) _wishTile(context, wish),
        ],
      ],
    );
  }

  Widget _header(BuildContext context, List<ShiftWish> wishes) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // How often each shift was wished for this month — a quick balance check.
    final perShift = <String, int>{};
    for (final w in wishes) {
      perShift[w.shiftId] = (perShift[w.shiftId] ?? 0) + 1;
    }
    final counted = perShift.entries.toList()
      ..sort((a, b) => (data.shiftById(a.key)?.order ?? 999)
          .compareTo(data.shiftById(b.key)?.order ?? 999));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.selectedEmployee?.name ?? '',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(l10n.wishPlannerCount(wishes.length),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 8),
          // Whether wishing is possible at all comes before any hint on how to
          // do it, so it sits directly under the employee.
          Align(
            alignment: Alignment.centerLeft,
            child: WishWindowChip(settings: data.wishSettings),
          ),
          const SizedBox(height: 6),
          Text(
              data.wishesOpen
                  ? l10n.wishPlannerHint
                  : l10n.wishWindowClosedDetail,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          if (counted.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in counted)
                  _tally(context, data.shiftById(entry.key), entry.value),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tally(BuildContext context, Shift? shift, int count) {
    final theme = Theme.of(context);
    final color = shift?.displayColor ?? theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${shift?.shortName ?? shift?.name ?? '?'} · $count',
        style: theme.textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final theme = Theme.of(context);
    final inMonth = day.month == visibleMonth.month;
    final isToday = dateKey(day) == dateKey(DateTime.now());
    final wish = inMonth ? data.wishForDay(day) : null;
    final shift = wish == null ? null : data.shiftById(wish.shiftId);
    final color = shift?.displayColor ?? theme.colorScheme.primary;
    // Days the wish window does not cover stay readable but inert: the server
    // would refuse a wish for them, so the grid must not invite one.
    final editable = inMonth && data.canWishOn(day);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: PaintableDay(
        day: dateKey(day),
        child: Material(
          color: wish == null
              ? Colors.transparent
              : color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            // Days outside the month belong to a neighbouring month's plan;
            // step there with the toolbar rather than editing them from here.
            onTap: editable
                ? () => showShiftWishSheet(context,
                    days: [dateKey(day)], data: data)
                : null,
              child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: wish != null
                      ? color
                      : isToday
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                  width: isToday ? 1.5 : 1,
                ),
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
                        color: inMonth && editable
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (wish != null)
                      Text(
                        shift?.shortName ?? '★',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: color, fontWeight: FontWeight.bold),
                      )
                    else if (inMonth && !editable)
                      Icon(Icons.lock_outline_rounded,
                          size: 10, color: theme.colorScheme.outlineVariant)
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wishTile(BuildContext context, ShiftWish wish) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final shift = data.shiftById(wish.shiftId);
    final color = shift?.displayColor ?? theme.colorScheme.outline;
    final times = shift?.timesFor(wish.date);

    return ListTile(
      leading: Container(
        width: 6,
        height: 36,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(3)),
      ),
      title: Text(DateFormat.MMMEd(context.dateLocale).format(wish.date),
          style: theme.textTheme.titleSmall),
      subtitle: Text(
        [
          shift?.name ?? l10n.unknownShift,
          if (times != null) '${times.startTime} – ${times.endTime}',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // A wish placed while the window was open cannot be withdrawn once it
      // closed — the server locks both directions.
      trailing: IconButton(
        tooltip: data.canWishOn(wish.date)
            ? l10n.removeWish
            : l10n.wishOutsideWindow,
        icon: Icon(Icons.star_rounded, color: color),
        onPressed: data.canWishOn(wish.date)
            ? () => withdrawShiftWish(context, wish: wish, data: data)
            : null,
      ),
      onTap: () =>
          showShiftWishSheet(context, days: [dateKey(wish.date)], data: data),
    );
  }
}
