import '../entities/grading_scale_config.dart';

/// Pure Dart grade evaluation service with strict exact-score cutoffs.
///
/// NEVER auto-rounds [totalScore] before comparing against [GradingRuleTier].
class GradeEvaluatorService {
  const GradeEvaluatorService();

  /// Evaluates the normal grade from exact [totalScore] against [rules].
  ///
  /// Rules are sorted internally by `minScore` descending so unsorted custom
  /// rules still evaluate accurately. Returns `'-'` if [rules] is empty or
  /// [totalScore] is below every defined tier.
  String evaluateNormalGrade({
    required double totalScore,
    required List<GradingRuleTier> rules,
  }) {
    if (rules.isEmpty) {
      return '-';
    }

    final sorted = List<GradingRuleTier>.of(rules)
      ..sort((a, b) => _toCents(b.minScore).compareTo(_toCents(a.minScore)));

    final scoreCents = _toCents(totalScore);
    for (final tier in sorted) {
      if (scoreCents >= _toCents(tier.minScore)) {
        return tier.grade;
      }
    }
    return '-';
  }

  /// Resolves the final displayed grade by prioritizing an explicit teacher
  /// override (`'ร'` or `'มส'`) over [evaluatedGrade].
  String resolveDisplayedGrade({
    required String evaluatedGrade,
    String? specialGradeOverride,
  }) {
    final normalized = specialGradeOverride?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return evaluatedGrade;
  }

  /// Validates [rules] before saving. Returns a Thai error message if invalid,
  /// or `null` when all tiers are valid.
  String? validateGradingRules(List<GradingRuleTier> rules) {
    if (rules.isEmpty) {
      return 'กรุณากำหนดเกณฑ์ตัดเกรดอย่างน้อย 1 ระดับ';
    }

    final seenMinScoreCents = <int>{};
    final seenGrades = <String>{};

    for (final tier in rules) {
      final gradeLabel = tier.grade.trim();
      if (gradeLabel.isEmpty) {
        return 'กรุณาระบุชื่อเกรดให้ครบทุกระดับ';
      }
      if (!tier.minScore.isFinite || tier.minScore < 0) {
        return 'คะแนนขั้นต่ำของเกรด "$gradeLabel" ต้องเป็นตัวเลขที่ไม่ติดลบ';
      }

      final minCents = _toCents(tier.minScore);
      if (!seenMinScoreCents.add(minCents)) {
        return 'พบคะแนนขั้นต่ำซ้ำกันในเกณฑ์ตัดเกรด กรุณาตรวจสอบอีกครั้ง';
      }
      if (!seenGrades.add(gradeLabel)) {
        return 'พบชื่อเกรด "$gradeLabel" ซ้ำกันในเกณฑ์ตัดเกรด';
      }
    }

    return null;
  }

  static int _toCents(double value) => (value * 100).round();
}
