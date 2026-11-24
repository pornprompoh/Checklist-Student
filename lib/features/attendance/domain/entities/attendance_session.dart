/// Single daily attendance session for one subject-class (`public.attendance_sessions`).
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class AttendanceSession {
  const AttendanceSession({
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

  final String id;
  final String teacherId;
  final String subjectClassId;
  final DateTime sessionDate;
  final bool isLocked;
  final String note;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceSession copyWith({
    bool? isLocked,
    String? note,
    int? version,
    DateTime? updatedAt,
  }) {
    return AttendanceSession(
      id: id,
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
      isLocked: isLocked ?? this.isLocked,
      note: note ?? this.note,
      version: version ?? this.version,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
