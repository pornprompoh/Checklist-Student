/// Graded assignment or exam item belonging to a subject class.
///
/// Maps to `public.assignments` including Optimistic Locking [version].
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class Assignment {
  const Assignment({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
    this.categoryId,
    required this.title,
    this.description = '',
    required this.maxScore,
    this.isMandatory = false,
    this.dueDate,
    this.sortOrder = 0,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String subjectClassId;
  final String? categoryId;
  final String title;
  final String description;
  final double maxScore;
  final bool isMandatory;
  final DateTime? dueDate;
  final int sortOrder;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const Object _sentinel = Object();

  Assignment copyWith({
    String? id,
    String? teacherId,
    String? subjectClassId,
    Object? categoryId = _sentinel,
    String? title,
    String? description,
    double? maxScore,
    bool? isMandatory,
    Object? dueDate = _sentinel,
    int? sortOrder,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      subjectClassId: subjectClassId ?? this.subjectClassId,
      categoryId: identical(categoryId, _sentinel)
          ? this.categoryId
          : categoryId as String?,
      title: title ?? this.title,
      description: description ?? this.description,
      maxScore: maxScore ?? this.maxScore,
      isMandatory: isMandatory ?? this.isMandatory,
      dueDate: identical(dueDate, _sentinel)
          ? this.dueDate
          : dueDate as DateTime?,
      sortOrder: sortOrder ?? this.sortOrder,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
