import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/day_insights.dart';
import '../services/shift_data_controller.dart';
import 'shift_insights_sheet.dart';

/// The list behind a number.
///
/// Everything in the day view and the insight sheets that shows a count — a
/// stat tile, a workstation row, a bar, a pill — answers a long press with one
/// of these: the rows the number was counted from, each one a way further in.
/// It is deliberately plain, because the interesting part is always the rows.

/// One row of a [showDetailListSheet] listing.
class DetailEntry {
  final String title;
  final String? subtitle;

  /// Right-hand value: hours, a count, a state.
  final String? trailing;

  final IconData icon;

  /// Tints the icon and the trailing text; the theme's outline when null.
  final Color? color;

  /// Where the row leads — usually a person's own sheet. Rows without one are
  /// plain facts.
  final VoidCallback? onTap;

  const DetailEntry({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon = Icons.chevron_right,
    this.color,
    this.onTap,
  });
}

/// Opens the listing for [title], with [subtitle] naming what was counted.
///
/// [entries] may be empty: a shift with nobody absent still deserves an answer
/// to the long press, so the sheet says there is nothing rather than not
/// opening at all.
Future<void> showDetailListSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<DetailEntry> entries,
  IconData icon = Icons.list_alt,
  Color? accent,
  String? emptyText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _DetailListBody(
      title: title,
      subtitle: subtitle,
      entries: entries,
      icon: icon,
      accent: accent,
      emptyText: emptyText,
    ),
  );
}

