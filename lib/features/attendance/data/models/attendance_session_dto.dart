import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/attendance_session.dart';

/// Data transfer object mapping `public.attendance_sessions` JSON rows to
/// [AttendanceSession].
class AttendanceSessionDto {
  const AttendanceSessionDto({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
    required this.sessionDate,
    required this.isLocked,
    required this.note,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceSessionDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['session_date'] as String?;
    final parsedDate =
        ThaiDateFormatter.parseIsoDate(rawDate) ??
        DateTime.parse(rawDate ?? DateTime.now().toIso8601String());

    return AttendanceSessionDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectClassId: json['subject_class_id'] as String,
      sessionDate: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      isLocked: json['is_locked'] as bool? ?? false,
      note: json['note'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String teacherId;
  final String subjectClassId;
  final DateTime sessionDate;
  final bool isLocked;
  final String note;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceSession toEntity() {
    return AttendanceSession(
      id: id,
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
      isLocked: isLocked,
      note: note,
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
