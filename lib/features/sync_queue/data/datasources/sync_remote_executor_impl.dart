import '../../../../core/constants/attendance_status.dart';
import '../../../../core/constants/submission_status.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../attendance/data/datasources/attendance_local_datasource.dart';
import '../../../attendance/data/datasources/attendance_remote_datasource.dart';
import '../../../attendance/domain/entities/attendance_record_input.dart';
import '../../../grading/data/datasources/grading_local_datasource.dart';
import '../../../grading/data/datasources/grading_remote_datasource.dart';
import '../../../homeroom_roster/data/datasources/homeroom_roster_local_datasource.dart';
import '../../domain/entities/sync_entity_type.dart';
import '../../domain/entities/sync_operation_type.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/repositories/sync_remote_executor.dart';
import '../models/sync_snapshot_codec.dart';

/// Concrete [SyncRemoteExecutor] dispatching queued mutations to Attendance and
/// Grading remote datasources, handling Client UUID v4 idempotency, capturing
/// authoritative server snapshots on [ConflictException], and updating local
/// Drift tables (`isDirty = false`).
class SyncRemoteExecutorImpl implements SyncRemoteExecutor {
  const SyncRemoteExecutorImpl({
    required this.attendanceRemote,
    required this.attendanceLocal,
    required this.gradingRemote,
    required this.gradingLocal,
    required this.homeroomRosterLocal,
    this.codec = const SyncSnapshotCodec(),
  });

  final AttendanceRemoteDataSource? attendanceRemote;
  final AttendanceLocalDataSource attendanceLocal;
  final GradingRemoteDataSource? gradingRemote;
  final GradingLocalDataSource gradingLocal;
  final HomeroomRosterLocalDataSource homeroomRosterLocal;
  final SyncSnapshotCodec codec;

  @override
  Future<SyncExecutionResult> executeItem(
    SyncQueueItem item, {
    int? overrideExpectedVersion,
  }) async {
    try {
      return switch (item.entityType) {
        SyncEntityType.attendanceSession => await _executeAttendanceSession(
          item,
          overrideExpectedVersion: overrideExpectedVersion,
        ),
        SyncEntityType.attendanceRecord => await _executeAttendanceRecord(
          item,
          overrideExpectedVersion: overrideExpectedVersion,
        ),
        SyncEntityType.studentScore => await _executeStudentScore(
          item,
          overrideExpectedVersion: overrideExpectedVersion,
        ),
        SyncEntityType.specialGradeStatus => await _executeSpecialGrade(
          item,
          overrideExpectedVersion: overrideExpectedVersion,
        ),
      };
    } on NetworkException catch (e) {
      return SyncExecutionResult.transientError(e.message);
    } on ConflictException catch (e) {
      final snapshot = await _fetchServerSnapshotSafe(item);
      return SyncExecutionResult.conflict(
        message: e.message,
        serverSnapshot: snapshot,
      );
    } on AppException catch (e) {
      return SyncExecutionResult.fatalError(e.message);
    } catch (e) {
      return SyncExecutionResult.transientError('ซิงค์ไม่สำเร็จ: $e');
    }
  }

  @override
  Future<void> applyServerSnapshotLocally(
    SyncQueueItem item,
    Map<String, dynamic> serverSnapshot,
  ) async {
    switch (item.entityType) {
      case SyncEntityType.attendanceSession:
        await attendanceLocal.markSessionSynced(
          codec.sessionFromSnapshot(serverSnapshot),
          previousLocalId: item.entityId,
        );
      case SyncEntityType.attendanceRecord:
        await attendanceLocal.markRecordSynced(
          codec.recordFromSnapshot(serverSnapshot),
          previousLocalId: item.entityId,
        );
      case SyncEntityType.studentScore:
        await gradingLocal.markScoreSynced(
          codec.scoreFromSnapshot(serverSnapshot),
          previousLocalId: item.entityId,
        );
      case SyncEntityType.specialGradeStatus:
        final resolvedAtRaw = serverSnapshot['resolved_grade_at'] as String?;
        await homeroomRosterLocal.patchCachedEnrollmentSpecialGrade(
          teacherId: item.teacherId,
          enrollmentId: item.entityId,
          specialGradeOverride:
              serverSnapshot['special_grade_override'] as String?,
          wasRResolved: serverSnapshot['was_r_resolved'] as bool?,
          wasMsResolved: serverSnapshot['was_ms_resolved'] as bool?,
          version: (serverSnapshot['version'] as num?)?.toInt(),
          resolvedGradeAt: resolvedAtRaw == null
              ? null
              : DateTime.tryParse(resolvedAtRaw)?.toUtc(),
        );
    }
  }

