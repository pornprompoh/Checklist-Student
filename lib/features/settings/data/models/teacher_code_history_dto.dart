import '../../domain/entities/teacher_code_history_entry.dart';

/// Data Transfer Object mapping `public.teacher_code_history` rows to
/// [TeacherCodeHistoryEntry].
class TeacherCodeHistoryDto {
  const TeacherCodeHistoryDto({
    required this.oldCode,
    required this.teacherId,
    required this.changedAt,
  });

  factory TeacherCodeHistoryDto.fromJson(Map<String, dynamic> json) {
    final changedAtRaw = json['changed_at'];
    return TeacherCodeHistoryDto(
      oldCode: json['old_code'] as String,
      teacherId: json['teacher_id'] as String,
      changedAt: changedAtRaw is String
          ? (DateTime.tryParse(changedAtRaw) ??
                DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String oldCode;
  final String teacherId;
  final DateTime changedAt;

  TeacherCodeHistoryEntry toEntity() {
    return TeacherCodeHistoryEntry(
      oldCode: oldCode,
      teacherId: teacherId,
      changedAt: changedAt,
    );
  }
}
