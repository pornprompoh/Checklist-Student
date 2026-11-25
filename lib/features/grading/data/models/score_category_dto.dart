import '../../domain/entities/score_category.dart';

/// Data Transfer Object mapping `public.score_categories` rows to
/// [ScoreCategory].
class ScoreCategoryDto {
  const ScoreCategoryDto({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
    required this.name,
    required this.targetMaxScore,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String subjectClassId;
  final String name;
  final double? targetMaxScore;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ScoreCategoryDto.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['target_max_score'];
    return ScoreCategoryDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectClassId: json['subject_class_id'] as String,
      name: (json['name'] as String?) ?? '',
      targetMaxScore: rawTarget == null ? null : (rawTarget as num).toDouble(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  ScoreCategory toEntity() {
    return ScoreCategory(
      id: id,
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
