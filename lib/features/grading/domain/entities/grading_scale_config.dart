/// Supported grading scale types matching
/// `public.subject_classes.grading_scale_type` CHECK constraint.
enum GradingScaleType {
  scale0To4('0-4', 'ระบบเกรด 0 - 4'),
  scaleAToF('A-F', 'ระบบเกรด A - F'),
  custom('custom', 'กำหนดเกณฑ์เอง');

  const GradingScaleType(this.dbValue, this.thaiLabel);

  /// Exact value stored in PostgreSQL `subject_classes.grading_scale_type`.
  final String dbValue;

  /// Human-readable Thai label.
  final String thaiLabel;

  static GradingScaleType fromDbValue(String value) {
    final matched = tryFromDbValue(value);
    if (matched == null) {
      throw ArgumentError.value(
        value,
        'value',
        'Unknown subject_classes.grading_scale_type value',
      );
    }
    return matched;
  }

  static GradingScaleType? tryFromDbValue(String? value) {
    if (value == null) {
      return null;
    }
    for (final type in GradingScaleType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    return null;
  }
}

/// Single threshold tier inside `subject_classes.grading_rules`.
class GradingRuleTier {
  const GradingRuleTier({required this.grade, required this.minScore});

  final String grade;
  final double minScore;

  GradingRuleTier copyWith({String? grade, double? minScore}) {
    return GradingRuleTier(
      grade: grade ?? this.grade,
      minScore: minScore ?? this.minScore,
    );
  }
}

/// Per-subject-class grading scale and missing-work threshold configuration.
///
/// Maps to `grading_scale_type`, `grading_rules`, and `missing_work_threshold`
/// on `public.subject_classes`. Pure Dart entity.
class GradingScaleConfig {
  const GradingScaleConfig({
    required this.subjectClassId,
    required this.scaleType,
    required this.rules,
    required this.missingWorkThreshold,
  });

  final String subjectClassId;
  final GradingScaleType scaleType;
  final List<GradingRuleTier> rules;
  final int missingWorkThreshold;

  /// Standard Thai 0-4 grading scale preset (exact cutoffs, no auto-rounding).
  static const List<GradingRuleTier> defaultZeroToFourRules = <GradingRuleTier>[
    GradingRuleTier(grade: '4', minScore: 80),
    GradingRuleTier(grade: '3.5', minScore: 75),
    GradingRuleTier(grade: '3', minScore: 70),
    GradingRuleTier(grade: '2.5', minScore: 65),
    GradingRuleTier(grade: '2', minScore: 60),
    GradingRuleTier(grade: '1.5', minScore: 55),
    GradingRuleTier(grade: '1', minScore: 50),
    GradingRuleTier(grade: '0', minScore: 0),
  ];

  /// Standard A-F grading scale preset.
  static const List<GradingRuleTier> defaultAToFRules = <GradingRuleTier>[
    GradingRuleTier(grade: 'A', minScore: 80),
    GradingRuleTier(grade: 'B+', minScore: 75),
    GradingRuleTier(grade: 'B', minScore: 70),
    GradingRuleTier(grade: 'C+', minScore: 65),
    GradingRuleTier(grade: 'C', minScore: 60),
    GradingRuleTier(grade: 'D+', minScore: 55),
    GradingRuleTier(grade: 'D', minScore: 50),
    GradingRuleTier(grade: 'F', minScore: 0),
  ];

  /// Returns preset tiers for [type]. Custom defaults to 0-4 as a template.
  static List<GradingRuleTier> presetRulesFor(GradingScaleType type) {
    switch (type) {
      case GradingScaleType.scale0To4:
      case GradingScaleType.custom:
        return defaultZeroToFourRules;
      case GradingScaleType.scaleAToF:
        return defaultAToFRules;
    }
  }

  GradingScaleConfig copyWith({
    String? subjectClassId,
    GradingScaleType? scaleType,
    List<GradingRuleTier>? rules,
    int? missingWorkThreshold,
  }) {
    return GradingScaleConfig(
      subjectClassId: subjectClassId ?? this.subjectClassId,
      scaleType: scaleType ?? this.scaleType,
      rules: rules ?? this.rules,
      missingWorkThreshold: missingWorkThreshold ?? this.missingWorkThreshold,
    );
  }
}
