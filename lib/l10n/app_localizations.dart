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
