import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/calendar_export.dart';
import '../services/calendar_handoff.dart';
import '../services/shift_data_controller.dart';

/// How many entries the sheet lists before collapsing the rest into a count.
const _previewLimit = 6;

/// Opens the calendar export for every confirmed shift between [from] and [to],
/// scoped to the employee the calendar is currently showing, and reports the
/// outcome in a snack bar.
///
/// A range always leaves as an `.ics` file — Google's link format carries a
/// single event — while a range holding exactly one shift is also offered the
/// direct route into Google Calendar.
///
/// [service] is for tests; production builds the real one, which talks to the
/// platform's launcher and share sheet.
Future<void> showCalendarExportSheet(
  BuildContext context, {
  required ShiftDataController data,
  required DateTime from,
  required DateTime to,
  CalendarHandoffService? service,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final selection = buildCalendarEntries(
    data,
    from: from,
    to: to,
    employeeId: data.selectedEmployeeId,
  );
  if (selection.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.calendarExportEmpty)));
    return;
  }

  final outcome = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CalendarExportSheet(
      selection: selection,
      from: from,
      to: to,
      who: data.selectedEmployee?.name ?? l10n.allEmployees,
      service: service ?? CalendarHandoffService(),
    ),
  );
  if (outcome != null && outcome.isNotEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(outcome)));
  }
}

/// Sends a single confirmed shift straight to Google Calendar, falling back to
/// a one-event `.ics` when nothing on the device opens the link. Reports the
/// outcome in a snack bar.
Future<void> addPlanToCalendar(
  BuildContext context, {
  required ShiftDataController data,
  required ConfirmedShiftPlan plan,
  required DateTime day,
  CalendarHandoffService? service,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final selection = buildCalendarEntries(
    data,
    from: day,
    to: day,
    employeeId: plan.employeeId,
  );
  CalendarEntry? entry;
  for (final e in selection.entries) {
    if (e.planId == plan.id) entry = e;
  }
  if (entry == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.calendarExportEmpty)));
    return;
  }

  final result = await (service ?? CalendarHandoffService())
      .addToGoogleCalendar(entry);
  messenger.showSnackBar(
      SnackBar(content: Text(calendarHandoffText(l10n, result))));
}

/// Turns a handoff outcome into a sentence in the current language.
String calendarHandoffText(
    AppLocalizations l10n, CalendarHandoffResult result) {
  switch (result.outcome) {
    case CalendarHandoff.google:
      return l10n.calendarOpenedGoogle;
    case CalendarHandoff.icsFile:
      return l10n.calendarIcsReady(result.count, result.fileName ?? '');
    case CalendarHandoff.dismissed:
      return l10n.calendarExportDismissed;
    case CalendarHandoff.empty:
      return l10n.calendarExportEmpty;
    case CalendarHandoff.failed:
      return l10n.calendarExportFailed(result.detail ?? '');
  }
}

/// Shows what would be exported and offers the two routes into a calendar.
class _CalendarExportSheet extends StatefulWidget {
  final CalendarExportSelection selection;
  final DateTime from;
  final DateTime to;

  /// Employee name, or the "all employees" label.
  final String who;
  final CalendarHandoffService service;

  const _CalendarExportSheet({
    required this.selection,
    required this.from,
    required this.to,
    required this.who,
    required this.service,
  });

  @override
  State<_CalendarExportSheet> createState() => _CalendarExportSheetState();
}

class _CalendarExportSheetState extends State<_CalendarExportSheet> {
  /// Set while a handoff is in flight, so neither route can be double tapped.
  bool _busy = false;

  List<CalendarEntry> get _entries => widget.selection.entries;

  /// The single shift, when the range holds exactly one — the only case where
  /// the direct Google Calendar link can carry the whole selection.
  CalendarEntry? get _lone => _entries.length == 1 ? _entries.first : null;

  Future<void> _run(
      Future<CalendarHandoffResult> Function() handoff) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final result = await handoff();
    if (!mounted) return;
    Navigator.of(context).pop(calendarHandoffText(l10n, result));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.dateLocale;
    final dayFmt = DateFormat.MMMd(locale);
    final lone = _lone;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_available, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.calendarExportTitle,
                      style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.calendarExportSubtitle(
                widget.who,
                dayFmt.format(widget.from),
                dayFmt.format(widget.to),
              ),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            Text(l10n.calendarExportCount(widget.selection.length),
                style: theme.textTheme.titleSmall),
            if (widget.selection.absences > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l10n.calendarExportAbsences(widget.selection.absences),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(child: _preview(context, locale)),
            const SizedBox(height: 16),
            if (lone != null) ...[
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() => widget.service.addToGoogleCalendar(lone)),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.addToGoogleCalendar),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(
                  l10n.calendarGoogleHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            ],
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() => widget.service.exportIcs(
                        widget.selection,
                        calendarName: widget.who,
                      )),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(kIsWeb ? Icons.download : Icons.ios_share),
              label: Text(
                  kIsWeb ? l10n.calendarDownloadIcs : l10n.calendarShareIcs),
            ),
            const SizedBox(height: 6),
            Text(
              kIsWeb ? l10n.calendarIcsHintWeb : l10n.calendarIcsHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  /// The first few shifts, so the user can see what they are about to import.
  Widget _preview(BuildContext context, String locale) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final shown = _entries.take(_previewLimit).toList();
    final rest = _entries.length - shown.length;
    final dateFmt = DateFormat.MMMEd(locale);
    final timeFmt = DateFormat.Hm(locale);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: parseHexColor(e.colorHex),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: Text(dateFmt.format(e.day),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: Text(e.title,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    e.allDay
                        ? l10n.calendarAllDay
                        : '${timeFmt.format(e.start)}–${timeFmt.format(e.end)}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          if (rest > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.calendarExportMore(rest),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
        ],
      ),
    );
  }
}
