import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/entities/attendance_session.dart';
import '../../../attendance/domain/services/attendance_statistics_service.dart';
import '../../../grading/domain/entities/assignment.dart';
import '../../../grading/domain/entities/grade_result.dart';
import '../../../grading/domain/entities/grading_scale_config.dart';
import '../../../grading/domain/entities/score_category.dart';
import '../../../grading/domain/entities/student_score.dart';
import '../../../grading/domain/services/grade_evaluator_service.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../../../grading/domain/services/special_grade_advisor_service.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../entities/export_document_header.dart';
import '../entities/export_options.dart';
import '../entities/export_report_bundle.dart';
import 'export_layout_advisor_service.dart';

/// Pure Dart service assembling [ExportReportBundle] by reusing the exact
/// Phase 3–4 business logic services (`AttendanceStatisticsService`,
/// `ScoreCalculatorService`, `GradeEvaluatorService`,
/// `SpecialGradeAdvisorService`) with zero score rounding.
class ExportReportBuilderService {
  const ExportReportBuilderService({
    this.attendanceStatsService = const AttendanceStatisticsService(),
    this.scoreCalculatorService = const ScoreCalculatorService(),
    this.gradeEvaluatorService = const GradeEvaluatorService(),
    this.specialGradeAdvisorService = const SpecialGradeAdvisorService(),
    this.layoutAdvisorService = const ExportLayoutAdvisorService(),
  });

  final AttendanceStatisticsService attendanceStatsService;
  final ScoreCalculatorService scoreCalculatorService;
  final GradeEvaluatorService gradeEvaluatorService;
  final SpecialGradeAdvisorService specialGradeAdvisorService;
  final ExportLayoutAdvisorService layoutAdvisorService;

