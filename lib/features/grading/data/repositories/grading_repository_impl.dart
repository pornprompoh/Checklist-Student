import 'package:uuid/uuid.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../homeroom_roster/data/datasources/homeroom_roster_local_datasource.dart';
import '../../../sync_queue/domain/entities/sync_entity_type.dart';
import '../../../sync_queue/domain/entities/sync_operation_type.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_pin_status.dart';
import '../../domain/entities/student_portal_visibility_config.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/repositories/grading_repository.dart';
import '../datasources/grading_local_datasource.dart';
import '../datasources/grading_remote_datasource.dart';

/// Offline-first repository for Grading coordinating Supabase remote, Drift
/// local score & plan caching (preserving `isDirty == true` rows), and
/// `SyncQueueRepository` for offline score & special-grade entry.
class GradingRepositoryImpl implements GradingRepository {
  GradingRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
    this._homeroomRosterLocalDataSource,
    this._syncQueueRepository,
    this._currentTeacherId,
    this._isOnline,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final GradingRemoteDataSource? _remoteDataSource;
  final GradingLocalDataSource? _localDataSource;
  final HomeroomRosterLocalDataSource? _homeroomRosterLocalDataSource;
  final SyncQueueRepository? _syncQueueRepository;
  final String? Function()? _currentTeacherId;
  final bool Function()? _isOnline;
  final Uuid _uuid;

  bool get _online => _isOnline?.call() ?? true;
  String? get _teacherId => _currentTeacherId?.call();

