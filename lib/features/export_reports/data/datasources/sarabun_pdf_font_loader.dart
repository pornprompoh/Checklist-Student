import 'package:flutter/services.dart';

import '../../../../core/errors/app_exception.dart';

/// Cached font bytes bundle loaded from Flutter assets for Sarabun PDF rendering.
class SarabunFontBytes {
  const SarabunFontBytes({required this.regular, required this.bold});

  final Uint8List regular;
  final Uint8List bold;
}

/// Asset loader caching `assets/fonts/Sarabun-Regular.ttf` and
/// `assets/fonts/Sarabun-Bold.ttf` in memory so `PdfReportGeneratorService`
/// inside `domain/` stays 100% Pure Dart.
class SarabunPdfFontLoader {
  SarabunFontBytes? _cached;

  static const String regularAssetPath = 'assets/fonts/Sarabun-Regular.ttf';
  static const String boldAssetPath = 'assets/fonts/Sarabun-Bold.ttf';

  Future<SarabunFontBytes> load() async {
    final existing = _cached;
    if (existing != null) {
      return existing;
    }
    try {
      final results = await Future.wait<ByteData>(<Future<ByteData>>[
        rootBundle.load(regularAssetPath),
        rootBundle.load(boldAssetPath),
      ]);
      final loaded = SarabunFontBytes(
        regular: results[0].buffer.asUint8List(
          results[0].offsetInBytes,
          results[0].lengthInBytes,
        ),
        bold: results[1].buffer.asUint8List(
          results[1].offsetInBytes,
          results[1].lengthInBytes,
        ),
      );
      _cached = loaded;
      return loaded;
    } catch (error) {
      throw ValidationException(
        'ไม่สามารถโหลดฟอนต์ภาษาไทย Sarabun สำหรับสร้าง PDF ได้ กรุณาลองรีเฟรชหน้าเว็บ',
        code: 'SARABUN_FONT_LOAD_FAILED',
        cause: error,
      );
    }
  }
}
