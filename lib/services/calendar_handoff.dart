import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'calendar_delivery.dart';
import 'calendar_export.dart';

/// How a shift ended up (or failed to end up) in the user's calendar.
enum CalendarHandoff {
  /// Google Calendar took it: its app on the phone, or its web form.
  google,

  /// An `.ics` file was handed to the platform — shared on Android/iOS,
  /// downloaded on web — for the user to import.
  icsFile,

  /// The share sheet was opened and dismissed without picking a target.
  dismissed,

  /// There were no confirmed shifts in the range to begin with.
  empty,

  /// Neither route worked; [CalendarHandoffResult.detail] says why.
  failed,
}

/// The outcome of one handoff, in a form the UI can turn into a sentence.
@immutable
class CalendarHandoffResult {
  final CalendarHandoff outcome;

  /// How many shifts were handed over.
  final int count;

  /// Error text for [CalendarHandoff.failed]; null otherwise.
  final String? detail;

  /// Name of the file written, for [CalendarHandoff.icsFile].
  final String? fileName;

  const CalendarHandoffResult(
    this.outcome, {
    this.count = 0,
    this.detail,
    this.fileName,
  });
}

/// Opens a URL and reports whether anything took it. Injectable so tests do not
/// need a real browser.
typedef UrlOpener = Future<bool> Function(Uri url, LaunchMode mode);

/// Writes an `.ics` document out to the platform; see `calendar_delivery.dart`.
typedef IcsDeliverer = Future<bool> Function(String ics, String fileName);

/// Gets confirmed shifts into the user's calendar, preferring Google Calendar
/// and falling back to an iCalendar file.
///
/// A single shift is offered to Google Calendar first — the installed app on a
/// phone, then its web form — because that route needs no file and no import
/// screen. Only when neither answers does it fall back to an `.ics`. A whole
/// range always goes as `.ics`: Google's link format carries exactly one event.
class CalendarHandoffService {
  final UrlOpener _open;
  final IcsDeliverer _deliver;

  CalendarHandoffService({UrlOpener? urlOpener, IcsDeliverer? icsDeliverer})
      : _open = urlOpener ?? _launch,
        _deliver = icsDeliverer ?? deliverIcs;

  static Future<bool> _launch(Uri url, LaunchMode mode) =>
      launchUrl(url, mode: mode);

  /// Sends one shift to Google Calendar's new-event form, falling back to a
  /// one-event `.ics` when nothing on the device will open the link.
  Future<CalendarHandoffResult> addToGoogleCalendar(CalendarEntry entry) async {
    final url = googleCalendarUrl(entry);

    // On a phone, ask for a non-browser handler first: that is the Google
    // Calendar app itself. Web has no such distinction — a new tab is the app.
    final modes = kIsWeb
        ? const [LaunchMode.platformDefault]
        : const [
            LaunchMode.externalNonBrowserApplication,
            LaunchMode.externalApplication,
          ];
    for (final mode in modes) {
      try {
        if (await _open(url, mode)) {
          return const CalendarHandoffResult(CalendarHandoff.google, count: 1);
        }
      } catch (e) {
        debugPrint('[calendar] $mode did not take the link: $e');
      }
    }

    debugPrint('[calendar] no handler for the Google link, falling back to ics');
    return exportIcs(
      CalendarExportSelection(entries: [entry]),
      calendarName: entry.title,
    );
  }

  /// Writes [selection] as an `.ics` and hands it to the platform: the share
  /// sheet on Android/iOS, a download on web.
  Future<CalendarHandoffResult> exportIcs(
    CalendarExportSelection selection, {
    String? calendarName,
  }) async {
    if (selection.isEmpty) {
      return const CalendarHandoffResult(CalendarHandoff.empty);
    }
    final fileName = icsFileName(selection);
    try {
      final ics = buildIcs(selection.entries, calendarName: calendarName);
      final taken = await _deliver(ics, fileName);
      return CalendarHandoffResult(
        taken ? CalendarHandoff.icsFile : CalendarHandoff.dismissed,
        count: selection.length,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('[calendar] ics export failed: $e');
      return CalendarHandoffResult(CalendarHandoff.failed,
          count: selection.length, detail: e.toString());
    }
  }
}
