import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/day_insights.dart';
import '../services/shift_data_controller.dart';
import 'detail_list_sheet.dart';

/// The detail sheets behind a tap in the day view: one for a shift, one for a
/// person.
///
/// Both open on what the loaded roster already knows and fill in the
/// `/analysis/*` figures — head count, planned hours per workstation — when
/// they arrive. Those calls may be refused on a tenant that restricts
/// analysis, so nothing here waits on them: the sheet is complete without
/// them and simply says so at the bottom.

/// Opens the detail sheet for [shiftId] on [day]. A null [shiftId] is the
/// bucket of people rostered without a shift, which is worth explaining too.
Future<void> showShiftInsightsSheet(
  BuildContext context, {
  required ShiftDataController data,
  required DateTime day,
  required String? shiftId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _InsightsShell(
      child: _ShiftInsightsBody(data: data, day: day, shiftId: shiftId),
    ),
  );
}

/// Opens the detail sheet for one employee, as seen from [day].
Future<void> showEmployeeInsightsSheet(
  BuildContext context, {
  required ShiftDataController data,
  required DateTime day,
  required String employeeId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _InsightsShell(
      child: _EmployeeInsightsBody(
        data: data,
        day: day,
        employeeId: employeeId,
      ),
    ),
  );
}

/// Caps the sheet at most of the screen and scrolls whatever does not fit.
class _InsightsShell extends StatelessWidget {
  final Widget child;
  const _InsightsShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shift
// ---------------------------------------------------------------------------

class _ShiftInsightsBody extends StatefulWidget {
  final ShiftDataController data;
  final DateTime day;
  final String? shiftId;

  const _ShiftInsightsBody({
    required this.data,
    required this.day,
    required this.shiftId,
  });

  @override
  State<_ShiftInsightsBody> createState() => _ShiftInsightsBodyState();
}

class _ShiftInsightsBodyState extends State<_ShiftInsightsBody> {
  ShiftDataController get data => widget.data;
  DateTime get day => widget.day;
  String? get shiftId => widget.shiftId;

  /// Started once: a fresh future per build would send [FutureBuilder] back
  /// through its waiting state on every rebuild.
  late final Future<DayAnalysis> _analysis = data.analysisForDay(day);

  /// This shift's plans on the day, optionally narrowed to who turned up.
  List<ConfirmedShiftPlan> _plans({bool? present}) => data
      .allPlansForDay(day)
      .where(
        (p) =>
            p.shiftId == shiftId && (present == null || p.isPresent == present),
      )
      .toList();

  /// Opens the people behind one of this sheet's numbers.
  void _showPeople(
    BuildContext context,
    String title, {
    required String subtitle,
    required List<ConfirmedShiftPlan> plans,
    bool showShift = false,
    bool showHours = false,
    Color? accent,
    IconData icon = Icons.groups_outlined,
  }) {
    showDetailListSheet(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      accent: accent,
      entries: peopleEntries(
        context,
        data: data,
        day: day,
        plans: plans,
        showShift: showShift,
        showHours: showHours,
      ),
    );
  }

  /// Everyone who wished for this shift on this day.
  void _showWishes(BuildContext context, ShiftInsight insight) {
    showDetailListSheet(
      context,
      title: insight.shift?.name ?? context.l10n.offNotScheduled,
      subtitle: context.l10n.sectionWishes,
      icon: Icons.star_border_rounded,
      accent: insight.shift?.displayColor,
      entries: _wishEntries(context),
    );
  }

  /// Who worked this shift on one day of the week the sheet is showing.
  void _showWeekDay(BuildContext context, ShiftInsight insight, int weekday) {
    final monday = insight.day.subtract(
      Duration(days: insight.day.weekday - 1),
    );
    final target = monday.add(Duration(days: weekday));
    showDetailListSheet(
      context,
      title: insight.shift?.name ?? context.l10n.offNotScheduled,
      subtitle: DateFormat.yMMMMEEEEd(context.dateLocale).format(target),
      icon: Icons.groups_outlined,
      accent: insight.shift?.displayColor,
      entries: peopleEntries(
        context,
        data: data,
        day: target,
        plans: data
            .allPlansForDay(target)
            .where((p) => p.shiftId == shiftId && p.isPresent)
            .toList(),
      ),
    );
  }

