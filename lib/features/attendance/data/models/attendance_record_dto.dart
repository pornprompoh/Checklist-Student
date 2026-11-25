import '../../../../core/constants/attendance_status.dart';
import '../../domain/entities/attendance_record.dart';

/// Data transfer object mapping `public.attendance_records` JSON rows to
/// [AttendanceRecord].
class AttendanceRecordDto {
  const AttendanceRecordDto({
    required this.id,
    required this.teacherId,
    required this.sessionId,
    required this.enrollmentId,
    required this.status,
    required this.note,
    required this.version,
    required this.updatedAt,
  });

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      sessionId: json['session_id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      status: AttendanceStatus.fromDbValue(json['status'] as String),
      note: json['note'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String teacherId;
  final String sessionId;
  final String enrollmentId;
  final AttendanceStatus status;
  final String note;
  final int version;
  final DateTime updatedAt;

  AttendanceRecord toEntity() {
    return AttendanceRecord(
      id: id,
      teacherId: teacherId,
      sessionId: sessionId,
      enrollmentId: enrollmentId,
      status: status,
      note: note,
      version: version,
      updatedAt: updatedAt,
    );
  }
}
