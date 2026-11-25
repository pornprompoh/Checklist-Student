import '../../domain/entities/audit_log_target_type.dart';
import '../../domain/entities/score_audit_log_entry.dart';

/// Data Transfer Object parsing nested PostgREST joins on
/// `public.score_audit_logs` into [ScoreAuditLogEntry].
///
/// Safely handles `student_scores == null` for `target_type = 'grade_status'`.
class ScoreAuditLogEntryDto {
  const ScoreAuditLogEntryDto({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.targetType,
    required this.studentScoreId,
    required this.enrollmentId,
    required this.oldValue,
    required this.newValue,
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
    required this.assignmentTitle,
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

  factory ScoreAuditLogEntryDto.fromJson(Map<String, dynamic> json) {
    final yearMap = _asMap(json['academic_years']);
    final enrollmentMap = _asMap(json['class_enrollments']);
    final classMap = _asMap(enrollmentMap?['subject_classes']);
    final subjectMap = _asMap(classMap?['subjects']);
    final scoreMap = _asMap(json['student_scores']);
    final assignmentMap = _asMap(scoreMap?['assignments']);

    final prefix = (enrollmentMap?['prefix'] as String?)?.trim() ?? '';
    final firstName = (enrollmentMap?['first_name'] as String?)?.trim() ?? '';
    final lastName = (enrollmentMap?['last_name'] as String?)?.trim() ?? '';
    final nameCore = lastName.isEmpty ? firstName : '$firstName $lastName';
    final fullName = prefix.isEmpty ? nameCore : '$prefix$nameCore';

    return ScoreAuditLogEntryDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      targetType: AuditLogTargetType.fromDbValue(
        json['target_type'] as String,
      ),
      studentScoreId: json['student_score_id'] as String?,
      enrollmentId: json['enrollment_id'] as String,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      isInitialEntry: (json['is_initial_entry'] as bool?) ?? false,
      changedAt: DateTime.parse(json['changed_at'] as String),
      yearBe: (yearMap?['year_be'] as num?)?.toInt() ?? 0,
      subjectClassId: (enrollmentMap?['subject_class_id'] as String?) ?? '',
      subjectCode: (subjectMap?['subject_code'] as String?) ?? '-',
      subjectName: (subjectMap?['subject_name'] as String?) ?? 'รายวิชา',
      roomName: (classMap?['room_name'] as String?) ?? '-',
      studentNumber: (enrollmentMap?['student_number'] as num?)?.toInt() ?? 0,
      studentCode: (enrollmentMap?['student_code'] as String?) ?? '-',
      studentFullName: fullName.isEmpty ? 'นักเรียน' : fullName,
      assignmentTitle: assignmentMap?['title'] as String?,
    );
  }

  ScoreAuditLogEntry toEntity() {
    return ScoreAuditLogEntry(
      id: id,
      teacherId: teacherId,
      academicYearId: academicYearId,
      targetType: targetType,
      studentScoreId: studentScoreId,
      enrollmentId: enrollmentId,
      oldValue: oldValue,
      newValue: newValue,
      isInitialEntry: isInitialEntry,
      changedAt: changedAt,
      yearBe: yearBe,
      subjectClassId: subjectClassId,
      subjectCode: subjectCode,
      subjectName: subjectName,
      roomName: roomName,
      studentNumber: studentNumber,
      studentCode: studentCode,
      studentFullName: studentFullName,
      assignmentTitle: assignmentTitle,
    );
  }

  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
