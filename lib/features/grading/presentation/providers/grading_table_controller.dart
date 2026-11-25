import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../attendance/domain/entities/student_attendance_summary.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_score.dart';
import 'grading_filter_provider.dart';
import 'grading_providers.dart';
import 'grading_table_state.dart';

export 'grading_table_state.dart';

class _FailedSaveRequest {
  const _FailedSaveRequest({
    required this.teacherId,
    required this.enrollmentId,
    required this.assignmentId,
    required this.score,
    required this.status,
    required this.note,
  });

  final String teacherId;
  final String enrollmentId;
  final String assignmentId;
  final double? score;
  final SubmissionStatus status;
  final String? note;
}

/// Controller for `GradingTablePage` managing Preview/Edit mode, active cell
/// focus, in-memory Optimistic Locking score cache, and per-cell auto-save.
class GradingTableController extends Notifier<GradingTableState> {
  _FailedSaveRequest? _lastFailedRequest;

  @override
  GradingTableState build() => const GradingTableState();

  /// Synchronizes server scores into local state. Resets Preview Mode when
  /// switching to a different [subjectClassId].
  void hydrateFromServer({
    required String subjectClassId,
    required List<StudentScore> serverScores,
    bool forceReplace = false,
  }) {
    final isClassSwitch = state.boundClassId != subjectClassId;
    if (!isClassSwitch && state.hasHydratedClass && !forceReplace) {
      return;
    }

    final nextScores = <String, StudentScore>{
      for (final item in serverScores)
        gradingCellKey(item.enrollmentId, item.assignmentId): item,
    };
    if (!isClassSwitch && !forceReplace) {
      for (final pendingKey in state.pendingKeys) {
        final local = state.scoresByCellKey[pendingKey];
        if (local != null) {
          nextScores[pendingKey] = local;
        }
      }
    }

    _lastFailedRequest = null;
    state = GradingTableState(
      boundClassId: subjectClassId,
      isEditMode: isClassSwitch ? false : state.isEditMode,
      activeCellKey: isClassSwitch ? null : state.activeCellKey,
      scoresByCellKey: Map<String, StudentScore>.unmodifiable(nextScores),
      cellStatuses: const <String, CellSaveStatus>{},
      pendingKeys: const <String>{},
      overallSaveStatus: CellSaveStatus.idle,
      lastSavedAt: isClassSwitch ? null : state.lastSavedAt,
      lastErrorMessage: null,
      hasHydratedClass: true,
    );
  }

  void toggleEditMode() {
    final nextMode = !state.isEditMode;
    state = state.copyWith(
      isEditMode: nextMode,
      activeCellKey: nextMode ? state.activeCellKey : null,
    );
  }

  void enterCellEdit(String enrollmentId, String assignmentId) {
    state = state.copyWith(
      activeCellKey: gradingCellKey(enrollmentId, assignmentId),
    );
  }

  void exitCellEdit() {
    if (state.activeCellKey != null) {
      state = state.copyWith(activeCellKey: null);
    }
  }