  Future<SyncExecutionResult> _executeAttendanceSession(
    SyncQueueItem item, {
    int? overrideExpectedVersion,
  }) async {
    final remote = attendanceRemote;
    if (remote == null) {
      return const SyncExecutionResult.transientError('ยังไม่เชื่อมต่อ Supabase');
    }
    final p = item.payload;
    final subjectClassId = p['subject_class_id'] as String;
    final sessionDate = ThaiDateFormatter.parseIsoDate(
      p['session_date'] as String?,
    )!;
    final note = (p['note'] as String?) ?? '';
    final isLocked = (p['is_locked'] as bool?) ?? false;

    if (item.operation == SyncOperationType.create &&
        overrideExpectedVersion == null) {
      try {
        final dto = await remote.createSession(
          clientId: item.entityId,
          teacherId: item.teacherId,
          subjectClassId: subjectClassId,
          sessionDate: sessionDate,
          note: note,
          isLocked: isLocked,
        );
        await attendanceLocal.markSessionSynced(dto.toEntity());
        return const SyncExecutionResult.synced();
      } on ValidationException catch (e) {
        if (e.code == '23505') {
          final existing =
              await remote.fetchSessionById(item.entityId) ??
              await remote.fetchSessionByDate(
                subjectClassId: subjectClassId,
                sessionDate: sessionDate,
              );
          if (existing != null) {
            final entity = existing.toEntity();
            if (entity.id == item.entityId &&
                entity.note == note.trim() &&
                entity.isLocked == isLocked) {
              await attendanceLocal.markSessionSynced(entity);
              return const SyncExecutionResult.synced();
            }
            return SyncExecutionResult.conflict(
              message: 'พบคาบเช็คชื่อของวันนี้ถูกสร้างไว้แล้วจากอุปกรณ์อื่น',
              serverSnapshot: codec.sessionToSnapshot(entity),
            );
          }
        }
        rethrow;
      }
    }

    final expectedVersion = overrideExpectedVersion ?? item.expectedVersion ?? 1;
    final dto = await remote.updateSession(
      sessionId: item.entityId,
      note: note,
      isLocked: isLocked,
      expectedVersion: expectedVersion,
    );
    await attendanceLocal.markSessionSynced(dto.toEntity());
    return const SyncExecutionResult.synced();
  }

  Future<SyncExecutionResult> _executeAttendanceRecord(
    SyncQueueItem item, {
    int? overrideExpectedVersion,
  }) async {
    final remote = attendanceRemote;
    if (remote == null) {
      return const SyncExecutionResult.transientError('ยังไม่เชื่อมต่อ Supabase');
    }
    final p = item.payload;
    final sessionId = p['session_id'] as String;
    final enrollmentId = p['enrollment_id'] as String;
    final status = AttendanceStatus.fromDbValue(
      (p['status'] as String?) ?? 'present',
    );
    final note = (p['note'] as String?) ?? '';
    final isCreate =
        item.operation == SyncOperationType.create &&
        overrideExpectedVersion == null;

    final input = AttendanceRecordInput(
      existingRecordId: isCreate ? null : item.entityId,
      clientId: isCreate ? item.entityId : null,
      enrollmentId: enrollmentId,
      status: status,
      note: note,
      expectedVersion: isCreate
          ? null
          : (overrideExpectedVersion ?? item.expectedVersion ?? 1),
    );
    try {
      final dtos = await remote.saveSessionRecords(
        teacherId: item.teacherId,
        sessionId: sessionId,
        inputs: <AttendanceRecordInput>[input],
      );
      for (final dto in dtos) {
        await attendanceLocal.markRecordSynced(dto.toEntity());
      }
      return const SyncExecutionResult.synced();
    } on ConflictException {
      if (isCreate) {
        final existing =
            await remote.fetchRecordById(item.entityId) ??
            await remote.fetchRecordByCell(
              sessionId: sessionId,
              enrollmentId: enrollmentId,
            );
        if (existing != null) {
          final entity = existing.toEntity();
          if (entity.id == item.entityId &&
              entity.status == status &&
              entity.note == note.trim()) {
            await attendanceLocal.markRecordSynced(entity);
            return const SyncExecutionResult.synced();
          }
          return SyncExecutionResult.conflict(
            message: 'ข้อมูลเช็คชื่อนักเรียนคนนี้ถูกบันทึกจากอุปกรณ์อื่นแล้ว',
            serverSnapshot: codec.recordToSnapshot(entity),
          );
        }
      }
      rethrow;
    }
  }

