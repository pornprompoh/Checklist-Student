import '../../../../core/constants/attendance_status.dart';
import '../../../../core/constants/submission_status.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/entities/attendance_session.dart';
import '../../../grading/domain/entities/student_score.dart';

/// Pure JSON snapshot serializer/deserializer for Optimistic Locking conflict
/// comparison (`serverSnapshotJson`) and local Drift restoration.
class SyncSnapshotCodec {
  const SyncSnapshotCodec();

  Map<String, dynamic> sessionToSnapshot(AttendanceSession s) =>
      <String, dynamic>{
        'id': s.id,
        'teacher_id': s.teacherId,
        'subject_class_id': s.subjectClassId,
        'session_date': ThaiDateFormatter.toIsoDate(s.sessionDate),
        'is_locked': s.isLocked,
        'note': s.note,
        'version': s.version,
        'created_at': s.createdAt.toUtc().toIso8601String(),
        'updated_at': s.updatedAt.toUtc().toIso8601String(),
      };

  AttendanceSession sessionFromSnapshot(Map<String, dynamic> json) =>
      AttendanceSession(
        id: json['id'] as String,
        teacherId: json['teacher_id'] as String,
        subjectClassId: json['subject_class_id'] as String,
        sessionDate:
            ThaiDateFormatter.parseIsoDate(json['session_date'] as String?) ??
            DateTime(2000),
        isLocked: (json['is_locked'] as bool?) ?? false,
        note: (json['note'] as String?) ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        createdAt: _parseTs(json['created_at']),
        updatedAt: _parseTs(json['updated_at']),
      );

  Map<String, dynamic> recordToSnapshot(AttendanceRecord r) =>
      <String, dynamic>{
        'id': r.id,
        'teacher_id': r.teacherId,
        'session_id': r.sessionId,
        'enrollment_id': r.enrollmentId,
        'status': r.status.dbValue,
        'note': r.note,
        'version': r.version,
        'updated_at': r.updatedAt.toUtc().toIso8601String(),
      };

  AttendanceRecord recordFromSnapshot(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        teacherId: json['teacher_id'] as String,
        sessionId: json['session_id'] as String,
        enrollmentId: json['enrollment_id'] as String,
        status: AttendanceStatus.fromDbValue(
          (json['status'] as String?) ?? 'present',
        ),
        note: (json['note'] as String?) ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        updatedAt: _parseTs(json['updated_at']),
      );

  Map<String, dynamic> scoreToSnapshot(StudentScore s) => <String, dynamic>{
    'id': s.id,
    'teacher_id': s.teacherId,
    'assignment_id': s.assignmentId,
    'enrollment_id': s.enrollmentId,
    'submission_status': s.submissionStatus.dbValue,
    'score': s.score,
    'note': s.note,
    'version': s.version,
    'updated_at': s.updatedAt.toUtc().toIso8601String(),
  };

  StudentScore scoreFromSnapshot(Map<String, dynamic> json) => StudentScore(
    id: json['id'] as String,
    teacherId: json['teacher_id'] as String,
    assignmentId: json['assignment_id'] as String,
    enrollmentId: json['enrollment_id'] as String,
    submissionStatus: SubmissionStatus.fromDbValue(
      (json['submission_status'] as String?) ?? 'missing',
    ),
    score: (json['score'] as num?)?.toDouble(),
    note: (json['note'] as String?) ?? '',
    version: (json['version'] as num?)?.toInt() ?? 1,
    updatedAt: _parseTs(json['updated_at']),
  );

  DateTime _parseTs(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }
}
