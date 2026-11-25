import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/assignment.dart';

/// Data Transfer Object mapping `public.assignments` rows to [Assignment].
class AssignmentDto {
  const AssignmentDto({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.maxScore,
    required this.isMandatory,
    required this.dueDate,
    required this.sortOrder,
    required this.version,
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

  factory AssignmentDto.fromJson(Map<String, dynamic> json) {
    final rawDueDate = json['due_date'] as String?;
    return AssignmentDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectClassId: json['subject_class_id'] as String,
      categoryId: json['category_id'] as String?,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      maxScore: (json['max_score'] as num).toDouble(),
      isMandatory: (json['is_mandatory'] as bool?) ?? false,
      dueDate: ThaiDateFormatter.parseIsoDate(rawDueDate),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Assignment toEntity() {
    return Assignment(
      id: id,
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      categoryId: categoryId,
      title: title,
      description: description,
      maxScore: maxScore,
      isMandatory: isMandatory,
      dueDate: dueDate,
      sortOrder: sortOrder,
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
