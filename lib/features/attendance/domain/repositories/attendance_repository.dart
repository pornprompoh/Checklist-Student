import '../entities/attendance_record.dart';
import '../entities/attendance_record_input.dart';
import '../entities/attendance_rule_config.dart';
import '../entities/attendance_session.dart';

/// Abstract repository contract for daily attendance sessions, individual
/// attendance records, and subject-class attendance rules.
///
/// Pure Dart interface following the Repository Pattern.
abstract interface class AttendanceRepository {
  /// Fetches all sessions for [subjectClassId] ordered by `session_date DESC`.
  Future<List<AttendanceSession>> fetchSessions(String subjectClassId);

  /// Fetches the single session on [sessionDate] (date-only), or `null`.
  Future<AttendanceSession?> fetchSessionByDate({
    required String subjectClassId,
    required DateTime sessionDate,
  });

  /// Fetches all attendance records belonging to [sessionId].
  Future<List<AttendanceRecord>> fetchRecordsBySession(String sessionId);

  /// Batch-fetches all attendance records across all sessions of [subjectClassId].
  Future<List<AttendanceRecord>> fetchRecordsByClass(String subjectClassId);

  /// Creates a new `attendance_sessions` row (`version = 1`).
  Future<AttendanceSession> createSession({
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
    String note = '',
    bool isLocked = false,
  });

  /// Updates an existing session using Optimistic Locking (`expectedVersion`).
  Future<AttendanceSession> updateSession({
    required String sessionId,
    required String note,
    required bool isLocked,
    required int expectedVersion,
  });

  /// Inserts or updates session attendance records with Optimistic Locking.
  Future<List<AttendanceRecord>> saveSessionRecords({
    required String teacherId,
    required String sessionId,
    required List<AttendanceRecordInput> inputs,
  });

  /// Fetches attendance rule settings from `public.subject_classes`.
  Future<AttendanceRuleConfig> fetchRuleConfig(String subjectClassId);

  /// Updates attendance rule settings on `public.subject_classes`.
  Future<AttendanceRuleConfig> updateRuleConfig(AttendanceRuleConfig config);
}
