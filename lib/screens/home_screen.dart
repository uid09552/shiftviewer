import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../models/models.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/iso_week.dart';
import '../services/shift_data_controller.dart';
import '../widgets/calendar_export_sheet.dart';
import '../widgets/day_detail.dart';
import '../widgets/day_legend.dart';
import '../widgets/month_view.dart';
import '../widgets/resizable_pane.dart';
import '../widgets/shift_wish_sheet.dart';
import '../widgets/week_view.dart';
import '../widgets/wish_planner_view.dart';
import 'admin/management_screen.dart';
import 'settings_screen.dart';

/// The views the bottom bar switches between. Exactly one fills the body at a
/// time — the panes are gone, so each view gets the whole screen.
enum HomeView { day, week, month, wishes }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// The day view opens first: after signing in the question is almost always
  /// "what am I working today", and the calendars are one tap away.
  HomeView _view = HomeView.day;

  /// Day the month/week views are derived from. The day view steers it too, so
  /// switching back to the calendar lands on the month you were reading.
  DateTime _anchor = DateTime.now();
  DateTime _selectedDay = dateKey(DateTime.now());
  String _lastSettingsKey = '';
  bool _preselectDone = false;

  /// Height the user dragged the day view's summary pane to; null means the
  /// pane sizes itself to its content. It is the requested value —
  /// [_summaryFor] clamps it to what currently fits.
  double? _summaryHeight;

  /// Height available to the day view's two panes, captured during layout so
  /// the drag handler can clamp against it.
  double _paneArea = 0;

  /// Fling speed (logical px/s) that counts as a day-changing swipe.
  static const double _swipeMinVelocity = 300;

  final GlobalKey _summaryKey = GlobalKey();

  static const double _minSummary = 56;
  static const double _minList = 120;
  static const double _defaultSummaryShare = 0.34;

  /// Ceiling on the legend under the month/week calendars.
  static const double _maxLegendShare = 0.45;

  /// The calendar day the screen last knew to be today, so a rollover while
  /// the app was open or backgrounded can be told from "same day".
  DateTime _today = dateKey(DateTime.now());
  Timer? _midnightTimer;

  /// Data older than this is reloaded when the app comes back to the
  /// foreground; the roster can change while it sits in a pocket.
  static const Duration _staleAfter = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
    // Load once settings are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final rolledOver = _rolloverIfNewDay();
    final updated = context.read<ShiftDataController>().lastUpdated;
    final stale =
        updated == null || DateTime.now().difference(updated) > _staleAfter;
    if (rolledOver || stale) _maybeRefresh();
    _scheduleMidnight();
  }

  /// A timer can sleep through midnight while the app is backgrounded, so this
  /// is re-armed on resume as well.
  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_rolloverIfNewDay()) _maybeRefresh();
      _scheduleMidnight();
    });
  }

  /// When the date has changed since the screen last looked, moves the view
  /// on to the new "today" — but only if it was showing the old one; someone
  /// who deliberately browsed elsewhere stays where they are. Returns whether
  /// the date changed.
  bool _rolloverIfNewDay() {
    final today = dateKey(DateTime.now());
    if (today == _today) return false;
    final previous = _today;
    _today = today;
    if (_selectedDay == previous) {
      setState(() {
        _selectedDay = today;
        _anchor = today;
      });
    } else {
      // Still redraw: "today" highlighting in the calendars has moved.
      setState(() {});
    }
    return true;
  }

  /// Keeps the data controller aligned with the latest settings, then reloads
  /// the currently visible range.
  Future<void> _maybeRefresh() async {
    final settings = context.read<SettingsController>().settings;
    final data = context.read<ShiftDataController>();
    data.updateSettings(settings);
    // No token is fetched here: every request asks the auth layer for one and
    // gets a renewed token when the old one has run out.
    data.updateTokenProvider(context.read<AuthController>().validAccessToken);
    final range = _visibleRange();
    await data.refresh(range.$1, range.$2);
    if (mounted) _maybePreselectEmployee();
  }

  /// Once employees are loaded, preselect the one whose email matches the
  /// signed-in user's token email. Runs at most once; the user can change it.
  void _maybePreselectEmployee() {
    if (_preselectDone) return;
    final data = context.read<ShiftDataController>();
    if (data.employees.isEmpty) return;
    _preselectDone = true;
    if (data.selectedEmployeeId != null) return;
    final email = context.read<AuthController>().userEmail?.trim().toLowerCase();
    if (email == null || email.isEmpty) return;
    Employee? match;
    for (final e in data.employees) {
      if (e.email.trim().toLowerCase() == email) {
        match = e;
        break;
      }
    }
    if (match != null) data.selectEmployee(match.id);
  }

  /// The inclusive [from, to] range the current view needs. The month grids are
  /// padded to whole weeks so their leading/trailing days are covered, and the
  /// day view loads its whole week so stepping through days rarely refetches.
  (DateTime, DateTime) _visibleRange() {
    switch (_view) {
      case HomeView.week:
        final start = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        return (dateKey(start), dateKey(start.add(const Duration(days: 6))));
      case HomeView.day:
        final start =
            _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
        return (dateKey(start), dateKey(start.add(const Duration(days: 6))));
      case HomeView.month:
      case HomeView.wishes:
        final first = DateTime(_anchor.year, _anchor.month, 1);
        final gridStart = first.subtract(Duration(days: first.weekday - 1));
        return (
          dateKey(gridStart),
          dateKey(gridStart.add(const Duration(days: 41)))
        );
    }
  }

  /// Moves the visible range one step forward or back, by whatever unit the
  /// current view is built on.
  void _step(int direction) {
    setState(() {
      switch (_view) {
        case HomeView.month:
        case HomeView.wishes:
          _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
        case HomeView.week:
          _anchor = _anchor.add(Duration(days: 7 * direction));
        case HomeView.day:
          _selectedDay = dateKey(_selectedDay.add(Duration(days: direction)));
          _anchor = _selectedDay;
      }
    });
    _maybeRefresh();
  }

  void _goToday() {
    setState(() {
      _anchor = DateTime.now();
      _selectedDay = dateKey(DateTime.now());
    });
    _maybeRefresh();
  }

  void _switchView(HomeView view) {
    if (_view == view) return;
    setState(() {
      _view = view;
      // Entering the day view from a calendar keeps the day you were looking
      // at; leaving it moves the calendar to that day's month/week.
      if (view == HomeView.day) {
        _anchor = _selectedDay;
      }
    });
    _maybeRefresh();
  }

  /// Selecting a day in a calendar view: the first tap selects it, a second tap
  /// on the already selected day opens it in the day view.
  void _selectDay(DateTime day) {
    final key = dateKey(day);
    if (key == _selectedDay) {
      _switchView(HomeView.day);
      return;
    }
    setState(() => _selectedDay = key);
  }

  /// Hands the visible range's confirmed shifts to the phone's calendar. The
  /// range is whatever the active view shows, so what gets exported is what the
  /// user is looking at.
  void _exportToCalendar(ShiftDataController data) {
    final range = _visibleRange();
    showCalendarExportSheet(context,
        data: data, from: range.$1, to: range.$2);
  }

  /// The planner/admin area. The roster may have changed there, so the
  /// calendars reload on the way back.
  Future<void> _openManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManagementScreen()),
    );
    if (mounted) _maybeRefresh();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) _maybeRefresh();
  }

  String _title(AppLocalizations l10n, String locale) {
    switch (_view) {
      case HomeView.week:
        final start = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return start.month == end.month
            ? l10n.weekTitle(DateFormat.MMMM(locale).format(start),
                '${start.year}', isoWeekNumber(start))
            : l10n.weekSpanTitle(DateFormat.MMM(locale).format(start),
                DateFormat.MMM(locale).format(end), '${end.year}');
      case HomeView.day:
        return DateFormat.yMMMMEEEEd(locale).format(_selectedDay);
      case HomeView.month:
      case HomeView.wishes:
        return DateFormat.yMMMM(locale).format(_anchor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    // Re-sync data if credentials changed while listening.
    final key = settings.settings.toJson().toString();
    if (key != _lastSettingsKey) {
      _lastSettingsKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeRefresh();
      });
    }

    final data = context.watch<ShiftDataController>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        // The employee picker lives in the title: it is a scope switch for
        // everything below, and it saves a whole row of chrome.
        title: _employeeSelector(context, data),
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: l10n.today,
            icon: const Icon(Icons.today),
            onPressed: _goToday,
          ),
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _maybeRefresh,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'calendar':
                  _exportToCalendar(data);
                case 'management':
                  _openManagement();
                case 'settings':
                  _openSettings();
                case _:
                  context.read<AuthController>().logout();
              }
            },
            itemBuilder: (context) => [
              // Only shift-planner and shift-admin get the management area;
              // the backend would refuse everyone else's writes anyway.
              if (context.read<AuthController>().canManage)
                PopupMenuItem(
                  value: 'management',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(l10n.admManagement),
                  ),
                ),
              PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available),
                  title: Text(l10n.addToCalendar),
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings),
                  title: Text(l10n.settings),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.signOut),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _toolbar(context),
          if (data.loading) const LinearProgressIndicator(minHeight: 2),
          if (data.error != null) _errorBanner(context, data.error!),
          Expanded(child: _viewBody(context, data)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _view.index,
        onDestinationSelected: (i) => _switchView(HomeView.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: l10n.navDay,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_view_week_outlined),
            selectedIcon: const Icon(Icons.calendar_view_week),
            label: l10n.navWeek,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navMonth,
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_border_rounded),
            selectedIcon: const Icon(Icons.star_rounded),
            label: l10n.navWishes,
          ),
        ],
      ),
    );
  }

  /// Makes a sideways swipe step the visible range by one day, week or month
  /// (left = forward, right = back), unless turned off in the settings.
  Widget _swipeable(Widget child) {
    if (!context.watch<SettingsController>().settings.swipeNavigation) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() < _swipeMinVelocity) return;
        _step(v < 0 ? 1 : -1);
      },
      child: child,
    );
  }

  /// The single view the bottom bar currently points at.
  Widget _viewBody(BuildContext context, ShiftDataController data) {
    switch (_view) {
      case HomeView.month:
        return _swipeable(
          _withLegend(
            data,
            MonthView(
              visibleMonth: _anchor,
              selectedDay: _selectedDay,
              data: data,
              onDaySelected: _selectDay,
              onDaysPainted: (days) => _editWishes(days, data),
            ),
          ),
        );
      case HomeView.week:
        return _swipeable(
          _withLegend(
            data,
            WeekView(
              visibleWeek: _anchor,
              selectedDay: _selectedDay,
              data: data,
              onDaySelected: _selectDay,
              onDaysPainted: (days) => _editWishes(days, data),
            ),
          ),
        );
      case HomeView.day:
        return LayoutBuilder(
          builder: (context, constraints) {
            _paneArea = constraints.maxHeight;
            return _swipeable(_dayPanes(context, data, constraints.maxHeight));
          },
        );
      case HomeView.wishes:
        return _pullToRefresh(
          WishPlannerView(visibleMonth: _anchor, data: data),
        );
    }
  }

  /// Pull-down-to-reload around a list. The list is made scrollable even when
  /// it is shorter than the screen, so the gesture always works.
  Widget _pullToRefresh(Widget list) {
    return RefreshIndicator(
      onRefresh: _maybeRefresh,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(physics: const AlwaysScrollableScrollPhysics()),
        child: list,
      ),
    );
  }

  /// A calendar over the legend for the day it has selected: tapping a date
  /// explains its colours right below the grid, without leaving the view.
  ///
  /// The legend takes only the height its rows need, and never more than a
  /// [_maxLegendShare] of the body — the calendar is still the point.
  Widget _withLegend(ShiftDataController data, Widget calendar) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Loose, not [Expanded]: a calendar that asks for less than the body
          // offers (the month grid keeps a fixed row height) is given just what
          // it asks for, so the legend sits under the grid rather than across
          // a gap from it.
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: calendar,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * _maxLegendShare,
            ),
            child: DayLegend(
              day: _selectedDay,
              data: data,
              onOpenDay: () => _switchView(HomeView.day),
            ),
          ),
        ],
      ),
    );
  }

  /// Day view: the summary on top, the full roster below, with a drag handle
  /// on the seam so either half can be given more room.
  Widget _dayPanes(
      BuildContext context, ShiftDataController data, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResizablePane(
          key: _summaryKey,
          // Until the user drags the handle the summary is as tall as its
          // content (up to what leaves the list its minimum), so the hero,
          // date header and wish chip are all visible.
          height: _summaryHeight == null ? null : _summaryFor(total),
          maxHeight: math.max(_minSummary, total - _minList),
          tooltip: context.l10n.resizeDayOverview,
          onResize: (delta) => setState(() {
            final current = _summaryHeight ??
                _summaryKey.currentContext?.size?.height ??
                _summaryFor(_paneArea);
            _summaryHeight = _summaryFor(_paneArea, requested: current + delta);
          }),
          onReset: () => setState(() => _summaryHeight = null),
          child: DayDetailSummary(day: _selectedDay, data: data),
        ),
        Expanded(
          child: ClipRect(
            child: _pullToRefresh(DayShiftList(day: _selectedDay, data: data)),
          ),
        ),
      ],
    );
  }

  /// Effective height of the summary pane for a pane area of [total]; the shift
  /// list keeps whatever is left. The lower bound wins when the window is too
  /// short for both minimums.
  double _summaryFor(double total, {double? requested}) {
    requested ??= _summaryHeight ?? total * _defaultSummaryShare;
    return requested
        .clamp(_minSummary, math.max(_minSummary, total - _minList))
        .toDouble();
  }

  /// Long pressing a calendar date — and dragging across its neighbours —
  /// opens the wish editor for every day the finger touched.
  void _editWishes(Set<DateTime> days, ShiftDataController data) {
    if (days.isEmpty) return;
    final sorted = days.toList()..sort();
    setState(() => _selectedDay = sorted.first);
    showShiftWishSheet(context, days: sorted, data: data);
  }

  Widget _employeeSelector(BuildContext context, ShiftDataController data) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selected = data.selectedEmployee;

    return PopupMenuButton<String?>(
      enabled: data.employees.isNotEmpty,
      tooltip: l10n.employee,
      initialValue: data.selectedEmployeeId,
      onSelected: data.selectEmployee,
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Text(l10n.allEmployees),
        ),
        const PopupMenuDivider(),
        for (final e in data.employees)
          PopupMenuItem<String?>(
            value: e.id,
            child: Text(e.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                selected?.name ?? l10n.allEmployees,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  /// Range stepper for the active view: ‹ title ›.
  Widget _toolbar(BuildContext context) {
    final l10n = context.l10n;
    final updated = context.watch<ShiftDataController>().lastUpdated;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.previous,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _step(-1),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(l10n, context.dateLocale),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (updated != null)
                  Text(
                    l10n.updatedAt(
                      DateFormat.Hm(context.dateLocale).format(updated),
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.next,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _step(1),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(BuildContext context, DataFailure failure) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(failureText(l10n, failure),
                style: TextStyle(color: scheme.onErrorContainer)),
          ),
          TextButton(onPressed: _openSettings, child: Text(l10n.settings)),
        ],
      ),
    );
  }
}
