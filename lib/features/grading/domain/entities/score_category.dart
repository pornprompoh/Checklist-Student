/// Score category grouping assignments inside a subject class.
///
/// Maps to `public.score_categories`. Pure Dart entity with zero Flutter or
/// Supabase dependencies.
class ScoreCategory {
  const ScoreCategory({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
    required this.name,
    this.targetMaxScore,
    this.sortOrder = 0,
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

  static const Object _sentinel = Object();

  ScoreCategory copyWith({
    String? id,
    String? teacherId,
    String? subjectClassId,
    String? name,
    Object? targetMaxScore = _sentinel,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScoreCategory(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      subjectClassId: subjectClassId ?? this.subjectClassId,
      name: name ?? this.name,
      targetMaxScore: identical(targetMaxScore, _sentinel)
          ? this.targetMaxScore
          : targetMaxScore as double?,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
