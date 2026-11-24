import 'import_file_record.dart';

/// Aggregated active `import_files` storage usage for one academic year (พ.ศ.).
///
/// Pure Dart entity.
class AcademicYearStorageSummary {
  const AcademicYearStorageSummary({
    required this.academicYearId,
    required this.yearBe,
    required this.files,
    required this.totalBytes,
    required this.latestUploadedAt,
    required this.isRecommendedForCleanup,
  });

  final String academicYearId;
  final int yearBe;
  final List<ImportFileRecord> files;
  final int totalBytes;
  final DateTime latestUploadedAt;
  final bool isRecommendedForCleanup;

  int get fileCount => files.length;
}
