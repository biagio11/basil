import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

web.Blob _blob(Uint8List bytes, String mime) =>
    web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));

Object? reserveWindow() {
  final w = web.window.open('', '_blank');
  if (w != null) {
    w.document.title = 'Basil PDF';
  }
  return w;
}

void showPdf(Uint8List bytes, String name, Object? window) {
  final url = web.URL.createObjectURL(_blob(bytes, 'application/pdf'));
  final w = window as web.Window?;
  if (w != null && !w.closed) {
    w.location.href = url;
  } else {
    download(bytes, name, 'application/pdf');
  }
}

/// Closes a tab opened with [reserveWindow] that is no longer needed.
void closeWindow(Object? window) {
  final w = window as web.Window?;
  if (w != null && !w.closed) w.close();
}

void download(Uint8List bytes, String name, String mime) {
  final url = web.URL.createObjectURL(_blob(bytes, mime));
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body!.append(a);
  a.click();
  a.remove();
  Future.delayed(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}

/// Opens [url] in a new tab. Called synchronously inside the user's tap.
void openUrl(String url) {
  web.window.open(url, '_blank', 'noopener,noreferrer');
}
