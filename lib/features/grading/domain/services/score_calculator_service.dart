import '../entities/assignment.dart';
import '../entities/grade_result.dart';
import '../entities/score_category.dart';
import '../entities/student_score.dart';
import '../../../../core/constants/submission_status.dart';

/// Output of [ScoreCalculatorService.calculateStudentScores].
class StudentScoreCalculation {
  const StudentScoreCalculation({
    required this.enrollmentId,
    required this.totalScore,
    required this.totalMaxScore,
    required this.percentage,
    required this.categorySummaries,
    required this.missingAssignmentsCount,
    required this.missingMandatoryCount,
    required this.overMaxAssignmentIds,
  });

  final String enrollmentId;
  final double totalScore;
  final double totalMaxScore;
  final double? percentage;
  final List<CategoryScoreSummary> categorySummaries;
  final int missingAssignmentsCount;
  final int missingMandatoryCount;
  final List<String> overMaxAssignmentIds;
}

/// Pure Dart score calculator using exact integer-cent (0.01) arithmetic.
///
/// Guarantees zero floating-point drift (e.g. `7.1 + 7.2 + 65.45 == 79.75`)
/// and NEVER auto-rounds total scores (`79.99` stays `79.99`).
class ScoreCalculatorService {
  const ScoreCalculatorService();

  static const String uncategorizedLabel = 'ไม่ระบุหมวด';

  /// Calculates exact total score, per-category breakdown, missing counts, and
  /// over-max warnings for one student [enrollmentId].
  StudentScoreCalculation calculateStudentScores({
    required String enrollmentId,
    required List<ScoreCategory> categories,
    required List<Assignment> assignments,
    required List<StudentScore> studentScores,
  }) {
    final scoreByAssignmentId = <String, StudentScore>{};
    for (final item in studentScores) {
      if (item.enrollmentId == enrollmentId) {
        scoreByAssignmentId[item.assignmentId] = item;
      }
    }

    final categoryById = <String, ScoreCategory>{
      for (final category in categories) category.id: category,
    };

    final earnedByCategoryCents = <String?, int>{
      for (final category in categories) category.id: 0,
    };
    final maxByCategoryCents = <String?, int>{
      for (final category in categories) category.id: 0,
    };
    final countByCategory = <String?, int>{
      for (final category in categories) category.id: 0,
    };

    var totalEarnedCents = 0;
    var totalMaxCents = 0;
    var missingAssignmentsCount = 0;
    var missingMandatoryCount = 0;
    final overMaxAssignmentIds = <String>[];

    for (final assignment in assignments) {
      final bucketKey =
          assignment.categoryId != null &&
              categoryById.containsKey(assignment.categoryId)
          ? assignment.categoryId
          : null;

      final assignmentMaxCents = _toCents(assignment.maxScore);
      totalMaxCents += assignmentMaxCents;
      maxByCategoryCents[bucketKey] =
          (maxByCategoryCents[bucketKey] ?? 0) + assignmentMaxCents;
      countByCategory[bucketKey] = (countByCategory[bucketKey] ?? 0) + 1;

      final record = scoreByAssignmentId[assignment.id];
      final rawScore = record?.score;
      if (rawScore != null) {
        final scoreCents = _toCents(rawScore);
        totalEarnedCents += scoreCents;
        earnedByCategoryCents[bucketKey] =
            (earnedByCategoryCents[bucketKey] ?? 0) + scoreCents;

        if (scoreCents > assignmentMaxCents) {
          overMaxAssignmentIds.add(assignment.id);
        }
      }

      final isMissing =
          record == null || record.submissionStatus == SubmissionStatus.missing;
      if (isMissing) {
        missingAssignmentsCount++;
        if (assignment.isMandatory) {
          missingMandatoryCount++;
        }
      }
    }

    final summaries = <CategoryScoreSummary>[];
    for (final category in categories) {
      summaries.add(
        CategoryScoreSummary(
          categoryId: category.id,
          categoryName: category.name,
          earnedScore: _fromCents(earnedByCategoryCents[category.id] ?? 0),
          maxScore: _fromCents(maxByCategoryCents[category.id] ?? 0),
          targetMaxScore: category.targetMaxScore,
          assignmentCount: countByCategory[category.id] ?? 0,
        ),
      );
    }

    final uncategorizedCount = countByCategory[null] ?? 0;
    if (uncategorizedCount > 0) {
      summaries.add(
        CategoryScoreSummary(
          categoryId: null,
          categoryName: uncategorizedLabel,
          earnedScore: _fromCents(earnedByCategoryCents[null] ?? 0),
          maxScore: _fromCents(maxByCategoryCents[null] ?? 0),
          targetMaxScore: null,
          assignmentCount: uncategorizedCount,
        ),
      );
    }

    final totalScore = _fromCents(totalEarnedCents);
    final totalMaxScore = _fromCents(totalMaxCents);
    final percentage = totalMaxCents == 0
        ? null
        : (totalEarnedCents * 100.0) / totalMaxCents;

    return StudentScoreCalculation(
      enrollmentId: enrollmentId,
      totalScore: totalScore,
      totalMaxScore: totalMaxScore,
      percentage: percentage,
      categorySummaries: List<CategoryScoreSummary>.unmodifiable(summaries),
      missingAssignmentsCount: missingAssignmentsCount,
      missingMandatoryCount: missingMandatoryCount,
      overMaxAssignmentIds: List<String>.unmodifiable(overMaxAssignmentIds),
    );
  }

  /// Returns the subset of [assignments] IDs that have been assessed (at least
  /// one [StudentScore] row recorded for any student in [activeEnrollmentIds]).
  ///
  /// Ignores rows belonging to transferred-out students or unknown assignments.
  Set<String> resolveAssessedAssignmentIds({
    required List<Assignment> assignments,
    required List<StudentScore> classScores,
    required Set<String> activeEnrollmentIds,
  }) {
    if (assignments.isEmpty ||
        classScores.isEmpty ||
        activeEnrollmentIds.isEmpty) {
      return const <String>{};
    }
    final validAssignmentIds = <String>{
      for (final assignment in assignments) assignment.id,
    };
    final assessed = <String>{};
    for (final score in classScores) {
      if (validAssignmentIds.contains(score.assignmentId) &&
          activeEnrollmentIds.contains(score.enrollmentId)) {
        assessed.add(score.assignmentId);
      }
    }
    return Set<String>.unmodifiable(assessed);
  }

  /// Returns `true` only when the class has at least one configured assignment
  /// and every configured assignment has been assessed.
  bool areAllAssignmentsAssessed({
    required int totalAssignmentsCount,
    required int assessedAssignmentsCount,
  }) {
    return totalAssignmentsCount > 0 &&
        assessedAssignmentsCount >= totalAssignmentsCount;
  }

  /// Formats a score preserving exact decimals up to 2 places without rounding
  /// to integers (e.g. `79.99` -> `'79.99'`, `80.0` -> `'80'`, `7.50` -> `'7.5'`).
  String formatExactScore(double value) {
    final cents = _toCents(value);
    final sign = cents < 0 ? '-' : '';
    final absCents = cents.abs();
    final whole = absCents ~/ 100;
    final frac = absCents % 100;

    if (frac == 0) {
      return '$sign$whole';
    }
    if (frac % 10 == 0) {
      return '$sign$whole.${frac ~/ 10}';
    }
    return '$sign$whole.${frac.toString().padLeft(2, '0')}';
  }

  static int _toCents(double value) => (value * 100).round();

  static double _fromCents(int cents) => cents / 100.0;
}
