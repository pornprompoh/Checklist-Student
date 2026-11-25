import '../../../auth/domain/entities/teacher_profile.dart';
import '../entities/import_file_record.dart';
import '../entities/teacher_code_history_entry.dart';
import '../entities/teacher_profile_update.dart';

/// Abstract repository contract for teacher profile settings, short code
/// management, code redirect history, and yearly `import-sources` cleanup.
///
/// Pure Dart interface following the Repository Pattern.
abstract interface class SettingsRepository {
  /// Updates editable profile and default threshold columns in `public.teachers`.
  Future<TeacherProfile> updateTeacherProfile({
    required String teacherId,
    required TeacherProfileUpdate update,
  });

  /// Updates `public.teachers.teacher_code` (archived automatically via trigger).
  Future<TeacherProfile> updateTeacherCode({
    required String teacherId,
    required String newTeacherCode,
  });

  /// Loads historical codes from `public.teacher_code_history` newest first.
  Future<List<TeacherCodeHistoryEntry>> fetchTeacherCodeHistory(
    String teacherId,
  );

  /// Loads active (`deleted_at IS NULL`) rows in `public.import_files`.
  Future<List<ImportFileRecord>> fetchActiveImportFiles(String teacherId);

  /// Generates a short-lived (60s) Signed URL for an owned file in `import-sources`.
  Future<String> createImportFileSignedUrl(String storagePath);

  /// Removes all active files for [academicYearId] from `import-sources` and
  /// soft-marks them (`deleted_at = NOW()`) in `public.import_files`.
  Future<int> cleanupImportFilesByAcademicYear({
    required String teacherId,
    required String academicYearId,
  });
}
