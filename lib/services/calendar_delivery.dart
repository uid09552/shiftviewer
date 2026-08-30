// Hands a generated .ics document to the platform, so the user can get it into
// Google Calendar.
//
// Native (Android/iOS): the file is written to a temporary directory and opened
// with whatever claims text/calendar — Google Calendar answers that with its
// "Import events" screen — falling back to the system share sheet.
// Web: the file is downloaded through a blob URL and imported via Google
// Calendar's Settings ▸ Import.
export 'calendar_delivery_io.dart'
    if (dart.library.js_interop) 'calendar_delivery_web.dart';
