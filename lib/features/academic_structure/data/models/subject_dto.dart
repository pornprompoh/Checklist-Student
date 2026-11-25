import '../../domain/entities/subject.dart';

/// Data Transfer Object mapping `public.subjects` rows to [Subject].
class SubjectDto {
  const SubjectDto({
    required this.id,
    required this.teacherId,
    required this.termId,
    required this.subjectCode,
    required this.subjectName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubjectDto.fromJson(Map<String, dynamic> json) {
    return SubjectDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      termId: json['term_id'] as String,
      subjectCode: (json['subject_code'] as String?) ?? '',
      subjectName: (json['subject_name'] as String?) ?? '',
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  final String id;
  final String teacherId;
  final String termId;
  final String subjectCode;
  final String subjectName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject toEntity() {
    return Subject(
      id: id,
      teacherId: teacherId,
      termId: termId,
      subjectCode: subjectCode,
      subjectName: subjectName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseTimestamp(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
