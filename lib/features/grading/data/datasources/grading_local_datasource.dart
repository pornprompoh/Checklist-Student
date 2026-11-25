import '../../domain/entities/assignment.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_score.dart';

/// Local Drift datasource contract for Grading offline-first caching,
/// exact-decimal score persistence, and dirty-row preservation.
abstract interface class GradingLocalDataSource {
  Future<void> saveScoreCategories(
    String teacherId,
    String subjectClassId,
    List<ScoreCategory> categories,
  );

  Future<List<ScoreCategory>?> readScoreCategories(
    String teacherId,
    String subjectClassId,
  );

  Future<void> saveAssignments(
    String teacherId,
    String subjectClassId,
    List<Assignment> assignments,
  );

  Future<List<Assignment>?> readAssignments(
    String teacherId,
    String subjectClassId,
  );

  Future<void> saveGradingScaleConfig(
    String teacherId,
    GradingScaleConfig config,
  );

  Future<GradingScaleConfig?> readGradingScaleConfig(
    String teacherId,
    String subjectClassId,
  );

  Future<List<StudentScore>?> fetchStudentScoresByClass(
    String teacherId,
    String subjectClassId,
  );

  Future<StudentScore?> fetchStudentScoreById(String teacherId, String scoreId);

  Future<StudentScore?> fetchStudentScoreByCell({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
  });

  /// Caches server scores locally without overwriting any `isDirty == true`
  /// local rows.
  Future<void> upsertScoresFromRemote(
    String teacherId,
    String subjectClassId,
    List<StudentScore> scores,
  );

  Future<void> saveScoreOffline(
    StudentScore score, {
    String? subjectClassId,
  });

  Future<void> markScoreSynced(
    StudentScore score, {
    String? subjectClassId,
    String? previousLocalId,
  });
}
