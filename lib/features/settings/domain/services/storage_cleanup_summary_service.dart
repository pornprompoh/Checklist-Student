import '../../../../core/utils/thai_date_formatter.dart';
import '../entities/academic_year_storage_summary.dart';
import '../entities/import_file_record.dart';

/// Pure Dart domain service grouping active `import_files` records by
/// academic year (พ.ศ.) and recommending cleanup for files older than 1 year
/// or belonging to past academic years.
abstract final class StorageCleanupSummaryService {
  static const int cleanupRecommendationAgeDays = 365;

  static List<AcademicYearStorageSummary> summarizeByAcademicYear(
    List<ImportFileRecord> records, {
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final currentYearBe = ThaiDateFormatter.toBuddhistYear(referenceNow.year);

    final grouped = <String, List<ImportFileRecord>>{};
    for (final record in records) {
      if (!record.isActive) continue;
      grouped
          .putIfAbsent(record.academicYearId, () => <ImportFileRecord>[])
          .add(record);
    }

    final summaries = <AcademicYearStorageSummary>[];
    for (final entry in grouped.entries) {
      final files = List<ImportFileRecord>.of(entry.value)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      var totalBytes = 0;
      DateTime latest = files.first.createdAt;
      DateTime oldest = files.first.createdAt;
      final yearBe = files.first.academicYearBe;

      for (final file in files) {
        totalBytes += file.fileSizeBytes;
        if (file.createdAt.isAfter(latest)) {
          latest = file.createdAt;
        }
        if (file.createdAt.isBefore(oldest)) {
          oldest = file.createdAt;
        }
      }

      final isPastAcademicYear = yearBe > 0 && yearBe < currentYearBe;
      final isOlderThanOneYear =
          referenceNow.difference(oldest).inDays >=
          cleanupRecommendationAgeDays;

      summaries.add(
        AcademicYearStorageSummary(
          academicYearId: entry.key,
          yearBe: yearBe,
          files: List<ImportFileRecord>.unmodifiable(files),
          totalBytes: totalBytes,
          latestUploadedAt: latest,
          isRecommendedForCleanup: isPastAcademicYear || isOlderThanOneYear,
        ),
      );
    }

    summaries.sort((a, b) {
      final byYear = b.yearBe.compareTo(a.yearBe);
      if (byYear != 0) return byYear;
      return b.latestUploadedAt.compareTo(a.latestUploadedAt);
    });

    return List<AcademicYearStorageSummary>.unmodifiable(summaries);
  }
}