  ExportReportBundle buildBundle({
    required ExportRawClassData raw,
    required ExportDocumentHeader header,
    required ExportOptions options,
  }) {
    final students = _filterAndSortStudents(
      raw.enrollments,
      includeTransferredOut: options.includeTransferredOut,
    );

    final sessions = List<AttendanceSession>.of(raw.attendanceSessions)
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    final categories = List<ScoreCategory>.of(raw.scoreCategories)
      ..sort((a, b) {
        final orderCmp = a.sortOrder.compareTo(b.sortOrder);
        return orderCmp != 0 ? orderCmp : a.createdAt.compareTo(b.createdAt);
      });

    final assignments = List<Assignment>.of(raw.assignments)
      ..sort((a, b) {
        final orderCmp = a.sortOrder.compareTo(b.sortOrder);
        return orderCmp != 0 ? orderCmp : a.createdAt.compareTo(b.createdAt);
      });

    final attendanceSummaries = attendanceStatsService.calculateClassSummaries(
      enrollments: students,
      sessions: sessions,
      records: raw.attendanceRecords,
      ruleConfig: raw.attendanceRuleConfig,
    );

    final attendanceMatrix = <String, Map<String, AttendanceRecord>>{};
    for (final record in raw.attendanceRecords) {
      attendanceMatrix
          .putIfAbsent(record.enrollmentId, () => <String, AttendanceRecord>{})[
            record.sessionId
          ] = record;
    }

    final scoreMatrix = <String, Map<String, StudentScore>>{};
    for (final score in raw.studentScores) {
      scoreMatrix
          .putIfAbsent(score.enrollmentId, () => <String, StudentScore>{})[
            score.assignmentId
          ] = score;
    }

    final gradeResults = <String, GradeResult>{};
    for (final student in students) {
      final calc = scoreCalculatorService.calculateStudentScores(
        enrollmentId: student.id,
        categories: categories,
        assignments: assignments,
        studentScores: raw.studentScores,
      );
      final evaluatedGrade = gradeEvaluatorService.evaluateNormalGrade(
        totalScore: calc.totalScore,
        rules: raw.gradingScaleConfig.rules,
      );
      final displayedGrade = gradeEvaluatorService.resolveDisplayedGrade(
        evaluatedGrade: evaluatedGrade,
        specialGradeOverride: student.specialGradeOverride,
      );
      final attendance = attendanceSummaries[student.id];
      final advice = specialGradeAdvisorService.evaluateAdvice(
        missingMandatoryCount: calc.missingMandatoryCount,
        missingAssignmentsCount: calc.missingAssignmentsCount,
        missingWorkThreshold: raw.gradingScaleConfig.missingWorkThreshold,
        attendanceSummary: attendance,
      );
      gradeResults[student.id] = GradeResult(
        enrollmentId: student.id,
        totalScore: calc.totalScore,
        totalMaxScore: calc.totalMaxScore,
        percentage: calc.percentage,
        categorySummaries: calc.categorySummaries,
        missingAssignmentsCount: calc.missingAssignmentsCount,
        missingMandatoryCount: calc.missingMandatoryCount,
        overMaxAssignmentIds: calc.overMaxAssignmentIds,
        evaluatedGrade: evaluatedGrade,
        specialGradeOverride: student.specialGradeOverride,
        displayedGrade: displayedGrade,
        specialGradeAdvice: advice,
        wasRResolved: student.wasRResolved,
        wasMsResolved: student.wasMsResolved,
        resolvedGradeAt: student.resolvedGradeAt,
      );
    }

    final gradeDistribution = _buildGradeDistribution(
      students: students,
      gradeResults: gradeResults,
      scaleConfig: raw.gradingScaleConfig,
    );

    final orientationDecision = layoutAdvisorService.resolveOrientation(
      orientationMode: options.orientationMode,
      selectedSections: options.selectedSections,
      attendanceSessionCount: sessions.length,
      assignmentCount: assignments.length,
      scoreCategoryCount: categories.length,
    );

    return ExportReportBundle(
      header: header,
      options: options,
      orientationDecision: orientationDecision,
      students: List<ClassEnrollment>.unmodifiable(students),
      attendanceSessions: List<AttendanceSession>.unmodifiable(sessions),
      attendanceMatrix: Map<String, Map<String, AttendanceRecord>>.unmodifiable(
        attendanceMatrix,
      ),
      attendanceSummaries: attendanceSummaries,
      scoreCategories: List<ScoreCategory>.unmodifiable(categories),
      assignments: List<Assignment>.unmodifiable(assignments),
      scoreMatrix: Map<String, Map<String, StudentScore>>.unmodifiable(
        scoreMatrix,
      ),
      gradingScaleConfig: raw.gradingScaleConfig,
      gradeResults: Map<String, GradeResult>.unmodifiable(gradeResults),
      gradeDistribution: Map<String, int>.unmodifiable(gradeDistribution),
    );
  }

  List<ClassEnrollment> _filterAndSortStudents(
    List<ClassEnrollment> enrollments, {
    required bool includeTransferredOut,
  }) {
    final filtered = includeTransferredOut
        ? List<ClassEnrollment>.of(enrollments)
        : enrollments.where((e) => !e.isTransferredOut).toList();
    filtered.sort((a, b) {
      if (a.isTransferredOut != b.isTransferredOut) {
        return a.isTransferredOut ? 1 : -1;
      }
      final numCmp = a.studentNumber.compareTo(b.studentNumber);
      if (numCmp != 0) return numCmp;
      return a.studentCode.compareTo(b.studentCode);
    });
    return filtered;
  }

  Map<String, int> _buildGradeDistribution({
    required List<ClassEnrollment> students,
    required Map<String, GradeResult> gradeResults,
    required GradingScaleConfig scaleConfig,
  }) {
    final sortedRules = List<GradingRuleTier>.of(scaleConfig.rules)
      ..sort(
        (a, b) => (b.minScore * 100).round().compareTo((a.minScore * 100).round()),
      );
    final distribution = <String, int>{
      for (final tier in sortedRules) tier.grade.trim(): 0,
      'ร': 0,
      'มส': 0,
    };

    // Grade distribution counts active students only.
    for (final student in students) {
      if (student.isTransferredOut) continue;
      final displayed = gradeResults[student.id]?.displayedGrade;
      if (displayed == null || displayed.isEmpty) continue;
      distribution[displayed] = (distribution[displayed] ?? 0) + 1;
    }
    return distribution;
  }
}
