import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web implementation using `package:web` and `dart:js_interop` (zero `dart:html`).
bool downloadBytesInBrowser({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  final blobParts = <JSAny>[bytes.toJS].toJS;
  final blob = web.Blob(
    blobParts,
    web.BlobPropertyBag(type: mimeType),
  );
  final objectUrl = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(objectUrl);
  return true;
}

/// Opens a temporary signed URL safely in a new tab on Flutter Web.
bool openUrlInBrowser(String url) {
  web.window.open(url, '_blank', 'noopener,noreferrer');
  return true;
}
