import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../sync_queue/domain/entities/sync_entity_type.dart';
import '../../../sync_queue/domain/entities/sync_operation_type.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_record_input.dart';
import '../../domain/entities/attendance_rule_config.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';

/// Offline-first repository for Attendance coordinating Supabase remote,
/// Drift structured local tables (preserving `isDirty == true` rows), and
/// `SyncQueueRepository` for offline classroom check-ins.
class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
    this._syncQueueRepository,
    this._currentTeacherId,
    this._isOnline,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final AttendanceRemoteDataSource? _remoteDataSource;
  final AttendanceLocalDataSource? _localDataSource;
  final SyncQueueRepository? _syncQueueRepository;
  final String? Function()? _currentTeacherId;
  final bool Function()? _isOnline;
  final Uuid _uuid;

  bool get _online => _isOnline?.call() ?? true;
  String? get _teacherId => _currentTeacherId?.call();

  @override
  Future<List<AttendanceSession>> fetchSessions(String subjectClassId) async {
    final local = _localDataSource;
    final tid = _teacherId;
    if (_online && _remoteDataSource != null) {
      try {
        final dtos = await _remoteDataSource.fetchSessions(subjectClassId);
        final remoteItems = dtos.map((d) => d.toEntity()).toList(growable: false);
        if (local != null && tid != null) {
          await local.upsertSessionsFromRemote(tid, subjectClassId, remoteItems);
          return await local.fetchSessions(tid, subjectClassId) ?? remoteItems;
        }
        return remoteItems;
      } on NetworkException {
        if (local != null && tid != null) {
          final cached = await local.fetchSessions(tid, subjectClassId);
          if (cached != null) return cached;
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      final cached = await local.fetchSessions(tid, subjectClassId);
      if (cached != null) return cached;
    }
    throw _offlineCacheMissingError();
  }

  @override
  Future<AttendanceSession?> fetchSessionByDate({
    required String subjectClassId,
    required DateTime sessionDate,
  }) async {
    final local = _localDataSource;
    final tid = _teacherId;
    if (_online && _remoteDataSource != null) {
      try {
        final dto = await _remoteDataSource.fetchSessionByDate(
          subjectClassId: subjectClassId,
          sessionDate: sessionDate,
        );
        final entity = dto?.toEntity();
        if (local != null && tid != null) {
          if (entity != null) {
            await local.upsertSessionsFromRemote(tid, subjectClassId, [entity]);
          }
          return local.fetchSessionByDate(
            teacherId: tid,
            subjectClassId: subjectClassId,
            sessionDate: sessionDate,
          );
        }
        return entity;
      } on NetworkException {
        if (local != null && tid != null) {
          return local.fetchSessionByDate(
            teacherId: tid,
            subjectClassId: subjectClassId,
            sessionDate: sessionDate,
          );
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      return local.fetchSessionByDate(
        teacherId: tid,
        subjectClassId: subjectClassId,
        sessionDate: sessionDate,
      );
    }
    throw _offlineCacheMissingError();
  }

  @override
  Future<List<AttendanceRecord>> fetchRecordsBySession(String sessionId) async {
    final local = _localDataSource;
    final tid = _teacherId;
    if (_online && _remoteDataSource != null) {
      try {
        final dtos = await _remoteDataSource.fetchRecordsBySession(sessionId);
        final remoteItems = dtos.map((d) => d.toEntity()).toList(growable: false);
        if (local != null && tid != null) {
          await local.upsertRecordsFromRemote(
            tid,
            remoteItems,
            sessionId: sessionId,
          );
          return await local.fetchRecordsBySession(tid, sessionId) ?? remoteItems;
        }
        return remoteItems;
      } on NetworkException {
        if (local != null && tid != null) {
          final cached = await local.fetchRecordsBySession(tid, sessionId);
          if (cached != null) return cached;
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      final cached = await local.fetchRecordsBySession(tid, sessionId);
      if (cached != null) return cached;
    }
    throw _offlineCacheMissingError();
  }

  @override
  Future<List<AttendanceRecord>> fetchRecordsByClass(
    String subjectClassId,
  ) async {
    final local = _localDataSource;
    final tid = _teacherId;
    if (_online && _remoteDataSource != null) {
      try {
        final dtos = await _remoteDataSource.fetchRecordsByClass(subjectClassId);
        final remoteItems = dtos.map((d) => d.toEntity()).toList(growable: false);
        if (local != null && tid != null) {
          await local.upsertRecordsFromRemote(
            tid,
            remoteItems,
            subjectClassId: subjectClassId,
          );
          return await local.fetchRecordsByClass(tid, subjectClassId) ??
              remoteItems;
        }
        return remoteItems;
      } on NetworkException {
        if (local != null && tid != null) {
          final cached = await local.fetchRecordsByClass(tid, subjectClassId);
          if (cached != null) return cached;
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      final cached = await local.fetchRecordsByClass(tid, subjectClassId);
      if (cached != null) return cached;
    }
    throw _offlineCacheMissingError();
  }

  @override
  Future<AttendanceSession> createSession({
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
    String note = '',
    bool isLocked = false,
  }) async {
    if (_online && _remoteDataSource != null) {
      try {
        final dto = await _remoteDataSource.createSession(
          teacherId: teacherId,
          subjectClassId: subjectClassId,
          sessionDate: sessionDate,
          note: note,
          isLocked: isLocked,
        );
        final entity = dto.toEntity();
        await _localDataSource?.markSessionSynced(entity);
        return entity;
      } on NetworkException {
        return _createSessionOffline(
          teacherId: teacherId,
          subjectClassId: subjectClassId,
          sessionDate: sessionDate,
          note: note,
          isLocked: isLocked,
        );
      }
    }
    return _createSessionOffline(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
      note: note,
      isLocked: isLocked,
    );
  }

  @override
  Future<AttendanceSession> updateSession({
    required String sessionId,
    required String note,
    required bool isLocked,
    required int expectedVersion,
  }) async {
    if (_online && _remoteDataSource != null) {
      try {
        final dto = await _remoteDataSource.updateSession(
          sessionId: sessionId,
          note: note,
          isLocked: isLocked,
          expectedVersion: expectedVersion,
        );
        final entity = dto.toEntity();
        await _localDataSource?.markSessionSynced(entity);
        return entity;
      } on NetworkException {
        return _updateSessionOffline(
          sessionId: sessionId,
          note: note,
          isLocked: isLocked,
          expectedVersion: expectedVersion,
        );
      }
    }
    return _updateSessionOffline(
      sessionId: sessionId,
      note: note,
      isLocked: isLocked,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<List<AttendanceRecord>> saveSessionRecords({
    required String teacherId,
    required String sessionId,
    required List<AttendanceRecordInput> inputs,
  }) async {
    if (inputs.isEmpty) return const <AttendanceRecord>[];
    if (_online && _remoteDataSource != null) {
      try {
        final dtos = await _remoteDataSource.saveSessionRecords(
          teacherId: teacherId,
          sessionId: sessionId,
          inputs: inputs,
        );
        final entities = dtos.map((d) => d.toEntity()).toList(growable: false);
        final local = _localDataSource;
        if (local != null) {
          for (final record in entities) {
            await local.markRecordSynced(record);
          }
        }
        return entities;
      } on NetworkException {
        return _saveRecordsOffline(
          teacherId: teacherId,
          sessionId: sessionId,
          inputs: inputs,
        );
      }
    }
    return _saveRecordsOffline(
      teacherId: teacherId,
      sessionId: sessionId,
      inputs: inputs,
    );
  }

  @override
  Future<AttendanceRuleConfig> fetchRuleConfig(String subjectClassId) async {
    final local = _localDataSource;
    final tid = _teacherId;
    if (_online && _remoteDataSource != null) {
      try {
        final dto = await _remoteDataSource.fetchRuleConfig(subjectClassId);
        final entity = dto.toEntity();
        if (local != null && tid != null) {
          await local.saveRuleConfig(tid, entity);
        }
        return entity;
      } on NetworkException {
        if (local != null && tid != null) {
          final cached = await local.readRuleConfig(tid, subjectClassId);
          if (cached != null) return cached;
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      final cached = await local.readRuleConfig(tid, subjectClassId);
      if (cached != null) return cached;
    }
    throw _offlineCacheMissingError();
  }

  @override
  Future<AttendanceRuleConfig> updateRuleConfig(
    AttendanceRuleConfig config,
  ) async {
    final dto = await _requireRemote().updateRuleConfig(config);
    final entity = dto.toEntity();
    final tid = _teacherId;
    if (_localDataSource != null && tid != null) {
      await _localDataSource.saveRuleConfig(tid, entity);
    }
    return entity;
  }

  Future<AttendanceSession> _createSessionOffline({
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
    required String note,
    required bool isLocked,
  }) async {
    final local = _localDataSource;
    final queue = _syncQueueRepository;
    if (local == null || queue == null) {
      throw _offlineCacheMissingError();
    }
    final existing = await local.fetchSessionByDate(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
    );
    if (existing != null) return existing;

    final now = DateTime.now().toUtc();
    final session = AttendanceSession(
      id: _uuid.v4(),
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: DateTime(sessionDate.year, sessionDate.month, sessionDate.day),
      isLocked: isLocked,
      note: note.trim(),
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
    await local.saveSessionOffline(session);
    await queue.enqueueMutation(
      teacherId: teacherId,
      entityType: SyncEntityType.attendanceSession,
      entityId: session.id,
      displayLabel:
          'สร้างคาบเช็คชื่อ (${ThaiDateFormatter.formatShortDate(session.sessionDate)})',
      operation: SyncOperationType.create,
      payload: <String, dynamic>{
        'id': session.id,
        'teacher_id': teacherId,
        'subject_class_id': subjectClassId,
        'session_date': ThaiDateFormatter.toIsoDate(session.sessionDate),
        'is_locked': session.isLocked,
        'note': session.note,
      },
      expectedVersion: null,
      now: now,
    );
    return session;
  }

  Future<AttendanceSession> _updateSessionOffline({
    required String sessionId,
    required String note,
    required bool isLocked,
    required int expectedVersion,
  }) async {
    final local = _localDataSource;
    final queue = _syncQueueRepository;
    final tid = _teacherId;
    if (local == null || queue == null || tid == null) {
      throw _offlineCacheMissingError();
    }
    final existing = await local.fetchSessionById(tid, sessionId);
    if (existing == null) {
      throw _offlineCacheMissingError();
    }
    final now = DateTime.now().toUtc();
    final updated = AttendanceSession(
      id: existing.id,
      teacherId: existing.teacherId,
      subjectClassId: existing.subjectClassId,
      sessionDate: existing.sessionDate,
      isLocked: isLocked,
      note: note.trim(),
      version: expectedVersion + 1,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    await local.saveSessionOffline(updated);
    await queue.enqueueMutation(
      teacherId: tid,
      entityType: SyncEntityType.attendanceSession,
      entityId: sessionId,
      displayLabel:
          'แก้ไขคาบเช็คชื่อ (${ThaiDateFormatter.formatShortDate(existing.sessionDate)})',
      operation: SyncOperationType.update,
      payload: <String, dynamic>{
        'id': sessionId,
        'teacher_id': existing.teacherId,
        'subject_class_id': existing.subjectClassId,
        'session_date': ThaiDateFormatter.toIsoDate(existing.sessionDate),
        'is_locked': updated.isLocked,
        'note': updated.note,
      },
      expectedVersion: expectedVersion,
      now: now,
    );
    return updated;
  }

  Future<List<AttendanceRecord>> _saveRecordsOffline({
    required String teacherId,
    required String sessionId,
    required List<AttendanceRecordInput> inputs,
  }) async {
    final local = _localDataSource;
    final queue = _syncQueueRepository;
    if (local == null || queue == null) {
      throw _offlineCacheMissingError();
    }
    final existingRows =
        await local.fetchRecordsBySession(teacherId, sessionId) ??
        const <AttendanceRecord>[];
    final existingByEnrollment = <String, AttendanceRecord>{
      for (final row in existingRows) row.enrollmentId: row,
    };

    final now = DateTime.now().toUtc();
    final saved = <AttendanceRecord>[];
    for (final input in inputs) {
      final existing = existingByEnrollment[input.enrollmentId];
      final isUpdate = input.isUpdate || existing != null;
      final id = input.existingRecordId ?? existing?.id ?? input.clientId ?? _uuid.v4();
      final queueExpectedVersion = isUpdate
          ? (input.expectedVersion ?? existing!.version)
          : null;
      final localVersion = isUpdate ? queueExpectedVersion! + 1 : 1;

      final record = AttendanceRecord(
        id: id,
        teacherId: teacherId,
        sessionId: sessionId,
        enrollmentId: input.enrollmentId,
        status: input.status,
        note: input.note.trim(),
        version: localVersion,
        updatedAt: now,
      );
      saved.add(record);
      await queue.enqueueMutation(
        teacherId: teacherId,
        entityType: SyncEntityType.attendanceRecord,
        entityId: id,
        displayLabel: 'เช็คชื่อ (${input.status.thaiLabel})',
        operation: isUpdate ? SyncOperationType.update : SyncOperationType.create,
        payload: <String, dynamic>{
          'id': id,
          'teacher_id': teacherId,
          'session_id': sessionId,
          'enrollment_id': input.enrollmentId,
          'status': input.status.dbValue,
          'note': input.note.trim(),
        },
        expectedVersion: queueExpectedVersion,
        now: now,
      );
    }

    await local.saveRecordsOffline(saved);
    return List<AttendanceRecord>.unmodifiable(saved);
  }

  NetworkException _offlineCacheMissingError() => const NetworkException(
    'ขณะนี้ออฟไลน์และยังไม่มีข้อมูลเช็คชื่อที่แคชไว้สำหรับห้องนี้ กรุณาเชื่อมต่ออินเทอร์เน็ตก่อนเปิดดูครั้งแรก',
    code: 'OFFLINE_NO_LOCAL_CACHE',
  );

  AttendanceRemoteDataSource _requireRemote() {
    final remote = _remoteDataSource;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนดำเนินการ',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote;
  }
}
