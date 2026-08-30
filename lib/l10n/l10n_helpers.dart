import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../services/shift_data_controller.dart';
import 'app_localizations.dart';

/// Shorthand for the generated strings: `context.l10n.today`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Locale tag to hand to [DateFormat] so month and weekday names follow the
  /// language the user picked, not the device's.
  String get dateLocale => Localizations.localeOf(this).toLanguageTag();
}

/// Turns a controller failure into a sentence in the current language.
///
/// [FailureReason.request] has no translation of its own — the server's text is
/// passed through, with the status code appended when there is one.
String failureText(AppLocalizations l10n, DataFailure failure) {
  switch (failure.reason) {
    case FailureReason.notConfigured:
      return l10n.notConfigured;
    case FailureReason.noEmployeeSelected:
      return l10n.wishSelectEmployeeFirst;
    case FailureReason.wishConflict:
      return l10n.wishConflict;
    case FailureReason.wishesClosed:
      return l10n.wishWindowClosedDetail;
    case FailureReason.request:
      final detail = failure.detail ?? '';
      final code = failure.statusCode;
      return code == null ? detail : l10n.errorWithCode(detail, code);
  }
}

/// Names an `absence_type` from the API in the current language. Anything the
/// API adds later falls through as its own wire value rather than vanishing.
String absenceLabel(AppLocalizations l10n, String? type) {
  switch (type) {
    case 'sick':
      return l10n.absenceSick;
    case 'day_off':
      return l10n.absenceDayOff;
    case 'holiday':
      return l10n.absenceHoliday;
    case 'unavailable':
      return l10n.absenceUnavailable;
    case 'free':
      return l10n.absenceFree;
    case 'unknown':
      return l10n.absenceUnknown;
    case null:
      return l10n.absent;
    default:
      return type;
  }
}

/// Names a workstation's scheduling priority in the current language.
String priorityLabel(AppLocalizations l10n, String priority) {
  switch (priority) {
    case 'high':
      return l10n.priorityHigh;
    case 'low':
      return l10n.priorityLow;
    default:
      return l10n.priorityMedium;
  }
}