  /// The wishes placed for this shift on this day, each saying whether the
  /// roster honoured it.
  List<DetailEntry> _wishEntries(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final rostered = {for (final p in _plans(present: true)) p.employeeId};
    final wishes = data.wishesForDay(day).where((w) => w.shiftId == shiftId);

    return [
      for (final wish in wishes)
        () {
          final granted = rostered.contains(wish.employeeId);
          return DetailEntry(
            title: data.employeeById(wish.employeeId)?.name ?? wish.employeeId,
            subtitle: granted ? l10n.wishGranted : l10n.wishNotGranted,
            icon: granted ? Icons.star_rounded : Icons.star_border_rounded,
            color: granted
                ? theme.colorScheme.tertiary
                : theme.colorScheme.outline,
            onTap: () => showEmployeeInsightsSheet(
              context,
              data: data,
              day: day,
              employeeId: wish.employeeId,
            ),
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // The roster half renders at once; the analysis half arrives later and
    // only ever adds numbers, so a null snapshot is a complete sheet.
    return FutureBuilder<DayAnalysis>(
      future: _analysis,
      builder: (context, snapshot) {
        final insight = buildShiftInsight(
          data,
          day: day,
          shiftId: shiftId,
          analysis: snapshot.data,
        );
        return _shiftContent(context, insight, waiting: !snapshot.hasData);
      },
    );
  }

  Widget _shiftContent(
    BuildContext context,
    ShiftInsight insight, {
    required bool waiting,
  }) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.dateLocale;
    final color = insight.shift?.displayColor ?? theme.colorScheme.outline;
    final times = insight.times;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 40,
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
                    insight.shift?.name ?? l10n.offNotScheduled,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat.yMMMMEEEEd(locale).format(insight.day),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if ((insight.shift?.shortName ?? '').isNotEmpty)
              _Pill(
                text: insight.shift!.shortName,
                color: color,
                onLongPress: _scheduleLongPress(context, insight.shift),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (times != null)
              _Pill(
                icon: Icons.schedule,
                text: '${times.startTime} – ${times.endTime}',
                color: theme.colorScheme.primary,
                onLongPress: _scheduleLongPress(context, insight.shift),
              )
            else if (insight.shift != null)
              _Pill(
                icon: Icons.event_busy_outlined,
                text: l10n.notScheduledOnWeekday,
                color: theme.colorScheme.outline,
                onLongPress: _scheduleLongPress(context, insight.shift),
              ),
            _coverageChip(context, insight),
            if (times != null && times.freeDaysAfterShift > 0)
              _Pill(
                icon: Icons.bedtime_outlined,
                text: l10n.restDaysAfter(times.freeDaysAfterShift),
                color: theme.colorScheme.outline,
                onLongPress: _scheduleLongPress(context, insight.shift),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _StatRow(
          tiles: [
            _Stat(
              label: l10n.statRostered,
              value: '${insight.rostered}',
              onLongPress: () => _showPeople(
                context,
                insight.shift?.name ?? l10n.offNotScheduled,
                subtitle: l10n.statRostered,
                plans: _plans(),
                accent: color,
              ),
            ),
            _Stat(
              label: l10n.statPresent,
              value: '${insight.present}',
              emphasis: color,
              onLongPress: () => _showPeople(
                context,
                insight.shift?.name ?? l10n.offNotScheduled,
                subtitle: l10n.statPresent,
                plans: _plans(present: true),
                accent: color,
              ),
            ),
            _Stat(
              label: l10n.statAbsent,
              value: '${insight.absent}',
              emphasis: insight.absent > 0 ? theme.colorScheme.error : null,
              onLongPress: () => _showPeople(
                context,
                insight.shift?.name ?? l10n.offNotScheduled,
                subtitle: l10n.statAbsent,
                plans: _plans(present: false),
                accent: theme.colorScheme.error,
                icon: Icons.person_off_outlined,
              ),
            ),
            if (insight.plannedHours > 0)
              _Stat(
                label: l10n.statPlannedHours,
                value: _hours(context, insight.plannedHours),
                onLongPress: () => _showPeople(
                  context,
                  insight.shift?.name ?? l10n.offNotScheduled,
                  subtitle: l10n.statPlannedHours,
                  plans: _plans(present: true),
                  showHours: true,
                  accent: color,
                  icon: Icons.schedule,
                ),
              ),
          ],
        ),
        if (times != null && insight.minRequired > 0) ...[
          const SizedBox(height: 12),
          LongPressTarget(
            onLongPress: _coverageLongPress(context, insight, l10n.statPresent),
            child: _CoverageMeter(insight: insight, color: color),
          ),
        ],
        if (insight.dayTotal > 0) ...[
          const SizedBox(height: 6),
          LongPressTarget(
            onLongPress: () => _showPeople(
              context,
              l10n.detailsEveryoneWorking,
              subtitle: DateFormat.yMMMMEEEEd(locale).format(insight.day),
              plans: data
                  .allPlansForDay(day)
                  .where((p) => p.isPresent)
                  .toList(),
              showShift: true,
            ),
            child: Text(
              '${l10n.dayHeadcount(insight.dayTotal)} · '
              '${l10n.shareOfDay((insight.shareOfDay * 100).round())}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
        if (insight.workstations.isNotEmpty) ...[
          _SectionTitle(
            l10n.sectionWorkstations,
            icon: Icons.desktop_windows_outlined,
          ),
          for (final load in insight.workstations)
            _workstationRow(context, load, color),
        ],
        if (insight.absencesByType.isNotEmpty) ...[
          _SectionTitle(l10n.sectionAbsences, icon: Icons.person_off_outlined),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final entry in insight.absencesByType)
                _Pill(
                  text: '${absenceLabel(l10n, entry.key)} · ${entry.value}',
                  color: theme.colorScheme.error,
                  onLongPress: () => _showPeople(
                    context,
                    absenceLabel(l10n, entry.key),
                    subtitle: insight.shift?.name ?? l10n.offNotScheduled,
                    plans: _plans(present: false)
                        .where((p) => (p.absenceType ?? 'unknown') == entry.key)
                        .toList(),
                    accent: theme.colorScheme.error,
                    icon: Icons.person_off_outlined,
                  ),
                ),
            ],
          ),
        ],
        if (shiftId != null) ...[
          _SectionTitle(l10n.sectionWishes, icon: Icons.star_border_rounded),
          LongPressTarget(
            onLongPress: () => _showWishes(context, insight),
            child: Text(
              l10n.wishesPlaced(insight.wishes),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (insight.wishes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _ProgressLine(
                label: l10n.wishesGrantedOf(
                  insight.wishesGranted,
                  insight.wishes,
                ),
                value: insight.wishesGranted / insight.wishes,
                color: color,
                onLongPress: () => _showWishes(context, insight),
              ),
            ),
        ],
        _SectionTitle(l10n.sectionWeekPattern, icon: Icons.bar_chart),
        _WeekBars(
          counts: insight.weekPattern,
          day: insight.day,
          color: color,
          onLongPressDay: (dayOfWeek) =>
              _showWeekDay(context, insight, dayOfWeek),
        ),
        _SectionTitle(l10n.sectionDayContext, icon: Icons.pie_chart_outline),
        _DaySplit(data: data, day: insight.day, highlightShiftId: shiftId),
        if (waiting || !insight.analysisReachable) ...[
          const SizedBox(height: 14),
          _Footnote(waiting: waiting, text: l10n.analysisUnavailable),
        ],
      ],
    );
  }

  /// A long press that opens [shift]'s week; null for the off bucket, which
  /// has no schedule of its own.
  VoidCallback? _scheduleLongPress(BuildContext context, Shift? shift) {
    if (shift == null) return null;
    return () => showDetailListSheet(
      context,
      title: shift.name,
      subtitle: context.l10n.sectionSchedule,
      icon: Icons.calendar_view_week,
      accent: shift.displayColor,
      entries: scheduleEntries(context, shift),
    );
  }

  /// Whoever is present, behind whichever coverage verdict is on show.
  VoidCallback _coverageLongPress(
    BuildContext context,
    ShiftInsight insight,
    String subtitle,
  ) {
    return () => _showPeople(
      context,
      insight.shift?.name ?? context.l10n.offNotScheduled,
      subtitle: subtitle,
      plans: _plans(present: true),
      accent: insight.shift?.displayColor,
    );
  }

  Widget _coverageChip(BuildContext context, ShiftInsight insight) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    switch (insight.coverage) {
      case Coverage.under:
        return _Pill(
          icon: Icons.trending_down,
          text: l10n.coverageShort(insight.missing),
          color: theme.colorScheme.error,
          onLongPress: _coverageLongPress(
            context,
            insight,
            l10n.detailsMissingPeople(insight.missing),
          ),
        );
      case Coverage.met:
        return _Pill(
          icon: Icons.check_circle_outline,
          text: l10n.coverageMet,
          color: Colors.green.shade700,
          onLongPress: _coverageLongPress(context, insight, l10n.coverageMet),
        );
      case Coverage.over:
        return _Pill(
          icon: Icons.trending_up,
          text: l10n.coverageOver,
          color: theme.colorScheme.tertiary,
          onLongPress: _coverageLongPress(context, insight, l10n.coverageOver),
        );
      case Coverage.unknown:
        return _Pill(
          icon: Icons.help_outline,
          text: l10n.coverageNoTarget,
          color: theme.colorScheme.outline,
          onLongPress: _coverageLongPress(context, insight, l10n.statPresent),
        );
    }
  }

  Widget _workstationRow(
    BuildContext context,
    WorkstationLoad load,
    Color color,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final station = load.station;

    final notes = <String>[
      if (load.plannedEmployees != null &&
          load.plannedEmployees != load.rostered)
        l10n.plannedAllShifts(load.plannedEmployees!),
      if (load.plannedHours != null && load.plannedHours! > 0)
        _hours(context, load.plannedHours!),
      if (station != null && !station.available) l10n.stationUnavailable,
      if (load.understaffed) l10n.stationBelowMinimum(station!.minEmployees),
      if (load.overstaffed) l10n.stationAboveMaximum(station!.maxEmployees!),
      if (station != null && station.priority != 'medium')
        priorityLabel(l10n, station.priority),
    ];

    return LongPressTarget(
      onLongPress: () => _showPeople(
        context,
        load.id == null
            ? l10n.unassignedWorkstation
            : (load.name.isEmpty ? load.id! : load.name),
        subtitle: notes.isEmpty
            ? l10n.detailsAtWorkstation
            : '${l10n.detailsAtWorkstation} · ${notes.join(' · ')}',
        plans: _plans().where((p) => p.workstationId == load.id).toList(),
        accent: color,
        icon: Icons.desktop_windows_outlined,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              load.id == null
                  ? Icons.help_outline
                  : Icons.desktop_windows_outlined,
              size: 18,
              color: load.understaffed
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    load.id == null
                        ? l10n.unassignedWorkstation
                        : (load.name.isEmpty ? load.id! : load.name),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notes.isNotEmpty)
                    Text(
                      notes.join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Pill(text: l10n.peopleHere(load.present), color: color),
          ],
        ),
      ),
    );
  }
}

/// A bar showing how the present head count sits against the weekday minimum,
/// with a tick where the minimum falls.
class _CoverageMeter extends StatelessWidget {
  final ShiftInsight insight;
  final Color color;

