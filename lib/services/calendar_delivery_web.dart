import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web: downloads the calendar as a file. The browser has no share target for
/// `text/calendar`, so a download plus Google Calendar's import screen is the
/// route in.
///
/// Returns true once the download has been started.
Future<bool> deliverIcs(String ics, String fileName) async {
  final blob = web.Blob(
    [ics.toJS].toJS,
    web.BlobPropertyBag(type: 'text/calendar;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  // Not attached to the document: a synthetic click is enough for the download.
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}