  Future<SyncExecutionResult> _executeStudentScore(
    SyncQueueItem item, {
    int? overrideExpectedVersion,
  }) async {
    final remote = gradingRemote;
    if (remote == null) {
      return const SyncExecutionResult.transientError('ยังไม่เชื่อมต่อ Supabase');
    }
    final p = item.payload;
    final assignmentId = p['assignment_id'] as String;
    final enrollmentId = p['enrollment_id'] as String;
    final status = SubmissionStatus.fromDbValue(
      (p['submission_status'] as String?) ?? 'missing',
    );
    final score = (p['score'] as num?)?.toDouble();
    final note = (p['note'] as String?) ?? '';
    final isCreate =
        item.operation == SyncOperationType.create &&
        overrideExpectedVersion == null;

    try {
      final dto = await remote.upsertStudentScore(
        clientId: isCreate ? item.entityId : null,
        teacherId: item.teacherId,
        assignmentId: assignmentId,
        enrollmentId: enrollmentId,
        existingScoreId: isCreate ? null : item.entityId,
        expectedVersion: isCreate
            ? null
            : (overrideExpectedVersion ?? item.expectedVersion ?? 1),
        submissionStatus: status,
        score: score,
        note: note,
      );
      await gradingLocal.markScoreSynced(dto.toEntity());
      return const SyncExecutionResult.synced();
    } on ConflictException {
      if (isCreate) {
        final existing =
            await remote.fetchStudentScoreById(item.entityId) ??
            await remote.fetchStudentScoreByCell(
              assignmentId: assignmentId,
              enrollmentId: enrollmentId,
            );
        if (existing != null) {
          final entity = existing.toEntity();
          if (entity.id == item.entityId &&
              entity.score == score &&
              entity.submissionStatus == status) {
            await gradingLocal.markScoreSynced(entity);
            return const SyncExecutionResult.synced();
          }
          return SyncExecutionResult.conflict(
            message: 'คะแนนช่องนี้ถูกบันทึกจากอุปกรณ์อื่นแล้ว',
            serverSnapshot: codec.scoreToSnapshot(entity),
          );
        }
      }
      rethrow;
    }
  }

  Future<SyncExecutionResult> _executeSpecialGrade(
    SyncQueueItem item, {
    int? overrideExpectedVersion,
  }) async {
    final remote = gradingRemote;
    if (remote == null) {
      return const SyncExecutionResult.transientError('ยังไม่เชื่อมต่อ Supabase');
    }
    final p = item.payload;
    final expectedVersion = overrideExpectedVersion ?? item.expectedVersion ?? 1;
    final override = p['special_grade_override'] as String?;
    final markR = (p['mark_r_resolved'] as bool?) ?? false;
    final markMs = (p['mark_ms_resolved'] as bool?) ?? false;

    await remote.updateSpecialGradeStatus(
      enrollmentId: item.entityId,
      expectedVersion: expectedVersion,
      specialGradeOverride: override,
      markRResolved: markR,
      markMsResolved: markMs,
    );
    await homeroomRosterLocal.patchCachedEnrollmentSpecialGrade(
      teacherId: item.teacherId,
      enrollmentId: item.entityId,
      specialGradeOverride: override,
      wasRResolved: markR ? true : null,
      wasMsResolved: markMs ? true : null,
      version: expectedVersion + 1,
      resolvedGradeAt: (markR || markMs) ? DateTime.now().toUtc() : null,
    );
    return const SyncExecutionResult.synced();
  }

  Future<Map<String, dynamic>?> _fetchServerSnapshotSafe(
    SyncQueueItem item,
  ) async {
    try {
      switch (item.entityType) {
        case SyncEntityType.attendanceSession:
          final dto = await attendanceRemote?.fetchSessionById(item.entityId);
          return dto == null ? null : codec.sessionToSnapshot(dto.toEntity());
        case SyncEntityType.attendanceRecord:
          final dto = await attendanceRemote?.fetchRecordById(item.entityId);
          return dto == null ? null : codec.recordToSnapshot(dto.toEntity());
        case SyncEntityType.studentScore:
          final dto = await gradingRemote?.fetchStudentScoreById(item.entityId);
          return dto == null ? null : codec.scoreToSnapshot(dto.toEntity());
        case SyncEntityType.specialGradeStatus:
          return gradingRemote?.fetchEnrollmentGradeStatusById(item.entityId);
      }
    } catch (_) {
      return null;
    }
  }
}
