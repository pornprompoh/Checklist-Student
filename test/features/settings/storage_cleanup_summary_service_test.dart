import 'package:checklist_student/features/settings/domain/entities/import_file_record.dart';
import 'package:checklist_student/features/settings/domain/services/storage_cleanup_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageCleanupSummaryService', () {
    ImportFileRecord makeRecord({
      required String id,
      required String yearId,
      required int yearBe,
      required int sizeBytes,
      required DateTime createdAt,
      DateTime? deletedAt,
    }) {
      return ImportFileRecord(
        id: id,
        teacherId: 'teacher-1',
        academicYearId: yearId,
        academicYearBe: yearBe,
        storagePath: 'teacher-1/$yearId/$id.jpg',
        originalFilename: '$id.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: sizeBytes,
        createdAt: createdAt,
        deletedAt: deletedAt,
      );
    }

    test('groups active files by academic year DESC, totals bytes, and flags cleanup', () {
      final now = DateTime(2026, 11, 24); // พ.ศ. 2569
      final records = <ImportFileRecord>[
        makeRecord(
          id: 'f1',
          yearId: 'ay-2568',
          yearBe: 2568,
          sizeBytes: 200000,
          createdAt: DateTime(2025, 5, 20),
        ),
        makeRecord(
          id: 'f2',
          yearId: 'ay-2568',
          yearBe: 2568,
          sizeBytes: 150000,
          createdAt: DateTime(2025, 11, 10),
        ),
        makeRecord(
          id: 'f3',
          yearId: 'ay-2569',
          yearBe: 2569,
          sizeBytes: 120000,
          createdAt: DateTime(2026, 5, 16),
        ),
        // Soft-deleted file must be ignored.
        makeRecord(
          id: 'f4-deleted',
          yearId: 'ay-2567',
          yearBe: 2567,
          sizeBytes: 300000,
          createdAt: DateTime(2024, 5, 1),
          deletedAt: DateTime(2025, 6, 1),
        ),
      ];

      final summaries = StorageCleanupSummaryService.summarizeByAcademicYear(
        records,
        now: now,
      );

      expect(summaries, hasLength(2));
      // Sorted by yearBe DESC: 2569 first, then 2568.
      expect(summaries[0].yearBe, 2569);
      expect(summaries[0].fileCount, 1);
      expect(summaries[0].totalBytes, 120000);
      expect(summaries[0].isRecommendedForCleanup, isFalse);

      expect(summaries[1].yearBe, 2568);
      expect(summaries[1].fileCount, 2);
      expect(summaries[1].totalBytes, 350000);
      expect(summaries[1].latestUploadedAt, DateTime(2025, 11, 10));
      expect(summaries[1].isRecommendedForCleanup, isTrue);
    });

    test('flags current year for cleanup when oldest file is >= 365 days old', () {
      final now = DateTime(2026, 12, 1); // พ.ศ. 2569
      final summaries = StorageCleanupSummaryService.summarizeByAcademicYear(
        <ImportFileRecord>[
          makeRecord(
            id: 'old-current',
            yearId: 'ay-2569',
            yearBe: 2569,
            sizeBytes: 50000,
            createdAt: DateTime(2025, 11, 30), // 366 days before now
          ),
        ],
        now: now,
      );

      expect(summaries, hasLength(1));
      expect(summaries.first.isRecommendedForCleanup, isTrue);
    });
  });
}
