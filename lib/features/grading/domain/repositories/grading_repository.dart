import '../../../../core/constants/submission_status.dart';
import '../entities/assignment.dart';
import '../entities/grade_result.dart';
import '../entities/grading_scale_config.dart';
import '../entities/score_category.dart';
import '../entities/student_pin_status.dart';
import '../entities/student_portal_visibility_config.dart';
import '../entities/student_score.dart';

/// Contract for grading persistence across score categories, assignments,
/// student scores, grading scale rules, plan copying, and special grades.
///
/// Pure Dart interface with zero Flutter or Supabase dependencies.
abstract interface class GradingRepository {
  Future<List<ScoreCategory>> fetchScoreCategories(String subjectClassId);

  Future<ScoreCategory> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  });

  Future<ScoreCategory> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  });

  Future<void> deleteScoreCategory(String categoryId);

  Future<List<Assignment>> fetchAssignments(String subjectClassId);

  Future<Assignment> createAssignment({
    required String teacherId,
    required String subjectClassId,
    String? categoryId,
    required String title,
    String description = '',
    required double maxScore,
    bool isMandatory = false,
    DateTime? dueDate,
    int? sortOrder,
  });

  Future<Assignment> updateAssignment({
    required String assignmentId,
    required int expectedVersion,
    String? categoryId,
    required String title,
    required String description,
    required double maxScore,
    required bool isMandatory,
    DateTime? dueDate,
    int? sortOrder,
  });

  Future<int> countScoredStudentsForAssignment(String assignmentId);

  Future<void> deleteAssignment(String assignmentId);

  Future<List<StudentScore>> fetchStudentScoresByClass(String subjectClassId);

  Future<StudentScore> upsertStudentScore({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    String? existingScoreId,
    int? expectedVersion,
    required SubmissionStatus submissionStatus,
    double? score,
    String note = '',
  });

  Future<GradingScaleConfig> fetchGradingScaleConfig(String subjectClassId);

  Future<GradingScaleConfig> updateGradingScaleConfig(
    GradingScaleConfig config,
  );

  Future<StudentPortalVisibilityConfig> fetchStudentPortalVisibility(
    String subjectClassId,
  );

  Future<StudentPortalVisibilityConfig> updateStudentPortalVisibility(
    StudentPortalVisibilityConfig config,
  );

  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  });

  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  });

  Future<StudentPinStatus> fetchStudentPinStatus(String studentIdentityId);

  Future<void> resetStudentPin(String studentIdentityId);
}