class _DetailListBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<DetailEntry> entries;
  final IconData icon;
  final Color? accent;
  final String? emptyText;

  const _DetailListBody({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.icon,
    required this.accent,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (entries.isNotEmpty)
                    Text(
                      '${entries.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Text(
                        emptyText ?? context.l10n.listNothingToShow,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (context, i) => _row(context, entries[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, DetailEntry entry) {
    final theme = Theme.of(context);
    final color = entry.color ?? theme.colorScheme.outline;

    return ListTile(
      dense: true,
      leading: Icon(entry.icon, size: 20, color: color),
      title: Text(
        entry.title,
        style: theme.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: entry.subtitle == null
          ? null
          : Text(
              entry.subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              maxLines: 2,
            ),
      trailing: entry.trailing == null && entry.onTap == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.trailing != null)
                  Text(
                    entry.trailing!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (entry.onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
              ],
            ),
      onTap: entry.onTap == null
          ? null
          : () {
              // The listing has served its purpose once it is being left; the
              // person's own sheet replaces it rather than stacking on it.
              Navigator.of(context).pop();
              entry.onTap!();
            },
    );
  }
}

/// Makes anything answer a long press with its listing, and says so on hover
/// or a long-press-averse platform through a tooltip.
///
/// A null [onLongPress] is the element that has nothing behind it: it renders
/// its child untouched, with no gesture and no tooltip promising one.
class LongPressTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  const LongPressTarget({
    super.key,
    required this.child,
    required this.onLongPress,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (onLongPress == null) return child;
    return Tooltip(
      message: context.l10n.longPressForDetails,
      // A pointer hovering still gets the hint; a long press must not pop a
      // tooltip over the sheet it just opened.
      triggerMode: TooltipTriggerMode.manual,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row builders — the shapes every caller needs
// ---------------------------------------------------------------------------

/// People behind a day's count: one row per plan, leading into each person's
/// own sheet.
///
/// [showShift] adds the shift to the subtitle, which matters in listings that
/// span shifts (a whole day) and only repeats itself inside one.
List<DetailEntry> peopleEntries(
  BuildContext context, {
  required ShiftDataController data,
  required DateTime day,
  required List<ConfirmedShiftPlan> plans,
  bool showShift = false,
  bool showWorkstation = true,
  bool showHours = false,
}) {
  final theme = Theme.of(context);
  final sorted = [...plans]
    ..sort((a, b) {
      final na = data.employeeById(a.employeeId)?.name ?? a.employeeId;
      final nb = data.employeeById(b.employeeId)?.name ?? b.employeeId;
      return na.toLowerCase().compareTo(nb.toLowerCase());
    });

  return [
    for (final plan in sorted)
      DetailEntry(
        title: data.employeeById(plan.employeeId)?.name ?? plan.employeeId,
        subtitle: _planSubtitle(
          context,
          data: data,
          plan: plan,
          showShift: showShift,
          showWorkstation: showWorkstation,
        ),
        trailing: showHours && plan.isPresent
            ? hoursLabel(context, plannedHoursFor(data, plan))
            : null,
        icon: plan.isPresent ? Icons.person : Icons.person_off_outlined,
        color: plan.isPresent
            ? (data.shiftById(plan.shiftId)?.displayColor ??
                  theme.colorScheme.primary)
            : theme.colorScheme.error,
        onTap: () => showEmployeeInsightsSheet(
          context,
          data: data,
          day: day,
          employeeId: plan.employeeId,
        ),
      ),
  ];
}

/// One employee's days behind a total: one row per plan, newest last, with the
/// shift and workstation each day was spent on.
List<DetailEntry> dayEntries(
  BuildContext context, {
  required ShiftDataController data,
  required List<ConfirmedShiftPlan> plans,
  bool showHours = false,
}) {
  final theme = Theme.of(context);
  final l10n = context.l10n;
  final locale = context.dateLocale;
  final sorted = [...plans]..sort((a, b) => a.date.compareTo(b.date));

  return [
    for (final plan in sorted)
      DetailEntry(
        title: l10n.detailsOnDay(
          DateFormat.E(locale).format(plan.date),
          DateFormat.yMMMd(locale).format(plan.date),
        ),
        subtitle: _planSubtitle(
          context,
          data: data,
          plan: plan,
          showShift: true,
          showWorkstation: true,
        ),
        trailing: showHours && plan.isPresent
            ? hoursLabel(context, plannedHoursFor(data, plan))
            : null,
        icon: plan.isPresent ? Icons.event_available : Icons.event_busy,
        color: plan.isPresent
            ? (data.shiftById(plan.shiftId)?.displayColor ??
                  theme.colorScheme.primary)
            : theme.colorScheme.error,
      ),
  ];
}

/// A shift's week, weekday by weekday — what a long press on its times shows.
List<DetailEntry> scheduleEntries(BuildContext context, Shift shift) {
  final theme = Theme.of(context);
  final l10n = context.l10n;
  final locale = context.dateLocale;
  // Any Monday will do: only the weekday names are read off these dates.
  final monday = DateTime(2024, 1, 1);
  final byWeekday = {for (final t in shift.weekdayTimes) t.weekday: t};

  return [
    for (var i = 0; i < 7; i++)
      DetailEntry(
        title: DateFormat.EEEE(locale).format(monday.add(Duration(days: i))),
        subtitle: switch (byWeekday[i]) {
          null => l10n.scheduleWeekdayOff,
          final times => [
            l10n.scheduleWeekdayLine(
              times.startTime,
              times.endTime,
              times.minEmployees,
            ),
            if (times.maxEmployees != null)
              l10n.stationAboveMaximum(times.maxEmployees!),
            if (times.freeDaysAfterShift > 0)
              l10n.restDaysAfter(times.freeDaysAfterShift),
          ].join(' · '),
        },
        trailing: byWeekday[i] == null
            ? null
            : hoursLabel(context, byWeekday[i]!.hours),
        icon: byWeekday[i] == null ? Icons.event_busy : Icons.schedule,
        color: byWeekday[i] == null
            ? theme.colorScheme.outline
            : shift.displayColor,
      ),
  ];
}

/// `12.5 h` in the current locale — shared with the insight sheets.
String hoursLabel(BuildContext context, double value) =>
    context.l10n.hoursValue(
      NumberFormat.decimalPattern(
        context.dateLocale,
      ).format(double.parse(value.toStringAsFixed(1))),
    );

/// Shift · times · workstation · absence, with whatever the caller asked to
/// leave out dropped.
String? _planSubtitle(
  BuildContext context, {
  required ShiftDataController data,
  required ConfirmedShiftPlan plan,
  required bool showShift,
  required bool showWorkstation,
}) {
  final l10n = context.l10n;
  final shift = data.shiftById(plan.shiftId);
  final times = shift?.timesFor(plan.date);
  final parts = <String>[
    if (showShift) shift?.name ?? l10n.offNotScheduled,
    if (showShift && times != null) '${times.startTime}–${times.endTime}',
    if (showWorkstation)
      data.workstationById(plan.workstationId)?.name ??
          l10n.unassignedWorkstation,
    if (!plan.isPresent) absenceLabel(l10n, plan.absenceType),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
