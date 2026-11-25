import '../../../../core/constants/attendance_status.dart';

/// Individual student attendance record inside one [AttendanceSession]
/// (`public.attendance_records`).
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.teacherId,
    required this.sessionId,
    required this.enrollmentId,
    required this.status,
    required this.note,
    required this.version,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String sessionId;
  final String enrollmentId;
  final AttendanceStatus status;
  final String note;
  final int version;
  final DateTime updatedAt;

  AttendanceRecord copyWith({
    AttendanceStatus? status,
    String? note,
    int? version,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id,
      teacherId: teacherId,
      sessionId: sessionId,
      enrollmentId: enrollmentId,
      status: status ?? this.status,
      note: note ?? this.note,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
