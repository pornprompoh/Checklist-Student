import '../../domain/entities/grading_scale_config.dart';

/// Data Transfer Object mapping grading configuration columns on
/// `public.subject_classes` (`grading_scale_type`, `grading_rules`,
/// `missing_work_threshold`) to [GradingScaleConfig].
class GradingScaleConfigDto {
  const GradingScaleConfigDto({
    required this.subjectClassId,
    required this.scaleType,
    required this.rules,
    required this.missingWorkThreshold,
  });

  final String subjectClassId;
  final GradingScaleType scaleType;
  final List<GradingRuleTier> rules;
  final int missingWorkThreshold;

  factory GradingScaleConfigDto.fromJson(Map<String, dynamic> json) {
    final scaleType =
        GradingScaleType.tryFromDbValue(json['grading_scale_type'] as String?) ??
        GradingScaleType.scale0To4;

    final rawRules = json['grading_rules'];
    final parsedRules = <GradingRuleTier>[];
    if (rawRules is List) {
      for (final entry in rawRules) {
        if (entry is Map) {
          final grade = entry['grade']?.toString().trim() ?? '';
          final minRaw = entry['min'];
          if (grade.isNotEmpty && minRaw is num) {
            parsedRules.add(
              GradingRuleTier(grade: grade, minScore: minRaw.toDouble()),
            );
          }
        }
      }
    }

    return GradingScaleConfigDto(
      subjectClassId: json['id'] as String,
      scaleType: scaleType,
      rules: parsedRules.isEmpty
          ? GradingScaleConfig.presetRulesFor(scaleType)
          : List<GradingRuleTier>.unmodifiable(parsedRules),
      missingWorkThreshold:
          (json['missing_work_threshold'] as num?)?.toInt() ?? 0,
    );
  }

  GradingScaleConfig toEntity() {
    return GradingScaleConfig(
      subjectClassId: subjectClassId,
      scaleType: scaleType,
      rules: rules,
      missingWorkThreshold: missingWorkThreshold,
    );
  }

  /// Serializes [config] into the exact columns on `public.subject_classes`.
  static Map<String, dynamic> toUpdateJson(GradingScaleConfig config) {
    final sorted = List<GradingRuleTier>.of(config.rules)
      ..sort(
        (a, b) => (b.minScore * 100).round().compareTo((a.minScore * 100).round()),
      );

    return <String, dynamic>{
      'grading_scale_type': config.scaleType.dbValue,
      'grading_rules': sorted
          .map(
            (tier) => <String, dynamic>{
              'grade': tier.grade.trim(),
              'min': tier.minScore,
            },
          )
          .toList(growable: false),
      'missing_work_threshold': config.missingWorkThreshold,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
