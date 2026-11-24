import 'dart:typed_data';

import 'web_file_downloader_stub.dart'
    if (dart.library.js_interop) 'web_file_downloader_web.dart'
    as impl;

/// Triggers a browser file download on Flutter Web (no-op returning `false`
/// on non-web VM/test targets).
bool downloadBytesInBrowser({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  return impl.downloadBytesInBrowser(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}

/// Opens an external/signed [url] in a new browser tab on Flutter Web.
bool openUrlInBrowser(String url) {
  return impl.openUrlInBrowser(url);
}
