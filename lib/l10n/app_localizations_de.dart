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
}
