import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_helpers.dart';
import '../../models/models.dart';
import 'admin_common.dart';

/// The public holidays of the tenant's configured state, month by month, with
/// a way to re-fetch them from the holiday API — `GET /holidays` and
/// `POST /holidays/sync`.
///
/// Read-only beyond the sync button: holidays come from an external source,
/// not from anything this app writes.
class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen>
    with AdminApiState<HolidaysScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  HolidayCalendar? _calendar;
  bool _loading = true;
  bool _syncing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) get _range {
    final from = _month;
    final to = DateTime(_month.year, _month.month + 1, 0);
    return (from, to);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (from, to) = _range;
      final calendar = await api.holidays(from, to);
      if (mounted) setState(() => _calendar = calendar);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await api.syncHolidays(year: _month.year);
      if (!mounted) return;
      showAdminMessage(context, context.l10n.admHolidaysSynced);
      await _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calendar = _calendar;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.admHolidays)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _loading ? null : () => _shiftMonth(-1),
                ),
                Expanded(
                  child: Text(
                    DateFormat.yMMMM(context.dateLocale).format(_month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _loading ? null : () => _shiftMonth(1),
                ),
              ],
            ),
          ),
          if (calendar != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      calendar.enabled
                          ? l10n.admHolidaysIntro
                          : l10n.admHolidaysDisabled,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _syncing ? null : _sync,
                    icon: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(l10n.admSyncHolidays),
                  ),
                ],
              ),
            ),
          Expanded(
            child: AdminLoadState(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () {
                final holidays = [...calendar?.holidays ?? const []]
                  ..sort((a, b) => a.date.compareTo(b.date));
                if (holidays.isEmpty) {
                  return AdminEmpty(l10n.admHolidaysEmpty,
                      icon: Icons.celebration_outlined);
                }
                return ListView.separated(
                  itemCount: holidays.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final h = holidays[i];
                    return ListTile(
                      leading: const Icon(Icons.celebration_outlined),
                      title: Text(h.name),
                      subtitle: Text(
                          DateFormat.yMMMMEEEEd(context.dateLocale)
                              .format(h.date)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
