import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_portal_visibility_config.dart';
import '../../domain/entities/student_score.dart';
import 'grading_providers.dart';

/// Detail of a student whose existing score exceeds a proposed lower `maxScore`.
class OverMaxScoreDetail {
  const OverMaxScoreDetail({
    required this.enrollmentId,
    required this.studentLabel,
    required this.currentScore,
  });

  final String enrollmentId;
  final String studentLabel;
  final double currentScore;
}

/// Controller coordinating mutations on `GradingPlanPage`:
/// score categories, assignments (with Optimistic Locking `version`),
/// mid-term safety checks, grading scale config, and plan copying.
class PlanEditorController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  String _requireTeacherId() {
    final userId = ref.read(authStateProvider).userId;
    if (userId == null || userId.isEmpty) {
      throw const ValidationException(
        'กรุณาเข้าสู่ระบบก่อนดำเนินการ',
        code: 'UNAUTHENTICATED',
      );
    }
    return userId;
  }

  Future<ScoreCategory?> createCategory({
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    return _run<ScoreCategory>(() async {
      final created = await ref
          .read(gradingRepositoryProvider)
          .createScoreCategory(
            teacherId: _requireTeacherId(),
            subjectClassId: subjectClassId,
            name: name,
            targetMaxScore: targetMaxScore,
            sortOrder: sortOrder,
          );
      ref.invalidate(scoreCategoriesProvider(subjectClassId));
      return created;
    });
  }

  Future<ScoreCategory?> updateCategory({
    required String subjectClassId,
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    return _run<ScoreCategory>(() async {
      final updated = await ref
          .read(gradingRepositoryProvider)
          .updateScoreCategory(
            categoryId: categoryId,
            name: name,
            targetMaxScore: targetMaxScore,
            sortOrder: sortOrder,
          );
      ref.invalidate(scoreCategoriesProvider(subjectClassId));
      return updated;
    });
  }

  Future<bool> deleteCategory({
    required String subjectClassId,
    required String categoryId,
  }) async {
    final done = await _run<bool>(() async {
      await ref
          .read(gradingRepositoryProvider)
          .deleteScoreCategory(categoryId);
      ref
        ..invalidate(scoreCategoriesProvider(subjectClassId))
        ..invalidate(assignmentsProvider(subjectClassId));
      return true;
    });
    return done ?? false;
  }

  Future<Assignment?> createAssignment({
    required String subjectClassId,
    String? categoryId,
    required String title,
    String description = '',
    required double maxScore,
    bool isMandatory = false,
    DateTime? dueDate,
  }) async {
    return _run<Assignment>(() async {
      final created = await ref
          .read(gradingRepositoryProvider)
          .createAssignment(
            teacherId: _requireTeacherId(),
            subjectClassId: subjectClassId,
            categoryId: categoryId,
            title: title,
            description: description,
            maxScore: maxScore,
            isMandatory: isMandatory,
            dueDate: dueDate,
          );
      ref.invalidate(assignmentsProvider(subjectClassId));
      return created;
    });
  }

  Future<Assignment?> updateAssignment({
    required String subjectClassId,
    required String assignmentId,
    required int expectedVersion,
    String? categoryId,
    required String title,
    required String description,
    required double maxScore,
    required bool isMandatory,
    DateTime? dueDate,
  }) async {
    return _run<Assignment>(() async {
      final updated = await ref
          .read(gradingRepositoryProvider)
          .updateAssignment(
            assignmentId: assignmentId,
            expectedVersion: expectedVersion,
            categoryId: categoryId,
            title: title,
            description: description,
            maxScore: maxScore,
            isMandatory: isMandatory,
            dueDate: dueDate,
          );
      ref
        ..invalidate(assignmentsProvider(subjectClassId))
        ..invalidate(studentScoresByClassProvider(subjectClassId));
      return updated;
    });
  }

  Future<int?> countScoredStudents(String assignmentId) async {
    return _run<int>(() {
      return ref
          .read(gradingRepositoryProvider)
          .countScoredStudentsForAssignment(assignmentId);
    });
  }

  Future<bool> deleteAssignment({
    required String subjectClassId,
    required String assignmentId,
  }) async {
    final done = await _run<bool>(() async {
      await ref.read(gradingRepositoryProvider).deleteAssignment(assignmentId);
      ref
        ..invalidate(assignmentsProvider(subjectClassId))
        ..invalidate(studentScoresByClassProvider(subjectClassId));
      return true;
    });
    return done ?? false;
  }

  /// Finds students whose recorded score for [assignmentId] strictly exceeds
  /// [newMaxScore], formatted with student numbers/names when available.
  Future<List<OverMaxScoreDetail>> findOverMaxScoresForNewMax({
    required String subjectClassId,
    required String assignmentId,
    required double newMaxScore,
  }) async {
    final scores = await ref.read(
      studentScoresByClassProvider(subjectClassId).future,
    );
    final newMaxCents = (newMaxScore * 100).round();
    final affected = <StudentScore>[
      for (final item in scores)
        if (item.assignmentId == assignmentId &&
            item.score != null &&
            (item.score! * 100).round() > newMaxCents)
          item,
    ];
    if (affected.isEmpty) {
      return const <OverMaxScoreDetail>[];
    }

    var enrollmentMap = const <String, ClassEnrollment>{};
    try {
      final enrollments = await ref.read(
        classEnrollmentsProvider(subjectClassId).future,
      );
      enrollmentMap = <String, ClassEnrollment>{
        for (final item in enrollments) item.id: item,
      };
    } catch (_) {
      enrollmentMap = const <String, ClassEnrollment>{};
    }

    final details = affected
        .map((score) {
          final enrollment = enrollmentMap[score.enrollmentId];
          final label = enrollment == null
              ? 'นักเรียน (รหัสลงทะเบียน ${score.enrollmentId.substring(0, 6)})'
              : 'เลขที่ ${enrollment.studentNumber} ${enrollment.fullName}';
          return OverMaxScoreDetail(
            enrollmentId: score.enrollmentId,
            studentLabel: label,
            currentScore: score.score!,
          );
        })
        .toList(growable: false);
    return details;
  }

  Future<GradingScaleConfig?> saveGradingScaleConfig(
    GradingScaleConfig config,
  ) async {
    return _run<GradingScaleConfig>(() async {
      final ruleError = ref
          .read(gradeEvaluatorServiceProvider)
          .validateGradingRules(config.rules);
      if (ruleError != null) {
        throw ValidationException(ruleError, code: 'INVALID_GRADING_RULES');
      }
      if (config.missingWorkThreshold < 1) {
        throw const ValidationException(
          'เกณฑ์จำนวนงานค้างต้องเป็นจำนวนเต็มตั้งแต่ 1 ชิ้นขึ้นไป',
          code: 'INVALID_MISSING_WORK_THRESHOLD',
        );
      }
      final saved = await ref
          .read(gradingRepositoryProvider)
          .updateGradingScaleConfig(config);
      ref.invalidate(gradingScaleConfigProvider(config.subjectClassId));
      return saved;
    });
  }

  Future<StudentPortalVisibilityConfig?> saveStudentPortalVisibility(
    StudentPortalVisibilityConfig config,
  ) async {
    return _run<StudentPortalVisibilityConfig>(() async {
      final saved = await ref
          .read(gradingRepositoryProvider)
          .updateStudentPortalVisibility(config);
      ref.invalidate(studentPortalVisibilityProvider(config.subjectClassId));
      return saved;
    });
  }

  Future<CopyPlanResult?> copyPlanFromClass({
    required String sourceClassId,
    required String targetClassId,
    required bool replaceExisting,
  }) async {
    return _run<CopyPlanResult>(() async {
      final result = await ref
          .read(gradingRepositoryProvider)
          .copySubjectClassPlan(
            sourceClassId: sourceClassId,
            targetClassId: targetClassId,
            replaceExisting: replaceExisting,
          );
      refreshClassPlan(targetClassId);
      return result;
    });
  }

  void refreshClassPlan(String subjectClassId) {
    ref
      ..invalidate(scoreCategoriesProvider(subjectClassId))
      ..invalidate(assignmentsProvider(subjectClassId))
      ..invalidate(studentScoresByClassProvider(subjectClassId))
      ..invalidate(gradingScaleConfigProvider(subjectClassId))
      ..invalidate(studentPortalVisibilityProvider(subjectClassId));
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading<void>();
    try {
      final result = await action();
      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return null;
    }
  }
}

final planEditorControllerProvider =
    NotifierProvider<PlanEditorController, AsyncValue<void>>(
      PlanEditorController.new,
    );
