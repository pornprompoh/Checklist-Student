import 'dart:typed_data';

/// Non-web stub for [downloadBytesInBrowser] used during VM unit/widget tests.
bool downloadBytesInBrowser({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  return false;
}

/// Non-web stub for [openUrlInBrowser].
bool openUrlInBrowser(String url) {
  return false;
}