  /// Auto-saves one student-assignment cell with Optimistic Locking (`version`).
  Future<bool> autoSaveCellScore({
    required String teacherId,
    required String enrollmentId,
    required String assignmentId,
    required double? score,
    required SubmissionStatus status,
    String? note,
  }) async {
    final cellKey = gradingCellKey(enrollmentId, assignmentId);
    if (state.pendingKeys.contains(cellKey)) {
      return false;
    }

    if (score != null && (!score.isFinite || score < 0)) {
      state = state.copyWith(
        cellStatuses: <String, CellSaveStatus>{
          ...state.cellStatuses,
          cellKey: CellSaveStatus.error,
        },
        overallSaveStatus: CellSaveStatus.error,
        lastErrorMessage: 'คะแนนต้องเป็นตัวเลขที่ไม่ติดลบ',
      );
      return false;
    }

    final existing = state.scoresByCellKey[cellKey];
    final effectiveNote = (note ?? existing?.note ?? '').trim();
    final effectiveStatus =
        score != null && status == SubmissionStatus.missing && existing == null
        ? SubmissionStatus.submitted
        : status;

    if (!_hasChanged(existing, score, effectiveStatus, effectiveNote)) {
      return true;
    }

    state = state.copyWith(
      pendingKeys: <String>{...state.pendingKeys, cellKey},
      cellStatuses: <String, CellSaveStatus>{
        ...state.cellStatuses,
        cellKey: CellSaveStatus.saving,
      },
      overallSaveStatus: CellSaveStatus.saving,
      lastErrorMessage: null,
    );

    try {
      final saved = await ref
          .read(gradingRepositoryProvider)
          .upsertStudentScore(
            teacherId: teacherId,
            assignmentId: assignmentId,
            enrollmentId: enrollmentId,
            existingScoreId: existing?.id,
            expectedVersion: existing?.version,
            submissionStatus: effectiveStatus,
            score: score,
            note: effectiveNote,
          );

      final nextPending = Set<String>.of(state.pendingKeys)..remove(cellKey);
      final nextScores = <String, StudentScore>{
        ...state.scoresByCellKey,
        cellKey: saved,
      };
      final nextStatuses = <String, CellSaveStatus>{
        ...state.cellStatuses,
        cellKey: CellSaveStatus.saved,
      };
      _lastFailedRequest = null;
      state = state.copyWith(
        scoresByCellKey: Map<String, StudentScore>.unmodifiable(nextScores),
        cellStatuses: Map<String, CellSaveStatus>.unmodifiable(nextStatuses),
        pendingKeys: Set<String>.unmodifiable(nextPending),
        overallSaveStatus: nextPending.isEmpty
            ? CellSaveStatus.saved
            : CellSaveStatus.saving,
        lastSavedAt: DateTime.now(),
        lastErrorMessage: null,
      );
      return true;
    } on ConflictException catch (error) {
      final nextPending = Set<String>.of(state.pendingKeys)..remove(cellKey);
      state = state.copyWith(
        pendingKeys: Set<String>.unmodifiable(nextPending),
        cellStatuses: <String, CellSaveStatus>{
          ...state.cellStatuses,
          cellKey: CellSaveStatus.conflict,
        },
        overallSaveStatus: CellSaveStatus.conflict,
        lastErrorMessage: ThaiErrorMapper.map(error),
      );
      return false;
    } catch (error) {
      final nextPending = Set<String>.of(state.pendingKeys)..remove(cellKey);
      _lastFailedRequest = _FailedSaveRequest(
        teacherId: teacherId,
        enrollmentId: enrollmentId,
        assignmentId: assignmentId,
        score: score,
        status: effectiveStatus,
        note: effectiveNote,
      );
      state = state.copyWith(
        pendingKeys: Set<String>.unmodifiable(nextPending),
        cellStatuses: <String, CellSaveStatus>{
          ...state.cellStatuses,
          cellKey: CellSaveStatus.error,
        },
        overallSaveStatus: CellSaveStatus.error,
        lastErrorMessage: ThaiErrorMapper.map(error),
      );
      return false;
    }
  }

  Future<void> retryLastFailedSave() async {
    final req = _lastFailedRequest;
    if (req == null) return;
    await autoSaveCellScore(
      teacherId: req.teacherId,
      enrollmentId: req.enrollmentId,
      assignmentId: req.assignmentId,
      score: req.score,
      status: req.status,
      note: req.note,
    );
  }

  /// Invalidates grading providers and clears local cache so the next load
  /// fetches fresh `version` rows from Supabase.
  void reloadFromServer(String subjectClassId) {
    _lastFailedRequest = null;
    state = state.copyWith(
      hasHydratedClass: false,
      activeCellKey: null,
      overallSaveStatus: CellSaveStatus.idle,
      lastErrorMessage: null,
      cellStatuses: const <String, CellSaveStatus>{},
    );
    ref
      ..invalidate(scoreCategoriesProvider(subjectClassId))
      ..invalidate(assignmentsProvider(subjectClassId))
      ..invalidate(studentScoresByClassProvider(subjectClassId))
      ..invalidate(gradingScaleConfigProvider(subjectClassId));
  }

