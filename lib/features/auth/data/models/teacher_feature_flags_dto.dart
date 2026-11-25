import '../../domain/entities/teacher_feature_flags.dart';

/// Data Transfer Object mapping PostgreSQL `public.teacher_feature_flags` rows
/// to [TeacherFeatureFlags] domain entities.
class TeacherFeatureFlagsDto {
  const TeacherFeatureFlagsDto({
    required this.teacherId,
    required this.canUseAi,
    required this.updatedAt,
  });

  factory TeacherFeatureFlagsDto.fromJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['updated_at'];
    return TeacherFeatureFlagsDto(
      teacherId: json['teacher_id'] as String,
      canUseAi: (json['can_use_ai'] as bool?) ?? false,
      updatedAt: updatedAtRaw is String
          ? (DateTime.tryParse(updatedAtRaw) ??
                DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String teacherId;
  final bool canUseAi;
  final DateTime updatedAt;

  TeacherFeatureFlags toEntity() {
    return TeacherFeatureFlags(
      teacherId: teacherId,
      canUseAi: canUseAi,
      updatedAt: updatedAt,
    );
  }
}
