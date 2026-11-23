/// Saving, sharing and printing files on every platform.
library;


import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'files_stub.dart' if (dart.library.js_interop) 'files_web.dart' as web;

/// A browser tab opened right away (inside the tap) so it is not blocked as
/// a popup, then filled once the PDF is ready. Null outside the web.
Object? reserveWindow() => kIsWeb ? web.reserveWindow() : null;

/// Closes a tab from [reserveWindow] when the job failed.
void closeReserved(Object? window) {
  if (kIsWeb) web.closeWindow(window);
}

/// Shows a PDF so the user can read, print or save it.
Future<void> showPdf(Uint8List bytes, String name, {Object? window}) async {
  if (kIsWeb) {
    web.showPdf(bytes, name, window);
    return;
  }
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
}

/// How a share attempt ended.
enum ShareOutcome { shared, dismissed, downloaded }

/// Opens the share sheet (phone) or downloads the file when the browser
/// cannot share files. Closing the sheet is not an error and downloads
/// nothing.
Future<ShareOutcome> shareFile(Uint8List bytes, String name, String mime, {String? text}) async {
  try {
    final r = await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: mime, name: name)],
      fileNameOverrides: [name],
      text: text,
      downloadFallbackEnabled: true,
    ));
    return switch (r.status) {
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => kIsWeb ? ShareOutcome.downloaded : ShareOutcome.shared,
      _ => ShareOutcome.shared,
    };
  } catch (e) {
    // The user closed the browser share sheet.
    if ('$e'.contains('Abort')) return ShareOutcome.dismissed;
    if (kIsWeb) {
      web.download(bytes, name, mime);
      return ShareOutcome.downloaded;
    }
    rethrow;
  }
}

/// Saves a file: a download on the web, the share sheet elsewhere.
Future<void> saveFile(Uint8List bytes, String name, String mime) async {
  if (kIsWeb) {
    web.download(bytes, name, mime);
    return;
  }
  await shareFile(bytes, name, mime);
}

/// Opens an external page: a new browser tab on the web, the browser app
/// on phones.
void openExternal(String url) {
  if (kIsWeb) {
    web.openUrl(url);
    return;
  }
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
}
