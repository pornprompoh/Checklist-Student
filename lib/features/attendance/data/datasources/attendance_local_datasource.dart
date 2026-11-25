import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_rule_config.dart';
import '../../domain/entities/attendance_session.dart';

/// Local Drift datasource contract for Attendance offline-first read/write
/// caching and dirty-row preservation.
abstract interface class AttendanceLocalDataSource {
  Future<List<AttendanceSession>?> fetchSessions(
    String teacherId,
    String subjectClassId,
  );

  Future<AttendanceSession?> fetchSessionById(
    String teacherId,
    String sessionId,
  );

  Future<AttendanceSession?> fetchSessionByDate({
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
  });

  Future<List<AttendanceRecord>?> fetchRecordsBySession(
    String teacherId,
    String sessionId,
  );

  Future<AttendanceRecord?> fetchRecordById(String teacherId, String recordId);

  Future<List<AttendanceRecord>?> fetchRecordsByClass(
    String teacherId,
    String subjectClassId,
  );

  /// Caches server sessions locally without overwriting any `isDirty == true`
  /// local rows.
  Future<void> upsertSessionsFromRemote(
    String teacherId,
    String subjectClassId,
    List<AttendanceSession> sessions,
  );

  /// Caches server records locally without overwriting any `isDirty == true`
  /// local rows.
  Future<void> upsertRecordsFromRemote(
    String teacherId,
    List<AttendanceRecord> records, {
    String? sessionId,
    String? subjectClassId,
  });

  Future<void> saveSessionOffline(AttendanceSession session);

  Future<void> saveRecordsOffline(List<AttendanceRecord> records);

  Future<void> markSessionSynced(
    AttendanceSession session, {
    String? previousLocalId,
  });

  Future<void> markRecordSynced(
    AttendanceRecord record, {
    String? previousLocalId,
  });

  Future<void> saveRuleConfig(String teacherId, AttendanceRuleConfig config);

  Future<AttendanceRuleConfig?> readRuleConfig(
    String teacherId,
    String subjectClassId,
  );
}