  /// Builds live [GradingTableRowData] for all enrollments using the controller's
  /// latest in-memory scores and the 3 Pure Dart Domain Services.
  List<GradingTableRowData> buildLiveRows({
    required List<ClassEnrollment> enrollments,
    required List<ScoreCategory> categories,
    required List<Assignment> assignments,
    required GradingScaleConfig scaleConfig,
    required Map<String, StudentAttendanceSummary> attendanceSummaries,
  }) {
    final calculator = ref.read(scoreCalculatorServiceProvider);
    final evaluator = ref.read(gradeEvaluatorServiceProvider);
    final advisor = ref.read(specialGradeAdvisorServiceProvider);
    final allScores = state.scoresByCellKey.values.toList(growable: false);
    final activeEnrollmentIds = enrollments
        .where((e) => !e.isTransferredOut)
        .map((e) => e.id)
        .toSet();
    final assessedAssignmentIds = calculator.resolveAssessedAssignmentIds(
      assignments: assignments,
      classScores: allScores,
      activeEnrollmentIds: activeEnrollmentIds,
    );

    return enrollments
        .map((enrollment) {
          final calc = calculator.calculateStudentScores(
            enrollmentId: enrollment.id,
            categories: categories,
            assignments: assignments,
            studentScores: allScores,
          );
          final evaluatedGrade = evaluator.evaluateNormalGrade(
            totalScore: calc.totalScore,
            rules: scaleConfig.rules,
          );
          final displayedGrade = evaluator.resolveDisplayedGrade(
            evaluatedGrade: evaluatedGrade,
            specialGradeOverride: enrollment.specialGradeOverride,
          );
          final attendance = attendanceSummaries[enrollment.id];
          final advice = advisor.evaluateAdvice(
            missingMandatoryCount: calc.missingMandatoryCount,
            missingAssignmentsCount: calc.missingAssignmentsCount,
            missingWorkThreshold: scaleConfig.missingWorkThreshold,
            totalAssignmentsCount: assignments.length,
            assessedAssignmentsCount: assessedAssignmentIds.length,
            attendanceSummary: attendance,
          );
          return GradingTableRowData(
            enrollment: enrollment,
            attendanceSummary: attendance,
            gradeResult: GradeResult(
              enrollmentId: enrollment.id,
              totalScore: calc.totalScore,
              totalMaxScore: calc.totalMaxScore,
              percentage: calc.percentage,
              categorySummaries: calc.categorySummaries,
              missingAssignmentsCount: calc.missingAssignmentsCount,
              missingMandatoryCount: calc.missingMandatoryCount,
              overMaxAssignmentIds: calc.overMaxAssignmentIds,
              evaluatedGrade: evaluatedGrade,
              specialGradeOverride: enrollment.specialGradeOverride,
              displayedGrade: displayedGrade,
              specialGradeAdvice: advice,
              wasRResolved: enrollment.wasRResolved,
              wasMsResolved: enrollment.wasMsResolved,
              resolvedGradeAt: enrollment.resolvedGradeAt,
            ),
          );
        })
        .toList(growable: false);
  }

  bool _hasChanged(
    StudentScore? existing,
    double? nextScore,
    SubmissionStatus nextStatus,
    String nextNote,
  ) {
    if (existing == null) {
      return nextScore != null ||
          nextStatus != SubmissionStatus.missing ||
          nextNote.isNotEmpty;
    }
    final oldCents = existing.score == null
        ? null
        : (existing.score! * 100).round();
    final newCents = nextScore == null ? null : (nextScore * 100).round();
    return oldCents != newCents ||
        existing.submissionStatus != nextStatus ||
        existing.note.trim() != nextNote;
  }
}

final gradingTableControllerProvider =
    NotifierProvider<GradingTableController, GradingTableState>(
      GradingTableController.new,
    );
