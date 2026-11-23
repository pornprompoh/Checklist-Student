import '../../../auth/domain/entities/teacher_profile.dart';
import '../entities/teacher_code_history_entry.dart';
import '../entities/teacher_profile_update.dart';

/// Abstract repository contract for teacher profile settings, short code
/// management, and code redirect history.
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
}
