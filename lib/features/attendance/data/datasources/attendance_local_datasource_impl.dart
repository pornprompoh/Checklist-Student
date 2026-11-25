import 'package:drift/drift.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_cache_store.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_rule_config.dart';
import '../../domain/entities/attendance_session.dart';
import '../models/attendance_rule_config_dto.dart';
import 'attendance_local_datasource.dart';

/// Drift-backed offline datasource for `local_attendance_sessions`,
/// `local_attendance_records`, and cached `AttendanceRuleConfig`.
class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  const AttendanceLocalDataSourceImpl(this._db, this._cache);

  final AppDatabase _db;
  final LocalCacheStore _cache;
  static const String _group = 'attendance';

  @override
  Future<List<AttendanceSession>?> fetchSessions(
    String teacherId,
    String subjectClassId,
  ) async {
    final rows = await (_db.select(_db.localAttendanceSessions)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.subjectClassId.equals(subjectClassId),
          )
          ..orderBy(<OrderingTerm Function($LocalAttendanceSessionsTable)>[
            (t) => OrderingTerm.desc(t.sessionDateIso),
          ]))
        .get();
    if (rows.isEmpty) {
      final marker = await _cache.readJson(
        teacherId: teacherId,
        cacheKey: 'att_sessions_synced_$subjectClassId',
      );
      if (marker == null) return null;
    }
    return rows.map(_sessionToEntity).toList(growable: false);
  }

  @override
  Future<AttendanceSession?> fetchSessionById(
    String teacherId,
    String sessionId,
  ) async {
    final row = await (_db.select(_db.localAttendanceSessions)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.id.equals(sessionId),
          ))
        .getSingleOrNull();
    return row == null ? null : _sessionToEntity(row);
  }

  @override
  Future<AttendanceSession?> fetchSessionByDate({
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
  }) async {
    final iso = ThaiDateFormatter.toIsoDate(sessionDate);
    final row = await (_db.select(_db.localAttendanceSessions)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.subjectClassId.equals(subjectClassId) &
                t.sessionDateIso.equals(iso),
          ))
        .getSingleOrNull();
    return row == null ? null : _sessionToEntity(row);
  }

  @override
  Future<List<AttendanceRecord>?> fetchRecordsBySession(
    String teacherId,
    String sessionId,
  ) async {
    final rows = await (_db.select(_db.localAttendanceRecords)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) & t.sessionId.equals(sessionId),
          ))
        .get();
    if (rows.isEmpty) {
      final marker = await _cache.readJson(
        teacherId: teacherId,
        cacheKey: 'att_records_session_$sessionId',
      );
      if (marker == null) return null;
    }
    return rows.map(_recordToEntity).toList(growable: false);
  }

  @override
  Future<AttendanceRecord?> fetchRecordById(
    String teacherId,
    String recordId,
  ) async {
    final row = await (_db.select(_db.localAttendanceRecords)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.id.equals(recordId),
          ))
        .getSingleOrNull();
    return row == null ? null : _recordToEntity(row);
  }

  @override
  Future<List<AttendanceRecord>?> fetchRecordsByClass(
    String teacherId,
    String subjectClassId,
  ) async {
    final sessions = await (_db.select(_db.localAttendanceSessions)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.subjectClassId.equals(subjectClassId),
          ))
        .get();
    if (sessions.isEmpty) {
      final marker = await _cache.readJson(
        teacherId: teacherId,
        cacheKey: 'att_records_class_$subjectClassId',
      );
      return marker == null ? null : const <AttendanceRecord>[];
    }
    final sessionIds = sessions.map((s) => s.id).toList(growable: false);
    final rows = await (_db.select(_db.localAttendanceRecords)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.sessionId.isIn(sessionIds),
          ))
        .get();
    return rows.map(_recordToEntity).toList(growable: false);
  }

  @override
  Future<void> upsertSessionsFromRemote(
    String teacherId,
    String subjectClassId,
    List<AttendanceSession> sessions,
  ) async {
    await _db.transaction(() async {
      for (final s in sessions) {
        final iso = ThaiDateFormatter.toIsoDate(s.sessionDate);
        final existing = await _findSessionRow(teacherId, s.id, s.subjectClassId, iso);
        if (existing != null && existing.isDirty) continue;
        await _db.into(_db.localAttendanceSessions).insertOnConflictUpdate(
          _sessionToCompanion(s, isDirty: false),
        );
      }
    });
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'att_sessions_synced_$subjectClassId',
      entityGroup: _group,
      jsonPayload: const <String, bool>{'cached': true},
    );
  }

  @override
  Future<void> upsertRecordsFromRemote(
    String teacherId,
    List<AttendanceRecord> records, {
    String? sessionId,
    String? subjectClassId,
  }) async {
    await _db.transaction(() async {
      for (final r in records) {
        final existing = await _findRecordRow(
          teacherId,
          r.id,
          r.sessionId,
          r.enrollmentId,
        );
        if (existing != null && existing.isDirty) continue;
        await _db.into(_db.localAttendanceRecords).insertOnConflictUpdate(
          _recordToCompanion(r, isDirty: false),
        );
      }
    });
    if (sessionId != null) {
      await _cache.writeJson(
        teacherId: teacherId,
        cacheKey: 'att_records_session_$sessionId',
        entityGroup: _group,
        jsonPayload: const <String, bool>{'cached': true},
      );
    }
    if (subjectClassId != null) {
      await _cache.writeJson(
        teacherId: teacherId,
        cacheKey: 'att_records_class_$subjectClassId',
        entityGroup: _group,
        jsonPayload: const <String, bool>{'cached': true},
      );
    }
  }

  @override
  Future<void> saveSessionOffline(AttendanceSession session) async {
    await _db.into(_db.localAttendanceSessions).insertOnConflictUpdate(
      _sessionToCompanion(session, isDirty: true),
    );
  }

  @override
  Future<void> saveRecordsOffline(List<AttendanceRecord> records) async {
    await _db.transaction(() async {
      for (final r in records) {
        await _db.into(_db.localAttendanceRecords).insertOnConflictUpdate(
          _recordToCompanion(r, isDirty: true),
        );
      }
    });
  }

  @override
  Future<void> markSessionSynced(
    AttendanceSession session, {
    String? previousLocalId,
  }) async {
    await _db.transaction(() async {
      if (previousLocalId != null && previousLocalId != session.id) {
        await (_db.delete(_db.localAttendanceSessions)
              ..where((t) => t.id.equals(previousLocalId)))
            .go();
      }
      await _db.into(_db.localAttendanceSessions).insertOnConflictUpdate(
        _sessionToCompanion(session, isDirty: false),
      );
    });
  }

  @override
  Future<void> markRecordSynced(
    AttendanceRecord record, {
    String? previousLocalId,
  }) async {
    await _db.transaction(() async {
      if (previousLocalId != null && previousLocalId != record.id) {
        await (_db.delete(_db.localAttendanceRecords)
              ..where((t) => t.id.equals(previousLocalId)))
            .go();
      }
      await _db.into(_db.localAttendanceRecords).insertOnConflictUpdate(
        _recordToCompanion(record, isDirty: false),
      );
    });
  }

  @override
  Future<void> saveRuleConfig(String teacherId, AttendanceRuleConfig config) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'att_rule_${config.subjectClassId}',
      entityGroup: _group,
      jsonPayload: <String, dynamic>{
        'id': config.subjectClassId,
        'absent_threshold_pct': config.absentThresholdPct,
        'late_to_absent_ratio': config.lateToAbsentRatio,
        'count_leave_as_absent': config.countLeaveAsAbsent,
        'attendance_score_weight': config.attendanceScoreWeight,
      },
    );
  }

  @override
  Future<AttendanceRuleConfig?> readRuleConfig(
    String teacherId,
    String subjectClassId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'att_rule_$subjectClassId',
    );
    if (raw is! Map) return null;
    return AttendanceRuleConfigDto.fromJson(
      Map<String, dynamic>.from(raw),
    ).toEntity();
  }

  Future<LocalAttendanceSession?> _findSessionRow(
    String teacherId,
    String id,
    String subjectClassId,
    String isoDate,
  ) {
    return (_db.select(_db.localAttendanceSessions)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                (t.id.equals(id) |
                    (t.subjectClassId.equals(subjectClassId) &
                        t.sessionDateIso.equals(isoDate))),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<LocalAttendanceRecord?> _findRecordRow(
    String teacherId,
    String id,
    String sessionId,
    String enrollmentId,
  ) {
    return (_db.select(_db.localAttendanceRecords)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                (t.id.equals(id) |
                    (t.sessionId.equals(sessionId) &
                        t.enrollmentId.equals(enrollmentId))),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  LocalAttendanceSessionsCompanion _sessionToCompanion(
    AttendanceSession s, {
    required bool isDirty,
  }) => LocalAttendanceSessionsCompanion.insert(
    id: s.id,
    teacherId: s.teacherId,
    subjectClassId: s.subjectClassId,
    sessionDateIso: ThaiDateFormatter.toIsoDate(s.sessionDate),
    isLocked: Value(s.isLocked),
    note: Value(s.note),
    version: Value(s.version),
    isDirty: Value(isDirty),
    createdAt: s.createdAt.toUtc(),
    updatedAt: s.updatedAt.toUtc(),
  );

  LocalAttendanceRecordsCompanion _recordToCompanion(
    AttendanceRecord r, {
    required bool isDirty,
  }) => LocalAttendanceRecordsCompanion.insert(
    id: r.id,
    teacherId: r.teacherId,
    sessionId: r.sessionId,
    enrollmentId: r.enrollmentId,
    status: r.status.dbValue,
    note: Value(r.note),
    version: Value(r.version),
    isDirty: Value(isDirty),
    updatedAt: r.updatedAt.toUtc(),
  );

  AttendanceSession _sessionToEntity(LocalAttendanceSession row) =>
      AttendanceSession(
        id: row.id,
        teacherId: row.teacherId,
        subjectClassId: row.subjectClassId,
        sessionDate:
            ThaiDateFormatter.parseIsoDate(row.sessionDateIso) ??
            DateTime(2000),
        isLocked: row.isLocked,
        note: row.note,
        version: row.version,
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );

  AttendanceRecord _recordToEntity(LocalAttendanceRecord row) =>
      AttendanceRecord(
        id: row.id,
        teacherId: row.teacherId,
        sessionId: row.sessionId,
        enrollmentId: row.enrollmentId,
        status: AttendanceStatus.fromDbValue(row.status),
        note: row.note,
        version: row.version,
        updatedAt: row.updatedAt.toUtc(),
      );
}
