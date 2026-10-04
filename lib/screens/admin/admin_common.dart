import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../services/admin_api.dart';
import '../../services/api_client.dart';
import '../../services/shift_data_controller.dart';

/// Shared plumbing for the management screens: one API wrapper per screen,
/// uniform loading/error states, confirmations and small form pieces.

/// Opens an [AdminApi] on the current session. The owning state closes it.
AdminApi openAdminApi(BuildContext context) =>
    AdminApi(context.read<ShiftDataController>().createClient());

/// Gives a screen its own [AdminApi], opened on first use and closed with the
/// screen. Opening lazily keeps a screen that never called out from reaching
/// for its context while it is being torn down.
mixin AdminApiState<T extends StatefulWidget> on State<T> {
  AdminApi? _adminApi;

  AdminApi get api => _adminApi ??= openAdminApi(context);

  @override
  void dispose() {
    _adminApi?.close();
    super.dispose();
  }
}

/// A failed call as one line for a snackbar or an error panel: the server's
/// own reason when it gave one, with the status code.
String adminErrorText(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    final code = error.statusCode;
    if (code == 403) return l10n.adminForbidden;
    return code == null ? error.message : l10n.errorWithCode(error.message, code);
  }
  return '$error';
}

void showAdminError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(adminErrorText(context.l10n, error))),
  );
}

void showAdminMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Asks before something destructive. Resolves to true only on "confirm".
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = true,
}) async {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? l10n.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Loading spinner, error with retry, or the content — the three states every
/// management list goes through.
class AdminLoadState extends StatelessWidget {
  final bool loading;
  final Object? error;
  final VoidCallback onRetry;
  final Widget Function() builder;

  const AdminLoadState({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final err = error;
    if (err != null) {
      final l10n = context.l10n;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(adminErrorText(l10n, err), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (loading) return const Center(child: CircularProgressIndicator());
    return builder();
  }
}

/// A centred hint for a list with nothing in it.
class AdminEmpty extends StatelessWidget {
  final String text;
  final IconData icon;

  const AdminEmpty(this.text, {super.key, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: muted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: muted)),
          ],
        ),
      ),
    );
  }
}

/// A section heading inside a form or a list.
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AdminSectionHeader(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A small filled circle in a shift's colour.
class ColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const ColorDot(this.color, {super.key, this.size = 12});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Picks an inclusive date range with the platform picker, starting on
/// [initial] when given.
Future<DateTimeRange?> pickDateRange(
  BuildContext context, {
  DateTimeRange? initial,
}) {
  final now = DateTime.now();
  return showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year - 3),
    lastDate: DateTime(now.year + 3, 12, 31),
    initialDateRange: initial,
  );
}

/// "Mar 3 – Mar 9, 2026", in the app's language.
String formatRange(BuildContext context, DateTime from, DateTime to) {
  final locale = context.dateLocale;
  final f = DateFormat.yMMMd(locale);
  if (from == to) return f.format(from);
  final short = DateFormat.MMMd(locale);
  return from.year == to.year
      ? '${short.format(from)} – ${f.format(to)}'
      : '${f.format(from)} – ${f.format(to)}';
}

/// Every day of [from]..[to], inclusive.
List<DateTime> daysBetween(DateTime from, DateTime to) {
  final out = <DateTime>[];
  for (var d = dateKey(from); !d.isAfter(dateKey(to)); d = DateTime(d.year, d.month, d.day + 1)) {
    out.add(d);
  }
  return out;
}

/// An integer field with − / + buttons, clamped to [min]..[max].
class IntStepper extends StatelessWidget {
  final String label;
  final String? hint;
  final int value;
  final int min;
  final int max;
  final String Function(int)? format;
  final ValueChanged<int> onChanged;

  const IntStepper({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    this.min = 0,
    this.max = 999,
    this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label),
      subtitle: hint == null ? null : Text(hint!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48),
            child: Text(
              format?.call(value) ?? '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
