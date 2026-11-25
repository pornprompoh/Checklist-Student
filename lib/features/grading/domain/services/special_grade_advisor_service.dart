import '../../../attendance/domain/entities/student_attendance_summary.dart';
import '../entities/grade_result.dart';

/// Pure Dart advisory service suggesting `ร` or `มส` based on missing work and
/// attendance risk.
///
/// Follows the non-intrusive advisor principle: suggests codes and Thai
/// reasons without automatically overriding the student's grade.
class SpecialGradeAdvisorService {
  const SpecialGradeAdvisorService();

  /// Evaluates whether `มส` and/or `ร` should be suggested for a student.
  ///
  /// - `มส` is recommended immediately whenever [attendanceSummary] exceeds the
  ///   class `มส` threshold, independent of score entry progress.
  /// - `ร` is recommended ONLY when every assignment in the class plan has been
  ///   assessed (`totalAssignmentsCount > 0 && assessedAssignmentsCount >=
  ///   totalAssignmentsCount`), preventing false positives before scores are
  ///   entered.
  /// - When both conditions apply, `primaryRecommendedCode` prioritizes `'มส'`
  ///   while preserving all reasons in [SpecialGradeAdvice.reasons].
  SpecialGradeAdvice evaluateAdvice({
    required int missingMandatoryCount,
    required int missingAssignmentsCount,
    required int missingWorkThreshold,
    required int totalAssignmentsCount,
    required int assessedAssignmentsCount,
    StudentAttendanceSummary? attendanceSummary,
  }) {
    final reasons = <String>[];

    final recommendMs =
        attendanceSummary != null && attendanceSummary.exceedsMsThreshold;
    if (recommendMs) {
      final pctText = _formatPercentage(attendanceSummary.absentPercentage);
      reasons.add('ขาดเรียนเกินเกณฑ์ มส ($pctText%)');
    }

    final isAllAssessed =
        totalAssignmentsCount > 0 &&
        assessedAssignmentsCount >= totalAssignmentsCount;

    var recommendR = false;
    if (isAllAssessed) {
      if (missingMandatoryCount > 0) {
        recommendR = true;
        reasons.add('ค้างงานบังคับส่ง $missingMandatoryCount ชิ้น');
      }
      if (missingWorkThreshold > 0 &&
          missingAssignmentsCount >= missingWorkThreshold) {
        recommendR = true;
        reasons.add(
          'ค้างส่งงาน $missingAssignmentsCount ชิ้น '
          '(เกณฑ์ $missingWorkThreshold ชิ้น)',
        );
      }
    }

    final primaryRecommendedCode = recommendMs
        ? 'มส'
        : (recommendR ? 'ร' : null);

    return SpecialGradeAdvice(
      recommendR: recommendR,
      recommendMs: recommendMs,
      primaryRecommendedCode: primaryRecommendedCode,
      reasons: List<String>.unmodifiable(reasons),
      assessedAssignmentsCount: assessedAssignmentsCount,
      totalAssignmentsCount: totalAssignmentsCount,
    );
  }

  static String _formatPercentage(double value) {
    final cents = (value * 100).round();
    final whole = cents ~/ 100;
    final frac = cents % 100;
    if (frac == 0) {
      return '$whole';
    }
    if (frac % 10 == 0) {
      return '$whole.${frac ~/ 10}';
    }
    return '$whole.${frac.toString().padLeft(2, '0')}';
  }
}
