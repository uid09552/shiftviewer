import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native: writes the calendar next to the app's other scratch files and gets
/// it to a calendar app.
///
/// Opening it comes first. On Android that is an `ACTION_VIEW` on
/// `text/calendar` through a FileProvider, which Google Calendar answers with
/// its "Import events" screen — the shortest path from here to shifts in the
/// calendar. It also claims `ACTION_VIEW` more reliably than it claims the
/// share intent, so the share sheet is only the fallback for a device with no
/// calendar app willing to open the file.
///
/// Returns false when nothing took the file and the user dismissed the share
/// sheet too. The file stays behind either way, so a second attempt is free.
Future<bool> deliverIcs(String ics, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(ics, flush: true);

  final opened = await OpenFilex.open(file.path, type: 'text/calendar');
  if (opened.type == ResultType.done) return true;
  debugPrint('[calendar] no app opened the ics (${opened.type}), sharing it');

  final shared = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/calendar')],
      fileNameOverrides: [fileName],
    ),
  );
  return shared.status != ShareResultStatus.dismissed;
}
