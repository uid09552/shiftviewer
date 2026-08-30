import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/shift_data_controller.dart';
import 'wish_window_status.dart';

/// How far a wish edit reaches beyond the days the user picked.
enum WishScope {
  /// Exactly the days handed to the sheet.
  selection,

  /// The whole Mon–Sun week the first picked day falls in.
  week,

  /// The whole calendar month the first picked day falls in.
  month,
}

/// Opens the shift wish editor for [days] and reports the outcome in a snack
/// bar. Wishes belong to an employee, so one has to be selected first, and the
/// tenant's wish window has to cover at least one of the days.
///
/// Pass a single day for the plain case; painting several days in a calendar
/// passes all of them, and the sheet can widen that to the week or month.
Future<void> showShiftWishSheet(
  BuildContext context, {
  required Iterable<DateTime> days,
  required ShiftDataController data,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  if (data.selectedEmployeeId == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.wishPickEmployeeFirst)));
    return;
  }
  if (data.wishableShifts.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.wishNoShiftsAvailable)));
    return;
  }
  final picked = {for (final d in days) dateKey(d)}.toList()..sort();
  if (picked.isEmpty) return;
  // With the window shut — or shut for every day picked — there is nothing the
  // sheet could offer, so say why instead of opening an inert editor.
  if (!picked.any(data.canWishOn)) {
    messenger.showSnackBar(
        SnackBar(content: Text(wishWindowDetail(context, data.wishSettings))));
    return;
  }

  final outcome = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ShiftWishSheet(days: picked, data: data),
  );
  if (outcome != null && outcome.isNotEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(outcome)));
  }
}

