// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Dienstplan';

  @override
  String get signInSubtitle => 'Melde dich an, um deinen Dienstplan zu sehen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signingIn => 'Weiterleitung…';

  @override
  String get loginUnsupported =>
      'Die Anmeldung wird auf dieser Plattform nicht unterstützt.';

  @override
  String get connectionSettings => 'Verbindungseinstellungen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get navMonth => 'Monat';

  @override
  String get navWeek => 'Woche';

  @override
  String get navDay => 'Tag';

  @override
  String get navWishes => 'Wünsche';

  @override
  String get openDayView => 'Tagesansicht öffnen';

  @override
  String get today => 'Heute';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get settings => 'Einstellungen';

  @override
  String get previous => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get save => 'Speichern';

  @override
  String get employee => 'Mitarbeiter';

  @override
  String get allEmployees => 'Alle Mitarbeiter';

  @override
  String weekTitle(String month, String year, int week) {
    return '$month $year · KW$week';
  }

  @override
  String weekSpanTitle(String from, String to, String year) {
    return '$from – $to $year';
  }

  @override
  String get notConfigured =>
      'Nicht konfiguriert. Öffne die Einstellungen und trage die API-URL ein.';

  @override
  String errorWithCode(String message, int code) {
    return '$message ($code)';
  }

  @override
  String get noShiftsScheduled => 'Keine Dienste geplant';

  @override
  String workingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count im Dienst',
      one: '1 im Dienst',
    );
    return '$_temp0';
  }

  @override
  String get offNoShift => 'Frei — kein Dienst';

  @override
  String get yourShift => 'DEIN DIENST';

  @override
  String get noWorkstation => 'Kein Arbeitsplatz zugewiesen';

  @override
  String get offNotScheduled => 'Frei / nicht eingeteilt';

  @override
  String get unassignedWorkstation => 'Ohne Arbeitsplatz';

  @override
  String get absent => 'abwesend';

  @override
  String get resizeDayOverview =>
      'Ziehen, um die Tagesübersicht zu skalieren · Doppeltippen setzt zurück';

  @override
  String get shiftWish => 'Dienstwunsch';

  @override
  String get addShiftWish => 'Dienstwunsch hinzufügen';

  @override
  String wishFor(String shift) {
    return 'Wunsch: $shift';
  }

  @override
  String get unknownShift => 'unbekannter Dienst';

  @override
  String get wishDisclaimer =>
      'Die Planung berücksichtigt Wünsche, garantiert sie aber nicht.';

  @override
  String get notScheduledOnWeekday => 'An diesem Wochentag nicht vorgesehen';

  @override
  String get removeWish => 'Wunsch entfernen';

  @override
  String removeWishCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wünsche entfernen',
      one: 'Wunsch entfernen',
    );
    return '$_temp0';
  }

  @override
  String get scopeDay => 'Dieser Tag';

  @override
  String scopeSelection(int count) {
    return '$count Tage';
  }

  @override
  String get scopeWeek => 'Diese Woche';

  @override
  String get scopeMonth => 'Dieser Monat';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String shiftRunsOnDays(int matching, int total) {
    return 'Findet an $matching von $total Tagen statt';
  }

  @override
  String wishBatchPlaced(int count, String shift) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$shift für $count Tage gewünscht',
      one: 'Wunsch eingetragen: $shift',
      zero: 'Kein Tag zum Wünschen',
    );
    return '$_temp0';
  }

  @override
  String wishBatchSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage übersprungen, der Dienst findet dann nicht statt',
      one: '1 Tag übersprungen, der Dienst findet dann nicht statt',
    );
    return '$_temp0';
  }

  @override
  String wishBatchRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wünsche entfernt',
      one: 'Wunsch entfernt',
      zero: 'Kein Wunsch zum Entfernen',
    );
    return '$_temp0';
  }

  @override
  String get wishSelectEmployeeFirst => 'Wähle zuerst einen Mitarbeiter.';

  @override
  String get wishPickEmployeeFirst =>
      'Wähle einen Mitarbeiter, bevor du einen Dienstwunsch einträgst.';

  @override
  String get wishNoShiftsAvailable => 'Keine Dienste zum Wünschen verfügbar.';

  @override
  String get wishConflict =>
      'Für diesen Tag existiert bereits ein Wunsch — bitte neu laden und erneut versuchen.';

  @override
  String get wishModeOpen => 'Wünsche offen';

  @override
  String wishModeRange(String from, String to) {
    return 'Wünsche $from – $to';
  }

  @override
  String get wishModeDisabled => 'Wünsche deaktiviert';

  @override
  String get wishWindowOpenDetail =>
      'Dienstwünsche sind für jeden Termin möglich.';

  @override
  String wishWindowRangeDetail(String from, String to) {
    return 'Dienstwünsche sind nur von $from bis $to möglich.';
  }

  @override
  String get wishWindowClosedDetail =>
      'Dienstwünsche sind derzeit deaktiviert.';

  @override
  String get wishOutsideWindow =>
      'Dieser Tag liegt außerhalb des Wunschzeitraums.';

  @override
  String wishBatchBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage außerhalb des Wunschzeitraums',
      one: '1 Tag außerhalb des Wunschzeitraums',
    );
    return '$_temp0';
  }

  @override
  String get wishPlannerHint =>
      'Tippe auf einen Tag für einen Dienstwunsch · gedrückt halten und ziehen, um mehrere Tage auf einmal zu planen.';

  @override
  String get wishPlannerEmpty => 'Noch keine Wünsche in diesem Monat';

  @override
  String wishPlannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wünsche',
      one: '1 Wunsch',
      zero: 'Keine Wünsche',
    );
    return '$_temp0';
  }

  @override
  String get wishPlannerPickEmployee =>
      'Wähle einen Mitarbeiter, um dessen Dienstwünsche zu planen.';

  @override
  String get addToCalendar => 'Zum Kalender hinzufügen';

  @override
  String get addToGoogleCalendar => 'Zu Google Kalender hinzufügen';

  @override
  String get calendarExportTitle => 'Schichten zum Kalender hinzufügen';

  @override
  String calendarExportSubtitle(String who, String from, String to) {
    return '$who · $from – $to';
  }

  @override
  String calendarExportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestätigte Schichten',
      one: '1 bestätigte Schicht',
      zero: 'Keine bestätigten Schichten',
    );
    return '$_temp0';
  }

  @override
  String calendarExportAbsences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Abwesenheiten ausgelassen',
      one: '1 Abwesenheit ausgelassen',
    );
    return '$_temp0';
  }

  @override
  String get calendarExportEmpty =>
      'Keine bestätigten Schichten in diesem Zeitraum.';

  @override
  String calendarExportMore(int count) {
    return '+$count weitere';
  }

  @override
  String get calendarShareIcs => 'Kalenderdatei teilen';

  @override
  String get calendarDownloadIcs => 'Kalenderdatei herunterladen';

  @override
  String get calendarIcsHint =>
      'Die Datei mit Google Kalender öffnen, um alle Schichten auf einmal zu importieren.';

  @override
  String get calendarIcsHintWeb =>
      'In Google Kalender unter Einstellungen ▸ Importieren & exportieren importieren.';

  @override
  String get calendarGoogleHint =>
      'Öffnet die Google-Kalender-App oder die Website.';

  @override
  String get calendarOpenedGoogle => 'In Google Kalender geöffnet.';

  @override
  String calendarIcsReady(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten nach $file exportiert',
      one: '1 Schicht nach $file exportiert',
    );
    return '$_temp0';
  }

  @override
  String get calendarExportDismissed => 'Es wurde nichts exportiert.';

  @override
  String calendarExportFailed(String reason) {
    return 'Export fehlgeschlagen: $reason';
  }

  @override
  String get calendarAllDay => 'Ganztägig';

  @override
  String get sectionServer => 'Server';

  @override
  String get apiBaseUrl => 'API-Basis-URL';

  @override
  String get fieldRequired => 'Pflichtfeld';

  @override
  String get enterValidUrl => 'Gib eine gültige URL ein';

  @override
  String get sectionSignIn => 'Anmeldung (OIDC · PKCE)';

  @override
  String get issuerUrl => 'Issuer- / Realm-URL';

  @override
  String get clientId => 'Client-ID';

  @override
  String get clientIdHelper =>
      'Derselbe Client wie im API-Gateway · PKCE (S256)';

  @override
  String get redirectUri => 'Redirect-URI';

  @override
  String get sectionManualLogin => 'Manuelle Anmeldung (Fallback)';

  @override
  String get username => 'Benutzername';

  @override
  String get password => 'Passwort';

  @override
  String get bearerToken => 'Bearer-Token (optional)';

  @override
  String get bearerTokenHelper =>
      'Wird statt Benutzername/Passwort verwendet, wenn gesetzt';

  @override
  String get sectionCalendarScope => 'Kalenderumfang';

  @override
  String get employeeIdOptional => 'Mitarbeiter-ID (optional)';

  @override
  String get employeeIdHelper =>
      'Nur den Plan dieses Mitarbeiters zeigen; leer lassen für alle';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get connectionSuccessful => 'Verbindung erfolgreich';

  @override
  String connectionFailed(String reason) {
    return 'Fehlgeschlagen: $reason';
  }

  @override
  String get sectionAppearance => 'Sprache';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get shiftInsights => 'Dienstdetails';

  @override
  String get employeeInsights => 'Mitarbeiter';

  @override
  String get showShiftDetails => 'Dienstdetails und Statistik anzeigen';

  @override
  String get showEmployeeDetails => 'Details zu diesem Mitarbeiter anzeigen';

  @override
  String get analysisUnavailable =>
      'Server-Statistiken sind nicht verfügbar — die Zahlen unten stammen aus dem Dienstplan.';

  @override
  String get statRostered => 'Eingeteilt';

  @override
  String get statPresent => 'Anwesend';

  @override
  String get statAbsent => 'Abwesend';

  @override
  String get statPlannedHours => 'Geplante Stunden';

  @override
  String get statWorking => 'Im Dienst';

  @override
  String get coverageMet => 'Vollständig besetzt';

  @override
  String coverageShort(int count) {
    return '$count zu wenig';
  }

  @override
  String get coverageOver => 'Überbesetzt';

  @override
  String get coverageNoTarget => 'Keine Sollbesetzung';

  @override
  String staffingNeedsMin(int min) {
    return 'Mindestens $min nötig';
  }

  @override
  String staffingNeedsRange(int min, int max) {
    return '$min–$max nötig';
  }

  @override
  String restDaysAfter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ruhetage danach',
      one: '1 Ruhetag danach',
    );
    return '$_temp0';
  }

  @override
  String shareOfDay(int percent) {
    return '$percent% der Tagesbesetzung';
  }

  @override
  String dayHeadcount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen an diesem Tag im Dienst',
      one: '1 Person an diesem Tag im Dienst',
    );
    return '$_temp0';
  }

  @override
  String get sectionWorkstations => 'Arbeitsplätze';

  @override
  String get sectionAbsences => 'Abwesenheiten';

  @override
  String get sectionWishes => 'Dienstwünsche';

  @override
  String get sectionWeekPattern => 'Über die Woche';

  @override
  String get sectionDayContext => 'Der restliche Tag';

  @override
  String get sectionOnThisDay => 'An diesem Tag';

  @override
  String get sectionCapabilities => 'Qualifikationen';

  @override
  String get sectionAvailableShifts => 'Einsetzbar für';

  @override
  String get sectionRangeTotals => 'Summen';

  @override
  String peopleHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

  @override
  String hoursValue(String hours) {
    return '$hours h';
  }

  @override
  String plannedAllShifts(int count) {
    return '$count hier geplant über alle Dienste';
  }

  @override
  String stationBelowMinimum(int min) {
    return 'Unter dem Minimum von $min';
  }

  @override
  String stationAboveMaximum(int max) {
    return 'Über dem Maximum von $max';
  }

  @override
  String get stationUnavailable => 'Arbeitsplatz deaktiviert';

  @override
  String get priorityHigh => 'Hohe Priorität';

  @override
  String get priorityMedium => 'Mittlere Priorität';

  @override
  String get priorityLow => 'Niedrige Priorität';

  @override
  String wishesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wünsche für diesen Dienst',
      one: '1 Wunsch für diesen Dienst',
      zero: 'Keine Wünsche für diesen Dienst',
    );
    return '$_temp0';
  }

  @override
  String wishesGrantedOf(int granted, int count) {
    return '$granted von $count erfüllt';
  }

  @override
  String get absenceSick => 'Krank';

  @override
  String get absenceDayOff => 'Freier Tag';

  @override
  String get absenceHoliday => 'Urlaub';

  @override
  String get absenceUnavailable => 'Nicht verfügbar';

  @override
  String get absenceFree => 'Frei';

  @override
  String get absenceUnknown => 'Unbekannt';

  @override
  String countedOver(String from, String to) {
    return 'Gezählt über $from – $to';
  }

  @override
  String monthlyHoursTarget(String hours) {
    return '$hours h pro Monat';
  }

  @override
  String monthlyLoad(int percent) {
    return '$percent% des Monatssolls';
  }

  @override
  String get statDaysWorked => 'Diensttage';

  @override
  String get statDaysRostered => 'Eingeteilte Tage';

  @override
  String skillLevel(int level) {
    return 'Stufe $level';
  }

  @override
  String get noCapabilities => 'Keine Qualifikationen hinterlegt';

  @override
  String get anyShift => 'Jeder Dienst';

  @override
  String get nothingRostered => 'An diesem Tag nichts eingeteilt';

  @override
  String get noRosterInRange => 'Im geladenen Zeitraum nichts eingeteilt';

  @override
  String get longPressForDetails =>
      'Lang drücken, um die Personen dahinter zu sehen';

  @override
  String get listNothingToShow => 'Hier gibt es nichts aufzulisten';

  @override
  String get sectionSchedule => 'Wochenplan';

  @override
  String scheduleWeekdayLine(String start, String end, int min) {
    return '$start – $end · mind. $min';
  }

  @override
  String get scheduleWeekdayOff => 'Findet nicht statt';

  @override
  String get othersWithCapability => 'Weitere mit dieser Qualifikation';

  @override
  String get noOthersWithCapability => 'Sonst niemand erfasst';

  @override
  String get wishGranted => 'Erfüllt';

  @override
  String get wishNotGranted => 'Nicht erfüllt';

  @override
  String get detailsEveryoneWorking => 'Alle im Dienst';

  @override
  String get detailsAtWorkstation => 'Personen an diesem Arbeitsplatz';

  @override
  String get detailsOnThisShift => 'Personen in diesem Dienst';

  @override
  String detailsMissingPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen unter dem Minimum',
      one: '1 Person unter dem Minimum',
    );
    return '$_temp0';
  }

  @override
  String detailsOnDay(String weekday, String date) {
    return '$weekday, $date';
  }

  @override
  String capabilityOfLevel(String group, int level) {
    return '$group · Stufe $level';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get adminForbidden => 'Ihre Rolle darf das nicht.';

  @override
  String get admManagement => 'Verwaltung';

  @override
  String get admToday => 'Heute';

  @override
  String get admSectionPlanning => 'Planung';

  @override
  String get admSectionConfiguration => 'Konfiguration';

  @override
  String get admRoster => 'Dienstplan';

  @override
  String get admRosterHint => 'Wer arbeitet was – Woche für Woche bearbeiten';

  @override
  String get admRotations => 'Rotationen';

  @override
  String get admRotationsHint => 'Wiederkehrende Rhythmen als feste Dienste';

  @override
  String get admOptimizer => 'Dienstplan-Optimierer';

  @override
  String get admOptimizerHint => 'Plan berechnen, prüfen und übernehmen';

  @override
  String get admFairness => 'Fairness';

  @override
  String get admFairnessHint =>
      'Nächte, Wochenenden, Stunden und Wünsche pro Person';

  @override
  String get admEmployees => 'Mitarbeitende';

  @override
  String get admEmployeesHint =>
      'Profile, Dienste, Qualifikationen und Abwesenheiten';

  @override
  String get admShifts => 'Dienste';

  @override
  String get admShiftsHint => 'Zeiten und Besetzung pro Wochentag';

  @override
  String get admWorkstations => 'Arbeitsplätze';

  @override
  String get admWorkstationsHint => 'Besetzung, Anforderungen, Schließzeiten';

  @override
  String get admCapabilities => 'Qualifikationen';

  @override
  String get admCapabilitiesHint => 'Fähigkeiten und ihre Stufen';

  @override
  String get admPlannerSettings => 'Planer-Einstellungen';

  @override
  String get admPlannerSettingsHint =>
      'Wie der Optimierer seine Ziele gewichtet';

  @override
  String get admWishSettings => 'Wunschzeitraum';

  @override
  String get admWishSettingsHint =>
      'Wann Mitarbeitende Dienstwünsche äußern dürfen';

  @override
  String get admUsers => 'Benutzer';

  @override
  String get admUsersHint => 'Anmeldekonten und Rollen';

  @override
  String get admAuditLog => 'Änderungsprotokoll';

  @override
  String get admAuditLogHint => 'Wer hat wann was geändert';

  @override
  String get admAllStationsCovered =>
      'Alle geöffneten Arbeitsplätze sind heute mindestens besetzt.';

  @override
  String get admUnderstaffedToday => 'Heute unterbesetzt';

  @override
  String admLatestRun(String status, String date) {
    return 'Letzter Optimierer-Lauf: $status · $date';
  }

  @override
  String get admRecentActivity => 'Letzte Änderungen';

  @override
  String get admTaskRunning => 'Läuft';

  @override
  String get admTaskDone => 'Fertig';

  @override
  String get admTaskFailed => 'Fehlgeschlagen';

  @override
  String get admSearchEmployees => 'Mitarbeitende suchen…';

  @override
  String get admSearchManagement => 'Verwaltung durchsuchen…';

  @override
  String get admNoMatches => 'Keine Treffer für diese Suche.';

  @override
  String get admNoEmployees => 'Keine Mitarbeitenden.';

  @override
  String get admRosterLegend =>
      'Tippen Sie auf einen Tag, um einen Dienst zuzuweisen, eine Abwesenheit einzutragen oder ihn zu leeren. ★ = Wunsch.';

  @override
  String get admAbsenceShortSick => 'K';

  @override
  String get admAbsenceShortDayOff => 'U';

  @override
  String get admAbsenceShortHoliday => 'F';

  @override
  String get admAbsenceShortFree => '–';

  @override
  String admWishedFor(String shift) {
    return 'Gewünscht: $shift';
  }

  @override
  String get admShift => 'Dienst';

  @override
  String get admNotOnThisDay => 'an diesem Tag nicht geplant';

  @override
  String get admWorkstation => 'Arbeitsplatz';

  @override
  String get admClosed => 'geschlossen';

  @override
  String get admAbsence => 'Abwesenheit';

  @override
  String get admClearDay => 'Tag leeren';

  @override
  String get admAddEmployee => 'Mitarbeitende hinzufügen';

  @override
  String admHoursPerMonth(String hours) {
    return '$hours Std./Monat';
  }

  @override
  String get admName => 'Name';

  @override
  String get admEmail => 'E-Mail';

  @override
  String get admMonthlyHours => 'Monatliches Stundensoll';

  @override
  String get admEnterNumber => 'Bitte eine Zahl eingeben';

  @override
  String get admSaved => 'Gespeichert.';

  @override
  String get admSaveFirstHint =>
      'Speichern Sie zuerst, um Dienste, Qualifikationen und Abwesenheiten zuzuordnen.';

  @override
  String get admDeleteEmployee => 'Mitarbeitende löschen';

  @override
  String admDeleteEmployeeMessage(String name) {
    return '$name löschen? Dienstplan, Wünsche und Abwesenheiten werden mitgelöscht.';
  }

  @override
  String get admLeave => 'Abwesenheiten';

  @override
  String get admLeaveHint =>
      'Urlaub und Krankheit stehen im Dienstplan; nicht verfügbare Tage beachtet der Optimierer.';

  @override
  String get admAdd => 'Hinzufügen';

  @override
  String get admAddLeave => 'Abwesenheit eintragen';

  @override
  String get admPickDates => 'Zeitraum wählen';

  @override
  String get admUnavailableHint =>
      'Der Optimierer plant die Person an diesen Tagen nicht ein.';

  @override
  String get admNoUpcomingLeave => 'Nichts eingetragen.';

  @override
  String admPastLeave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vergangene Einträge',
      one: '1 vergangener Eintrag',
    );
    return '$_temp0';
  }

  @override
  String admDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get admRemoveLeave => 'Abwesenheit entfernen';

  @override
  String admRemoveLeaveMessage(String kind, String range) {
    return '$kind für $range entfernen?';
  }

  @override
  String get admAddShift => 'Dienst hinzufügen';

  @override
  String get admNoShifts => 'Noch keine Dienste.';

  @override
  String get admNoWeekdays => 'An keinem Wochentag';

  @override
  String get admShortName => 'Kürzel';

  @override
  String get admOrder => 'Reihenfolge';

  @override
  String get admColor => 'Farbe';

  @override
  String get admWeekdayTimesHint =>
      'Zeiten und Besetzung je Wochentag. Ausgeschaltete Tage haben diesen Dienst nicht.';

  @override
  String get admStart => 'Beginn';

  @override
  String get admEnd => 'Ende';

  @override
  String get admMinStaff => 'Mindestbesetzung';

  @override
  String get admMaxStaff => 'Höchstbesetzung (∞ = keine)';

  @override
  String get admRestDaysAfter => 'Freie Tage danach';

  @override
  String get admDeleteShift => 'Dienst löschen';

  @override
  String admDeleteShiftMessage(String name) {
    return '$name löschen? Geplante Tage mit diesem Dienst verlieren ihn.';
  }

  @override
  String get admAddWorkstation => 'Arbeitsplatz hinzufügen';

  @override
  String get admNoWorkstations => 'Noch keine Arbeitsplätze.';

  @override
  String get admInactive => 'inaktiv';

  @override
  String get admActive => 'Aktiv';

  @override
  String get admActiveHint => 'Inaktive Arbeitsplätze werden nicht besetzt.';

  @override
  String get admPriority => 'Priorität';

  @override
  String get admPerShift => 'pro Dienst';

  @override
  String get admRunsInShifts => 'Besetzt in Diensten';

  @override
  String get admRunsInShiftsHint => 'Keiner gewählt heißt: in allen Diensten.';

  @override
  String get admRequiredCapabilities => 'Erforderliche Qualifikationen';

  @override
  String get admClosures => 'Schließzeiten';

  @override
  String get admClosuresHint =>
      'Zeiträume, in denen hier niemand eingeplant werden darf.';

  @override
  String get admNoClosures => 'Keine Schließzeiten.';

  @override
  String get admDeleteWorkstation => 'Arbeitsplatz löschen';

  @override
  String admDeleteWorkstationMessage(String name) {
    return '$name löschen?';
  }

  @override
  String get admAddCapability => 'Qualifikation hinzufügen';

  @override
  String get admEditCapability => 'Qualifikation bearbeiten';

  @override
  String get admNoSkillGroup => 'Ohne Gruppe';

  @override
  String get admSkillGroup => 'Gruppe';

  @override
  String get admSkillGroupHint =>
      'Innerhalb einer Gruppe kann eine höhere Stufe eine niedrigere vertreten.';

  @override
  String get admLevel => 'Stufe';

  @override
  String get admDeleteCapability => 'Qualifikation löschen';

  @override
  String admDeleteCapabilityMessage(String name) {
    return '$name löschen? Sie wird bei allen Mitarbeitenden und Arbeitsplätzen entfernt.';
  }

  @override
  String get admExpertValues => 'Expertenwerte';

  @override
  String get admDiscardChanges => 'Änderungen verwerfen?';

  @override
  String get admDiscardChangesMessage =>
      'Ihre Änderungen wurden nicht gespeichert.';

  @override
  String get admDiscard => 'Verwerfen';

  @override
  String admLastUpdated(String date) {
    return 'Zuletzt geändert $date';
  }

  @override
  String get admPsUseCase => 'Einsatzzweck';

  @override
  String get admPsUseCaseHint =>
      'Wählen Sie das Ziel, das zur Station passt – es füllt alle Einstellungen unten aus, die Sie weiter anpassen können. Der Rechenaufwand bleibt unberührt.';

  @override
  String get admPsCustomMix =>
      'Eigene Mischung – keine Vorlage passt zu diesen Werten.';

  @override
  String get admTplBalanced => 'Ausgewogen';

  @override
  String get admTplBalancedHint =>
      'Die Standardwerte: Besetzung, Fairness und Wünsche gegeneinander abgewogen.';

  @override
  String get admTplFairness => 'Gleiche Verteilung';

  @override
  String get admTplFairnessHint =>
      'Alle arbeiten vergleichbar viel. Stundensoll geht vor Wünschen und Kontinuität.';

  @override
  String get admTplWishes => 'Wünsche zuerst';

  @override
  String get admTplWishesHint =>
      'Gewünschte Dienste werden erfüllt, wann immer möglich – auf Kosten gleichmäßiger Stunden.';

  @override
  String get admTplCoverage => 'Besetzung zuerst';

  @override
  String get admTplCoverageHint =>
      'Kritische Arbeitsplätze werden zuerst besetzt, mit lockereren Ruhezeiten.';

  @override
  String get admTplStability => 'Stabile Pläne';

  @override
  String get admTplStabilityHint =>
      'Lange, planbare Blöcke im selben Dienst statt häufiger Wechsel.';

  @override
  String get admTplWellbeing => 'Wohlbefinden';

  @override
  String get admTplWellbeingHint =>
      'Längere Ruhe, begrenzte Wochen und gleichmäßig verteilte Belastung – der schonendste mögliche Plan.';

  @override
  String get admPsRest => 'Ruhe & Erholung';

  @override
  String get admPsRestHint =>
      'Harte Grenzen für Arbeit am Stück und Ruhe zwischen Diensten';

  @override
  String get admPsNightRecovery => 'Erholung nach Nachtdienst';

  @override
  String get admPsNightRecoveryHint => 'Freie Tage nach einem Nachtdienst.';

  @override
  String get admPsMinRest => 'Mindestruhe zwischen Diensten';

  @override
  String get admPsMinRestHint =>
      'Ruhezeit zwischen Diensten an aufeinanderfolgenden Tagen.';

  @override
  String get admPsMaxConsecutive => 'Max. Tage am Stück';

  @override
  String get admPsMaxConsecutiveHint =>
      'Längste erlaubte Folge von Arbeitstagen.';

  @override
  String get admPsMaxPerWeek => 'Max. Tage pro Woche';

  @override
  String get admPsMaxPerWeekHint => 'Erlaubte Arbeitstage pro Kalenderwoche.';

  @override
  String admUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: 'Aus',
    );
    return '$_temp0';
  }

  @override
  String admUnitHours(int count) {
    return '$count Std.';
  }

  @override
  String get admOff => 'Aus';

  @override
  String get admPsFairness => 'Fairness & Stunden';

  @override
  String get admPsFairnessHint =>
      'Wie gleichmäßig die Arbeit verteilt wird und wie genau das Stundensoll getroffen wird';

  @override
  String get admPsEquality => 'Fairness';

  @override
  String get admPsEqualityHint => 'Verteilt Stunden gleichmäßiger auf alle.';

  @override
  String get admPsMonthlyTarget => 'Monatliches Stundensoll';

  @override
  String get admPsMonthlyTargetHint =>
      'Drängt auf das Monatssoll jeder Person hin.';

  @override
  String get admPsWeeklyBand => 'Wöchentlicher Stundenkorridor';

  @override
  String get admPsWeeklyBandHint =>
      'Weiche Unter- und Obergrenze pro Woche, zusätzlich zum Monatssoll.';

  @override
  String get admPsWeeklyMin => 'Minimum pro Woche';

  @override
  String get admPsWeeklyMax => 'Maximum pro Woche';

  @override
  String get admPsBandStrength => 'Stärke des Korridors';

  @override
  String get admPsCoverage => 'Besetzung & Kontinuität';

  @override
  String get admPsCoverageHint =>
      'Welche Arbeitsplätze zuerst besetzt werden und wie stabil Dienstmuster bleiben';

  @override
  String get admPsPriority => 'Arbeitsplatz-Priorität';

  @override
  String get admPsPriorityHint =>
      'Wie deutlich Arbeitsplätze hoher Priorität zuerst besetzt werden.';

  @override
  String get admPrioIgnore => 'Alle gleich';

  @override
  String get admPrioSoft => 'Leichte Bevorzugung';

  @override
  String get admPrioBalanced => 'Ausgewogen';

  @override
  String get admPrioStrict => 'Strikte Reihenfolge';

  @override
  String get admCustom => 'Benutzerdefiniert';

  @override
  String admCustomValue(String value) {
    return 'Eigener Wert ($value)';
  }

  @override
  String get admPsMinStaffing => 'Mindestbesetzung';

  @override
  String get admPsMinStaffingHint =>
      'Ob die Mindestbesetzung pro Dienst und Arbeitsplatz ein Ziel oder eine Pflicht ist.';

  @override
  String get admPsMinStaffingSoft => 'Ziel';

  @override
  String get admPsMinStaffingHard => 'Pflicht';

  @override
  String get admPsMinStaffingHardWarning =>
      'Als Pflicht entsteht bei zu wenig verfügbaren Personen gar kein Plan statt eines unterbesetzten.';

  @override
  String get admPsPersonalLimits => 'Persönliche Grenzen';

  @override
  String get admPsPersonalLimitsHint =>
      'Wie die eigenen Grenzen für Nächte/Wochenenden pro Monat gelten. Keine Nächte ist immer verbindlich.';

  @override
  String get admPsPersonalLimitsHard => 'Verbindlich';

  @override
  String get admPsPersonalLimitsSoft => 'Flexibel';

  @override
  String get admPsKeepRotations => 'Rotationen beibehalten';

  @override
  String get admPsKeepRotationsHint =>
      'Feste Dienste und freie Tage aus Rotationen werden zuerst eingeplant.';

  @override
  String get admPsKeepRotationsOff =>
      'Rotationen werden beim Planen ignoriert. Sie bleiben gespeichert und gelten wieder, sobald dies eingeschaltet ist.';

  @override
  String get admPsContinuity => 'Dienstkontinuität';

  @override
  String get admPsContinuityHint => 'Belohnt denselben Dienst an Folgetagen.';

  @override
  String get admPsWeekStreak => 'Wochenserien-Bonus';

  @override
  String get admPsWeekStreakHint =>
      'Zusätzliche Belohnung für 7+ Tage im selben Dienst.';

  @override
  String get admPsPreferences => 'Präferenzen, Qualifikation & Belastung';

  @override
  String get admPsPreferencesHint =>
      'Weiche Ziele: Wünsche, bevorzugte freie Tage, passende Qualifikation und Belastung.';

  @override
  String get admPsWishes => 'Dienstwünsche';

  @override
  String get admPsWishesHint => 'Belohnung für einen erfüllten Dienstwunsch.';

  @override
  String get admPsPreferredOff => 'Bevorzugte freie Tage';

  @override
  String get admPsPreferredOffHint =>
      'Kosten, wenn jemand an einem bevorzugt freien Tag eingeplant wird. Blockiert nie.';

  @override
  String get admPsSkillDowngrade => 'Kosten für Überqualifikation';

  @override
  String get admPsSkillDowngradeHint =>
      'Kosten, wenn eine höhere Stufe derselben Gruppe einspringt.';

  @override
  String get admPsFatigue => 'Belastungsausgleich';

  @override
  String get admPsFatigueHint => 'Schützt die am stärksten belastete Person.';

  @override
  String get admPsNightFatigue => 'Belastung durch Nachtdienst';

  @override
  String get admPsNightFatigueHint =>
      'Wie belastend ein Nachtdienst im Vergleich zum Tagdienst ist.';

  @override
  String get admNightSame => 'Wie ein Tagdienst';

  @override
  String get admNightSlight => 'Etwas härter';

  @override
  String get admNightNoticeable => 'Doppelt so hart';

  @override
  String get admNightStrong => 'Dreimal so hart';

  @override
  String get admPsSolver => 'Rechenleistung';

  @override
  String get admPsSolverHint => 'Wie lange und wie intensiv der Solver sucht';

  @override
  String get admPsEffort => 'Suchaufwand';

  @override
  String admPsEffortHint(int seconds, int workers) {
    return 'Bis zu $seconds s auf $workers CPU-Threads.';
  }

  @override
  String get admPsEffortQuick => 'Schnell';

  @override
  String get admPsEffortBalanced => 'Ausgewogen';

  @override
  String get admPsEffortThorough => 'Gründlich';

  @override
  String get admPsTimeLimit => 'Zeitlimit (Sekunden)';

  @override
  String get admPsWorkers => 'Parallele Worker';

  @override
  String get admLevelOff => 'Aus';

  @override
  String get admLevelWeak => 'Schwach';

  @override
  String get admLevelBalanced => 'Ausgewogen';

  @override
  String get admLevelStrong => 'Stark';

  @override
  String get admLevelMax => 'Sehr stark';

  @override
  String get admWishSettingsIntro =>
      'Legen Sie fest, ob und für welche Tage Mitarbeitende Dienstwünsche äußern dürfen. Der Optimierer belohnt erfüllte Wünsche; garantiert ist ein Wunsch nie.';

  @override
  String get admWishSettingsReadOnly =>
      'Nur die Rolle shift-admin kann den Wunschzeitraum ändern.';

  @override
  String get admWishModeEnabled => 'Immer offen';

  @override
  String get admWishModeEnabledHint => 'Wünsche sind für jeden Tag möglich.';

  @override
  String get admWishModeRange => 'Zeitraum';

  @override
  String get admWishModeRangeHint => 'Nur Tage im Zeitraum nehmen Wünsche an.';

  @override
  String get admWishModeDisabled => 'Geschlossen';

  @override
  String get admWishModeDisabledHint =>
      'Keine Wünsche können geäußert oder zurückgezogen werden.';

  @override
  String get admRoleAdmin => 'Admin';

  @override
  String get admRoleAdminHint => 'Alles, auch Benutzer und Wunschzeitraum.';

  @override
  String get admRolePlanner => 'Planer';

  @override
  String get admRolePlannerHint =>
      'Bearbeitet Dienstpläne und Stammdaten, startet den Optimierer.';

  @override
  String get admRoleViewer => 'Betrachter';

  @override
  String get admRoleViewerHint =>
      'Sieht den Dienstplan und äußert eigene Wünsche.';

  @override
  String get admRolesSaved => 'Rollen gespeichert.';

  @override
  String get admRemoveUser => 'Aus Organisation entfernen';

  @override
  String admRemoveUserMessage(String name) {
    return '$name aus dieser Organisation entfernen? Das Konto selbst bleibt im Identity Provider.';
  }

  @override
  String get admRemove => 'Entfernen';

  @override
  String get admAddUser => 'Benutzer hinzufügen';

  @override
  String get admNoUsers => 'Keine Benutzer.';

  @override
  String get admNoRoles => 'keine Rolle';

  @override
  String admUsernameValue(String name) {
    return 'Benutzername: $name';
  }

  @override
  String get admFirstName => 'Vorname';

  @override
  String get admLastName => 'Nachname';

  @override
  String get admPasswordHint =>
      'Optional. Ohne Passwort kann sich das Konto erst anmelden, wenn im Identity Provider eines gesetzt wurde.';

  @override
  String get admTemporaryPassword => 'Passwort bei erster Anmeldung ändern';

  @override
  String get admCreate => 'Anlegen';

  @override
  String get admAll => 'Alle';

  @override
  String get admAuditEntity => 'Objekt';

  @override
  String get admAuditAction => 'Aktion';

  @override
  String get admAuditActor => 'Von';

  @override
  String get admAuditEmpty => 'Keine passenden Einträge.';

  @override
  String admAuditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get admLoadMore => 'Mehr laden';

  @override
  String get admAuditChanges => 'Änderungen';

  @override
  String get admAuditNoFieldChanges => 'Kein Feld geändert.';

  @override
  String get admAuditNoPrevious => 'Kein früherer Stand zum Vergleich.';

  @override
  String get admAuditCompare => 'Mit vorherigem vergleichen';

  @override
  String get admNewPattern => 'Neues Muster';

  @override
  String get admEditPattern => 'Muster bearbeiten';

  @override
  String get admNoPatterns =>
      'Noch keine Muster. Legen Sie eines an, z. B. „F F S S N N - -“.';

  @override
  String admCycle(int days, int working) {
    return '$days-Tage-Zyklus, $working Arbeitstage';
  }

  @override
  String get admEdit => 'Bearbeiten';

  @override
  String get admApply => 'Anwenden';

  @override
  String get admDeletePattern => 'Muster löschen';

  @override
  String admDeletePatternMessage(String name) {
    return '„$name“ löschen? Bereits geschriebene feste Dienste bleiben.';
  }

  @override
  String get admPatternNameHint => 'z. B. Stationsrotation A';

  @override
  String get admPatternSequence => 'Tage des Zyklus';

  @override
  String admPatternSequenceHint(String shifts) {
    return 'Ein Eintrag pro Tag, durch Leerzeichen getrennt: Kürzel eines Dienstes ($shifts) oder - für frei.';
  }

  @override
  String admUnknownTokens(String tokens) {
    return 'Kein Dienst heißt $tokens.';
  }

  @override
  String get admPatternIssues => 'Der Planer kann nicht alles davon einhalten:';

  @override
  String get admPatternFits => 'Passt zu den Regeln des Planers.';

  @override
  String admIssueConsecutive(int run, int max) {
    return '$run Arbeitstage am Stück; höchstens $max sind erlaubt.';
  }

  @override
  String admIssueNoDayOff(int max) {
    return 'Kein freier Tag im Zyklus; höchstens $max Arbeitstage am Stück sind erlaubt.';
  }

  @override
  String admIssueWeekly(int days, int max) {
    return 'Bis zu $days Arbeitstage in 7; höchstens $max sind erlaubt.';
  }

  @override
  String admIssueRest(int day, String from, String to, String hours, int min) {
    return 'Tag $day: $from dann $to lässt $hours Std. Ruhe; mindestens $min Std. sind nötig.';
  }

  @override
  String admIssueRecovery(int day, String shift, int days) {
    return 'Tag $day: nach $shift wird gearbeitet, nötig sind $days freie Tag(e).';
  }

  @override
  String admApplyTitle(String name) {
    return '„$name“ anwenden';
  }

  @override
  String get admApplyIntro =>
      'Schreibt feste Dienste und freie Tage für die gewählten Personen und den Zeitraum. Der Planer berücksichtigt sie vor allem anderen.';

  @override
  String get admPeriod => 'Zeitraum';

  @override
  String admPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
      zero: 'Keine Personen',
    );
    return '$_temp0';
  }

  @override
  String get admPickPeople => 'Tippen, um Personen zu wählen';

  @override
  String get admSelectAll => 'Alle auswählen';

  @override
  String get admDone => 'Fertig';

  @override
  String get admStagger => 'Versatz';

  @override
  String get admStaggerHint =>
      'Jede weitere Person startet so viele Tage später im Zyklus. 0 = alle gleich.';

  @override
  String get admReplaceFixed => 'Vorhandene feste Dienste ersetzen';

  @override
  String get admReplaceFixedHint =>
      'Sonst bleiben bereits feste Tage, wie sie sind.';

  @override
  String get admPreview => 'Vorschau';

  @override
  String admWrite(int count) {
    return '$count schreiben';
  }

  @override
  String admWritten(int count) {
    return '$count feste Dienste geschrieben.';
  }

  @override
  String get admClearFixed => 'Feste Dienste entfernen';

  @override
  String admClearFixedMessage(int count) {
    return 'Alle festen Dienste und freien Tage der $count gewählten Personen in diesem Zeitraum entfernen? Der Planer entscheidet diese Tage dann neu.';
  }

  @override
  String admCleared(int count) {
    return '$count feste Dienste entfernt.';
  }

  @override
  String admApplySummary(
    int written,
    int replaced,
    int unchanged,
    int conflicts,
    int absent,
  ) {
    return '$written zu schreiben ($replaced ersetzend) · $unchanged schon so · $conflicts anders fest, bleibt · $absent bei Abwesenheit, übersprungen';
  }

  @override
  String get admApplyLegend =>
      'Blass: schon fest · Umrandet: ersetzt · Gelb: anders fest, bleibt · Durchgestrichen: abwesend';

  @override
  String get admNewRun => 'Neue Optimierung';

  @override
  String get admNewRunHint =>
      'Berechnet einen Planvorschlag für den Zeitraum. Der Dienstplan ändert sich erst, wenn Sie ihn übernehmen.';

  @override
  String get admRunPeopleHint => 'Leer lassen, um alle einzuplanen.';

  @override
  String get admStartRun => 'Optimierung starten';

  @override
  String get admRunStarted => 'Optimierung gestartet.';

  @override
  String get admRunFinished => 'Ein Optimierungslauf ist fertig.';

  @override
  String get admRuns => 'Läufe';

  @override
  String get admNoRuns => 'Noch keine Läufe.';

  @override
  String get admDeleteRun => 'Lauf löschen';

  @override
  String get admDeleteRunMessage =>
      'Diesen Lauf und seinen Planvorschlag löschen? Der bestätigte Dienstplan bleibt unberührt.';

  @override
  String get admProposedPlan => 'Planvorschlag';

  @override
  String admResultStats(
    String status,
    int employees,
    int assignments,
    String objective,
  ) {
    return 'Status $status · $employees Personen · $assignments Dienste · Zielwert $objective';
  }

  @override
  String get admVerify => 'Vom Assistenten prüfen';

  @override
  String get admTakeAsPlan => 'Als Plan übernehmen';

  @override
  String admTakeAsPlanMessage(String range) {
    return 'Den bestätigten Dienstplan für $range mit diesem Vorschlag überschreiben?';
  }

  @override
  String admTakenAsPlan(int count) {
    return '$count Dienstplaneinträge geschrieben.';
  }

  @override
  String get admResultEmpty => 'Dieser Lauf hat keinen Plan ergeben.';

  @override
  String get admThisMonth => 'Dieser Monat';

  @override
  String get admLastMonth => 'Letzter Monat';

  @override
  String get admThisQuarter => 'Dieses Quartal';

  @override
  String get admLast3Months => 'Letzte 3 Monate';

  @override
  String get admOnlyWorking => 'Nur mit Diensten';

  @override
  String get admFairnessEmpty =>
      'In diesem Zeitraum hat noch niemand einen bestätigten Dienst.';

  @override
  String admSpread(String min, String max, String avg) {
    return '$min–$max (Ø $avg)';
  }

  @override
  String admFairnessWorkingNote(int working, int total) {
    return 'Die Spannen umfassen $working von $total Personen mit mindestens einem Dienst.';
  }

  @override
  String get admColShifts => 'Dienste';

  @override
  String get admColHours => 'Stunden';

  @override
  String get admColTarget => 'ggü. Soll';

  @override
  String get admColNights => 'Nächte';

  @override
  String get admColWeekend => 'Wochenendtage';

  @override
  String get admColWishes => 'Erfüllte Wünsche';

  @override
  String get admColAbsent => 'Abwesend';

  @override
  String get admNameFixed =>
      'Ein Arbeitsplatz behält seinen Namen nach dem Anlegen.';

  @override
  String get admPersonalLimits => 'Persönliche Grenzen';

  @override
  String get admPersonalLimitsHint =>
      'Was für diese Person über die Stationsregeln hinaus gilt.';

  @override
  String get admMaxNightsPerMonth => 'Max. Nächte / Monat';

  @override
  String get admMaxWeekendsPerMonth => 'Max. Wochenenden / Monat';

  @override
  String get admNoLimit => 'Keine Grenze';

  @override
  String get admNoNightShifts => 'Nie im Nachtdienst';

  @override
  String get admNoNightShiftsHint =>
      'Gilt immer, unabhängig vom Modus für persönliche Grenzen.';

  @override
  String get admPreferredDaysOff => 'Bevorzugte freie Tage';

  @override
  String get admHolidays => 'Feiertage';

  @override
  String get admHolidaysHint =>
      'Gesetzliche Feiertage des eingestellten Bundeslands';

  @override
  String get admHolidaysIntro =>
      'Ein Feiertag läuft mit den Sonntagszeiten der Dienste und zählt für die Planung als Wochenendtag.';

  @override
  String get admHolidaysDisabled =>
      'Feiertage sind für diese Instanz ausgeschaltet.';

  @override
  String get admHolidaysEmpty =>
      'Für diesen Zeitraum sind noch keine Feiertage gespeichert.';

  @override
  String get admSyncHolidays => 'Von der Quelle aktualisieren';

  @override
  String get admHolidaysSynced => 'Feiertage aktualisiert';

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
    return 'Erstellt am $date';
  }

  @override
  String get admWishScheduleTitle => 'Automatisch öffnen';

  @override
  String get admWishScheduleHint =>
      'Schaltet den Zeitraum wiederkehrend auf \"immer offen\" und danach wieder auf geschlossen.';

  @override
  String get admWishScheduleUnit => 'Alle';

  @override
  String get admWishScheduleUnitDays => 'Tag(e)';

  @override
  String get admWishScheduleUnitWeeks => 'Woche(n)';

  @override
  String get admWishScheduleUnitMonths => 'Monat(e)';

  @override
  String get admWishScheduleWeekday => 'Am';

  @override
  String get admWishScheduleDayOfMonth => 'Am Tag';

  @override
  String get admWishScheduleTime => 'Uhrzeit (UTC)';

  @override
  String get admWishScheduleOpenDays => 'Bleibt offen für';

  @override
  String get admWishScheduleOpenDaysUnit => 'Tag(e)';

  @override
  String admWishScheduleNextChangeOpens(String when) {
    return 'Öffnet $when';
  }

  @override
  String admWishScheduleNextChangeCloses(String when) {
    return 'Schließt $when';
  }
}
