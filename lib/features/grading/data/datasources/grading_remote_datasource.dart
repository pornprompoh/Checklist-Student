import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/student_portal_visibility_config.dart';
import '../models/assignment_dto.dart';
import '../models/grading_scale_config_dto.dart';
import '../models/score_category_dto.dart';
import '../models/student_pin_status_dto.dart';
import '../models/student_score_dto.dart';
import 'grading_score_remote_helper.dart';
import 'grading_structure_remote_helper.dart';

/// Public remote datasource facade for `features/grading/`.
///
/// Delegates to [GradingStructureRemoteHelper] and [GradingScoreRemoteHelper]
/// so each file in `data/datasources/` stays focused and concise.
class GradingRemoteDataSource {
  GradingRemoteDataSource(SupabaseClient client)
    : _structure = GradingStructureRemoteHelper(client),
      _scores = GradingScoreRemoteHelper(client);

  final GradingStructureRemoteHelper _structure;
  final GradingScoreRemoteHelper _scores;

  Future<List<ScoreCategoryDto>> fetchScoreCategories(String subjectClassId) {
    return _structure.fetchScoreCategories(subjectClassId);
  }

  Future<ScoreCategoryDto> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) {
    return _structure.createScoreCategory(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
    );
  }

  Future<ScoreCategoryDto> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) {
    return _structure.updateScoreCategory(
      categoryId: categoryId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
    );
  }

  Future<void> deleteScoreCategory(String categoryId) {
    return _structure.deleteScoreCategory(categoryId);
  }

  Future<List<AssignmentDto>> fetchAssignments(String subjectClassId) {
    return _structure.fetchAssignments(subjectClassId);
  }

  Future<AssignmentDto> createAssignment({
    required String teacherId,
    required String subjectClassId,
    String? categoryId,
    required String title,
    String description = '',
    required double maxScore,
    bool isMandatory = false,
    DateTime? dueDate,
    int? sortOrder,
  }) {
    return _structure.createAssignment(
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
  }

  Future<AssignmentDto> updateAssignment({
    required String assignmentId,
    required int expectedVersion,
    String? categoryId,
    required String title,
    required String description,
    required double maxScore,
    required bool isMandatory,
    DateTime? dueDate,
    int? sortOrder,
  }) {
    return _structure.updateAssignment(
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
  }

  Future<int> countScoredStudentsForAssignment(String assignmentId) {
    return _structure.countScoredStudentsForAssignment(assignmentId);
  }

  Future<void> deleteAssignment(String assignmentId) {
    return _structure.deleteAssignment(assignmentId);
  }

  Future<List<StudentScoreDto>> fetchStudentScoresByClass(
    String subjectClassId,
  ) {
    return _scores.fetchStudentScoresByClass(subjectClassId);
  }

  Future<StudentScoreDto?> fetchStudentScoreById(String scoreId) {
    return _scores.fetchStudentScoreById(scoreId);
  }

  Future<StudentScoreDto?> fetchStudentScoreByCell({
    required String assignmentId,
    required String enrollmentId,
  }) {
    return _scores.fetchStudentScoreByCell(
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
    );
  }

  Future<Map<String, dynamic>?> fetchEnrollmentGradeStatusById(
    String enrollmentId,
  ) {
    return _scores.fetchEnrollmentGradeStatusById(enrollmentId);
  }

  Future<StudentScoreDto> upsertStudentScore({
    String? clientId,
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    String? existingScoreId,
    int? expectedVersion,
    required SubmissionStatus submissionStatus,
    double? score,
    String note = '',
  }) {
    return _scores.upsertStudentScore(
      clientId: clientId,
      teacherId: teacherId,
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      existingScoreId: existingScoreId,
      expectedVersion: expectedVersion,
      submissionStatus: submissionStatus,
      score: score,
      note: note,
    );
  }

  Future<GradingScaleConfigDto> fetchGradingScaleConfig(String subjectClassId) {
    return _scores.fetchGradingScaleConfig(subjectClassId);
  }

  Future<GradingScaleConfigDto> updateGradingScaleConfig(
    GradingScaleConfig config,
  ) {
    return _scores.updateGradingScaleConfig(config);
  }

  Future<StudentPortalVisibilityConfig> fetchStudentPortalVisibility(
    String subjectClassId,
  ) {
    return _scores.fetchStudentPortalVisibility(subjectClassId);
  }

  Future<StudentPortalVisibilityConfig> updateStudentPortalVisibility(
    StudentPortalVisibilityConfig config,
  ) {
    return _scores.updateStudentPortalVisibility(config);
  }

  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  }) {
    return _scores.copySubjectClassPlan(
      sourceClassId: sourceClassId,
      targetClassId: targetClassId,
      replaceExisting: replaceExisting,
    );
  }

  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) {
    return _scores.updateSpecialGradeStatus(
      enrollmentId: enrollmentId,
      expectedVersion: expectedVersion,
      specialGradeOverride: specialGradeOverride,
      markRResolved: markRResolved,
      markMsResolved: markMsResolved,
    );
  }

  Future<StudentPinStatusDto> fetchStudentPinStatus(String studentIdentityId) {
    return _scores.fetchStudentPinStatus(studentIdentityId);
  }

  Future<void> resetStudentPin(String studentIdentityId) {
    return _scores.resetStudentPin(studentIdentityId);
  }
}

final gradingRemoteDataSourceProvider = Provider<GradingRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return GradingRemoteDataSource(client);
});
