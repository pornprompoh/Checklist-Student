import '../../../../core/constants/submission_status.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_pin_status.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/repositories/grading_repository.dart';
import '../datasources/grading_local_datasource.dart';
import '../datasources/grading_remote_datasource.dart';

/// Repository implementation bridging [GradingRemoteDataSource] and future
/// Phase 6 [GradingLocalDataSource] (Drift).
class GradingRepositoryImpl implements GradingRepository {
  const GradingRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
  });

  final GradingRemoteDataSource? _remoteDataSource;
  // Reserved for Phase 6 Drift local caching.
  // ignore: unused_field
  final GradingLocalDataSource? _localDataSource;

  @override
  Future<List<ScoreCategory>> fetchScoreCategories(
    String subjectClassId,
  ) async {
    final dtos = await _requireRemote().fetchScoreCategories(subjectClassId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<ScoreCategory> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    final dto = await _requireRemote().createScoreCategory(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
  Future<ScoreCategory> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    final dto = await _requireRemote().updateScoreCategory(
      categoryId: categoryId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteScoreCategory(String categoryId) {
    return _requireRemote().deleteScoreCategory(categoryId);
  }

  @override
  Future<List<Assignment>> fetchAssignments(String subjectClassId) async {
    final dtos = await _requireRemote().fetchAssignments(subjectClassId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
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
  }) async {
    final dto = await _requireRemote().createAssignment(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      categoryId: categoryId,
      title: title,
      description: description,
      maxScore: maxScore,
      isMandatory: isMandatory,
      dueDate: dueDate,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
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
  }) async {
    final dto = await _requireRemote().updateAssignment(
      assignmentId: assignmentId,
      expectedVersion: expectedVersion,
      categoryId: categoryId,
      title: title,
      description: description,
      maxScore: maxScore,
      isMandatory: isMandatory,
      dueDate: dueDate,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
  Future<int> countScoredStudentsForAssignment(String assignmentId) {
    return _requireRemote().countScoredStudentsForAssignment(assignmentId);
  }

  @override
  Future<void> deleteAssignment(String assignmentId) {
    return _requireRemote().deleteAssignment(assignmentId);
  }

  @override
  Future<List<StudentScore>> fetchStudentScoresByClass(
    String subjectClassId,
  ) async {
    final dtos = await _requireRemote().fetchStudentScoresByClass(
      subjectClassId,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<StudentScore> upsertStudentScore({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    String? existingScoreId,
    int? expectedVersion,
    required SubmissionStatus submissionStatus,
    double? score,
    String note = '',
  }) async {
    final dto = await _requireRemote().upsertStudentScore(
      teacherId: teacherId,
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      existingScoreId: existingScoreId,
      expectedVersion: expectedVersion,
      submissionStatus: submissionStatus,
      score: score,
      note: note,
    );
    return dto.toEntity();
  }

  @override
  Future<GradingScaleConfig> fetchGradingScaleConfig(
    String subjectClassId,
  ) async {
    final dto = await _requireRemote().fetchGradingScaleConfig(subjectClassId);
    return dto.toEntity();
  }

  @override
  Future<GradingScaleConfig> updateGradingScaleConfig(
    GradingScaleConfig config,
  ) async {
    final dto = await _requireRemote().updateGradingScaleConfig(config);
    return dto.toEntity();
  }

  @override
  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  }) {
    return _requireRemote().copySubjectClassPlan(
      sourceClassId: sourceClassId,
      targetClassId: targetClassId,
      replaceExisting: replaceExisting,
    );
  }

  @override
  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) {
    return _requireRemote().updateSpecialGradeStatus(
      enrollmentId: enrollmentId,
      expectedVersion: expectedVersion,
      specialGradeOverride: specialGradeOverride,
      markRResolved: markRResolved,
      markMsResolved: markMsResolved,
    );
  }

  @override
  Future<StudentPinStatus> fetchStudentPinStatus(
    String studentIdentityId,
  ) async {
    final dto = await _requireRemote().fetchStudentPinStatus(studentIdentityId);
    return dto.toEntity();
  }

  @override
  Future<void> resetStudentPin(String studentIdentityId) {
    return _requireRemote().resetStudentPin(studentIdentityId);
  }

  GradingRemoteDataSource _requireRemote() {
    final remote = _remoteDataSource;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนดำเนินการ',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote;
  }
}
