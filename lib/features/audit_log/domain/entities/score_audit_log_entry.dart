import 'audit_log_target_type.dart';

/// Single audit log record joined with student, class, subject, and assignment
/// metadata for readable display and CSV/JSON export.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class ScoreAuditLogEntry {
  const ScoreAuditLogEntry({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.targetType,
    this.studentScoreId,
    required this.enrollmentId,
    this.oldValue,
    this.newValue,
    required this.isInitialEntry,
    required this.changedAt,
    required this.yearBe,
    required this.subjectClassId,
    required this.subjectCode,
    required this.subjectName,
    required this.roomName,
    required this.studentNumber,
    required this.studentCode,
    required this.studentFullName,
    this.assignmentTitle,
  });

  final String id;
  final String teacherId;
  final String academicYearId;
  final AuditLogTargetType targetType;
  final String? studentScoreId;
  final String enrollmentId;
  final String? oldValue;
  final String? newValue;
  final bool isInitialEntry;
  final DateTime changedAt;
  final int yearBe;
  final String subjectClassId;
  final String subjectCode;
  final String subjectName;
  final String roomName;
  final int studentNumber;
  final String studentCode;
  final String studentFullName;
  final String? assignmentTitle;

  String get displayOldValue {
    final raw = oldValue?.trim();
    if (raw == null || raw.isEmpty) {
      return targetType == AuditLogTargetType.score ? 'ยังไม่กรอก' : 'เกรดปกติ';
    }
    return raw;
  }

  String get displayNewValue {
    final raw = newValue?.trim();
    if (raw == null || raw.isEmpty) {
      return targetType == AuditLogTargetType.score ? 'ล้างคะแนน' : 'เกรดปกติ';
    }
    return raw;
  }

  String get displayTargetLabel {
    if (targetType == AuditLogTargetType.gradeStatus) {
      return 'สถานะเกรดพิเศษ';
    }
    final title = assignmentTitle?.trim();
    return (title == null || title.isEmpty) ? 'ชิ้นงาน' : title;
  }
}