  const _CoverageMeter({required this.insight, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final max = insight.maxAllowed;
    // The scale has to hold the minimum, any maximum, and whoever turned up.
    final scale = [
      insight.minRequired,
      max ?? 0,
      insight.present,
      1,
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (insight.present / scale).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: insight.coverage == Coverage.under
                            ? theme.colorScheme.error
                            : color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // The minimum's tick, so a short shift shows the gap.
                  Positioned(
                    left: (width * insight.minRequired / scale).clamp(
                      0.0,
                      width - 2,
                    ),
                    width: 2,
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          max == null
              ? l10n.staffingNeedsMin(insight.minRequired)
              : l10n.staffingNeedsRange(insight.minRequired, max),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Seven bars, Monday to Sunday, with the day the sheet is about picked out.
class _WeekBars extends StatelessWidget {
  final List<int> counts;
  final DateTime day;
  final Color color;

  /// Lists who worked the bar's own day, Monday being 0.
  final void Function(int weekday)? onLongPressDay;

  const _WeekBars({
    required this.counts,
    required this.day,
    required this.color,
    this.onLongPressDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.dateLocale;
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final peak = counts.fold(0, (a, b) => a > b ? a : b);

    // Tall enough for the count, a full-height bar and the weekday label at
    // the text scales a phone actually uses.
    return SizedBox(
      height: 92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < counts.length; i++)
            Expanded(
              child: LongPressTarget(
                onLongPress: onLongPressDay == null
                    ? null
                    : () => onLongPressDay!(i),
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${counts[i]}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: peak == 0 ? 2 : 2 + 40 * counts[i] / peak,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: i == day.weekday - 1 ? 1.0 : 0.35,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.E(
                        locale,
                      ).format(monday.add(Duration(days: i))),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: i == day.weekday - 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// How the day's head count splits across every shift, so one shift can be
/// read against its neighbours.
class _DaySplit extends StatelessWidget {
  final ShiftDataController data;
  final DateTime day;
  final String? highlightShiftId;

  const _DaySplit({
    required this.data,
    required this.day,
    required this.highlightShiftId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final slices = dayShiftSplit(
      data,
      day,
      unassignedLabel: l10n.offNotScheduled,
    );
    if (slices.isEmpty) {
      return Text(
        l10n.nothingRostered,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }
    final peak = slices.fold(0, (a, s) => a > s.count ? a : s.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _ProgressLine(
              label: slice.name,
              trailing: '${slice.count}',
              value: peak == 0 ? 0 : slice.count / peak,
              color:
                  data.shiftById(slice.shiftId)?.displayColor ??
                  theme.colorScheme.outline,
              dim: slice.shiftId != highlightShiftId,
              onLongPress: () => showDetailListSheet(
                context,
                title: slice.name,
                subtitle: l10n.detailsOnThisShift,
                icon: Icons.groups_outlined,
                accent: data.shiftById(slice.shiftId)?.displayColor,
                entries: peopleEntries(
                  context,
                  data: data,
                  day: day,
                  plans: data
                      .allPlansForDay(day)
                      .where((p) => p.shiftId == slice.shiftId && p.isPresent)
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Employee
// ---------------------------------------------------------------------------

class _EmployeeInsightsBody extends StatefulWidget {
  final ShiftDataController data;
  final DateTime day;
  final String employeeId;

  const _EmployeeInsightsBody({
    required this.data,
    required this.day,
    required this.employeeId,
  });

  @override
  State<_EmployeeInsightsBody> createState() => _EmployeeInsightsBodyState();
}

class _EmployeeInsightsBodyState extends State<_EmployeeInsightsBody> {
  ShiftDataController get data => widget.data;
  DateTime get day => widget.day;
  String get employeeId => widget.employeeId;

  /// Started once, for the same reason as the shift sheet's analysis future.
  late final Future<Employee?> _detail = data.employeeDetail(employeeId);

  /// This employee's plans across the loaded range, narrowed the way the tile
  /// that was pressed counted them.
  List<ConfirmedShiftPlan> _rangePlans({
    bool? present,
    String? onShiftId,
    String? absenceType,
  }) => employeePlansInRange(
    data,
    employeeId,
    where: (p) {
      if (present != null && p.isPresent != present) return false;
      if (onShiftId != null && p.shiftId != onShiftId) return false;
      if (absenceType != null && (p.absenceType ?? 'unknown') != absenceType) {
        return false;
      }
      return true;
    },
  );

  /// Opens the days behind one of the range totals.
  void _showDays(
    BuildContext context,
    String subtitle, {
    required List<ConfirmedShiftPlan> plans,
    bool showHours = false,
    Color? accent,
    IconData icon = Icons.calendar_month_outlined,
  }) {
    showDetailListSheet(
      context,
      title: data.employeeById(employeeId)?.name ?? employeeId,
      subtitle: subtitle,
      icon: icon,
      accent: accent,
      entries: dayEntries(
        context,
        data: data,
        plans: plans,
        showHours: showHours,
      ),
    );
  }

  /// Opens the people rostered alongside this employee on [day], narrowed by
  /// [where] to the shift or the workstation that was pressed.
  void _showColleagues(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool Function(ConfirmedShiftPlan plan) where,
    Color? accent,
    IconData icon = Icons.groups_outlined,
    bool showShift = false,
  }) {
    showDetailListSheet(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      accent: accent,
      entries: peopleEntries(
        context,
        data: data,
        day: day,
        plans: data.allPlansForDay(day).where(where).toList(),
        showShift: showShift,
      ),
    );
  }

  /// A long press that opens [shift]'s week.
  VoidCallback? _scheduleLongPress(BuildContext context, Shift? shift) {
    if (shift == null) return null;
    return () => showDetailListSheet(
      context,
      title: shift.name,
      subtitle: context.l10n.sectionSchedule,
      icon: Icons.calendar_view_week,
      accent: shift.displayColor,
      entries: scheduleEntries(context, shift),
    );
  }

  /// Colleagues who hold the same capability, as far as the loaded records
  /// say — the list endpoint may not carry capabilities at all, in which case
  /// only the pressed capability itself is described.
  void _showCapability(BuildContext context, Capability capability) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final others = [
      for (final e in data.employees)
        if (e.id != employeeId &&
            e.capabilities.any((c) => c.id == capability.id))
          e,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDetailListSheet(
      context,
      title: capability.name,
      subtitle: capability.skillGroup == null
          ? l10n.skillLevel(capability.level)
          : l10n.capabilityOfLevel(capability.skillGroup!, capability.level),
      icon: Icons.workspace_premium_outlined,
      accent: theme.colorScheme.secondary,
      emptyText: l10n.noOthersWithCapability,
      entries: [
        for (final other in others)
          DetailEntry(
            title: other.name,
            subtitle: () {
              final held = other.capabilities.firstWhere(
                (c) => c.id == capability.id,
              );
              return held.skillGroup == null
                  ? l10n.skillLevel(held.level)
                  : l10n.capabilityOfLevel(held.skillGroup!, held.level);
            }(),
            icon: Icons.person_outline,
            color: theme.colorScheme.secondary,
            onTap: () => showEmployeeInsightsSheet(
              context,
              data: data,
              day: day,
              employeeId: other.id,
            ),
          ),
      ],
    );
  }

  /// The wishes this employee placed in the loaded range, each with the
  /// outcome the hit rate counted.
  List<DetailEntry> _wishEntries(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.dateLocale;

    return [
      for (final outcome in employeeWishesInRange(data, employeeId))
        DetailEntry(
          title: l10n.detailsOnDay(
            DateFormat.E(locale).format(outcome.wish.date),
            DateFormat.yMMMd(locale).format(outcome.wish.date),
          ),
          subtitle:
              '${data.shiftById(outcome.wish.shiftId)?.name ?? l10n.unknownShift}'
              ' · ${outcome.granted ? l10n.wishGranted : l10n.wishNotGranted}',
          icon: outcome.granted
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          color: outcome.granted
              ? theme.colorScheme.tertiary
              : theme.colorScheme.outline,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // The list entry is enough for everything but capabilities and available
    // shifts, so the sheet renders immediately and those two fill in.
    return FutureBuilder<Employee?>(
      future: _detail,
      builder: (context, snapshot) {
        final insight = buildEmployeeInsight(
          data,
          day: day,
          employeeId: employeeId,
          detail: snapshot.data,
          detailPending: !snapshot.hasData,
        );
        return _employeeContent(context, insight);
      },
    );
  }

  Widget _employeeContent(BuildContext context, EmployeeInsight insight) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.dateLocale;
    final employee = insight.employee;
    final plan = insight.planForDay;
    final shift = data.shiftById(plan?.shiftId);
    final dayFmt = DateFormat.MMMd(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.15,
              ),
              child: Text(
                _initials(employee?.name ?? '?'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee?.name ?? employeeId,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((employee?.email ?? '').isNotEmpty)
                    Text(
                      employee!.email,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _SectionTitle(l10n.sectionOnThisDay, icon: Icons.event_note),
        if (plan == null)
          Text(
            l10n.nothingRostered,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Pill(
                text: shift?.name ?? l10n.offNotScheduled,
                color: shift?.displayColor ?? theme.colorScheme.outline,
                onLongPress: () => _showColleagues(
                  context,
                  title: shift?.name ?? l10n.offNotScheduled,
                  subtitle: l10n.detailsOnThisShift,
                  where: (p) => p.shiftId == plan.shiftId,
                  accent: shift?.displayColor,
                ),
              ),
              if (shift?.timesFor(insight.day) case final times?)
                _Pill(
                  icon: Icons.schedule,
                  text: '${times.startTime} – ${times.endTime}',
                  color: theme.colorScheme.primary,
                  onLongPress: _scheduleLongPress(context, shift),
                ),
              _Pill(
                icon: Icons.desktop_windows_outlined,
                text:
                    data.workstationById(plan.workstationId)?.name ??
                    l10n.unassignedWorkstation,
                color: theme.colorScheme.outline,
                onLongPress: () => _showColleagues(
                  context,
                  title:
                      data.workstationById(plan.workstationId)?.name ??
                      l10n.unassignedWorkstation,
                  subtitle: l10n.detailsAtWorkstation,
                  where: (p) => p.workstationId == plan.workstationId,
                  icon: Icons.desktop_windows_outlined,
                  showShift: true,
                ),
              ),
              if (!plan.isPresent)
                _Pill(
                  icon: Icons.person_off_outlined,
                  text: absenceLabel(l10n, plan.absenceType),
                  color: theme.colorScheme.error,
                  onLongPress: () => _showDays(
                    context,
                    absenceLabel(l10n, plan.absenceType),
                    plans: _rangePlans(
                      present: false,
                      absenceType: plan.absenceType ?? 'unknown',
                    ),
                    accent: theme.colorScheme.error,
                    icon: Icons.person_off_outlined,
                  ),
                ),
            ],
          ),

        _SectionTitle(l10n.sectionRangeTotals, icon: Icons.insights_outlined),
        if (insight.from != null && insight.to != null)
          Text(
            l10n.countedOver(
              dayFmt.format(insight.from!),
              dayFmt.format(insight.to!),
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        const SizedBox(height: 8),
        if (insight.rosteredDays == 0)
          Text(
            l10n.noRosterInRange,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else ...[
          _StatRow(
            tiles: [
              _Stat(
                label: l10n.statDaysRostered,
                value: '${insight.rosteredDays}',
                onLongPress: () => _showDays(
                  context,
                  l10n.statDaysRostered,
                  plans: _rangePlans(),
                ),
              ),
              _Stat(
                label: l10n.statDaysWorked,
                value: '${insight.workedDays}',
                emphasis: theme.colorScheme.primary,
                onLongPress: () => _showDays(
                  context,
                  l10n.statDaysWorked,
                  plans: _rangePlans(present: true),
                  accent: theme.colorScheme.primary,
                ),
              ),
              _Stat(
                label: l10n.statAbsent,
                value: '${insight.absentDays}',
                emphasis: insight.absentDays > 0
                    ? theme.colorScheme.error
                    : null,
                onLongPress: () => _showDays(
                  context,
                  l10n.statAbsent,
                  plans: _rangePlans(present: false),
                  accent: theme.colorScheme.error,
                  icon: Icons.person_off_outlined,
                ),
              ),
              _Stat(
                label: l10n.statPlannedHours,
                value: _hours(context, insight.plannedHours),
                onLongPress: () => _showDays(
                  context,
                  l10n.statPlannedHours,
                  plans: _rangePlans(present: true),
                  showHours: true,
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
          if (insight.monthlyLoad case final load?) ...[
            const SizedBox(height: 10),
            _ProgressLine(
              label: l10n.monthlyHoursTarget(
                _number(context, employee!.monthlyWorkingHours),
              ),
              trailing: l10n.monthlyLoad((load * 100).round()),
              value: load.clamp(0.0, 1.0),
              color: theme.colorScheme.primary,
              onLongPress: () => _showDays(
                context,
                l10n.statPlannedHours,
                plans: _rangePlans(present: true),
                showHours: true,
                accent: theme.colorScheme.primary,
                icon: Icons.schedule,
              ),
            ),
          ],
          if (insight.daysByShift.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final entry in insight.daysByShift)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _ProgressLine(
                  label: data.shiftById(entry.key)?.name ?? l10n.unknownShift,
                  trailing: '${entry.value}',
                  value: entry.value / insight.workedDays.clamp(1, 1 << 30),
                  color:
                      data.shiftById(entry.key)?.displayColor ??
                      theme.colorScheme.outline,
                  onLongPress: () => _showDays(
                    context,
                    data.shiftById(entry.key)?.name ?? l10n.unknownShift,
                    plans: _rangePlans(present: true, onShiftId: entry.key),
                    accent: data.shiftById(entry.key)?.displayColor,
                  ),
                ),
              ),
          ],
          if (insight.absencesByType.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final entry in insight.absencesByType)
                  _Pill(
                    text: '${absenceLabel(l10n, entry.key)} · ${entry.value}',
                    color: theme.colorScheme.error,
                    onLongPress: () => _showDays(
                      context,
                      absenceLabel(l10n, entry.key),
                      plans: _rangePlans(
                        present: false,
                        absenceType: entry.key,
                      ),
                      accent: theme.colorScheme.error,
                      icon: Icons.person_off_outlined,
                    ),
                  ),
              ],
            ),
          ],
          if (insight.wishes > 0) ...[
            const SizedBox(height: 10),
            _ProgressLine(
              label: l10n.sectionWishes,
              trailing: l10n.wishesGrantedOf(
                insight.wishesGranted,
                insight.wishes,
              ),
              value: insight.wishHitRate ?? 0,
              color: theme.colorScheme.tertiary,
              onLongPress: () => showDetailListSheet(
                context,
                title: employee?.name ?? employeeId,
                subtitle: l10n.sectionWishes,
                icon: Icons.star_border_rounded,
                accent: theme.colorScheme.tertiary,
                entries: _wishEntries(context),
              ),
            ),
          ],
        ],

        _SectionTitle(
          l10n.sectionCapabilities,
          icon: Icons.workspace_premium_outlined,
        ),
        if (insight.detailPending)
          const _InlineSpinner()
        else if ((employee?.capabilities ?? const []).isEmpty)
          Text(
            l10n.noCapabilities,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final c in employee!.capabilities)
                _Pill(
                  text: c.skillGroup == null
                      ? c.name
                      : '${c.name} · ${l10n.skillLevel(c.level)}',
                  color: theme.colorScheme.secondary,
                  onLongPress: () => _showCapability(context, c),
                ),
            ],
          ),

        _SectionTitle(l10n.sectionAvailableShifts, icon: Icons.checklist),
        if (insight.detailPending)
          const _InlineSpinner()
        else if ((employee?.availableShifts ?? const []).isEmpty)
          Text(
            l10n.anyShift,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final s in employee!.availableShifts)
                _Pill(
                  text: s.name.isEmpty ? s.shortName : s.name,
                  color: data.shiftById(s.id)?.displayColor ?? s.displayColor,
                  onLongPress: _scheduleLongPress(
                    context,
                    data.shiftById(s.id) ?? s,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Up to two initials for the avatar; '?' when the name is unknown.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }
}

// ---------------------------------------------------------------------------
// Small shared pieces
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionTitle(this.text, {required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;

  /// Colours the number when it is the one worth looking at.
  final Color? emphasis;

  /// Lists the rows the number was counted from.
  final VoidCallback? onLongPress;

  const _Stat({
    required this.label,
    required this.value,
    this.emphasis,
    this.onLongPress,
  });
}

/// The tiles wrap rather than shrink, so four of them survive a narrow phone.
class _StatRow extends StatelessWidget {
  final List<_Stat> tiles;
  const _StatRow({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two per row on a narrow sheet, all in one row when there is room.
        final perRow = constraints.maxWidth < 340 ? 2 : tiles.length;
        final width = (constraints.maxWidth - 8 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: LongPressTarget(
                  onLongPress: tile.onLongPress,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tile.value,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tile.emphasis,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tile.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A labelled bar: the label on the left, an optional value on the right, and
/// the bar underneath.
class _ProgressLine extends StatelessWidget {
  final String label;
  final String? trailing;
  final double value;
  final Color color;

  /// Fades the whole line, for rows that are context rather than the subject.
  final bool dim;

  /// Lists what the bar is measuring.
  final VoidCallback? onLongPress;

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
    this.dim = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dim ? 0.6 : 1,
      child: LongPressTarget(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.isFinite ? value.clamp(0.0, 1.0) : 0,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tinted rounded label, with an optional leading icon.
class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  /// Lists what the pill summarises.
  final VoidCallback? onLongPress;

  const _Pill({
    required this.text,
    required this.color,
    this.icon,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressTarget(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSpinner extends StatelessWidget {
  const _InlineSpinner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

/// The line at the bottom that explains why the server figures are missing —
/// a spinner while they are still coming, the reason once they are not.
class _Footnote extends StatelessWidget {
  final bool waiting;
  final String text;

  const _Footnote({required this.waiting, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (waiting)
          const _InlineSpinner()
        else
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            waiting ? '' : text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

/// `12.5 h` in the current locale, trimming a trailing `.0`.
String _hours(BuildContext context, double value) =>
    context.l10n.hoursValue(_number(context, value));

String _number(BuildContext context, double value) =>
    NumberFormat.decimalPattern(
      context.dateLocale,
    ).format(double.parse(value.toStringAsFixed(1)));
