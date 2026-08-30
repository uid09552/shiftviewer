import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';
import '../models/models.dart';

/// Short label for the tenant's wish window: open, a date range, or off.
///
/// A `date_range` window missing one of its bounds cannot be satisfied by the
/// server either, so it reads as deactivated rather than as a range.
String wishModeLabel(BuildContext context, WishSettings settings) {
  final l10n = context.l10n;
  if (!settings.isOpen) return l10n.wishModeDisabled;
  switch (settings.mode) {
    case WishMode.enabled:
      return l10n.wishModeOpen;
    case WishMode.dateRange:
      final fmt = DateFormat.yMMMd(context.dateLocale);
      return l10n.wishModeRange(
          fmt.format(settings.windowStart!), fmt.format(settings.windowEnd!));
    case WishMode.disabled:
      return l10n.wishModeDisabled;
  }
}

/// The same state as a full sentence, for places with room to explain.
String wishWindowDetail(BuildContext context, WishSettings settings) {
  final l10n = context.l10n;
  if (!settings.isOpen) return l10n.wishWindowClosedDetail;
  switch (settings.mode) {
    case WishMode.enabled:
      return l10n.wishWindowOpenDetail;
    case WishMode.dateRange:
      final fmt = DateFormat.yMMMd(context.dateLocale);
      return l10n.wishWindowRangeDetail(
          fmt.format(settings.windowStart!), fmt.format(settings.windowEnd!));
    case WishMode.disabled:
      return l10n.wishWindowClosedDetail;
  }
}

/// Icon and colour standing for a wish window state, so the three cases stay
/// recognisable wherever the status is shown.
({IconData icon, Color color}) _style(
    BuildContext context, WishSettings settings) {
  final scheme = Theme.of(context).colorScheme;
  if (!settings.isOpen) {
    return (icon: Icons.lock_outline_rounded, color: scheme.error);
  }
  return switch (settings.mode) {
    WishMode.enabled => (icon: Icons.lock_open_rounded, color: scheme.primary),
    WishMode.dateRange => (
        icon: Icons.date_range_rounded,
        color: scheme.tertiary
      ),
    WishMode.disabled => (icon: Icons.lock_outline_rounded, color: scheme.error),
  };
}

/// Badge telling the user whether wishes are open, limited to a date range, or
/// deactivated — the one thing that decides whether the rest of the wish UI
/// does anything.
class WishWindowChip extends StatelessWidget {
  final WishSettings settings;

  const WishWindowChip({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _style(context, settings);
    return Tooltip(
      message: wishWindowDetail(context, settings),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 14, color: style.color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                wishModeLabel(context, settings),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: style.color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wish window spelled out on one line, for the wish sheet and any other
/// place where the badge alone would leave the user guessing.
class WishWindowNotice extends StatelessWidget {
  final WishSettings settings;

  const WishWindowNotice({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _style(context, settings);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, size: 16, color: style.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              wishWindowDetail(context, settings),
              style: theme.textTheme.bodySmall?.copyWith(color: style.color),
            ),
          ),
        ],
      ),
    );
  }
}
