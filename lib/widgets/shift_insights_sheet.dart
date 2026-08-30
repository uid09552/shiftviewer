import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/day_insights.dart';
import '../services/shift_data_controller.dart';

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
              _Pill(text: insight.shift!.shortName, color: color),
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
              )
            else if (insight.shift != null)
              _Pill(
                icon: Icons.event_busy_outlined,
                text: l10n.notScheduledOnWeekday,
                color: theme.colorScheme.outline,
              ),
            _coverageChip(context, insight),
            if (times != null && times.freeDaysAfterShift > 0)
              _Pill(
                icon: Icons.bedtime_outlined,
                text: l10n.restDaysAfter(times.freeDaysAfterShift),
                color: theme.colorScheme.outline,
              ),
          ],
        ),
        const SizedBox(height: 14),
        _StatRow(
          tiles: [
            _Stat(label: l10n.statRostered, value: '${insight.rostered}'),
            _Stat(
              label: l10n.statPresent,
              value: '${insight.present}',
              emphasis: color,
            ),
            _Stat(
              label: l10n.statAbsent,
              value: '${insight.absent}',
              emphasis: insight.absent > 0 ? theme.colorScheme.error : null,
            ),
            if (insight.plannedHours > 0)
              _Stat(
                label: l10n.statPlannedHours,
                value: _hours(context, insight.plannedHours),
              ),
          ],
        ),
        if (times != null && insight.minRequired > 0) ...[
          const SizedBox(height: 12),
          _CoverageMeter(insight: insight, color: color),
        ],
        if (insight.dayTotal > 0) ...[
          const SizedBox(height: 6),
          Text(
            '${l10n.dayHeadcount(insight.dayTotal)} · '
            '${l10n.shareOfDay((insight.shareOfDay * 100).round())}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
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
                ),
            ],
          ),
        ],
        if (shiftId != null) ...[
          _SectionTitle(l10n.sectionWishes, icon: Icons.star_border_rounded),
          Text(
            l10n.wishesPlaced(insight.wishes),
            style: theme.textTheme.bodyMedium,
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
              ),
            ),
        ],
        _SectionTitle(l10n.sectionWeekPattern, icon: Icons.bar_chart),
        _WeekBars(counts: insight.weekPattern, day: insight.day, color: color),
        _SectionTitle(l10n.sectionDayContext, icon: Icons.pie_chart_outline),
        _DaySplit(data: data, day: insight.day, highlightShiftId: shiftId),
        if (waiting || !insight.analysisReachable) ...[
          const SizedBox(height: 14),
          _Footnote(waiting: waiting, text: l10n.analysisUnavailable),
        ],
      ],
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
        );
      case Coverage.met:
        return _Pill(
          icon: Icons.check_circle_outline,
          text: l10n.coverageMet,
          color: Colors.green.shade700,
        );
      case Coverage.over:
        return _Pill(
          icon: Icons.trending_up,
          text: l10n.coverageOver,
          color: theme.colorScheme.tertiary,
        );
      case Coverage.unknown:
        return _Pill(
          icon: Icons.help_outline,
          text: l10n.coverageNoTarget,
          color: theme.colorScheme.outline,
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

    return Padding(
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

  const _WeekBars({
    required this.counts,
    required this.day,
    required this.color,
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
                    DateFormat.E(locale).format(monday.add(Duration(days: i))),
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
              ),
              if (shift?.timesFor(insight.day) case final times?)
                _Pill(
                  icon: Icons.schedule,
                  text: '${times.startTime} – ${times.endTime}',
                  color: theme.colorScheme.primary,
                ),
              _Pill(
                icon: Icons.desktop_windows_outlined,
                text:
                    data.workstationById(plan.workstationId)?.name ??
                    l10n.unassignedWorkstation,
                color: theme.colorScheme.outline,
              ),
              if (!plan.isPresent)
                _Pill(
                  icon: Icons.person_off_outlined,
                  text: absenceLabel(l10n, plan.absenceType),
                  color: theme.colorScheme.error,
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
              ),
              _Stat(
                label: l10n.statDaysWorked,
                value: '${insight.workedDays}',
                emphasis: theme.colorScheme.primary,
              ),
              _Stat(
                label: l10n.statAbsent,
                value: '${insight.absentDays}',
                emphasis: insight.absentDays > 0
                    ? theme.colorScheme.error
                    : null,
              ),
              _Stat(
                label: l10n.statPlannedHours,
                value: _hours(context, insight.plannedHours),
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

  const _Stat({required this.label, required this.value, this.emphasis});
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
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

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dim ? 0.6 : 1,
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
    );
  }
}

/// A tinted rounded label, with an optional leading icon.
class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Pill({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
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