/// Withdraws [wish] and reports the outcome in a snack bar. Used by the wish
/// planner, where a wish can be dropped without opening the editor.
Future<void> withdrawShiftWish(
  BuildContext context, {
  required ShiftWish wish,
  required ShiftDataController data,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  if (!data.canWishOn(wish.date)) {
    messenger.showSnackBar(
        SnackBar(content: Text(wishWindowDetail(context, data.wishSettings))));
    return;
  }
  final result = await data.removeWishes([wish.date]);
  messenger.showSnackBar(SnackBar(
    content: Text(result.failure == null
        ? l10n.wishBatchRemoved(result.applied)
        : failureText(l10n, result.failure!)),
  ));
}

/// Lets the selected employee wish for one shift across one or more days: pick
/// how wide the edit should reach, then a shift to place — or withdraw every
/// wish in reach.
class _ShiftWishSheet extends StatefulWidget {
  /// Normalised, sorted and non-empty.
  final List<DateTime> days;
  final ShiftDataController data;

  const _ShiftWishSheet({required this.days, required this.data});

  @override
  State<_ShiftWishSheet> createState() => _ShiftWishSheetState();
}

class _ShiftWishSheetState extends State<_ShiftWishSheet> {
  /// Set while a request is in flight, so the sheet cannot be double submitted.
  bool _busy = false;

  WishScope _scope = WishScope.selection;

  /// The day the wider scopes are measured from.
  DateTime get _anchor => widget.days.first;

  /// Every day the current scope covers, in order.
  List<DateTime> get _scopeDays {
    switch (_scope) {
      case WishScope.selection:
        return widget.days;
      case WishScope.week:
        final start = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        return [
          for (int i = 0; i < 7; i++)
            DateTime(start.year, start.month, start.day + i),
        ];
      case WishScope.month:
        final days = DateTime(_anchor.year, _anchor.month + 1, 0).day;
        return [
          for (int d = 1; d <= days; d++)
            DateTime(_anchor.year, _anchor.month, d),
        ];
    }
  }

  /// The days in scope the wish window actually accepts — the only ones any
  /// button here can change.
  List<DateTime> get _allowedDays =>
      _scopeDays.where(widget.data.canWishOn).toList();

  /// The shift wished for on *every* day in scope, if they agree on one.
  String? get _uniformShiftId {
    String? shiftId;
    for (final day in _allowedDays) {
      final wish = widget.data.wishForDay(day);
      if (wish == null) return null;
      if (shiftId != null && shiftId != wish.shiftId) return null;
      shiftId = wish.shiftId;
    }
    return shiftId;
  }

  /// How many days in scope carry a wish that may still be withdrawn.
  int get _wishedInScope => _allowedDays
      .where((d) => widget.data.wishForDay(d) != null)
      .length;

  Future<void> _place(Shift shift) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final result = await widget.data.placeWishes(_scopeDays, shift.id);
    if (!mounted) return;
    Navigator.of(context).pop(_describe(l10n, result, shift: shift));
  }

  Future<void> _withdraw() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final result = await widget.data.removeWishes(_scopeDays);
    if (!mounted) return;
    Navigator.of(context).pop(_describe(l10n, result));
  }

  /// One sentence covering what was written, what was left out and what broke.
  String _describe(AppLocalizations l10n, WishBatchResult result,
      {Shift? shift}) {
    final parts = <String>[
      shift == null
          ? l10n.wishBatchRemoved(result.applied)
          : l10n.wishBatchPlaced(result.applied, shift.name),
      if (result.skipped > 0) l10n.wishBatchSkipped(result.skipped),
      if (result.blocked > 0) l10n.wishBatchBlocked(result.blocked),
      if (result.failure != null) failureText(l10n, result.failure!),
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final employee = widget.data.selectedEmployee;
    final uniformShiftId = _uniformShiftId;
    final scopeDays = _scopeDays;
    final allowedDays = _allowedDays;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.shiftWish,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (employee != null) ...[
              const SizedBox(height: 2),
              Text(employee.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
            const SizedBox(height: 12),
            // Only worth the room when the window narrows what the buttons
            // below can do; a plain "enabled" needs no explanation.
            if (widget.data.wishSettings.mode != WishMode.enabled) ...[
              WishWindowNotice(settings: widget.data.wishSettings),
              const SizedBox(height: 12),
            ],
            _scopePicker(context),
            const SizedBox(height: 6),
            // Spelling out the dates keeps a month-wide edit from being a
            // surprise.
            Text(
              _scopeSummary(context, scopeDays),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.wishDisclaimer,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final shift in widget.data.wishableShifts)
                      _shiftTile(context, shift, allowedDays, scopeDays.length,
                          shift.id == uniformShiftId),
                  ],
                ),
              ),
            ),
            if (_wishedInScope > 0) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : _withdraw,
                icon: const Icon(Icons.star_border_rounded, size: 18),
                label: Text(l10n.removeWishCount(_wishedInScope)),
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The "take it for the whole week" proposal: widen the edit from the picked
  /// days to the week or the month around them.
  Widget _scopePicker(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<WishScope>(
        showSelectedIcon: false,
        selected: {_scope},
        onSelectionChanged:
            _busy ? null : (s) => setState(() => _scope = s.first),
        segments: [
          ButtonSegment(
            value: WishScope.selection,
            label: Text(widget.days.length == 1
                ? l10n.scopeDay
                : l10n.scopeSelection(widget.days.length)),
          ),
          ButtonSegment(value: WishScope.week, label: Text(l10n.scopeWeek)),
          ButtonSegment(value: WishScope.month, label: Text(l10n.scopeMonth)),
        ],
      ),
    );
  }

  /// The dates the current scope resolves to, in words.
  String _scopeSummary(BuildContext context, List<DateTime> days) {
    final locale = context.dateLocale;
    switch (_scope) {
      case WishScope.selection:
        if (days.length == 1) {
          return DateFormat.yMMMMEEEEd(locale).format(days.first);
        }
        return context.l10n.dayRange(
          DateFormat.MMMEd(locale).format(days.first),
          DateFormat.MMMEd(locale).format(days.last),
        );
      case WishScope.week:
        return context.l10n.dayRange(
          DateFormat.MMMEd(locale).format(days.first),
          DateFormat.MMMEd(locale).format(days.last),
        );
      case WishScope.month:
        return DateFormat.yMMMM(locale).format(_anchor);
    }
  }

  /// One shift the scope can be filled with. [allowedDays] are the days of the
  /// scope the wish window accepts; [scopeSize] is the whole scope, so the
  /// subtitle can say how much of it the tile would really cover.
  Widget _shiftTile(BuildContext context, Shift shift,
      List<DateTime> allowedDays, int scopeSize, bool selected) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final color = shift.displayColor;
    // A shift can only be wished for on the weekdays it actually runs, and only
    // inside the wish window, so say up front how much of the scope is left.
    final matching = allowedDays.where((d) => shift.timesFor(d) != null).length;
    final enabled = !_busy && matching > 0;

    final String subtitle;
    if (scopeSize == 1) {
      if (allowedDays.isEmpty) {
        subtitle = l10n.wishOutsideWindow;
      } else {
        final times = shift.timesFor(allowedDays.first);
        subtitle = times == null
            ? l10n.notScheduledOnWeekday
            : '${times.startTime} – ${times.endTime}';
      }
    } else {
      subtitle = l10n.shiftRunsOnDays(matching, scopeSize);
    }

    return Opacity(
      opacity: matching > 0 ? 1 : 0.5,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 3),
        color: selected
            ? color.withValues(alpha: 0.14)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? color : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? () => _place(shift) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shift.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 20,
                  color: selected ? color : theme.colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
