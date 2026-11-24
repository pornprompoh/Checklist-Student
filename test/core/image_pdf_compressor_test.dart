import 'dart:math' as math;
import 'dart:typed_data';

import 'package:checklist_student/core/errors/app_exception.dart';
import 'package:checklist_student/core/utils/image_pdf_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImagePdfCompressor', () {
    test('compresses large noisy PNG over 500 KB down to <= 500 KB JPEG', () {
      // Generate a high-entropy 1800x1200 image so PNG exceeds 500 KB.
      final random = math.Random(42);
      final rawImage = img.Image(width: 1800, height: 1200);
      for (var y = 0; y < rawImage.height; y += 2) {
        for (var x = 0; x < rawImage.width; x += 2) {
          final r = random.nextInt(256);
          final g = random.nextInt(256);
          final b = random.nextInt(256);
          rawImage.setPixelRgb(x, y, r, g, b);
          rawImage.setPixelRgb(x + 1, y, r, g, b);
          rawImage.setPixelRgb(x, y + 1, r, g, b);
          rawImage.setPixelRgb(x + 1, y + 1, r, g, b);
        }
      }
      final oversizedPng = Uint8List.fromList(img.encodePng(rawImage));
      expect(
        oversizedPng.length,
        greaterThan(ImagePdfCompressor.maxFileSizeBytes),
      );

      final result = ImagePdfCompressor.compressIfNeeded(
        bytes: oversizedPng,
        fileName: 'roster_photo.png',
      );

      expect(result.wasCompressed, isTrue);
      expect(result.mimeType, 'image/jpeg');
      expect(result.fileExtension, 'jpg');
      expect(result.originalSizeBytes, oversizedPng.length);
      expect(
        result.compressedSizeBytes,
        lessThanOrEqualTo(ImagePdfCompressor.maxFileSizeBytes),
      );
      expect(result.bytes.length, result.compressedSizeBytes);
    });

    test('keeps small JPEG under 500 KB unchanged without re-encoding', () {
      final smallImage = img.Image(width: 120, height: 80);
      final smallJpg = Uint8List.fromList(
        img.encodeJpg(smallImage, quality: 80),
      );
      expect(smallJpg.length, lessThan(ImagePdfCompressor.maxFileSizeBytes));

      final result = ImagePdfCompressor.compressIfNeeded(
        bytes: smallJpg,
        fileName: 'small_list.JPG',
      );

      expect(result.wasCompressed, isFalse);
      expect(result.mimeType, 'image/jpeg');
      expect(result.fileExtension, 'jpg');
      expect(result.bytes, same(smallJpg));
    });

    test('allows PDF <= 500 KB and rejects PDF > 500 KB with Thai message', () {
      final validPdf = Uint8List(128 * 1024);
      final ok = ImagePdfCompressor.compressIfNeeded(
        bytes: validPdf,
        fileName: 'sgs_m1_1.pdf',
      );
      expect(ok.wasCompressed, isFalse);
      expect(ok.mimeType, 'application/pdf');
      expect(ok.fileExtension, 'pdf');

      final hugePdf = Uint8List(ImagePdfCompressor.maxFileSizeBytes + 1024);
      expect(
        () => ImagePdfCompressor.compressIfNeeded(
          bytes: hugePdf,
          fileName: 'too_large.pdf',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'PDF_TOO_LARGE')
              .having((e) => e.message, 'message', contains('500 KB')),
        ),
      );
    });

    test('rejects unsupported file extensions and empty files', () {
      expect(
        () => ImagePdfCompressor.compressIfNeeded(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'malware.exe',
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'UNSUPPORTED_MIME_TYPE',
          ),
        ),
      );

      expect(
        () => ImagePdfCompressor.compressIfNeeded(
          bytes: Uint8List(0),
          fileName: 'empty.jpg',
        ),
        throwsA(
          isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FILE'),
        ),
      );
    });
  });
}
