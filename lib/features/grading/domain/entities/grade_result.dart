/// Aggregated score totals for one score category (or `'ไม่ระบุหมวด'`).
class CategoryScoreSummary {
  const CategoryScoreSummary({
    required this.categoryId,
    required this.categoryName,
    required this.earnedScore,
    required this.maxScore,
    this.targetMaxScore,
    required this.assignmentCount,
  });

  /// `null` when representing assignments without an assigned category.
  final String? categoryId;
  final String categoryName;
  final double earnedScore;
  final double maxScore;
  final double? targetMaxScore;
  final int assignmentCount;
}

/// Advisory suggestion for special grades (`ร` / `มส`).
///
/// The system only recommends; teachers explicitly confirm any override.
class SpecialGradeAdvice {
  const SpecialGradeAdvice({
    required this.recommendR,
    required this.recommendMs,
    required this.primaryRecommendedCode,
    required this.reasons,
  });

  final bool recommendR;
  final bool recommendMs;

  /// `'มส'` when attendance threshold exceeded, else `'ร'` when work missing,
  /// otherwise `null`.
  final String? primaryRecommendedCode;

  /// Thai explanation items for why a special grade is suggested.
  final List<String> reasons;

  bool get hasRecommendation => recommendR || recommendMs;
}

/// Complete grading evaluation output for one student enrollment in a class.
class GradeResult {
  const GradeResult({
    required this.enrollmentId,
    required this.totalScore,
    required this.totalMaxScore,
    required this.percentage,
    required this.categorySummaries,
    required this.missingAssignmentsCount,
    required this.missingMandatoryCount,
    required this.overMaxAssignmentIds,
    required this.evaluatedGrade,
    required this.specialGradeOverride,
    required this.displayedGrade,
    required this.specialGradeAdvice,
    this.wasRResolved = false,
    this.wasMsResolved = false,
    this.resolvedGradeAt,
  });

  final String enrollmentId;
  final double totalScore;
  final double totalMaxScore;
  final double? percentage;
  final List<CategoryScoreSummary> categorySummaries;
  final int missingAssignmentsCount;
  final int missingMandatoryCount;
  final List<String> overMaxAssignmentIds;
  final String evaluatedGrade;
  final String? specialGradeOverride;
  final String displayedGrade;
  final SpecialGradeAdvice specialGradeAdvice;
  final bool wasRResolved;
  final bool wasMsResolved;
  final DateTime? resolvedGradeAt;
}

/// Summary returned by RPC `public.copy_subject_class_plan`.
class CopyPlanResult {
  const CopyPlanResult({
    required this.copiedCategoriesCount,
    required this.copiedAssignmentsCount,
    required this.gradingScaleType,
  });

  final int copiedCategoriesCount;
  final int copiedAssignmentsCount;
  final String gradingScaleType;
}
