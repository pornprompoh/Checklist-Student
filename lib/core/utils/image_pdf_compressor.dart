import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../errors/app_exception.dart';

/// Result of client-side validation and optional JPEG compression before
/// uploading to the private `import-sources` bucket (`<= 500 KB`).
class CompressedImportFile {
  const CompressedImportFile({
    required this.bytes,
    required this.mimeType,
    required this.fileExtension,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.wasCompressed,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileExtension;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final bool wasCompressed;
}

/// Pure Dart client-side file validator and image compressor enforcing
/// Supabase Free Tier Storage limits (`<= 512000` bytes / 500 KB).
abstract final class ImagePdfCompressor {
  static const int maxFileSizeBytes = 512000;
  static const Set<String> allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'application/pdf',
  };

  static const List<int> _resizeMaxWidths = <int>[1600, 1280, 1024, 800];
  static const List<int> _jpegQualities = <int>[85, 70, 55, 40];

  /// Validates [fileName] & [bytes] and compresses JPG/PNG images when larger
  /// than [maxFileSizeBytes]. Throws [ValidationException] with a Thai message
  /// for unsupported types or oversized PDFs.
  static CompressedImportFile compressIfNeeded({
    required Uint8List bytes,
    required String fileName,
  }) {
    if (bytes.isEmpty) {
      throw const ValidationException(
        'ไฟล์ที่เลือกไม่มีข้อมูล กรุณาเลือกไฟล์ใหม่อีกครั้ง',
        code: 'EMPTY_FILE',
      );
    }

    final (String mimeType, String ext) = _resolveMimeAndExtension(fileName);
    final originalSize = bytes.length;

    if (mimeType == 'application/pdf') {
      if (originalSize > maxFileSizeBytes) {
        final sizeKb = (originalSize / 1024).toStringAsFixed(0);
        throw ValidationException(
          'ไฟล์ PDF มีขนาด $sizeKb KB เกินขีดจำกัด 500 KB '
          'กรุณาบีบอัดไฟล์ PDF ก่อน หรือถ่ายภาพรายชื่อทีละหน้าเพื่อให้ระบบย่อขนาดอัตโนมัติ',
          code: 'PDF_TOO_LARGE',
        );
      }
      return CompressedImportFile(
        bytes: bytes,
        mimeType: mimeType,
        fileExtension: ext,
        originalSizeBytes: originalSize,
        compressedSizeBytes: originalSize,
        wasCompressed: false,
      );
    }

    if (originalSize <= maxFileSizeBytes) {
      return CompressedImportFile(
        bytes: bytes,
        mimeType: mimeType,
        fileExtension: ext,
        originalSizeBytes: originalSize,
        compressedSizeBytes: originalSize,
        wasCompressed: false,
      );
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const ValidationException(
        'ไม่สามารถอ่านไฟล์รูปภาพนี้ได้ กรุณาตรวจสอบว่าไฟล์เป็น JPG หรือ PNG ที่ไม่เสียหาย',
        code: 'INVALID_IMAGE',
      );
    }

    for (final maxWidth in _resizeMaxWidths) {
      final resized = decoded.width > maxWidth
          ? img.copyResize(decoded, width: maxWidth)
          : decoded;

      for (final quality in _jpegQualities) {
        final encoded = Uint8List.fromList(
          img.encodeJpg(resized, quality: quality),
        );
        if (encoded.length <= maxFileSizeBytes) {
          return CompressedImportFile(
            bytes: encoded,
            mimeType: 'image/jpeg',
            fileExtension: 'jpg',
            originalSizeBytes: originalSize,
            compressedSizeBytes: encoded.length,
            wasCompressed: true,
          );
        }
      }
    }

    throw const ValidationException(
      'ไม่สามารถบีบอัดรูปภาพให้มีขนาดไม่เกิน 500 KB ได้ กรุณาครอปเฉพาะตารางรายชื่อแล้วลองใหม่อีกครั้ง',
      code: 'IMAGE_COMPRESSION_LIMIT',
    );
  }

  /// Formats bytes cleanly into KB / MB for Thai UI summaries.
  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  static (String, String) _resolveMimeAndExtension(String fileName) {
    final lower = fileName.trim().toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return ('image/jpeg', 'jpg');
    }
    if (lower.endsWith('.png')) {
      return ('image/png', 'png');
    }
    if (lower.endsWith('.pdf')) {
      return ('application/pdf', 'pdf');
    }
    throw const ValidationException(
      'รองรับเฉพาะไฟล์รูปภาพ (.jpg, .jpeg, .png) และไฟล์ .pdf เท่านั้น',
      code: 'UNSUPPORTED_MIME_TYPE',
    );
  }
}
