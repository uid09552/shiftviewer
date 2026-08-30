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
}
