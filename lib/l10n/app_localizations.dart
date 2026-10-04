import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Application name, shown in the app bar and on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Shift Viewer'**
  String get appTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your shift schedule'**
  String get signInSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Redirecting…'**
  String get signingIn;

  /// No description provided for @loginUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Login is not supported on this platform.'**
  String get loginUnsupported;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get connectionSettings;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @navMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get navMonth;

  /// No description provided for @navWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get navWeek;

  /// No description provided for @navDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get navDay;

  /// Bottom navigation label for the shift wish planner.
  ///
  /// In en, this message translates to:
  /// **'Wishes'**
  String get navWishes;

  /// No description provided for @openDayView.
  ///
  /// In en, this message translates to:
  /// **'Open day view'**
  String get openDayView;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @allEmployees.
  ///
  /// In en, this message translates to:
  /// **'All employees'**
  String get allEmployees;

  /// Calendar title for a week that stays inside one month.
  ///
  /// In en, this message translates to:
  /// **'{month} {year} · W{week}'**
  String weekTitle(String month, String year, int week);

  /// Calendar title for a week spanning two months.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to} {year}'**
  String weekSpanTitle(String from, String to, String year);

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured. Open settings to set the API URL.'**
  String get notConfigured;

  /// An API failure with its HTTP status code.
  ///
  /// In en, this message translates to:
  /// **'{message} ({code})'**
  String errorWithCode(String message, int code);

  /// No description provided for @noShiftsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No shifts scheduled'**
  String get noShiftsScheduled;

  /// How many employees are rostered on the selected day.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 working} other{{count} working}}'**
  String workingCount(int count);

  /// No description provided for @offNoShift.
  ///
  /// In en, this message translates to:
  /// **'Off — no shift'**
  String get offNoShift;

  /// No description provided for @yourShift.
  ///
  /// In en, this message translates to:
  /// **'YOUR SHIFT'**
  String get yourShift;

  /// No description provided for @noWorkstation.
  ///
  /// In en, this message translates to:
  /// **'No workstation assigned'**
  String get noWorkstation;

  /// No description provided for @offNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Off / not scheduled'**
  String get offNotScheduled;

  /// No description provided for @unassignedWorkstation.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedWorkstation;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'absent'**
  String get absent;

  /// No description provided for @resizeDayOverview.
  ///
  /// In en, this message translates to:
  /// **'Drag to resize the day overview · double tap to reset'**
  String get resizeDayOverview;

  /// No description provided for @shiftWish.
  ///
  /// In en, this message translates to:
  /// **'Shift wish'**
  String get shiftWish;

  /// No description provided for @addShiftWish.
  ///
  /// In en, this message translates to:
  /// **'Add shift wish'**
  String get addShiftWish;

  /// Chip label showing the shift the employee wished for.
  ///
  /// In en, this message translates to:
  /// **'Wish: {shift}'**
  String wishFor(String shift);

  /// No description provided for @unknownShift.
  ///
  /// In en, this message translates to:
  /// **'unknown shift'**
  String get unknownShift;

  /// No description provided for @wishDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The planner rewards fulfilling a wish, but never guarantees it.'**
  String get wishDisclaimer;

  /// No description provided for @notScheduledOnWeekday.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled on this weekday'**
  String get notScheduledOnWeekday;

  /// No description provided for @removeWish.
  ///
  /// In en, this message translates to:
  /// **'Remove wish'**
  String get removeWish;

  /// Withdraws every wish the current scope covers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Remove wish} other{Remove {count} wishes}}'**
  String removeWishCount(int count);

  /// No description provided for @scopeDay.
  ///
  /// In en, this message translates to:
  /// **'This day'**
  String get scopeDay;

  /// Scope button for the days the user painted in the calendar.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String scopeSelection(int count);

  /// No description provided for @scopeWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get scopeWeek;

  /// No description provided for @scopeMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get scopeMonth;

  /// No description provided for @dayRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String dayRange(String from, String to);

  /// How much of a multi-day scope a shift can actually cover.
  ///
  /// In en, this message translates to:
  /// **'Runs on {matching} of {total} days'**
  String shiftRunsOnDays(int matching, int total);

  /// Result of placing a wish across one or more days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No day to wish for} =1{Wish placed: {shift}} other{{shift} wished for {count} days}}'**
  String wishBatchPlaced(int count, String shift);

  /// No description provided for @wishBatchSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day skipped, the shift does not run then} other{{count} days skipped, the shift does not run then}}'**
  String wishBatchSkipped(int count);

  /// No description provided for @wishBatchRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No wish to remove} =1{Wish removed} other{{count} wishes removed}}'**
  String wishBatchRemoved(int count);

  /// No description provided for @wishSelectEmployeeFirst.
  ///
  /// In en, this message translates to:
  /// **'Select an employee first.'**
  String get wishSelectEmployeeFirst;

  /// No description provided for @wishPickEmployeeFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick an employee before placing a shift wish.'**
  String get wishPickEmployeeFirst;

  /// No description provided for @wishNoShiftsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No shifts available to wish for.'**
  String get wishNoShiftsAvailable;

  /// No description provided for @wishConflict.
  ///
  /// In en, this message translates to:
  /// **'A wish for this day already exists — reload and try again.'**
  String get wishConflict;

  /// Status chip: the tenant accepts wishes for any date.
  ///
  /// In en, this message translates to:
  /// **'Wishes open'**
  String get wishModeOpen;

  /// Status chip: wishes are accepted only inside this window.
  ///
  /// In en, this message translates to:
  /// **'Wishes {from} – {to}'**
  String wishModeRange(String from, String to);

  /// Status chip: the tenant accepts no wishes at all.
  ///
  /// In en, this message translates to:
  /// **'Wishes deactivated'**
  String get wishModeDisabled;

  /// No description provided for @wishWindowOpenDetail.
  ///
  /// In en, this message translates to:
  /// **'Shift wishes can be placed for any date.'**
  String get wishWindowOpenDetail;

  /// No description provided for @wishWindowRangeDetail.
  ///
  /// In en, this message translates to:
  /// **'Shift wishes can only be placed for {from} – {to}.'**
  String wishWindowRangeDetail(String from, String to);

  /// No description provided for @wishWindowClosedDetail.
  ///
  /// In en, this message translates to:
  /// **'Shift wishes are deactivated right now.'**
  String get wishWindowClosedDetail;

  /// No description provided for @wishOutsideWindow.
  ///
  /// In en, this message translates to:
  /// **'This day is outside the wish window.'**
  String get wishOutsideWindow;

  /// How many days a bulk edit had to leave alone because the wish window does not cover them.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day outside the wish window} other{{count} days outside the wish window}}'**
  String wishBatchBlocked(int count);

  /// No description provided for @wishPlannerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to wish for a shift · long press and drag across days to plan several at once.'**
  String get wishPlannerHint;

  /// No description provided for @wishPlannerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No wishes in this month yet'**
  String get wishPlannerEmpty;

  /// Number of wishes the employee placed in the visible month.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No wishes} =1{1 wish} other{{count} wishes}}'**
  String wishPlannerCount(int count);

  /// No description provided for @wishPlannerPickEmployee.
  ///
  /// In en, this message translates to:
  /// **'Pick an employee to plan their shift wishes.'**
  String get wishPlannerPickEmployee;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// Sends one confirmed shift to Google Calendar's new-event form.
  ///
  /// In en, this message translates to:
  /// **'Add to Google Calendar'**
  String get addToGoogleCalendar;

  /// No description provided for @calendarExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Add shifts to calendar'**
  String get calendarExportTitle;

  /// Whose shifts are being exported, and over which dates.
  ///
  /// In en, this message translates to:
  /// **'{who} · {from} – {to}'**
  String calendarExportSubtitle(String who, String from, String to);

  /// How many shifts the export covers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No confirmed shifts} =1{1 confirmed shift} other{{count} confirmed shifts}}'**
  String calendarExportCount(int count);

  /// Rostered days the employee is not present are not appointments, so they are skipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 absence left out} other{{count} absences left out}}'**
  String calendarExportAbsences(int count);

  /// No description provided for @calendarExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No confirmed shifts in this range.'**
  String get calendarExportEmpty;

  /// No description provided for @calendarExportMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String calendarExportMore(int count);

  /// No description provided for @calendarShareIcs.
  ///
  /// In en, this message translates to:
  /// **'Share calendar file'**
  String get calendarShareIcs;

  /// No description provided for @calendarDownloadIcs.
  ///
  /// In en, this message translates to:
  /// **'Download calendar file'**
  String get calendarDownloadIcs;

  /// No description provided for @calendarIcsHint.
  ///
  /// In en, this message translates to:
  /// **'Open the file with Google Calendar to import every shift at once.'**
  String get calendarIcsHint;

  /// No description provided for @calendarIcsHintWeb.
  ///
  /// In en, this message translates to:
  /// **'Import it in Google Calendar under Settings ▸ Import & export.'**
  String get calendarIcsHintWeb;

  /// No description provided for @calendarGoogleHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the Google Calendar app, or its website.'**
  String get calendarGoogleHint;

  /// No description provided for @calendarOpenedGoogle.
  ///
  /// In en, this message translates to:
  /// **'Opened in Google Calendar.'**
  String get calendarOpenedGoogle;

  /// Confirmation that the .ics file was handed to the platform.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shift exported to {file}} other{{count} shifts exported to {file}}}'**
  String calendarIcsReady(int count, String file);

  /// No description provided for @calendarExportDismissed.
  ///
  /// In en, this message translates to:
  /// **'Nothing was exported.'**
  String get calendarExportDismissed;

  /// No description provided for @calendarExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export: {reason}'**
  String calendarExportFailed(String reason);

  /// No description provided for @calendarAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @sectionServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get sectionServer;

  /// No description provided for @apiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get apiBaseUrl;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @enterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get enterValidUrl;

  /// No description provided for @sectionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in (OIDC · PKCE)'**
  String get sectionSignIn;

  /// No description provided for @issuerUrl.
  ///
  /// In en, this message translates to:
  /// **'Issuer / realm URL'**
  String get issuerUrl;

  /// No description provided for @clientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientId;

  /// No description provided for @clientIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Same client as the API gateway · PKCE (S256)'**
  String get clientIdHelper;

  /// No description provided for @redirectUri.
  ///
  /// In en, this message translates to:
  /// **'Redirect URI'**
  String get redirectUri;

  /// No description provided for @sectionManualLogin.
  ///
  /// In en, this message translates to:
  /// **'Manual login (fallback)'**
  String get sectionManualLogin;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @bearerToken.
  ///
  /// In en, this message translates to:
  /// **'Bearer token (optional)'**
  String get bearerToken;

  /// No description provided for @bearerTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Used instead of username/password when set'**
  String get bearerTokenHelper;

  /// No description provided for @sectionCalendarScope.
  ///
  /// In en, this message translates to:
  /// **'Calendar scope'**
  String get sectionCalendarScope;

  /// No description provided for @employeeIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Employee ID (optional)'**
  String get employeeIdOptional;

  /// No description provided for @employeeIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Show only this employee\'s roster; leave empty for all'**
  String get employeeIdHelper;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {reason}'**
  String connectionFailed(String reason);

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionAppearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @shiftInsights.
  ///
  /// In en, this message translates to:
  /// **'Shift details'**
  String get shiftInsights;

  /// No description provided for @employeeInsights.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeeInsights;

  /// No description provided for @showShiftDetails.
  ///
  /// In en, this message translates to:
  /// **'Show shift details and statistics'**
  String get showShiftDetails;

  /// No description provided for @showEmployeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Show this employee\'s details'**
  String get showEmployeeDetails;

  /// No description provided for @analysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server statistics are unavailable — the numbers below come from the roster.'**
  String get analysisUnavailable;

  /// No description provided for @statRostered.
  ///
  /// In en, this message translates to:
  /// **'Rostered'**
  String get statRostered;

  /// No description provided for @statPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get statPresent;

  /// No description provided for @statAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get statAbsent;

  /// No description provided for @statPlannedHours.
  ///
  /// In en, this message translates to:
  /// **'Planned hours'**
  String get statPlannedHours;

  /// No description provided for @statWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get statWorking;

  /// No description provided for @coverageMet.
  ///
  /// In en, this message translates to:
  /// **'Fully staffed'**
  String get coverageMet;

  /// How many people the shift is missing against its weekday minimum.
  ///
  /// In en, this message translates to:
  /// **'{count} short'**
  String coverageShort(int count);

  /// No description provided for @coverageOver.
  ///
  /// In en, this message translates to:
  /// **'Over capacity'**
  String get coverageOver;

  /// No description provided for @coverageNoTarget.
  ///
  /// In en, this message translates to:
  /// **'No staffing target'**
  String get coverageNoTarget;

  /// No description provided for @staffingNeedsMin.
  ///
  /// In en, this message translates to:
  /// **'Needs at least {min}'**
  String staffingNeedsMin(int min);

  /// No description provided for @staffingNeedsRange.
  ///
  /// In en, this message translates to:
  /// **'Needs {min}–{max}'**
  String staffingNeedsRange(int min, int max);

  /// Recovery days the planner keeps free after this shift.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rest day after} other{{count} rest days after}}'**
  String restDaysAfter(int count);

  /// No description provided for @shareOfDay.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the day\'s staff'**
  String shareOfDay(int percent);

  /// No description provided for @dayHeadcount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person working that day} other{{count} people working that day}}'**
  String dayHeadcount(int count);

  /// No description provided for @sectionWorkstations.
  ///
  /// In en, this message translates to:
  /// **'Workstations'**
  String get sectionWorkstations;

  /// No description provided for @sectionAbsences.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get sectionAbsences;

  /// No description provided for @sectionWishes.
  ///
  /// In en, this message translates to:
  /// **'Shift wishes'**
  String get sectionWishes;

  /// No description provided for @sectionWeekPattern.
  ///
  /// In en, this message translates to:
  /// **'Across the week'**
  String get sectionWeekPattern;

  /// No description provided for @sectionDayContext.
  ///
  /// In en, this message translates to:
  /// **'The rest of the day'**
  String get sectionDayContext;

  /// No description provided for @sectionOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'On this day'**
  String get sectionOnThisDay;

  /// No description provided for @sectionCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get sectionCapabilities;

  /// No description provided for @sectionAvailableShifts.
  ///
  /// In en, this message translates to:
  /// **'Can be scheduled for'**
  String get sectionAvailableShifts;

  /// No description provided for @sectionRangeTotals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get sectionRangeTotals;

  /// No description provided for @peopleHere.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleHere(int count);

  /// No description provided for @hoursValue.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String hoursValue(String hours);

  /// No description provided for @plannedAllShifts.
  ///
  /// In en, this message translates to:
  /// **'{count} planned here across all shifts'**
  String plannedAllShifts(int count);

  /// No description provided for @stationBelowMinimum.
  ///
  /// In en, this message translates to:
  /// **'Below its minimum of {min}'**
  String stationBelowMinimum(int min);

  /// No description provided for @stationAboveMaximum.
  ///
  /// In en, this message translates to:
  /// **'Above its maximum of {max}'**
  String stationAboveMaximum(int max);

  /// No description provided for @stationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Workstation disabled'**
  String get stationUnavailable;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium priority'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low priority'**
  String get priorityLow;

  /// No description provided for @wishesPlaced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No wishes for this shift} =1{1 wish for this shift} other{{count} wishes for this shift}}'**
  String wishesPlaced(int count);

  /// No description provided for @wishesGrantedOf.
  ///
  /// In en, this message translates to:
  /// **'{granted} of {count} granted'**
  String wishesGrantedOf(int granted, int count);

  /// No description provided for @absenceSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get absenceSick;

  /// No description provided for @absenceDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get absenceDayOff;

  /// No description provided for @absenceHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get absenceHoliday;

  /// No description provided for @absenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get absenceUnavailable;

  /// No description provided for @absenceFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get absenceFree;

  /// No description provided for @absenceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get absenceUnknown;

  /// Which date range an employee's totals were computed from.
  ///
  /// In en, this message translates to:
  /// **'Counted over {from} – {to}'**
  String countedOver(String from, String to);

  /// No description provided for @monthlyHoursTarget.
  ///
  /// In en, this message translates to:
  /// **'{hours} h per month'**
  String monthlyHoursTarget(String hours);

  /// No description provided for @monthlyLoad.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the monthly target'**
  String monthlyLoad(int percent);

  /// No description provided for @statDaysWorked.
  ///
  /// In en, this message translates to:
  /// **'Days worked'**
  String get statDaysWorked;

  /// No description provided for @statDaysRostered.
  ///
  /// In en, this message translates to:
  /// **'Days rostered'**
  String get statDaysRostered;

  /// No description provided for @skillLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String skillLevel(int level);

  /// No description provided for @noCapabilities.
  ///
  /// In en, this message translates to:
  /// **'No capabilities recorded'**
  String get noCapabilities;

  /// No description provided for @anyShift.
  ///
  /// In en, this message translates to:
  /// **'Any shift'**
  String get anyShift;

  /// No description provided for @nothingRostered.
  ///
  /// In en, this message translates to:
  /// **'Nothing rostered on this day'**
  String get nothingRostered;

  /// No description provided for @noRosterInRange.
  ///
  /// In en, this message translates to:
  /// **'Nothing rostered in the loaded range'**
  String get noRosterInRange;

  /// No description provided for @longPressForDetails.
  ///
  /// In en, this message translates to:
  /// **'Long press to list who is behind this'**
  String get longPressForDetails;

  /// No description provided for @listNothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to list here'**
  String get listNothingToShow;

  /// No description provided for @sectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get sectionSchedule;

  /// One weekday of a shift's schedule inside a detail list.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} · needs {min}'**
  String scheduleWeekdayLine(String start, String end, int min);

  /// No description provided for @scheduleWeekdayOff.
  ///
  /// In en, this message translates to:
  /// **'Does not run'**
  String get scheduleWeekdayOff;

  /// No description provided for @othersWithCapability.
  ///
  /// In en, this message translates to:
  /// **'Others with this capability'**
  String get othersWithCapability;

  /// No description provided for @noOthersWithCapability.
  ///
  /// In en, this message translates to:
  /// **'Nobody else on record with it'**
  String get noOthersWithCapability;

  /// No description provided for @wishGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get wishGranted;

  /// No description provided for @wishNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get wishNotGranted;

  /// No description provided for @detailsEveryoneWorking.
  ///
  /// In en, this message translates to:
  /// **'Everyone working'**
  String get detailsEveryoneWorking;

  /// No description provided for @detailsAtWorkstation.
  ///
  /// In en, this message translates to:
  /// **'People at this workstation'**
  String get detailsAtWorkstation;

  /// No description provided for @detailsOnThisShift.
  ///
  /// In en, this message translates to:
  /// **'People on this shift'**
  String get detailsOnThisShift;

  /// No description provided for @detailsMissingPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person short of the minimum} other{{count} people short of the minimum}}'**
  String detailsMissingPeople(int count);

  /// Row title for one day inside a per-day detail list.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {date}'**
  String detailsOnDay(String weekday, String date);

  /// No description provided for @capabilityOfLevel.
  ///
  /// In en, this message translates to:
  /// **'{group} · level {level}'**
  String capabilityOfLevel(String group, int level);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @adminForbidden.
  ///
  /// In en, this message translates to:
  /// **'Your role may not do this.'**
  String get adminForbidden;

  /// No description provided for @admManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get admManagement;

  /// No description provided for @admToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get admToday;

  /// No description provided for @admSectionPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get admSectionPlanning;

  /// No description provided for @admSectionConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get admSectionConfiguration;

  /// No description provided for @admRoster.
  ///
  /// In en, this message translates to:
  /// **'Roster'**
  String get admRoster;

  /// No description provided for @admRosterHint.
  ///
  /// In en, this message translates to:
  /// **'Edit who works what, week by week'**
  String get admRosterHint;

  /// No description provided for @admRotations.
  ///
  /// In en, this message translates to:
  /// **'Rotations'**
  String get admRotations;

  /// No description provided for @admRotationsHint.
  ///
  /// In en, this message translates to:
  /// **'Recurring rhythms as fixed shifts'**
  String get admRotationsHint;

  /// No description provided for @admOptimizer.
  ///
  /// In en, this message translates to:
  /// **'Schedule optimizer'**
  String get admOptimizer;

  /// No description provided for @admOptimizerHint.
  ///
  /// In en, this message translates to:
  /// **'Generate, check and adopt a plan'**
  String get admOptimizerHint;

  /// No description provided for @admFairness.
  ///
  /// In en, this message translates to:
  /// **'Fairness'**
  String get admFairness;

  /// No description provided for @admFairnessHint.
  ///
  /// In en, this message translates to:
  /// **'Nights, weekends, hours and wishes per person'**
  String get admFairnessHint;

  /// No description provided for @admEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get admEmployees;

  /// No description provided for @admEmployeesHint.
  ///
  /// In en, this message translates to:
  /// **'Profiles, shifts, capabilities and leave'**
  String get admEmployeesHint;

  /// No description provided for @admShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get admShifts;

  /// No description provided for @admShiftsHint.
  ///
  /// In en, this message translates to:
  /// **'Times and staffing per weekday'**
  String get admShiftsHint;

  /// No description provided for @admWorkstations.
  ///
  /// In en, this message translates to:
  /// **'Workstations'**
  String get admWorkstations;

  /// No description provided for @admWorkstationsHint.
  ///
  /// In en, this message translates to:
  /// **'Staffing, required capabilities, closures'**
  String get admWorkstationsHint;

  /// No description provided for @admCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get admCapabilities;

  /// No description provided for @admCapabilitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Skills and their levels'**
  String get admCapabilitiesHint;

  /// No description provided for @admPlannerSettings.
  ///
  /// In en, this message translates to:
  /// **'Planner settings'**
  String get admPlannerSettings;

  /// No description provided for @admPlannerSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'How the optimizer weighs its goals'**
  String get admPlannerSettingsHint;

  /// No description provided for @admWishSettings.
  ///
  /// In en, this message translates to:
  /// **'Wish window'**
  String get admWishSettings;

  /// No description provided for @admWishSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'When employees may place shift wishes'**
  String get admWishSettingsHint;

  /// No description provided for @admUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get admUsers;

  /// No description provided for @admUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Sign-in accounts and roles'**
  String get admUsersHint;

  /// No description provided for @admAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get admAuditLog;

  /// No description provided for @admAuditLogHint.
  ///
  /// In en, this message translates to:
  /// **'Who changed what, and when'**
  String get admAuditLogHint;

  /// No description provided for @admAllStationsCovered.
  ///
  /// In en, this message translates to:
  /// **'Every open workstation has its minimum today.'**
  String get admAllStationsCovered;

  /// No description provided for @admUnderstaffedToday.
  ///
  /// In en, this message translates to:
  /// **'Below minimum today'**
  String get admUnderstaffedToday;

  /// No description provided for @admLatestRun.
  ///
  /// In en, this message translates to:
  /// **'Latest optimizer run: {status} · {date}'**
  String admLatestRun(String status, String date);

  /// No description provided for @admRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get admRecentActivity;

  /// No description provided for @admTaskRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get admTaskRunning;

  /// No description provided for @admTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get admTaskDone;

  /// No description provided for @admTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get admTaskFailed;

  /// No description provided for @admSearchEmployees.
  ///
  /// In en, this message translates to:
  /// **'Search employees…'**
  String get admSearchEmployees;

  /// No description provided for @admSearchManagement.
  ///
  /// In en, this message translates to:
  /// **'Search management…'**
  String get admSearchManagement;

  /// No description provided for @admNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing here matches that search.'**
  String get admNoMatches;

  /// No description provided for @admNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees.'**
  String get admNoEmployees;

  /// No description provided for @admRosterLegend.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to assign a shift, mark an absence or clear it. ★ = wish.'**
  String get admRosterLegend;

  /// No description provided for @admAbsenceShortSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get admAbsenceShortSick;

  /// No description provided for @admAbsenceShortDayOff.
  ///
  /// In en, this message translates to:
  /// **'Vac'**
  String get admAbsenceShortDayOff;

  /// No description provided for @admAbsenceShortHoliday.
  ///
  /// In en, this message translates to:
  /// **'Hol'**
  String get admAbsenceShortHoliday;

  /// No description provided for @admAbsenceShortFree.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get admAbsenceShortFree;

  /// No description provided for @admWishedFor.
  ///
  /// In en, this message translates to:
  /// **'Wished for: {shift}'**
  String admWishedFor(String shift);

  /// No description provided for @admShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get admShift;

  /// No description provided for @admNotOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'not scheduled this day'**
  String get admNotOnThisDay;

  /// No description provided for @admWorkstation.
  ///
  /// In en, this message translates to:
  /// **'Workstation'**
  String get admWorkstation;

  /// No description provided for @admClosed.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get admClosed;

  /// No description provided for @admAbsence.
  ///
  /// In en, this message translates to:
  /// **'Absence'**
  String get admAbsence;

  /// No description provided for @admClearDay.
  ///
  /// In en, this message translates to:
  /// **'Clear day'**
  String get admClearDay;

  /// No description provided for @admAddEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get admAddEmployee;

  /// No description provided for @admHoursPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{hours} h/month'**
  String admHoursPerMonth(String hours);

  /// No description provided for @admName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get admName;

  /// No description provided for @admEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get admEmail;

  /// No description provided for @admMonthlyHours.
  ///
  /// In en, this message translates to:
  /// **'Monthly hours target'**
  String get admMonthlyHours;

  /// No description provided for @admEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get admEnterNumber;

  /// No description provided for @admSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get admSaved;

  /// No description provided for @admSaveFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Save the employee first to assign shifts, capabilities and leave.'**
  String get admSaveFirstHint;

  /// No description provided for @admDeleteEmployee.
  ///
  /// In en, this message translates to:
  /// **'Delete employee'**
  String get admDeleteEmployee;

  /// No description provided for @admDeleteEmployeeMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Their roster, wishes and leave go with them.'**
  String admDeleteEmployeeMessage(String name);

  /// No description provided for @admLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave & unavailability'**
  String get admLeave;

  /// No description provided for @admLeaveHint.
  ///
  /// In en, this message translates to:
  /// **'Vacation and sick days go on the roster; unavailable days are respected by the optimizer.'**
  String get admLeaveHint;

  /// No description provided for @admAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get admAdd;

  /// No description provided for @admAddLeave.
  ///
  /// In en, this message translates to:
  /// **'Add leave'**
  String get admAddLeave;

  /// No description provided for @admPickDates.
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get admPickDates;

  /// No description provided for @admUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'The optimizer will not plan this person on these days.'**
  String get admUnavailableHint;

  /// No description provided for @admNoUpcomingLeave.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned.'**
  String get admNoUpcomingLeave;

  /// No description provided for @admPastLeave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 past entry} other{{count} past entries}}'**
  String admPastLeave(int count);

  /// No description provided for @admDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String admDayCount(int count);

  /// No description provided for @admRemoveLeave.
  ///
  /// In en, this message translates to:
  /// **'Remove leave'**
  String get admRemoveLeave;

  /// No description provided for @admRemoveLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {kind} for {range}?'**
  String admRemoveLeaveMessage(String kind, String range);

  /// No description provided for @admAddShift.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get admAddShift;

  /// No description provided for @admNoShifts.
  ///
  /// In en, this message translates to:
  /// **'No shifts yet.'**
  String get admNoShifts;

  /// No description provided for @admNoWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Runs on no weekday'**
  String get admNoWeekdays;

  /// No description provided for @admShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name'**
  String get admShortName;

  /// No description provided for @admOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get admOrder;

  /// No description provided for @admColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get admColor;

  /// No description provided for @admWeekdayTimesHint.
  ///
  /// In en, this message translates to:
  /// **'Times and head count per weekday. Switched-off days have no such shift.'**
  String get admWeekdayTimesHint;

  /// No description provided for @admStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get admStart;

  /// No description provided for @admEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get admEnd;

  /// No description provided for @admMinStaff.
  ///
  /// In en, this message translates to:
  /// **'Minimum staff'**
  String get admMinStaff;

  /// No description provided for @admMaxStaff.
  ///
  /// In en, this message translates to:
  /// **'Maximum staff (∞ = none)'**
  String get admMaxStaff;

  /// No description provided for @admRestDaysAfter.
  ///
  /// In en, this message translates to:
  /// **'Rest days after'**
  String get admRestDaysAfter;

  /// No description provided for @admDeleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete shift'**
  String get admDeleteShift;

  /// No description provided for @admDeleteShiftMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Planned days with this shift lose it.'**
  String admDeleteShiftMessage(String name);

  /// No description provided for @admAddWorkstation.
  ///
  /// In en, this message translates to:
  /// **'Add workstation'**
  String get admAddWorkstation;

  /// No description provided for @admNoWorkstations.
  ///
  /// In en, this message translates to:
  /// **'No workstations yet.'**
  String get admNoWorkstations;

  /// No description provided for @admInactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get admInactive;

  /// No description provided for @admActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get admActive;

  /// No description provided for @admActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Inactive workstations are not staffed.'**
  String get admActiveHint;

  /// No description provided for @admPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get admPriority;

  /// No description provided for @admPerShift.
  ///
  /// In en, this message translates to:
  /// **'per shift'**
  String get admPerShift;

  /// No description provided for @admRunsInShifts.
  ///
  /// In en, this message translates to:
  /// **'Runs in shifts'**
  String get admRunsInShifts;

  /// No description provided for @admRunsInShiftsHint.
  ///
  /// In en, this message translates to:
  /// **'None selected means every shift.'**
  String get admRunsInShiftsHint;

  /// No description provided for @admRequiredCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Required capabilities'**
  String get admRequiredCapabilities;

  /// No description provided for @admClosures.
  ///
  /// In en, this message translates to:
  /// **'Closures'**
  String get admClosures;

  /// No description provided for @admClosuresHint.
  ///
  /// In en, this message translates to:
  /// **'Periods nobody may be planned here.'**
  String get admClosuresHint;

  /// No description provided for @admNoClosures.
  ///
  /// In en, this message translates to:
  /// **'No closures.'**
  String get admNoClosures;

  /// No description provided for @admDeleteWorkstation.
  ///
  /// In en, this message translates to:
  /// **'Delete workstation'**
  String get admDeleteWorkstation;

  /// No description provided for @admDeleteWorkstationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String admDeleteWorkstationMessage(String name);

  /// No description provided for @admAddCapability.
  ///
  /// In en, this message translates to:
  /// **'Add capability'**
  String get admAddCapability;

  /// No description provided for @admEditCapability.
  ///
  /// In en, this message translates to:
  /// **'Edit capability'**
  String get admEditCapability;

  /// No description provided for @admNoSkillGroup.
  ///
  /// In en, this message translates to:
  /// **'Without skill group'**
  String get admNoSkillGroup;

  /// No description provided for @admSkillGroup.
  ///
  /// In en, this message translates to:
  /// **'Skill group'**
  String get admSkillGroup;

  /// No description provided for @admSkillGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Within a group, a higher level may cover a lower one.'**
  String get admSkillGroupHint;

  /// No description provided for @admLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get admLevel;

  /// No description provided for @admDeleteCapability.
  ///
  /// In en, this message translates to:
  /// **'Delete capability'**
  String get admDeleteCapability;

  /// No description provided for @admDeleteCapabilityMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? It is removed from every employee and workstation.'**
  String admDeleteCapabilityMessage(String name);

  /// No description provided for @admExpertValues.
  ///
  /// In en, this message translates to:
  /// **'Expert values'**
  String get admExpertValues;

  /// No description provided for @admDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get admDiscardChanges;

  /// No description provided for @admDiscardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Your changes have not been saved.'**
  String get admDiscardChangesMessage;

  /// No description provided for @admDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get admDiscard;

  /// No description provided for @admLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String admLastUpdated(String date);

  /// No description provided for @admPsUseCase.
  ///
  /// In en, this message translates to:
  /// **'Use case'**
  String get admPsUseCase;

  /// No description provided for @admPsUseCaseHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the goal that fits this ward — it fills in every setting below, which you can still fine-tune. Solver effort is never touched.'**
  String get admPsUseCaseHint;

  /// No description provided for @admPsCustomMix.
  ///
  /// In en, this message translates to:
  /// **'Custom mix — no preset matches these values.'**
  String get admPsCustomMix;

  /// No description provided for @admTplBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get admTplBalanced;

  /// No description provided for @admTplBalancedHint.
  ///
  /// In en, this message translates to:
  /// **'The shipped defaults: coverage, fairness and wishes weighed against each other.'**
  String get admTplBalancedHint;

  /// No description provided for @admTplFairness.
  ///
  /// In en, this message translates to:
  /// **'Equal share'**
  String get admTplFairness;

  /// No description provided for @admTplFairnessHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone works a comparable amount. Hour targets win over wishes and continuity.'**
  String get admTplFairnessHint;

  /// No description provided for @admTplWishes.
  ///
  /// In en, this message translates to:
  /// **'Wishes first'**
  String get admTplWishes;

  /// No description provided for @admTplWishesHint.
  ///
  /// In en, this message translates to:
  /// **'Requested shifts are granted whenever the plan allows, at some cost to even hours.'**
  String get admTplWishesHint;

  /// No description provided for @admTplCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage first'**
  String get admTplCoverage;

  /// No description provided for @admTplCoverageHint.
  ///
  /// In en, this message translates to:
  /// **'Critical workstations get staffed before anything else, with looser rest limits.'**
  String get admTplCoverageHint;

  /// No description provided for @admTplStability.
  ///
  /// In en, this message translates to:
  /// **'Stable rosters'**
  String get admTplStability;

  /// No description provided for @admTplStabilityHint.
  ///
  /// In en, this message translates to:
  /// **'Long, predictable blocks on the same shift instead of frequent rotation.'**
  String get admTplStabilityHint;

  /// No description provided for @admTplWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Staff wellbeing'**
  String get admTplWellbeing;

  /// No description provided for @admTplWellbeingHint.
  ///
  /// In en, this message translates to:
  /// **'Longer rest, capped weeks and fatigue spread evenly — the gentlest plan the ward allows.'**
  String get admTplWellbeingHint;

  /// No description provided for @admPsRest.
  ///
  /// In en, this message translates to:
  /// **'Rest & recovery'**
  String get admPsRest;

  /// No description provided for @admPsRestHint.
  ///
  /// In en, this message translates to:
  /// **'Hard limits on consecutive work and rest between shifts'**
  String get admPsRestHint;

  /// No description provided for @admPsNightRecovery.
  ///
  /// In en, this message translates to:
  /// **'Night shift recovery'**
  String get admPsNightRecovery;

  /// No description provided for @admPsNightRecoveryHint.
  ///
  /// In en, this message translates to:
  /// **'Days off required after a night shift.'**
  String get admPsNightRecoveryHint;

  /// No description provided for @admPsMinRest.
  ///
  /// In en, this message translates to:
  /// **'Minimum rest between shifts'**
  String get admPsMinRest;

  /// No description provided for @admPsMinRestHint.
  ///
  /// In en, this message translates to:
  /// **'Rest required between shifts on consecutive days.'**
  String get admPsMinRestHint;

  /// No description provided for @admPsMaxConsecutive.
  ///
  /// In en, this message translates to:
  /// **'Max consecutive days'**
  String get admPsMaxConsecutive;

  /// No description provided for @admPsMaxConsecutiveHint.
  ///
  /// In en, this message translates to:
  /// **'Longest run of working days allowed.'**
  String get admPsMaxConsecutiveHint;

  /// No description provided for @admPsMaxPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Max days per week'**
  String get admPsMaxPerWeek;

  /// No description provided for @admPsMaxPerWeekHint.
  ///
  /// In en, this message translates to:
  /// **'Working days allowed per calendar week.'**
  String get admPsMaxPerWeekHint;

  /// No description provided for @admUnitDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Off} =1{1 day} other{{count} days}}'**
  String admUnitDays(int count);

  /// No description provided for @admUnitHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String admUnitHours(int count);

  /// No description provided for @admOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get admOff;

  /// No description provided for @admPsFairness.
  ///
  /// In en, this message translates to:
  /// **'Fairness & hours'**
  String get admPsFairness;

  /// No description provided for @admPsFairnessHint.
  ///
  /// In en, this message translates to:
  /// **'How evenly work is shared, and how closely hour targets are met'**
  String get admPsFairnessHint;

  /// No description provided for @admPsEquality.
  ///
  /// In en, this message translates to:
  /// **'Fairness'**
  String get admPsEquality;

  /// No description provided for @admPsEqualityHint.
  ///
  /// In en, this message translates to:
  /// **'Spreads hours more evenly across employees.'**
  String get admPsEqualityHint;

  /// No description provided for @admPsMonthlyTarget.
  ///
  /// In en, this message translates to:
  /// **'Monthly hours target'**
  String get admPsMonthlyTarget;

  /// No description provided for @admPsMonthlyTargetHint.
  ///
  /// In en, this message translates to:
  /// **'Pushes towards each employee\'s monthly hours target.'**
  String get admPsMonthlyTargetHint;

  /// No description provided for @admPsWeeklyBand.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours band'**
  String get admPsWeeklyBand;

  /// No description provided for @admPsWeeklyBandHint.
  ///
  /// In en, this message translates to:
  /// **'A soft floor and ceiling per week, on top of the monthly target.'**
  String get admPsWeeklyBandHint;

  /// No description provided for @admPsWeeklyMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum per week'**
  String get admPsWeeklyMin;

  /// No description provided for @admPsWeeklyMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum per week'**
  String get admPsWeeklyMax;

  /// No description provided for @admPsBandStrength.
  ///
  /// In en, this message translates to:
  /// **'Band strength'**
  String get admPsBandStrength;

  /// No description provided for @admPsCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage & continuity'**
  String get admPsCoverage;

  /// No description provided for @admPsCoverageHint.
  ///
  /// In en, this message translates to:
  /// **'Which workstations are staffed first, and how stable shift patterns stay'**
  String get admPsCoverageHint;

  /// No description provided for @admPsPriority.
  ///
  /// In en, this message translates to:
  /// **'Workstation priority'**
  String get admPsPriority;

  /// No description provided for @admPsPriorityHint.
  ///
  /// In en, this message translates to:
  /// **'How sharply high-priority workstations are staffed first.'**
  String get admPsPriorityHint;

  /// No description provided for @admPrioIgnore.
  ///
  /// In en, this message translates to:
  /// **'Treat all the same'**
  String get admPrioIgnore;

  /// No description provided for @admPrioSoft.
  ///
  /// In en, this message translates to:
  /// **'Slight preference'**
  String get admPrioSoft;

  /// No description provided for @admPrioBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get admPrioBalanced;

  /// No description provided for @admPrioStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict order'**
  String get admPrioStrict;

  /// No description provided for @admCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get admCustom;

  /// No description provided for @admCustomValue.
  ///
  /// In en, this message translates to:
  /// **'Custom ({value})'**
  String admCustomValue(String value);

  /// No description provided for @admPsMinStaffing.
  ///
  /// In en, this message translates to:
  /// **'Minimum staffing'**
  String get admPsMinStaffing;

  /// No description provided for @admPsMinStaffingHint.
  ///
  /// In en, this message translates to:
  /// **'Whether the minimum per shift and workstation is a target or a requirement.'**
  String get admPsMinStaffingHint;

  /// No description provided for @admPsMinStaffingSoft.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get admPsMinStaffingSoft;

  /// No description provided for @admPsMinStaffingHard.
  ///
  /// In en, this message translates to:
  /// **'Requirement'**
  String get admPsMinStaffingHard;

  /// No description provided for @admPsMinStaffingHardWarning.
  ///
  /// In en, this message translates to:
  /// **'As a requirement, a period without enough available employees produces no plan at all instead of an understaffed one.'**
  String get admPsMinStaffingHardWarning;

  /// No description provided for @admPsPersonalLimits.
  ///
  /// In en, this message translates to:
  /// **'Personal limits'**
  String get admPsPersonalLimits;

  /// No description provided for @admPsPersonalLimitsHint.
  ///
  /// In en, this message translates to:
  /// **'How an employee\'s own max nights/weekends per month hold. Never scheduling nights is always strict.'**
  String get admPsPersonalLimitsHint;

  /// No description provided for @admPsPersonalLimitsHard.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get admPsPersonalLimitsHard;

  /// No description provided for @admPsPersonalLimitsSoft.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get admPsPersonalLimitsSoft;

  /// No description provided for @admPsKeepRotations.
  ///
  /// In en, this message translates to:
  /// **'Keep rotations'**
  String get admPsKeepRotations;

  /// No description provided for @admPsKeepRotationsHint.
  ///
  /// In en, this message translates to:
  /// **'Fixed shifts and days off from rotations are planned first.'**
  String get admPsKeepRotationsHint;

  /// No description provided for @admPsKeepRotationsOff.
  ///
  /// In en, this message translates to:
  /// **'Rotations are ignored when planning. They stay saved and apply again once this is back on.'**
  String get admPsKeepRotationsOff;

  /// No description provided for @admPsContinuity.
  ///
  /// In en, this message translates to:
  /// **'Shift continuity'**
  String get admPsContinuity;

  /// No description provided for @admPsContinuityHint.
  ///
  /// In en, this message translates to:
  /// **'Rewards the same shift on consecutive days.'**
  String get admPsContinuityHint;

  /// No description provided for @admPsWeekStreak.
  ///
  /// In en, this message translates to:
  /// **'Week-streak bonus'**
  String get admPsWeekStreak;

  /// No description provided for @admPsWeekStreakHint.
  ///
  /// In en, this message translates to:
  /// **'Extra reward for 7+ days in a row on the same shift.'**
  String get admPsWeekStreakHint;

  /// No description provided for @admPsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences, skills & fatigue'**
  String get admPsPreferences;

  /// No description provided for @admPsPreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'Soft goals: wishes, preferred days off, skill matching and fatigue.'**
  String get admPsPreferencesHint;

  /// No description provided for @admPsWishes.
  ///
  /// In en, this message translates to:
  /// **'Shift wishes'**
  String get admPsWishes;

  /// No description provided for @admPsWishesHint.
  ///
  /// In en, this message translates to:
  /// **'Reward for granting a shift an employee asked for.'**
  String get admPsWishesHint;

  /// No description provided for @admPsPreferredOff.
  ///
  /// In en, this message translates to:
  /// **'Preferred days off'**
  String get admPsPreferredOff;

  /// No description provided for @admPsPreferredOffHint.
  ///
  /// In en, this message translates to:
  /// **'Cost of planning someone on a day they prefer off. Never blocks.'**
  String get admPsPreferredOffHint;

  /// No description provided for @admPsSkillDowngrade.
  ///
  /// In en, this message translates to:
  /// **'Skill downgrade cost'**
  String get admPsSkillDowngrade;

  /// No description provided for @admPsSkillDowngradeHint.
  ///
  /// In en, this message translates to:
  /// **'Cost of covering a slot with a higher level of the same skill group.'**
  String get admPsSkillDowngradeHint;

  /// No description provided for @admPsFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue balancing'**
  String get admPsFatigue;

  /// No description provided for @admPsFatigueHint.
  ///
  /// In en, this message translates to:
  /// **'Protects the most fatigued employee.'**
  String get admPsFatigueHint;

  /// No description provided for @admPsNightFatigue.
  ///
  /// In en, this message translates to:
  /// **'Night shift fatigue'**
  String get admPsNightFatigue;

  /// No description provided for @admPsNightFatigueHint.
  ///
  /// In en, this message translates to:
  /// **'How draining a night shift is compared with a day shift.'**
  String get admPsNightFatigueHint;

  /// No description provided for @admNightSame.
  ///
  /// In en, this message translates to:
  /// **'Same as a day shift'**
  String get admNightSame;

  /// No description provided for @admNightSlight.
  ///
  /// In en, this message translates to:
  /// **'Slightly harder'**
  String get admNightSlight;

  /// No description provided for @admNightNoticeable.
  ///
  /// In en, this message translates to:
  /// **'Twice as hard'**
  String get admNightNoticeable;

  /// No description provided for @admNightStrong.
  ///
  /// In en, this message translates to:
  /// **'Three times as hard'**
  String get admNightStrong;

  /// No description provided for @admPsSolver.
  ///
  /// In en, this message translates to:
  /// **'Solver performance'**
  String get admPsSolver;

  /// No description provided for @admPsSolverHint.
  ///
  /// In en, this message translates to:
  /// **'How long and how hard the solver searches'**
  String get admPsSolverHint;

  /// No description provided for @admPsEffort.
  ///
  /// In en, this message translates to:
  /// **'Search effort'**
  String get admPsEffort;

  /// No description provided for @admPsEffortHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {seconds} s on {workers} CPU threads.'**
  String admPsEffortHint(int seconds, int workers);

  /// No description provided for @admPsEffortQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get admPsEffortQuick;

  /// No description provided for @admPsEffortBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get admPsEffortBalanced;

  /// No description provided for @admPsEffortThorough.
  ///
  /// In en, this message translates to:
  /// **'Thorough'**
  String get admPsEffortThorough;

  /// No description provided for @admPsTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time limit (seconds)'**
  String get admPsTimeLimit;

  /// No description provided for @admPsWorkers.
  ///
  /// In en, this message translates to:
  /// **'Parallel workers'**
  String get admPsWorkers;

  /// No description provided for @admLevelOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get admLevelOff;

  /// No description provided for @admLevelWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get admLevelWeak;

  /// No description provided for @admLevelBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get admLevelBalanced;

  /// No description provided for @admLevelStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get admLevelStrong;

  /// No description provided for @admLevelMax.
  ///
  /// In en, this message translates to:
  /// **'Very strong'**
  String get admLevelMax;

  /// No description provided for @admWishSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Decide whether employees may place shift wishes, and for which dates. The optimizer rewards granted wishes; a wish is never a guarantee.'**
  String get admWishSettingsIntro;

  /// No description provided for @admWishSettingsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the shift-admin role can change the wish window.'**
  String get admWishSettingsReadOnly;

  /// No description provided for @admWishModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Always open'**
  String get admWishModeEnabled;

  /// No description provided for @admWishModeEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Wishes may be placed for any date.'**
  String get admWishModeEnabledHint;

  /// No description provided for @admWishModeRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get admWishModeRange;

  /// No description provided for @admWishModeRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Only dates inside the window accept wishes.'**
  String get admWishModeRangeHint;

  /// No description provided for @admWishModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get admWishModeDisabled;

  /// No description provided for @admWishModeDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'No wish may be placed or withdrawn.'**
  String get admWishModeDisabledHint;

  /// No description provided for @admRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admRoleAdmin;

  /// No description provided for @admRoleAdminHint.
  ///
  /// In en, this message translates to:
  /// **'Everything, including users and the wish window.'**
  String get admRoleAdminHint;

  /// No description provided for @admRolePlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get admRolePlanner;

  /// No description provided for @admRolePlannerHint.
  ///
  /// In en, this message translates to:
  /// **'Edits rosters, master data and runs the optimizer.'**
  String get admRolePlannerHint;

  /// No description provided for @admRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get admRoleViewer;

  /// No description provided for @admRoleViewerHint.
  ///
  /// In en, this message translates to:
  /// **'Sees the roster and places their own wishes.'**
  String get admRoleViewerHint;

  /// No description provided for @admRolesSaved.
  ///
  /// In en, this message translates to:
  /// **'Roles saved.'**
  String get admRolesSaved;

  /// No description provided for @admRemoveUser.
  ///
  /// In en, this message translates to:
  /// **'Remove from organization'**
  String get admRemoveUser;

  /// No description provided for @admRemoveUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this organization? The account itself stays in the identity provider.'**
  String admRemoveUserMessage(String name);

  /// No description provided for @admRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get admRemove;

  /// No description provided for @admAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get admAddUser;

  /// No description provided for @admNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users.'**
  String get admNoUsers;

  /// No description provided for @admNoRoles.
  ///
  /// In en, this message translates to:
  /// **'no role'**
  String get admNoRoles;

  /// No description provided for @admUsernameValue.
  ///
  /// In en, this message translates to:
  /// **'Username: {name}'**
  String admUsernameValue(String name);

  /// No description provided for @admFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get admFirstName;

  /// No description provided for @admLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get admLastName;

  /// No description provided for @admPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Without one, the account cannot sign in until a password is set in the identity provider.'**
  String get admPasswordHint;

  /// No description provided for @admTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Must change password at first sign-in'**
  String get admTemporaryPassword;

  /// No description provided for @admCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get admCreate;

  /// No description provided for @admAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get admAll;

  /// No description provided for @admAuditEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get admAuditEntity;

  /// No description provided for @admAuditAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get admAuditAction;

  /// No description provided for @admAuditActor.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get admAuditActor;

  /// No description provided for @admAuditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries match.'**
  String get admAuditEmpty;

  /// No description provided for @admAuditCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String admAuditCount(int count);

  /// No description provided for @admLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get admLoadMore;

  /// No description provided for @admAuditChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get admAuditChanges;

  /// No description provided for @admAuditNoFieldChanges.
  ///
  /// In en, this message translates to:
  /// **'No field changed.'**
  String get admAuditNoFieldChanges;

  /// No description provided for @admAuditNoPrevious.
  ///
  /// In en, this message translates to:
  /// **'No earlier state to compare with.'**
  String get admAuditNoPrevious;

  /// No description provided for @admAuditCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare with previous'**
  String get admAuditCompare;

  /// No description provided for @admNewPattern.
  ///
  /// In en, this message translates to:
  /// **'New pattern'**
  String get admNewPattern;

  /// No description provided for @admEditPattern.
  ///
  /// In en, this message translates to:
  /// **'Edit pattern'**
  String get admEditPattern;

  /// No description provided for @admNoPatterns.
  ///
  /// In en, this message translates to:
  /// **'No patterns yet. Create one, e.g. “F F S S N N - -”.'**
  String get admNoPatterns;

  /// No description provided for @admCycle.
  ///
  /// In en, this message translates to:
  /// **'{days}-day cycle, {working} working days'**
  String admCycle(int days, int working);

  /// No description provided for @admEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get admEdit;

  /// No description provided for @admApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get admApply;

  /// No description provided for @admDeletePattern.
  ///
  /// In en, this message translates to:
  /// **'Delete pattern'**
  String get admDeletePattern;

  /// No description provided for @admDeletePatternMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? Fixed assignments already written from it stay.'**
  String admDeletePatternMessage(String name);

  /// No description provided for @admPatternNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ward rotation A'**
  String get admPatternNameHint;

  /// No description provided for @admPatternSequence.
  ///
  /// In en, this message translates to:
  /// **'Days of the cycle'**
  String get admPatternSequence;

  /// No description provided for @admPatternSequenceHint.
  ///
  /// In en, this message translates to:
  /// **'One entry per day, separated by spaces: a shift’s short name ({shifts}) or - for a day off.'**
  String admPatternSequenceHint(String shifts);

  /// No description provided for @admUnknownTokens.
  ///
  /// In en, this message translates to:
  /// **'No shift is called {tokens}.'**
  String admUnknownTokens(String tokens);

  /// No description provided for @admPatternIssues.
  ///
  /// In en, this message translates to:
  /// **'The planner will not be able to keep all of it:'**
  String get admPatternIssues;

  /// No description provided for @admPatternFits.
  ///
  /// In en, this message translates to:
  /// **'Fits the planner’s rules.'**
  String get admPatternFits;

  /// No description provided for @admIssueConsecutive.
  ///
  /// In en, this message translates to:
  /// **'{run} working days in a row; at most {max} are allowed.'**
  String admIssueConsecutive(int run, int max);

  /// No description provided for @admIssueNoDayOff.
  ///
  /// In en, this message translates to:
  /// **'No day off in the cycle; at most {max} working days in a row are allowed.'**
  String admIssueNoDayOff(int max);

  /// No description provided for @admIssueWeekly.
  ///
  /// In en, this message translates to:
  /// **'Up to {days} working days in 7; at most {max} are allowed.'**
  String admIssueWeekly(int days, int max);

  /// No description provided for @admIssueRest.
  ///
  /// In en, this message translates to:
  /// **'Day {day}: {from} then {to} leaves {hours} h rest; at least {min} h are required.'**
  String admIssueRest(int day, String from, String to, String hours, int min);

  /// No description provided for @admIssueRecovery.
  ///
  /// In en, this message translates to:
  /// **'Day {day}: {shift} is followed by work, but needs {days} free day(s) after it.'**
  String admIssueRecovery(int day, String shift, int days);

  /// No description provided for @admApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply “{name}”'**
  String admApplyTitle(String name);

  /// No description provided for @admApplyIntro.
  ///
  /// In en, this message translates to:
  /// **'Writes fixed shifts and days off for the people and period you pick. The planner keeps them ahead of everything else.'**
  String get admApplyIntro;

  /// No description provided for @admPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get admPeriod;

  /// No description provided for @admPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No people} =1{1 person} other{{count} people}}'**
  String admPeople(int count);

  /// No description provided for @admPickPeople.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick people'**
  String get admPickPeople;

  /// No description provided for @admSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get admSelectAll;

  /// No description provided for @admDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get admDone;

  /// No description provided for @admStagger.
  ///
  /// In en, this message translates to:
  /// **'Stagger'**
  String get admStagger;

  /// No description provided for @admStaggerHint.
  ///
  /// In en, this message translates to:
  /// **'Each next person starts this many days later in the cycle. 0 = everyone in step.'**
  String get admStaggerHint;

  /// No description provided for @admReplaceFixed.
  ///
  /// In en, this message translates to:
  /// **'Replace existing fixed assignments'**
  String get admReplaceFixed;

  /// No description provided for @admReplaceFixedHint.
  ///
  /// In en, this message translates to:
  /// **'Otherwise days that are already fixed stay as they are.'**
  String get admReplaceFixedHint;

  /// No description provided for @admPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get admPreview;

  /// No description provided for @admWrite.
  ///
  /// In en, this message translates to:
  /// **'Write {count}'**
  String admWrite(int count);

  /// No description provided for @admWritten.
  ///
  /// In en, this message translates to:
  /// **'{count} fixed assignments written.'**
  String admWritten(int count);

  /// No description provided for @admClearFixed.
  ///
  /// In en, this message translates to:
  /// **'Remove fixed assignments'**
  String get admClearFixed;

  /// No description provided for @admClearFixedMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove every fixed shift and day off of the {count} selected people in this period? The planner then decides those days again.'**
  String admClearFixedMessage(int count);

  /// No description provided for @admCleared.
  ///
  /// In en, this message translates to:
  /// **'{count} fixed assignments removed.'**
  String admCleared(int count);

  /// No description provided for @admApplySummary.
  ///
  /// In en, this message translates to:
  /// **'{written} to write ({replaced} replacing) · {unchanged} already so · {conflicts} fixed differently, kept · {absent} on absences, skipped'**
  String admApplySummary(
    int written,
    int replaced,
    int unchanged,
    int conflicts,
    int absent,
  );

  /// No description provided for @admApplyLegend.
  ///
  /// In en, this message translates to:
  /// **'Faded: already fixed · Outlined: replaces · Amber: fixed differently, kept · Struck through: absent'**
  String get admApplyLegend;

  /// No description provided for @admNewRun.
  ///
  /// In en, this message translates to:
  /// **'New optimization'**
  String get admNewRun;

  /// No description provided for @admNewRunHint.
  ///
  /// In en, this message translates to:
  /// **'Computes a proposed plan for the period. Nothing changes on the roster until you take it over.'**
  String get admNewRunHint;

  /// No description provided for @admRunPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to plan everyone.'**
  String get admRunPeopleHint;

  /// No description provided for @admStartRun.
  ///
  /// In en, this message translates to:
  /// **'Start optimization'**
  String get admStartRun;

  /// No description provided for @admRunStarted.
  ///
  /// In en, this message translates to:
  /// **'Optimization started.'**
  String get admRunStarted;

  /// No description provided for @admRunFinished.
  ///
  /// In en, this message translates to:
  /// **'An optimization run finished.'**
  String get admRunFinished;

  /// No description provided for @admRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get admRuns;

  /// No description provided for @admNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs yet.'**
  String get admNoRuns;

  /// No description provided for @admDeleteRun.
  ///
  /// In en, this message translates to:
  /// **'Delete run'**
  String get admDeleteRun;

  /// No description provided for @admDeleteRunMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this run and its proposed plan? The confirmed roster is not touched.'**
  String get admDeleteRunMessage;

  /// No description provided for @admProposedPlan.
  ///
  /// In en, this message translates to:
  /// **'Proposed plan'**
  String get admProposedPlan;

  /// No description provided for @admResultStats.
  ///
  /// In en, this message translates to:
  /// **'Status {status} · {employees} people · {assignments} shifts · objective {objective}'**
  String admResultStats(
    String status,
    int employees,
    int assignments,
    String objective,
  );

  /// No description provided for @admVerify.
  ///
  /// In en, this message translates to:
  /// **'Check with assistant'**
  String get admVerify;

  /// No description provided for @admTakeAsPlan.
  ///
  /// In en, this message translates to:
  /// **'Take as plan'**
  String get admTakeAsPlan;

  /// No description provided for @admTakeAsPlanMessage.
  ///
  /// In en, this message translates to:
  /// **'Overwrite the confirmed roster for {range} with this proposal?'**
  String admTakeAsPlanMessage(String range);

  /// No description provided for @admTakenAsPlan.
  ///
  /// In en, this message translates to:
  /// **'{count} roster entries written.'**
  String admTakenAsPlan(int count);

  /// No description provided for @admResultEmpty.
  ///
  /// In en, this message translates to:
  /// **'This run produced no plan.'**
  String get admResultEmpty;

  /// No description provided for @admThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get admThisMonth;

  /// No description provided for @admLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get admLastMonth;

  /// No description provided for @admThisQuarter.
  ///
  /// In en, this message translates to:
  /// **'This quarter'**
  String get admThisQuarter;

  /// No description provided for @admLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get admLast3Months;

  /// No description provided for @admOnlyWorking.
  ///
  /// In en, this message translates to:
  /// **'Only staff with shifts'**
  String get admOnlyWorking;

  /// No description provided for @admFairnessEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody has a confirmed shift in this period yet.'**
  String get admFairnessEmpty;

  /// No description provided for @admSpread.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} (avg {avg})'**
  String admSpread(String min, String max, String avg);

  /// No description provided for @admFairnessWorkingNote.
  ///
  /// In en, this message translates to:
  /// **'Ranges cover the {working} of {total} staff with at least one shift.'**
  String admFairnessWorkingNote(int working, int total);

  /// No description provided for @admColShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get admColShifts;

  /// No description provided for @admColHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get admColHours;

  /// No description provided for @admColTarget.
  ///
  /// In en, this message translates to:
  /// **'vs target'**
  String get admColTarget;

  /// No description provided for @admColNights.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get admColNights;

  /// No description provided for @admColWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend days'**
  String get admColWeekend;

  /// No description provided for @admColWishes.
  ///
  /// In en, this message translates to:
  /// **'Wishes granted'**
  String get admColWishes;

  /// No description provided for @admColAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get admColAbsent;

  /// No description provided for @admNameFixed.
  ///
  /// In en, this message translates to:
  /// **'A workstation keeps its name once created.'**
  String get admNameFixed;

  /// No description provided for @admPersonalLimits.
  ///
  /// In en, this message translates to:
  /// **'Personal limits'**
  String get admPersonalLimits;

  /// No description provided for @admPersonalLimitsHint.
  ///
  /// In en, this message translates to:
  /// **'What this employee may be planned for beyond the ward\'s rules.'**
  String get admPersonalLimitsHint;

  /// No description provided for @admMaxNightsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Max nights / month'**
  String get admMaxNightsPerMonth;

  /// No description provided for @admMaxWeekendsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Max weekends / month'**
  String get admMaxWeekendsPerMonth;

  /// No description provided for @admNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get admNoLimit;

  /// No description provided for @admNoNightShifts.
  ///
  /// In en, this message translates to:
  /// **'Never on a night shift'**
  String get admNoNightShifts;

  /// No description provided for @admNoNightShiftsHint.
  ///
  /// In en, this message translates to:
  /// **'Always enforced, whatever the tenant\'s personal-limits mode.'**
  String get admNoNightShiftsHint;

  /// No description provided for @admPreferredDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Preferred days off'**
  String get admPreferredDaysOff;

  /// No description provided for @admHolidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get admHolidays;

  /// No description provided for @admHolidaysHint.
  ///
  /// In en, this message translates to:
  /// **'Public holidays of the configured state'**
  String get admHolidaysHint;

  /// No description provided for @admHolidaysIntro.
  ///
  /// In en, this message translates to:
  /// **'A holiday runs on its shifts\' Sunday times and counts as a weekend day for the planner.'**
  String get admHolidaysIntro;

  /// No description provided for @admHolidaysDisabled.
  ///
  /// In en, this message translates to:
  /// **'Holidays are switched off for this deployment.'**
  String get admHolidaysDisabled;

  /// No description provided for @admHolidaysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No holidays stored for this range yet.'**
  String get admHolidaysEmpty;

  /// No description provided for @admSyncHolidays.
  ///
  /// In en, this message translates to:
  /// **'Refresh from source'**
  String get admSyncHolidays;

  /// No description provided for @admHolidaysSynced.
  ///
  /// In en, this message translates to:
  /// **'Holidays refreshed'**
  String get admHolidaysSynced;

  /// No description provided for @admBackendInfo.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get admBackendInfo;

  /// No description provided for @admBackendVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String admBackendVersion(String version);

  /// No description provided for @admBackendCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit {commit}'**
  String admBackendCommit(String commit);

  /// No description provided for @admBackendBuildDate.
  ///
  /// In en, this message translates to:
  /// **'Built {date}'**
  String admBackendBuildDate(String date);

  /// No description provided for @admWishScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Open automatically'**
  String get admWishScheduleTitle;

  /// No description provided for @admWishScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Switches the window to \"always open\" on a recurring schedule, and back to closed after it has been open long enough.'**
  String get admWishScheduleHint;

  /// No description provided for @admWishScheduleUnit.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get admWishScheduleUnit;

  /// No description provided for @admWishScheduleUnitDays.
  ///
  /// In en, this message translates to:
  /// **'day(s)'**
  String get admWishScheduleUnitDays;

  /// No description provided for @admWishScheduleUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'week(s)'**
  String get admWishScheduleUnitWeeks;

  /// No description provided for @admWishScheduleUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'month(s)'**
  String get admWishScheduleUnitMonths;

  /// No description provided for @admWishScheduleWeekday.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get admWishScheduleWeekday;

  /// No description provided for @admWishScheduleDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'On day'**
  String get admWishScheduleDayOfMonth;

  /// No description provided for @admWishScheduleTime.
  ///
  /// In en, this message translates to:
  /// **'Time (UTC)'**
  String get admWishScheduleTime;

  /// No description provided for @admWishScheduleOpenDays.
  ///
  /// In en, this message translates to:
  /// **'Stays open for'**
  String get admWishScheduleOpenDays;

  /// No description provided for @admWishScheduleOpenDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'day(s)'**
  String get admWishScheduleOpenDaysUnit;

  /// No description provided for @admWishScheduleNextChangeOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens {when}'**
  String admWishScheduleNextChangeOpens(String when);

  /// No description provided for @admWishScheduleNextChangeCloses.
  ///
  /// In en, this message translates to:
  /// **'Closes {when}'**
  String admWishScheduleNextChangeCloses(String when);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
