import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/calendar_handoff.dart';
import '../services/shift_data_controller.dart';
import 'calendar_export_sheet.dart';
import 'shift_insights_sheet.dart';
import 'shift_wish_sheet.dart';
import 'wish_window_status.dart';

/// Summary panel for the selected day: the signed-in employee's own shift as a
/// hero banner, plus the date header.
///
/// It is a pane of its own so it can be resized independently of the shift
/// list below it; the content scrolls when the pane is dragged smaller.
class DayDetailSummary extends StatelessWidget {
  final DateTime day;
  final ShiftDataController data;

  /// Injectable for tests; production uses the real launcher/share sheet.
  final CalendarHandoffService? calendarService;

  const DayDetailSummary({
    super.key,
    required this.day,
    required this.data,
    this.calendarService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = data.allPlansForDay(day);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.selectedEmployeeId != null) _myShiftHero(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.event_note,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat.yMMMMEEEEd(context.dateLocale).format(day),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  context.l10n.workingCount(plans.length),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          if (data.selectedEmployeeId != null) _wishRow(context),
        ],
      ),
    );
  }

  /// The selected employee's wish for the day, and the way to place one without
  /// having to long press the calendar.
  ///
  /// Outside the tenant's wish window the chip only reports what was already
  /// wished for: the server refuses both placing and withdrawing there, and the
  /// window's own badge sits next to it to explain why.
  Widget _wishRow(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final wish = data.wishForDay(day);
    final shift = wish == null ? null : data.shiftById(wish.shiftId);
    final color = shift?.displayColor ?? theme.colorScheme.primary;
    final editable = data.canWishOn(day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Tooltip(
            message: editable ? '' : l10n.wishOutsideWindow,
            child: ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                wish == null ? Icons.star_border_rounded : Icons.star_rounded,
                size: 18,
                color: editable ? color : theme.colorScheme.outline,
              ),
              label: Text(
                wish == null
                    ? l10n.addShiftWish
                    : l10n.wishFor(shift?.name ?? l10n.unknownShift),
              ),
              onPressed: editable
                  ? () => showShiftWishSheet(context, days: [day], data: data)
                  : null,
            ),
          ),
          if (data.wishSettings.mode != WishMode.enabled)
            WishWindowChip(settings: data.wishSettings),
        ],
      ),
    );
  }

  /// Large, at-a-glance banner with the selected employee's own shift and
  /// workstation for the selected day — the thing the user looks for first.
  Widget _myShiftHero(BuildContext context) {
    final theme = Theme.of(context);
    final plans = data
        .allPlansForDay(day)
        .where((p) => p.employeeId == data.selectedEmployeeId)
        .toList();

    // Nothing rostered at all for this employee on this day.
    if (plans.isEmpty) {
      return _heroShell(
        context,
        color: theme.colorScheme.outline,
        child: Row(
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 28,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.offNoShift,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normally a single plan per day; render each if the roster has more.
    return Column(
      children: [for (final plan in plans) _heroForPlan(context, plan)],
    );
  }

  Widget _heroForPlan(BuildContext context, ConfirmedShiftPlan plan) {
    final theme = Theme.of(context);
    final shift = data.shiftById(plan.shiftId);
    final ws = data.workstationById(plan.workstationId);
    final times = shift?.timesFor(day);
    final color = shift?.displayColor ?? theme.colorScheme.outline;

    return _heroShell(
      context,
      color: color,
      onTap: () => showShiftInsightsSheet(
        context,
        data: data,
        day: day,
        shiftId: plan.shiftId,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift?.name ?? context.l10n.offNotScheduled,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (times != null)
                      Text(
                        '${times.startTime} – ${times.endTime}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
              ),
              // A shift that is actually worked is the one worth putting in a
              // calendar; an absence is the opposite of an appointment.
              if (plan.isPresent && plan.shiftId != null)
                IconButton(
                  tooltip: context.l10n.addToGoogleCalendar,
                  icon: const Icon(Icons.event_available_outlined),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => addPlanToCalendar(
                    context,
                    data: data,
                    plan: plan,
                    day: day,
                    service: calendarService,
                  ),
                ),
              if (!plan.isPresent)
                _badge(
                  context,
                  absenceLabel(context.l10n, plan.absenceType),
                  theme.colorScheme.error,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.desktop_windows_outlined,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ws?.name ?? context.l10n.noWorkstation,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ws == null
                        ? theme.colorScheme.outline
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroShell(
    BuildContext context, {
    required Color color,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.selectedEmployee?.name.toUpperCase() ??
                          context.l10n.yourShift,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Only advertise the tap when there is a sheet behind it.
                  if (onTap != null)
                    Icon(
                      Icons.insights_outlined,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// The scrollable shift listing for the selected day: every confirmed plan
/// grouped by shift, then by workstation, with each employee's presence.
class DayShiftList extends StatelessWidget {
  final DateTime day;
  final ShiftDataController data;

  const DayShiftList({super.key, required this.day, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = data.allPlansForDay(day);
    if (plans.isEmpty) {
      return _centeredHint(theme, context.l10n.noShiftsScheduled);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: _buildShiftGroups(context),
    );
  }

  List<Widget> _buildShiftGroups(BuildContext context) {
    final plans = data.allPlansForDay(day);

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
    BuildContext context,
    String? shiftId,
    List<ConfirmedShiftPlan> plans,
  ) {
    final theme = Theme.of(context);
    final shift = data.shiftById(shiftId);
    final color = shift?.displayColor ?? theme.colorScheme.outline;
    final times = shift?.timesFor(day);

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
          // Shift header — and the way into the shift's own statistics.
          Tooltip(
            message: context.l10n.showShiftDetails,
            child: InkWell(
              onTap: () => showShiftInsightsSheet(
                context,
                data: data,
                day: day,
                shiftId: shiftId,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        shift?.name ?? context.l10n.offNotScheduled,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (times != null)
                      Text(
                        '${times.startTime}–${times.endTime}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${plans.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.insights_outlined,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (final wsId in wsKeys)
            _workstationBlock(context, shiftId, wsId, byWs[wsId]!),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _workstationBlock(
    BuildContext context,
    String? shiftId,
    String? workstationId,
    List<ConfirmedShiftPlan> plans,
  ) {
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
                Icon(
                  Icons.desktop_windows_outlined,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  ws?.name ?? context.l10n.unassignedWorkstation,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        for (final p in plans..sort(_byEmployeeName)) _employeeRow(context, p),
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

    return InkWell(
      onTap: () => showEmployeeInsightsSheet(
        context,
        data: data,
        day: day,
        employeeId: plan.employeeId,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 14, 5),
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
                absenceLabel(context.l10n, plan.absenceType),
                theme.colorScheme.error,
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _centeredHint(ThemeData theme, String text) => Center(
  child: Text(
    text,
    style: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.outline,
    ),
  ),
);

Widget _badge(BuildContext context, String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Text(
    text,
    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
  ),
);