  @override
  Future<List<ScoreCategory>> fetchScoreCategories(String subjectClassId) {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dtos = await _requireRemote().fetchScoreCategories(subjectClassId);
        return dtos.map((dto) => dto.toEntity()).toList(growable: false);
      },
      saveLocal: (tid, data) =>
          _localDataSource!.saveScoreCategories(tid, subjectClassId, data),
      readLocal: (tid) =>
          _localDataSource!.readScoreCategories(tid, subjectClassId),
    );
  }

  @override
  Future<ScoreCategory> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    final dto = await _requireRemote().createScoreCategory(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
  Future<ScoreCategory> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    final dto = await _requireRemote().updateScoreCategory(
      categoryId: categoryId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteScoreCategory(String categoryId) {
    return _requireRemote().deleteScoreCategory(categoryId);
  }

  @override
  Future<List<Assignment>> fetchAssignments(String subjectClassId) {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dtos = await _requireRemote().fetchAssignments(subjectClassId);
        return dtos.map((dto) => dto.toEntity()).toList(growable: false);
      },
      saveLocal: (tid, data) =>
          _localDataSource!.saveAssignments(tid, subjectClassId, data),
      readLocal: (tid) => _localDataSource!.readAssignments(tid, subjectClassId),
    );
  }

  @override
  Future<Assignment> createAssignment({
    required String teacherId,
    required String subjectClassId,
    String? categoryId,
    required String title,
    String description = '',
    required double maxScore,
    bool isMandatory = false,
    DateTime? dueDate,
    int? sortOrder,
  }) async {
    final dto = await _requireRemote().createAssignment(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      categoryId: categoryId,
      title: title,
      description: description,
      maxScore: maxScore,
      isMandatory: isMandatory,
      dueDate: dueDate,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
  Future<Assignment> updateAssignment({
    required String assignmentId,
    required int expectedVersion,
    String? categoryId,
    required String title,
    required String description,
    required double maxScore,
    required bool isMandatory,
    DateTime? dueDate,
    int? sortOrder,
  }) async {
    final dto = await _requireRemote().updateAssignment(
      assignmentId: assignmentId,
      expectedVersion: expectedVersion,
      categoryId: categoryId,
      title: title,
      description: description,
      maxScore: maxScore,
      isMandatory: isMandatory,
      dueDate: dueDate,
      sortOrder: sortOrder,
    );
    return dto.toEntity();
  }

  @override
  Future<int> countScoredStudentsForAssignment(String assignmentId) {
    return _requireRemote().countScoredStudentsForAssignment(assignmentId);
  }

  @override
  Future<void> deleteAssignment(String assignmentId) {
    return _requireRemote().deleteAssignment(assignmentId);
  }

  @override
  Future<List<StudentScore>> fetchStudentScoresByClass(
    String subjectClassId,
  ) async {
    final local = _localDataSource;
    final tid = _teacherId;
    if (_online && _remoteDataSource != null) {
      try {
        final dtos = await _remoteDataSource.fetchStudentScoresByClass(
          subjectClassId,
        );
        final remoteItems = dtos.map((d) => d.toEntity()).toList(growable: false);
        if (local != null && tid != null) {
          await local.upsertScoresFromRemote(tid, subjectClassId, remoteItems);
          return await local.fetchStudentScoresByClass(tid, subjectClassId) ??
              remoteItems;
        }
        return remoteItems;
      } on NetworkException {
        if (local != null && tid != null) {
          final cached = await local.fetchStudentScoresByClass(
            tid,
            subjectClassId,
          );
          if (cached != null) return cached;
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      final cached = await local.fetchStudentScoresByClass(tid, subjectClassId);
      if (cached != null) return cached;
    }
    throw _offlineCacheMissingError();
  }

  @override
  Future<StudentScore> upsertStudentScore({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    String? existingScoreId,
    int? expectedVersion,
    required SubmissionStatus submissionStatus,
    double? score,
    String note = '',
  }) async {
    if (score != null && (!score.isFinite || score < 0)) {
      throw const ValidationException(
        'คะแนนต้องเป็นตัวเลขที่ไม่ติดลบ',
        code: 'INVALID_STUDENT_SCORE',
      );
    }
    if (_online && _remoteDataSource != null) {
      try {
        final dto = await _remoteDataSource.upsertStudentScore(
          teacherId: teacherId,
          assignmentId: assignmentId,
          enrollmentId: enrollmentId,
          existingScoreId: existingScoreId,
          expectedVersion: expectedVersion,
          submissionStatus: submissionStatus,
          score: score,
          note: note,
        );
        final entity = dto.toEntity();
        await _localDataSource?.markScoreSynced(entity);
        return entity;
      } on NetworkException {
        return _upsertScoreOffline(
          teacherId: teacherId,
          assignmentId: assignmentId,
          enrollmentId: enrollmentId,
          existingScoreId: existingScoreId,
          expectedVersion: expectedVersion,
          submissionStatus: submissionStatus,
          score: score,
          note: note,
        );
      }
    }
    return _upsertScoreOffline(
      teacherId: teacherId,
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      existingScoreId: existingScoreId,
      expectedVersion: expectedVersion,
      submissionStatus: submissionStatus,
      score: score,
      note: note,
    );
  }

  @override
  Future<GradingScaleConfig> fetchGradingScaleConfig(String subjectClassId) {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dto = await _requireRemote().fetchGradingScaleConfig(
          subjectClassId,
        );
        return dto.toEntity();
      },
      saveLocal: (tid, data) =>
          _localDataSource!.saveGradingScaleConfig(tid, data),
      readLocal: (tid) =>
          _localDataSource!.readGradingScaleConfig(tid, subjectClassId),
    );
  }

  @override
  Future<GradingScaleConfig> updateGradingScaleConfig(
    GradingScaleConfig config,
  ) async {
    final dto = await _requireRemote().updateGradingScaleConfig(config);
    final entity = dto.toEntity();
    final tid = _teacherId;
    if (_localDataSource != null && tid != null) {
      await _localDataSource.saveGradingScaleConfig(tid, entity);
    }
    return entity;
  }

  @override
  Future<StudentPortalVisibilityConfig> fetchStudentPortalVisibility(
    String subjectClassId,
  ) {
    return _requireRemote().fetchStudentPortalVisibility(subjectClassId);
  }

  @override
  Future<StudentPortalVisibilityConfig> updateStudentPortalVisibility(
    StudentPortalVisibilityConfig config,
  ) {
    return _requireRemote().updateStudentPortalVisibility(config);
  }

  @override
  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  }) {
    return _requireRemote().copySubjectClassPlan(
      sourceClassId: sourceClassId,
      targetClassId: targetClassId,
      replaceExisting: replaceExisting,
    );
  }

  @override
  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) async {
    if (specialGradeOverride != null &&
        specialGradeOverride != 'ร' &&
        specialGradeOverride != 'มส') {
      throw const ValidationException(
        'สถานะเกรดพิเศษต้องเป็น ร, มส หรือยกเลิกสถานะเท่านั้น',
        code: 'INVALID_SPECIAL_GRADE_OVERRIDE',
      );
    }
    if (_online && _remoteDataSource != null) {
      try {
        await _remoteDataSource.updateSpecialGradeStatus(
          enrollmentId: enrollmentId,
          expectedVersion: expectedVersion,
          specialGradeOverride: specialGradeOverride,
          markRResolved: markRResolved,
          markMsResolved: markMsResolved,
        );
        final tid = _teacherId;
        if (tid != null) {
          await _homeroomRosterLocalDataSource
              ?.patchCachedEnrollmentSpecialGrade(
                teacherId: tid,
                enrollmentId: enrollmentId,
                specialGradeOverride: specialGradeOverride,
                wasRResolved: markRResolved ? true : null,
                wasMsResolved: markMsResolved ? true : null,
                version: expectedVersion + 1,
                resolvedGradeAt: (markRResolved || markMsResolved)
                    ? DateTime.now().toUtc()
                    : null,
              );
        }
        return;
      } on NetworkException {
        await _updateSpecialGradeOffline(
          enrollmentId: enrollmentId,
          expectedVersion: expectedVersion,
          specialGradeOverride: specialGradeOverride,
          markRResolved: markRResolved,
          markMsResolved: markMsResolved,
        );
        return;
      }
    }
    await _updateSpecialGradeOffline(
      enrollmentId: enrollmentId,
      expectedVersion: expectedVersion,
      specialGradeOverride: specialGradeOverride,
      markRResolved: markRResolved,
      markMsResolved: markMsResolved,
    );
  }

  @override
  Future<StudentPinStatus> fetchStudentPinStatus(
    String studentIdentityId,
  ) async {
    final dto = await _requireRemote().fetchStudentPinStatus(studentIdentityId);
    return dto.toEntity();
  }

  @override
  Future<void> resetStudentPin(String studentIdentityId) {
    return _requireRemote().resetStudentPin(studentIdentityId);
  }

  Future<StudentScore> _upsertScoreOffline({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    required String? existingScoreId,
    required int? expectedVersion,
    required SubmissionStatus submissionStatus,
    required double? score,
    required String note,
  }) async {
    final local = _localDataSource;
    final queue = _syncQueueRepository;
    if (local == null || queue == null) {
      throw _offlineCacheMissingError();
    }
    final existingLocal = existingScoreId != null
        ? await local.fetchStudentScoreById(teacherId, existingScoreId)
        : await local.fetchStudentScoreByCell(
            teacherId: teacherId,
            assignmentId: assignmentId,
            enrollmentId: enrollmentId,
          );
    final isUpdate = existingScoreId != null || existingLocal != null;
    final id = existingScoreId ?? existingLocal?.id ?? _uuid.v4();
    final queueExpectedVersion = isUpdate
        ? (expectedVersion ?? existingLocal!.version)
        : null;
    final localVersion = isUpdate ? queueExpectedVersion! + 1 : 1;
    final now = DateTime.now().toUtc();

    final entity = StudentScore(
      id: id,
      teacherId: teacherId,
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      submissionStatus: submissionStatus,
      score: score,
      note: note.trim(),
      version: localVersion,
      updatedAt: now,
    );
    await local.saveScoreOffline(entity);
    await queue.enqueueMutation(
      teacherId: teacherId,
      entityType: SyncEntityType.studentScore,
      entityId: id,
      displayLabel: score == null
          ? 'อัปเดตสถานะงาน (${submissionStatus.thaiLabel})'
          : 'บันทึกคะแนน ($score คะแนน)',
      operation: isUpdate ? SyncOperationType.update : SyncOperationType.create,
      payload: <String, dynamic>{
        'id': id,
        'teacher_id': teacherId,
        'assignment_id': assignmentId,
        'enrollment_id': enrollmentId,
        'submission_status': submissionStatus.dbValue,
        'score': score,
        'note': note.trim(),
      },
      expectedVersion: queueExpectedVersion,
      now: now,
    );
    return entity;
  }

  Future<void> _updateSpecialGradeOffline({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) async {
    final queue = _syncQueueRepository;
    final tid = _teacherId;
    if (queue == null || tid == null) {
      throw _offlineCacheMissingError();
    }
    final now = DateTime.now().toUtc();
    await _homeroomRosterLocalDataSource?.patchCachedEnrollmentSpecialGrade(
      teacherId: tid,
      enrollmentId: enrollmentId,
      specialGradeOverride: specialGradeOverride,
      wasRResolved: markRResolved ? true : null,
      wasMsResolved: markMsResolved ? true : null,
      version: expectedVersion + 1,
      resolvedGradeAt: (markRResolved || markMsResolved) ? now : null,
    );
    await queue.enqueueMutation(
      teacherId: tid,
      entityType: SyncEntityType.specialGradeStatus,
      entityId: enrollmentId,
      displayLabel:
          'อัปเดตเกรดพิเศษ (${specialGradeOverride ?? 'แก้ผ่าน/ปกติ'})',
      operation: SyncOperationType.update,
      payload: <String, dynamic>{
        'enrollment_id': enrollmentId,
        'special_grade_override': specialGradeOverride,
        'mark_r_resolved': markRResolved,
        'mark_ms_resolved': markMsResolved,
      },
      expectedVersion: expectedVersion,
      now: now,
    );
  }

  Future<T> _readWithCacheFallback<T>({
    required Future<T> Function() fetchRemote,
    required Future<void> Function(String teacherId, T data) saveLocal,
    required Future<T?> Function(String teacherId) readLocal,
  }) async {
    final tid = _teacherId;
    final local = _localDataSource;
    if (_online && _remoteDataSource != null) {
      try {
        final fresh = await fetchRemote();
        if (local != null && tid != null) {
          await saveLocal(tid, fresh);
        }
        return fresh;
      } on NetworkException {
        if (local != null && tid != null) {
          final cached = await readLocal(tid);
          if (cached != null) return cached;
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      final cached = await readLocal(tid);
      if (cached != null) return cached;
    }
    throw _offlineCacheMissingError();
  }

  NetworkException _offlineCacheMissingError() => const NetworkException(
    'ขณะนี้ออฟไลน์และยังไม่มีข้อมูลคะแนนที่แคชไว้สำหรับห้องนี้ กรุณาเชื่อมต่ออินเทอร์เน็ตก่อนเปิดดูครั้งแรก',
    code: 'OFFLINE_NO_LOCAL_CACHE',
  );

  GradingRemoteDataSource _requireRemote() {
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
