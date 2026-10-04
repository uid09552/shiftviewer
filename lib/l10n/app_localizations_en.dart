// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shift Viewer';

  @override
  String get signInSubtitle => 'Sign in to view your shift schedule';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Redirecting…';

  @override
  String get loginUnsupported => 'Login is not supported on this platform.';

  @override
  String get connectionSettings => 'Connection settings';

  @override
  String get signOut => 'Sign out';

  @override
  String get navMonth => 'Month';

  @override
  String get navWeek => 'Week';

  @override
  String get navDay => 'Day';

  @override
  String get navWishes => 'Wishes';

  @override
  String get openDayView => 'Open day view';

  @override
  String get today => 'Today';

  @override
  String get refresh => 'Refresh';

  @override
  String get settings => 'Settings';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get save => 'Save';

  @override
  String get employee => 'Employee';

  @override
  String get allEmployees => 'All employees';

  @override
  String weekTitle(String month, String year, int week) {
    return '$month $year · W$week';
  }

  @override
  String weekSpanTitle(String from, String to, String year) {
    return '$from – $to $year';
  }

  @override
  String get notConfigured =>
      'Not configured. Open settings to set the API URL.';

  @override
  String errorWithCode(String message, int code) {
    return '$message ($code)';
  }

  @override
  String get noShiftsScheduled => 'No shifts scheduled';

  @override
  String workingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count working',
      one: '1 working',
    );
    return '$_temp0';
  }

  @override
  String get offNoShift => 'Off — no shift';

  @override
  String get yourShift => 'YOUR SHIFT';

  @override
  String get noWorkstation => 'No workstation assigned';

  @override
  String get offNotScheduled => 'Off / not scheduled';

  @override
  String get unassignedWorkstation => 'Unassigned';

  @override
  String get absent => 'absent';

  @override
  String get resizeDayOverview =>
      'Drag to resize the day overview · double tap to reset';

  @override
  String get shiftWish => 'Shift wish';

  @override
  String get addShiftWish => 'Add shift wish';

  @override
  String wishFor(String shift) {
    return 'Wish: $shift';
  }

  @override
  String get unknownShift => 'unknown shift';

  @override
  String get wishDisclaimer =>
      'The planner rewards fulfilling a wish, but never guarantees it.';

  @override
  String get notScheduledOnWeekday => 'Not scheduled on this weekday';

  @override
  String get removeWish => 'Remove wish';

  @override
  String removeWishCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count wishes',
      one: 'Remove wish',
    );
    return '$_temp0';
  }

  @override
  String get scopeDay => 'This day';

  @override
  String scopeSelection(int count) {
    return '$count days';
  }

  @override
  String get scopeWeek => 'This week';

  @override
  String get scopeMonth => 'This month';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String shiftRunsOnDays(int matching, int total) {
    return 'Runs on $matching of $total days';
  }

  @override
  String wishBatchPlaced(int count, String shift) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$shift wished for $count days',
      one: 'Wish placed: $shift',
      zero: 'No day to wish for',
    );
    return '$_temp0';
  }

  @override
  String wishBatchSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days skipped, the shift does not run then',
      one: '1 day skipped, the shift does not run then',
    );
    return '$_temp0';
  }

  @override
  String wishBatchRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wishes removed',
      one: 'Wish removed',
      zero: 'No wish to remove',
    );
    return '$_temp0';
  }

  @override
  String get wishSelectEmployeeFirst => 'Select an employee first.';

  @override
  String get wishPickEmployeeFirst =>
      'Pick an employee before placing a shift wish.';

  @override
  String get wishNoShiftsAvailable => 'No shifts available to wish for.';

  @override
  String get wishConflict =>
      'A wish for this day already exists — reload and try again.';

  @override
  String get wishModeOpen => 'Wishes open';

  @override
  String wishModeRange(String from, String to) {
    return 'Wishes $from – $to';
  }

  @override
  String get wishModeDisabled => 'Wishes deactivated';

  @override
  String get wishWindowOpenDetail => 'Shift wishes can be placed for any date.';

  @override
  String wishWindowRangeDetail(String from, String to) {
    return 'Shift wishes can only be placed for $from – $to.';
  }

  @override
  String get wishWindowClosedDetail =>
      'Shift wishes are deactivated right now.';

  @override
  String get wishOutsideWindow => 'This day is outside the wish window.';

  @override
  String wishBatchBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days outside the wish window',
      one: '1 day outside the wish window',
    );
    return '$_temp0';
  }

  @override
  String get wishPlannerHint =>
      'Tap a day to wish for a shift · long press and drag across days to plan several at once.';

  @override
  String get wishPlannerEmpty => 'No wishes in this month yet';

  @override
  String wishPlannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wishes',
      one: '1 wish',
      zero: 'No wishes',
    );
    return '$_temp0';
  }

  @override
  String get wishPlannerPickEmployee =>
      'Pick an employee to plan their shift wishes.';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get addToGoogleCalendar => 'Add to Google Calendar';

  @override
  String get calendarExportTitle => 'Add shifts to calendar';

  @override
  String calendarExportSubtitle(String who, String from, String to) {
    return '$who · $from – $to';
  }

  @override
  String calendarExportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmed shifts',
      one: '1 confirmed shift',
      zero: 'No confirmed shifts',
    );
    return '$_temp0';
  }

  @override
  String calendarExportAbsences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count absences left out',
      one: '1 absence left out',
    );
    return '$_temp0';
  }

  @override
  String get calendarExportEmpty => 'No confirmed shifts in this range.';

  @override
  String calendarExportMore(int count) {
    return '+$count more';
  }

  @override
  String get calendarShareIcs => 'Share calendar file';

  @override
  String get calendarDownloadIcs => 'Download calendar file';

  @override
  String get calendarIcsHint =>
      'Open the file with Google Calendar to import every shift at once.';

  @override
  String get calendarIcsHintWeb =>
      'Import it in Google Calendar under Settings ▸ Import & export.';

  @override
  String get calendarGoogleHint =>
      'Opens the Google Calendar app, or its website.';

  @override
  String get calendarOpenedGoogle => 'Opened in Google Calendar.';

  @override
  String calendarIcsReady(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts exported to $file',
      one: '1 shift exported to $file',
    );
    return '$_temp0';
  }

  @override
  String get calendarExportDismissed => 'Nothing was exported.';

  @override
  String calendarExportFailed(String reason) {
    return 'Could not export: $reason';
  }

  @override
  String get calendarAllDay => 'All day';

  @override
  String get sectionServer => 'Server';

  @override
  String get apiBaseUrl => 'API base URL';

  @override
  String get fieldRequired => 'Required';

  @override
  String get enterValidUrl => 'Enter a valid URL';

  @override
  String get sectionSignIn => 'Sign-in (OIDC · PKCE)';

  @override
  String get issuerUrl => 'Issuer / realm URL';

  @override
  String get clientId => 'Client ID';

  @override
  String get clientIdHelper => 'Same client as the API gateway · PKCE (S256)';

  @override
  String get redirectUri => 'Redirect URI';

  @override
  String get sectionManualLogin => 'Manual login (fallback)';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get bearerToken => 'Bearer token (optional)';

  @override
  String get bearerTokenHelper => 'Used instead of username/password when set';

  @override
  String get sectionCalendarScope => 'Calendar scope';

  @override
  String get employeeIdOptional => 'Employee ID (optional)';

  @override
  String get employeeIdHelper =>
      'Show only this employee\'s roster; leave empty for all';

  @override
  String get testConnection => 'Test connection';

  @override
  String get connectionSuccessful => 'Connection successful';

  @override
  String connectionFailed(String reason) {
    return 'Failed: $reason';
  }

  @override
  String get sectionAppearance => 'Language';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'German';

  @override
  String get shiftInsights => 'Shift details';

  @override
  String get employeeInsights => 'Employee';

  @override
  String get showShiftDetails => 'Show shift details and statistics';

  @override
  String get showEmployeeDetails => 'Show this employee\'s details';

  @override
  String get analysisUnavailable =>
      'Server statistics are unavailable — the numbers below come from the roster.';

  @override
  String get statRostered => 'Rostered';

  @override
  String get statPresent => 'Present';

  @override
  String get statAbsent => 'Absent';

  @override
  String get statPlannedHours => 'Planned hours';

  @override
  String get statWorking => 'Working';

  @override
  String get coverageMet => 'Fully staffed';

  @override
  String coverageShort(int count) {
    return '$count short';
  }

  @override
  String get coverageOver => 'Over capacity';

  @override
  String get coverageNoTarget => 'No staffing target';

  @override
  String staffingNeedsMin(int min) {
    return 'Needs at least $min';
  }

  @override
  String staffingNeedsRange(int min, int max) {
    return 'Needs $min–$max';
  }

  @override
  String restDaysAfter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rest days after',
      one: '1 rest day after',
    );
    return '$_temp0';
  }

  @override
  String shareOfDay(int percent) {
    return '$percent% of the day\'s staff';
  }

  @override
  String dayHeadcount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people working that day',
      one: '1 person working that day',
    );
    return '$_temp0';
  }

  @override
  String get sectionWorkstations => 'Workstations';

  @override
  String get sectionAbsences => 'Absences';

  @override
  String get sectionWishes => 'Shift wishes';

  @override
  String get sectionWeekPattern => 'Across the week';

  @override
  String get sectionDayContext => 'The rest of the day';

  @override
  String get sectionOnThisDay => 'On this day';

  @override
  String get sectionCapabilities => 'Capabilities';

  @override
  String get sectionAvailableShifts => 'Can be scheduled for';

  @override
  String get sectionRangeTotals => 'Totals';

  @override
  String peopleHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String hoursValue(String hours) {
    return '$hours h';
  }

  @override
  String plannedAllShifts(int count) {
    return '$count planned here across all shifts';
  }

  @override
  String stationBelowMinimum(int min) {
    return 'Below its minimum of $min';
  }

  @override
  String stationAboveMaximum(int max) {
    return 'Above its maximum of $max';
  }

  @override
  String get stationUnavailable => 'Workstation disabled';

  @override
  String get priorityHigh => 'High priority';

  @override
  String get priorityMedium => 'Medium priority';

  @override
  String get priorityLow => 'Low priority';

  @override
  String wishesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wishes for this shift',
      one: '1 wish for this shift',
      zero: 'No wishes for this shift',
    );
    return '$_temp0';
  }

  @override
  String wishesGrantedOf(int granted, int count) {
    return '$granted of $count granted';
  }

  @override
  String get absenceSick => 'Sick';

  @override
  String get absenceDayOff => 'Day off';

  @override
  String get absenceHoliday => 'Holiday';

  @override
  String get absenceUnavailable => 'Unavailable';

  @override
  String get absenceFree => 'Free';

  @override
  String get absenceUnknown => 'Unknown';

  @override
  String countedOver(String from, String to) {
    return 'Counted over $from – $to';
  }

  @override
  String monthlyHoursTarget(String hours) {
    return '$hours h per month';
  }

  @override
  String monthlyLoad(int percent) {
    return '$percent% of the monthly target';
  }

  @override
  String get statDaysWorked => 'Days worked';

  @override
  String get statDaysRostered => 'Days rostered';

  @override
  String skillLevel(int level) {
    return 'Level $level';
  }

  @override
  String get noCapabilities => 'No capabilities recorded';

  @override
  String get anyShift => 'Any shift';

  @override
  String get nothingRostered => 'Nothing rostered on this day';

  @override
  String get noRosterInRange => 'Nothing rostered in the loaded range';

  @override
  String get longPressForDetails => 'Long press to list who is behind this';

  @override
  String get listNothingToShow => 'Nothing to list here';

  @override
  String get sectionSchedule => 'Weekly schedule';

  @override
  String scheduleWeekdayLine(String start, String end, int min) {
    return '$start – $end · needs $min';
  }

  @override
  String get scheduleWeekdayOff => 'Does not run';

  @override
  String get othersWithCapability => 'Others with this capability';

  @override
  String get noOthersWithCapability => 'Nobody else on record with it';

  @override
  String get wishGranted => 'Granted';

  @override
  String get wishNotGranted => 'Not granted';

  @override
  String get detailsEveryoneWorking => 'Everyone working';

  @override
  String get detailsAtWorkstation => 'People at this workstation';

  @override
  String get detailsOnThisShift => 'People on this shift';

  @override
  String detailsMissingPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people short of the minimum',
      one: '1 person short of the minimum',
    );
    return '$_temp0';
  }

  @override
  String detailsOnDay(String weekday, String date) {
    return '$weekday, $date';
  }

  @override
  String capabilityOfLevel(String group, int level) {
    return '$group · level $level';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get adminForbidden => 'Your role may not do this.';

  @override
  String get admManagement => 'Management';

  @override
  String get admToday => 'Today';

  @override
  String get admSectionPlanning => 'Planning';

  @override
  String get admSectionConfiguration => 'Configuration';

  @override
  String get admRoster => 'Roster';

  @override
  String get admRosterHint => 'Edit who works what, week by week';

  @override
  String get admRotations => 'Rotations';

  @override
  String get admRotationsHint => 'Recurring rhythms as fixed shifts';

  @override
  String get admOptimizer => 'Schedule optimizer';

  @override
  String get admOptimizerHint => 'Generate, check and adopt a plan';

  @override
  String get admFairness => 'Fairness';

  @override
  String get admFairnessHint => 'Nights, weekends, hours and wishes per person';

  @override
  String get admEmployees => 'Employees';

  @override
  String get admEmployeesHint => 'Profiles, shifts, capabilities and leave';

  @override
  String get admShifts => 'Shifts';

  @override
  String get admShiftsHint => 'Times and staffing per weekday';

  @override
  String get admWorkstations => 'Workstations';

  @override
  String get admWorkstationsHint => 'Staffing, required capabilities, closures';

  @override
  String get admCapabilities => 'Capabilities';

  @override
  String get admCapabilitiesHint => 'Skills and their levels';

  @override
  String get admPlannerSettings => 'Planner settings';

  @override
  String get admPlannerSettingsHint => 'How the optimizer weighs its goals';

  @override
  String get admWishSettings => 'Wish window';

  @override
  String get admWishSettingsHint => 'When employees may place shift wishes';

  @override
  String get admUsers => 'Users';

  @override
  String get admUsersHint => 'Sign-in accounts and roles';

  @override
  String get admAuditLog => 'Audit log';

  @override
  String get admAuditLogHint => 'Who changed what, and when';

  @override
  String get admAllStationsCovered =>
      'Every open workstation has its minimum today.';

  @override
  String get admUnderstaffedToday => 'Below minimum today';

  @override
  String admLatestRun(String status, String date) {
    return 'Latest optimizer run: $status · $date';
  }

  @override
  String get admRecentActivity => 'Recent activity';

  @override
  String get admTaskRunning => 'Running';

  @override
  String get admTaskDone => 'Finished';

  @override
  String get admTaskFailed => 'Failed';

  @override
  String get admSearchEmployees => 'Search employees…';

  @override
  String get admSearchManagement => 'Search management…';

  @override
  String get admNoMatches => 'Nothing here matches that search.';

  @override
  String get admNoEmployees => 'No employees.';

  @override
  String get admRosterLegend =>
      'Tap a day to assign a shift, mark an absence or clear it. ★ = wish.';

  @override
  String get admAbsenceShortSick => 'Sick';

  @override
  String get admAbsenceShortDayOff => 'Vac';

  @override
  String get admAbsenceShortHoliday => 'Hol';

  @override
  String get admAbsenceShortFree => 'Off';

  @override
  String admWishedFor(String shift) {
    return 'Wished for: $shift';
  }

  @override
  String get admShift => 'Shift';

  @override
  String get admNotOnThisDay => 'not scheduled this day';

  @override
  String get admWorkstation => 'Workstation';

  @override
  String get admClosed => 'closed';

  @override
  String get admAbsence => 'Absence';

  @override
  String get admClearDay => 'Clear day';

  @override
  String get admAddEmployee => 'Add employee';

  @override
  String admHoursPerMonth(String hours) {
    return '$hours h/month';
  }

  @override
  String get admName => 'Name';

  @override
  String get admEmail => 'Email';

  @override
  String get admMonthlyHours => 'Monthly hours target';

  @override
  String get admEnterNumber => 'Enter a number';

  @override
  String get admSaved => 'Saved.';

  @override
  String get admSaveFirstHint =>
      'Save the employee first to assign shifts, capabilities and leave.';

  @override
  String get admDeleteEmployee => 'Delete employee';

  @override
  String admDeleteEmployeeMessage(String name) {
    return 'Delete $name? Their roster, wishes and leave go with them.';
  }

  @override
  String get admLeave => 'Leave & unavailability';

  @override
  String get admLeaveHint =>
      'Vacation and sick days go on the roster; unavailable days are respected by the optimizer.';

  @override
  String get admAdd => 'Add';

  @override
  String get admAddLeave => 'Add leave';

  @override
  String get admPickDates => 'Pick dates';

  @override
  String get admUnavailableHint =>
      'The optimizer will not plan this person on these days.';

  @override
  String get admNoUpcomingLeave => 'Nothing planned.';

  @override
  String admPastLeave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count past entries',
      one: '1 past entry',
    );
    return '$_temp0';
  }

  @override
  String admDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get admRemoveLeave => 'Remove leave';

  @override
  String admRemoveLeaveMessage(String kind, String range) {
    return 'Remove $kind for $range?';
  }

  @override
  String get admAddShift => 'Add shift';

  @override
  String get admNoShifts => 'No shifts yet.';

  @override
  String get admNoWeekdays => 'Runs on no weekday';

  @override
  String get admShortName => 'Short name';

  @override
  String get admOrder => 'Order';

  @override
  String get admColor => 'Colour';

  @override
  String get admWeekdayTimesHint =>
      'Times and head count per weekday. Switched-off days have no such shift.';

  @override
  String get admStart => 'Start';

  @override
  String get admEnd => 'End';

  @override
  String get admMinStaff => 'Minimum staff';

  @override
  String get admMaxStaff => 'Maximum staff (∞ = none)';

  @override
  String get admRestDaysAfter => 'Rest days after';

  @override
  String get admDeleteShift => 'Delete shift';

  @override
  String admDeleteShiftMessage(String name) {
    return 'Delete $name? Planned days with this shift lose it.';
  }

  @override
  String get admAddWorkstation => 'Add workstation';

  @override
  String get admNoWorkstations => 'No workstations yet.';

  @override
  String get admInactive => 'inactive';

  @override
  String get admActive => 'Active';

  @override
  String get admActiveHint => 'Inactive workstations are not staffed.';

  @override
  String get admPriority => 'Priority';

  @override
  String get admPerShift => 'per shift';

  @override
  String get admRunsInShifts => 'Runs in shifts';

  @override
  String get admRunsInShiftsHint => 'None selected means every shift.';

  @override
  String get admRequiredCapabilities => 'Required capabilities';

  @override
  String get admClosures => 'Closures';

  @override
  String get admClosuresHint => 'Periods nobody may be planned here.';

  @override
  String get admNoClosures => 'No closures.';

  @override
  String get admDeleteWorkstation => 'Delete workstation';

  @override
  String admDeleteWorkstationMessage(String name) {
    return 'Delete $name?';
  }

  @override
  String get admAddCapability => 'Add capability';

  @override
  String get admEditCapability => 'Edit capability';

  @override
  String get admNoSkillGroup => 'Without skill group';

  @override
  String get admSkillGroup => 'Skill group';

  @override
  String get admSkillGroupHint =>
      'Within a group, a higher level may cover a lower one.';

  @override
  String get admLevel => 'Level';

  @override
  String get admDeleteCapability => 'Delete capability';

  @override
  String admDeleteCapabilityMessage(String name) {
    return 'Delete $name? It is removed from every employee and workstation.';
  }

  @override
  String get admExpertValues => 'Expert values';

  @override
  String get admDiscardChanges => 'Discard changes?';

  @override
  String get admDiscardChangesMessage => 'Your changes have not been saved.';

  @override
  String get admDiscard => 'Discard';

  @override
  String admLastUpdated(String date) {
    return 'Last updated $date';
  }

  @override
  String get admPsUseCase => 'Use case';

  @override
  String get admPsUseCaseHint =>
      'Pick the goal that fits this ward — it fills in every setting below, which you can still fine-tune. Solver effort is never touched.';

  @override
  String get admPsCustomMix => 'Custom mix — no preset matches these values.';

  @override
  String get admTplBalanced => 'Balanced';

  @override
  String get admTplBalancedHint =>
      'The shipped defaults: coverage, fairness and wishes weighed against each other.';

  @override
  String get admTplFairness => 'Equal share';

  @override
  String get admTplFairnessHint =>
      'Everyone works a comparable amount. Hour targets win over wishes and continuity.';

  @override
  String get admTplWishes => 'Wishes first';

  @override
  String get admTplWishesHint =>
      'Requested shifts are granted whenever the plan allows, at some cost to even hours.';

  @override
  String get admTplCoverage => 'Coverage first';

  @override
  String get admTplCoverageHint =>
      'Critical workstations get staffed before anything else, with looser rest limits.';

  @override
  String get admTplStability => 'Stable rosters';

  @override
  String get admTplStabilityHint =>
      'Long, predictable blocks on the same shift instead of frequent rotation.';

  @override
  String get admTplWellbeing => 'Staff wellbeing';

  @override
  String get admTplWellbeingHint =>
      'Longer rest, capped weeks and fatigue spread evenly — the gentlest plan the ward allows.';

  @override
  String get admPsRest => 'Rest & recovery';

  @override
  String get admPsRestHint =>
      'Hard limits on consecutive work and rest between shifts';

  @override
  String get admPsNightRecovery => 'Night shift recovery';

  @override
  String get admPsNightRecoveryHint => 'Days off required after a night shift.';

  @override
  String get admPsMinRest => 'Minimum rest between shifts';

  @override
  String get admPsMinRestHint =>
      'Rest required between shifts on consecutive days.';

  @override
  String get admPsMaxConsecutive => 'Max consecutive days';

  @override
  String get admPsMaxConsecutiveHint => 'Longest run of working days allowed.';

  @override
  String get admPsMaxPerWeek => 'Max days per week';

  @override
  String get admPsMaxPerWeekHint => 'Working days allowed per calendar week.';

  @override
  String admUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'Off',
    );
    return '$_temp0';
  }

  @override
  String admUnitHours(int count) {
    return '$count h';
  }

  @override
  String get admOff => 'Off';

  @override
  String get admPsFairness => 'Fairness & hours';

  @override
  String get admPsFairnessHint =>
      'How evenly work is shared, and how closely hour targets are met';

  @override
  String get admPsEquality => 'Fairness';

  @override
  String get admPsEqualityHint => 'Spreads hours more evenly across employees.';

  @override
  String get admPsMonthlyTarget => 'Monthly hours target';

  @override
  String get admPsMonthlyTargetHint =>
      'Pushes towards each employee\'s monthly hours target.';

  @override
  String get admPsWeeklyBand => 'Weekly hours band';

  @override
  String get admPsWeeklyBandHint =>
      'A soft floor and ceiling per week, on top of the monthly target.';

  @override
  String get admPsWeeklyMin => 'Minimum per week';

  @override
  String get admPsWeeklyMax => 'Maximum per week';

  @override
  String get admPsBandStrength => 'Band strength';

  @override
  String get admPsCoverage => 'Coverage & continuity';

  @override
  String get admPsCoverageHint =>
      'Which workstations are staffed first, and how stable shift patterns stay';

  @override
  String get admPsPriority => 'Workstation priority';

  @override
  String get admPsPriorityHint =>
      'How sharply high-priority workstations are staffed first.';

  @override
  String get admPrioIgnore => 'Treat all the same';

  @override
  String get admPrioSoft => 'Slight preference';

  @override
  String get admPrioBalanced => 'Balanced';

  @override
  String get admPrioStrict => 'Strict order';

  @override
  String get admCustom => 'Custom';

  @override
  String admCustomValue(String value) {
    return 'Custom ($value)';
  }

  @override
  String get admPsMinStaffing => 'Minimum staffing';

  @override
  String get admPsMinStaffingHint =>
      'Whether the minimum per shift and workstation is a target or a requirement.';

  @override
  String get admPsMinStaffingSoft => 'Target';

  @override
  String get admPsMinStaffingHard => 'Requirement';

  @override
  String get admPsMinStaffingHardWarning =>
      'As a requirement, a period without enough available employees produces no plan at all instead of an understaffed one.';

  @override
  String get admPsPersonalLimits => 'Personal limits';

  @override
  String get admPsPersonalLimitsHint =>
      'How an employee\'s own max nights/weekends per month hold. Never scheduling nights is always strict.';

  @override
  String get admPsPersonalLimitsHard => 'Strict';

  @override
  String get admPsPersonalLimitsSoft => 'Flexible';

  @override
  String get admPsKeepRotations => 'Keep rotations';

  @override
  String get admPsKeepRotationsHint =>
      'Fixed shifts and days off from rotations are planned first.';

  @override
  String get admPsKeepRotationsOff =>
      'Rotations are ignored when planning. They stay saved and apply again once this is back on.';

  @override
  String get admPsContinuity => 'Shift continuity';

  @override
  String get admPsContinuityHint =>
      'Rewards the same shift on consecutive days.';

  @override
  String get admPsWeekStreak => 'Week-streak bonus';

  @override
  String get admPsWeekStreakHint =>
      'Extra reward for 7+ days in a row on the same shift.';

  @override
  String get admPsPreferences => 'Preferences, skills & fatigue';

  @override
  String get admPsPreferencesHint =>
      'Soft goals: wishes, preferred days off, skill matching and fatigue.';

  @override
  String get admPsWishes => 'Shift wishes';

  @override
  String get admPsWishesHint =>
      'Reward for granting a shift an employee asked for.';

  @override
  String get admPsPreferredOff => 'Preferred days off';

  @override
  String get admPsPreferredOffHint =>
      'Cost of planning someone on a day they prefer off. Never blocks.';

  @override
  String get admPsSkillDowngrade => 'Skill downgrade cost';

  @override
  String get admPsSkillDowngradeHint =>
      'Cost of covering a slot with a higher level of the same skill group.';

  @override
  String get admPsFatigue => 'Fatigue balancing';

  @override
  String get admPsFatigueHint => 'Protects the most fatigued employee.';

  @override
  String get admPsNightFatigue => 'Night shift fatigue';

  @override
  String get admPsNightFatigueHint =>
      'How draining a night shift is compared with a day shift.';

  @override
  String get admNightSame => 'Same as a day shift';

  @override
  String get admNightSlight => 'Slightly harder';

  @override
  String get admNightNoticeable => 'Twice as hard';

  @override
  String get admNightStrong => 'Three times as hard';

  @override
  String get admPsSolver => 'Solver performance';

  @override
  String get admPsSolverHint => 'How long and how hard the solver searches';

  @override
  String get admPsEffort => 'Search effort';

  @override
  String admPsEffortHint(int seconds, int workers) {
    return 'Up to $seconds s on $workers CPU threads.';
  }

  @override
  String get admPsEffortQuick => 'Quick';

  @override
  String get admPsEffortBalanced => 'Balanced';

  @override
  String get admPsEffortThorough => 'Thorough';

  @override
  String get admPsTimeLimit => 'Time limit (seconds)';

  @override
  String get admPsWorkers => 'Parallel workers';

  @override
  String get admLevelOff => 'Off';

  @override
  String get admLevelWeak => 'Weak';

  @override
  String get admLevelBalanced => 'Balanced';

  @override
  String get admLevelStrong => 'Strong';

  @override
  String get admLevelMax => 'Very strong';

  @override
  String get admWishSettingsIntro =>
      'Decide whether employees may place shift wishes, and for which dates. The optimizer rewards granted wishes; a wish is never a guarantee.';

  @override
  String get admWishSettingsReadOnly =>
      'Only the shift-admin role can change the wish window.';

  @override
  String get admWishModeEnabled => 'Always open';

  @override
  String get admWishModeEnabledHint => 'Wishes may be placed for any date.';

  @override
  String get admWishModeRange => 'Date range';

  @override
  String get admWishModeRangeHint =>
      'Only dates inside the window accept wishes.';

  @override
  String get admWishModeDisabled => 'Closed';

  @override
  String get admWishModeDisabledHint => 'No wish may be placed or withdrawn.';

  @override
  String get admRoleAdmin => 'Admin';

  @override
  String get admRoleAdminHint =>
      'Everything, including users and the wish window.';

  @override
  String get admRolePlanner => 'Planner';

  @override
  String get admRolePlannerHint =>
      'Edits rosters, master data and runs the optimizer.';

  @override
  String get admRoleViewer => 'Viewer';

  @override
  String get admRoleViewerHint =>
      'Sees the roster and places their own wishes.';

  @override
  String get admRolesSaved => 'Roles saved.';

  @override
  String get admRemoveUser => 'Remove from organization';

  @override
  String admRemoveUserMessage(String name) {
    return 'Remove $name from this organization? The account itself stays in the identity provider.';
  }

  @override
  String get admRemove => 'Remove';

  @override
  String get admAddUser => 'Add user';

  @override
  String get admNoUsers => 'No users.';

  @override
  String get admNoRoles => 'no role';

  @override
  String admUsernameValue(String name) {
    return 'Username: $name';
  }

  @override
  String get admFirstName => 'First name';

  @override
  String get admLastName => 'Last name';

  @override
  String get admPasswordHint =>
      'Optional. Without one, the account cannot sign in until a password is set in the identity provider.';

  @override
  String get admTemporaryPassword => 'Must change password at first sign-in';

  @override
  String get admCreate => 'Create';

  @override
  String get admAll => 'All';

  @override
  String get admAuditEntity => 'Entity';

  @override
  String get admAuditAction => 'Action';

  @override
  String get admAuditActor => 'By';

  @override
  String get admAuditEmpty => 'No entries match.';

  @override
  String admAuditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get admLoadMore => 'Load more';

  @override
  String get admAuditChanges => 'Changes';

  @override
  String get admAuditNoFieldChanges => 'No field changed.';

  @override
  String get admAuditNoPrevious => 'No earlier state to compare with.';

  @override
  String get admAuditCompare => 'Compare with previous';

  @override
  String get admNewPattern => 'New pattern';

  @override
  String get admEditPattern => 'Edit pattern';

  @override
  String get admNoPatterns =>
      'No patterns yet. Create one, e.g. “F F S S N N - -”.';

  @override
  String admCycle(int days, int working) {
    return '$days-day cycle, $working working days';
  }

  @override
  String get admEdit => 'Edit';

  @override
  String get admApply => 'Apply';

  @override
  String get admDeletePattern => 'Delete pattern';

  @override
  String admDeletePatternMessage(String name) {
    return 'Delete “$name”? Fixed assignments already written from it stay.';
  }

  @override
  String get admPatternNameHint => 'e.g. Ward rotation A';

  @override
  String get admPatternSequence => 'Days of the cycle';

  @override
  String admPatternSequenceHint(String shifts) {
    return 'One entry per day, separated by spaces: a shift’s short name ($shifts) or - for a day off.';
  }

  @override
  String admUnknownTokens(String tokens) {
    return 'No shift is called $tokens.';
  }

  @override
  String get admPatternIssues =>
      'The planner will not be able to keep all of it:';

  @override
  String get admPatternFits => 'Fits the planner’s rules.';

  @override
  String admIssueConsecutive(int run, int max) {
    return '$run working days in a row; at most $max are allowed.';
  }

  @override
  String admIssueNoDayOff(int max) {
    return 'No day off in the cycle; at most $max working days in a row are allowed.';
  }

  @override
  String admIssueWeekly(int days, int max) {
    return 'Up to $days working days in 7; at most $max are allowed.';
  }

  @override
  String admIssueRest(int day, String from, String to, String hours, int min) {
    return 'Day $day: $from then $to leaves $hours h rest; at least $min h are required.';
  }

  @override
  String admIssueRecovery(int day, String shift, int days) {
    return 'Day $day: $shift is followed by work, but needs $days free day(s) after it.';
  }

  @override
  String admApplyTitle(String name) {
    return 'Apply “$name”';
  }

  @override
  String get admApplyIntro =>
      'Writes fixed shifts and days off for the people and period you pick. The planner keeps them ahead of everything else.';

  @override
  String get admPeriod => 'Period';

  @override
  String admPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
      zero: 'No people',
    );
    return '$_temp0';
  }

  @override
  String get admPickPeople => 'Tap to pick people';

  @override
  String get admSelectAll => 'Select all';

  @override
  String get admDone => 'Done';

  @override
  String get admStagger => 'Stagger';

  @override
  String get admStaggerHint =>
      'Each next person starts this many days later in the cycle. 0 = everyone in step.';

  @override
  String get admReplaceFixed => 'Replace existing fixed assignments';

  @override
  String get admReplaceFixedHint =>
      'Otherwise days that are already fixed stay as they are.';

  @override
  String get admPreview => 'Preview';

  @override
  String admWrite(int count) {
    return 'Write $count';
  }

  @override
  String admWritten(int count) {
    return '$count fixed assignments written.';
  }

  @override
  String get admClearFixed => 'Remove fixed assignments';

  @override
  String admClearFixedMessage(int count) {
    return 'Remove every fixed shift and day off of the $count selected people in this period? The planner then decides those days again.';
  }

  @override
  String admCleared(int count) {
    return '$count fixed assignments removed.';
  }

  @override
  String admApplySummary(
    int written,
    int replaced,
    int unchanged,
    int conflicts,
    int absent,
  ) {
    return '$written to write ($replaced replacing) · $unchanged already so · $conflicts fixed differently, kept · $absent on absences, skipped';
  }

  @override
  String get admApplyLegend =>
      'Faded: already fixed · Outlined: replaces · Amber: fixed differently, kept · Struck through: absent';

  @override
  String get admNewRun => 'New optimization';

  @override
  String get admNewRunHint =>
      'Computes a proposed plan for the period. Nothing changes on the roster until you take it over.';

  @override
  String get admRunPeopleHint => 'Leave empty to plan everyone.';

  @override
  String get admStartRun => 'Start optimization';

  @override
  String get admRunStarted => 'Optimization started.';

  @override
  String get admRunFinished => 'An optimization run finished.';

  @override
  String get admRuns => 'Runs';

  @override
  String get admNoRuns => 'No runs yet.';

  @override
  String get admDeleteRun => 'Delete run';

  @override
  String get admDeleteRunMessage =>
      'Delete this run and its proposed plan? The confirmed roster is not touched.';

  @override
  String get admProposedPlan => 'Proposed plan';

  @override
  String admResultStats(
    String status,
    int employees,
    int assignments,
    String objective,
  ) {
    return 'Status $status · $employees people · $assignments shifts · objective $objective';
  }

  @override
  String get admVerify => 'Check with assistant';

  @override
  String get admTakeAsPlan => 'Take as plan';

  @override
  String admTakeAsPlanMessage(String range) {
    return 'Overwrite the confirmed roster for $range with this proposal?';
  }

  @override
  String admTakenAsPlan(int count) {
    return '$count roster entries written.';
  }

  @override
  String get admResultEmpty => 'This run produced no plan.';

  @override
  String get admThisMonth => 'This month';

  @override
  String get admLastMonth => 'Last month';

  @override
  String get admThisQuarter => 'This quarter';

  @override
  String get admLast3Months => 'Last 3 months';

  @override
  String get admOnlyWorking => 'Only staff with shifts';

  @override
  String get admFairnessEmpty =>
      'Nobody has a confirmed shift in this period yet.';

  @override
  String admSpread(String min, String max, String avg) {
    return '$min–$max (avg $avg)';
  }

  @override
  String admFairnessWorkingNote(int working, int total) {
    return 'Ranges cover the $working of $total staff with at least one shift.';
  }

  @override
  String get admColShifts => 'Shifts';

  @override
  String get admColHours => 'Hours';

  @override
  String get admColTarget => 'vs target';

  @override
  String get admColNights => 'Nights';

  @override
  String get admColWeekend => 'Weekend days';

  @override
  String get admColWishes => 'Wishes granted';

  @override
  String get admColAbsent => 'Absent';

  @override
  String get admNameFixed => 'A workstation keeps its name once created.';

  @override
  String get admPersonalLimits => 'Personal limits';

  @override
  String get admPersonalLimitsHint =>
      'What this employee may be planned for beyond the ward\'s rules.';

  @override
  String get admMaxNightsPerMonth => 'Max nights / month';

  @override
  String get admMaxWeekendsPerMonth => 'Max weekends / month';

  @override
  String get admNoLimit => 'No limit';

  @override
  String get admNoNightShifts => 'Never on a night shift';

  @override
  String get admNoNightShiftsHint =>
      'Always enforced, whatever the tenant\'s personal-limits mode.';

  @override
  String get admPreferredDaysOff => 'Preferred days off';

  @override
  String get admHolidays => 'Holidays';

  @override
  String get admHolidaysHint => 'Public holidays of the configured state';

  @override
  String get admHolidaysIntro =>
      'A holiday runs on its shifts\' Sunday times and counts as a weekend day for the planner.';

  @override
  String get admHolidaysDisabled =>
      'Holidays are switched off for this deployment.';

  @override
  String get admHolidaysEmpty => 'No holidays stored for this range yet.';

  @override
  String get admSyncHolidays => 'Refresh from source';

  @override
  String get admHolidaysSynced => 'Holidays refreshed';

  @override
  String get admBackendInfo => 'Backend';

  @override
  String admBackendVersion(String version) {
    return 'Version $version';
  }

  @override
  String admBackendCommit(String commit) {
    return 'Commit $commit';
  }

  @override
  String admBackendBuildDate(String date) {
    return 'Built $date';
  }

  @override
  String get admWishScheduleTitle => 'Open automatically';

  @override
  String get admWishScheduleHint =>
      'Switches the window to \"always open\" on a recurring schedule, and back to closed after it has been open long enough.';

  @override
  String get admWishScheduleUnit => 'Every';

  @override
  String get admWishScheduleUnitDays => 'day(s)';

  @override
  String get admWishScheduleUnitWeeks => 'week(s)';

  @override
  String get admWishScheduleUnitMonths => 'month(s)';

  @override
  String get admWishScheduleWeekday => 'On';

  @override
  String get admWishScheduleDayOfMonth => 'On day';

  @override
  String get admWishScheduleTime => 'Time (UTC)';

  @override
  String get admWishScheduleOpenDays => 'Stays open for';

  @override
  String get admWishScheduleOpenDaysUnit => 'day(s)';

  @override
  String admWishScheduleNextChangeOpens(String when) {
    return 'Opens $when';
  }

  @override
  String admWishScheduleNextChangeCloses(String when) {
    return 'Closes $when';
  }
}
