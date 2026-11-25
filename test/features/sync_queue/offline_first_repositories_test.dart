import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/database/app_database.dart';
import 'package:checklist_student/core/database/local_cache_store.dart';
import 'package:checklist_student/core/errors/app_exception.dart';
import 'package:checklist_student/features/attendance/data/datasources/attendance_local_datasource_impl.dart';
import 'package:checklist_student/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:checklist_student/features/attendance/data/models/attendance_record_dto.dart';
import 'package:checklist_student/features/attendance/data/models/attendance_rule_config_dto.dart';
import 'package:checklist_student/features/attendance/data/models/attendance_session_dto.dart';
import 'package:checklist_student/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record_input.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_rule_config.dart';
import 'package:checklist_student/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:checklist_student/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:checklist_student/features/dashboard/data/datasources/dashboard_local_datasource_impl.dart';
import 'package:checklist_student/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:checklist_student/features/dashboard/data/models/dashboard_class_item_dto.dart';
import 'package:checklist_student/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:checklist_student/features/grading/data/datasources/grading_local_datasource_impl.dart';
import 'package:checklist_student/features/grading/data/datasources/grading_remote_datasource.dart';
import 'package:checklist_student/features/grading/data/models/assignment_dto.dart';
import 'package:checklist_student/features/grading/data/models/grading_scale_config_dto.dart';
import 'package:checklist_student/features/grading/data/models/score_category_dto.dart';
import 'package:checklist_student/features/grading/data/models/student_pin_status_dto.dart';
import 'package:checklist_student/features/grading/data/models/student_score_dto.dart';
import 'package:checklist_student/features/grading/data/repositories/grading_repository_impl.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/homeroom_roster/data/datasources/homeroom_roster_local_datasource_impl.dart';
import 'package:checklist_student/features/sync_queue/data/datasources/sync_queue_local_datasource.dart';
import 'package:checklist_student/features/sync_queue/data/datasources/sync_remote_executor_impl.dart';
import 'package:checklist_student/features/sync_queue/data/repositories/sync_queue_repository_impl.dart';
import 'package:checklist_student/features/sync_queue/domain/services/sync_engine_service.dart';

class _FakeDashboardRemote implements DashboardRemoteDataSource {
  bool shouldFailNetwork = false;
  List<DashboardClassItemDto> items = const <DashboardClassItemDto>[];

  @override
  Future<List<DashboardClassItemDto>> fetchDashboardClasses({
    required String termId,
    required DateTime referenceDate,
  }) async {
    if (shouldFailNetwork) {
      throw const NetworkException('ไม่มีสัญญาณอินเทอร์เน็ต');
    }
    return items;
  }

  @override
  Future<void> toggleClassPin({
    required String subjectClassId,
    required bool isPinned,
  }) async {}
}

class _FakeAttendanceRemote implements AttendanceRemoteDataSource {
  final Map<String, AttendanceSessionDto> sessions =
      <String, AttendanceSessionDto>{};
  final Map<String, AttendanceRecordDto> records =
      <String, AttendanceRecordDto>{};

  @override
  Future<List<AttendanceSessionDto>> fetchSessions(String subjectClassId) async =>
      sessions.values
          .where((s) => s.subjectClassId == subjectClassId)
          .toList(growable: false);

  @override
  Future<AttendanceSessionDto?> fetchSessionById(String sessionId) async =>
      sessions[sessionId];

  @override
  Future<AttendanceSessionDto?> fetchSessionByDate({
    required String subjectClassId,
    required DateTime sessionDate,
  }) async {
    for (final s in sessions.values) {
      if (s.subjectClassId == subjectClassId &&
          s.sessionDate.year == sessionDate.year &&
          s.sessionDate.month == sessionDate.month &&
          s.sessionDate.day == sessionDate.day) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<List<AttendanceRecordDto>> fetchRecordsBySession(
    String sessionId,
  ) async => records.values
      .where((r) => r.sessionId == sessionId)
      .toList(growable: false);

  @override
  Future<AttendanceRecordDto?> fetchRecordById(String recordId) async =>
      records[recordId];

  @override
  Future<AttendanceRecordDto?> fetchRecordByCell({
    required String sessionId,
    required String enrollmentId,
  }) async {
    for (final r in records.values) {
      if (r.sessionId == sessionId && r.enrollmentId == enrollmentId) return r;
    }
    return null;
  }

  @override
  Future<List<AttendanceRecordDto>> fetchRecordsByClass(
    String subjectClassId,
  ) async {
    final sIds = sessions.values
        .where((s) => s.subjectClassId == subjectClassId)
        .map((s) => s.id)
        .toSet();
    return records.values
        .where((r) => sIds.contains(r.sessionId))
        .toList(growable: false);
  }

  @override
  Future<AttendanceSessionDto> createSession({
    String? clientId,
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
    String note = '',
    bool isLocked = false,
  }) async {
    final now = DateTime.now().toUtc();
    final dto = AttendanceSessionDto(
      id: clientId ?? 'srv-sess-${sessions.length + 1}',
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
      isLocked: isLocked,
      note: note,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
    sessions[dto.id] = dto;
    return dto;
  }

  @override
  Future<AttendanceSessionDto> updateSession({
    required String sessionId,
    required String note,
    required bool isLocked,
    required int expectedVersion,
  }) async {
    final existing = sessions[sessionId]!;
    if (existing.version != expectedVersion) {
      throw const ConflictException('session version conflict');
    }
    final updated = AttendanceSessionDto(
      id: existing.id,
      teacherId: existing.teacherId,
      subjectClassId: existing.subjectClassId,
      sessionDate: existing.sessionDate,
      isLocked: isLocked,
      note: note,
      version: expectedVersion + 1,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<List<AttendanceRecordDto>> saveSessionRecords({
    required String teacherId,
    required String sessionId,
    required List<AttendanceRecordInput> inputs,
  }) async {
    final now = DateTime.now().toUtc();
    final saved = <AttendanceRecordDto>[];
    for (final input in inputs) {
      if (input.isUpdate) {
        final existing = records[input.existingRecordId!]!;
        if (existing.version != input.expectedVersion) {
          throw const ConflictException('record version conflict');
        }
        final dto = AttendanceRecordDto(
          id: existing.id,
          teacherId: teacherId,
          sessionId: sessionId,
          enrollmentId: input.enrollmentId,
          status: input.status,
          note: input.note,
          version: input.expectedVersion! + 1,
          updatedAt: now,
        );
        records[dto.id] = dto;
        saved.add(dto);
      } else {
        final dto = AttendanceRecordDto(
          id: input.clientId ?? 'srv-rec-${records.length + 1}',
          teacherId: teacherId,
          sessionId: sessionId,
          enrollmentId: input.enrollmentId,
          status: input.status,
          note: input.note,
          version: 1,
          updatedAt: now,
        );
        records[dto.id] = dto;
        saved.add(dto);
      }
    }
    return saved;
  }

  @override
  Future<AttendanceRuleConfigDto> fetchRuleConfig(String subjectClassId) async =>
      AttendanceRuleConfigDto(
        subjectClassId: subjectClassId,
        absentThresholdPct: 20,
        countLeaveAsAbsent: false,
      );

  @override
  Future<AttendanceRuleConfigDto> updateRuleConfig(
    AttendanceRuleConfig config,
  ) async => fetchRuleConfig(config.subjectClassId);
}

class _FakeGradingRemote implements GradingRemoteDataSource {
  final Map<String, StudentScoreDto> scores = <String, StudentScoreDto>{};
  final List<int?> receivedExpectedVersions = <int?>[];

  @override
  Future<List<StudentScoreDto>> fetchStudentScoresByClass(
    String subjectClassId,
  ) async => scores.values.toList(growable: false);

  @override
  Future<StudentScoreDto?> fetchStudentScoreById(String scoreId) async =>
      scores[scoreId];

  @override
  Future<StudentScoreDto?> fetchStudentScoreByCell({
    required String assignmentId,
    required String enrollmentId,
  }) async {
    for (final s in scores.values) {
      if (s.assignmentId == assignmentId && s.enrollmentId == enrollmentId) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<StudentScoreDto> upsertStudentScore({
    String? clientId,
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    String? existingScoreId,
    int? expectedVersion,
    required SubmissionStatus submissionStatus,
    double? score,
    String note = '',
  }) async {
    receivedExpectedVersions.add(expectedVersion);
    final now = DateTime.now().toUtc();
    if (existingScoreId != null) {
      final existing = scores[existingScoreId]!;
      if (existing.version != expectedVersion) {
        throw const ConflictException('score version conflict');
      }
      final dto = StudentScoreDto(
        id: existing.id,
        teacherId: teacherId,
        assignmentId: assignmentId,
        enrollmentId: enrollmentId,
        submissionStatus: submissionStatus,
        score: score,
        note: note,
        version: expectedVersion! + 1,
        updatedAt: now,
      );
      scores[dto.id] = dto;
      return dto;
    }
    final dto = StudentScoreDto(
      id: clientId ?? 'srv-sc-${scores.length + 1}',
      teacherId: teacherId,
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      submissionStatus: submissionStatus,
      score: score,
      note: note,
      version: 1,
      updatedAt: now,
    );
    scores[dto.id] = dto;
    return dto;
  }

  @override
  Future<List<ScoreCategoryDto>> fetchScoreCategories(String classId) async =>
      const <ScoreCategoryDto>[];

  @override
  Future<List<AssignmentDto>> fetchAssignments(String classId) async =>
      const <AssignmentDto>[];

  @override
  Future<GradingScaleConfigDto> fetchGradingScaleConfig(String classId) async =>
      GradingScaleConfigDto(
        subjectClassId: classId,
        scaleType: GradingScaleType.scale0To4,
        rules: GradingScaleConfig.defaultZeroToFourRules,
        missingWorkThreshold: 3,
      );

  @override
  Future<Map<String, dynamic>?> fetchEnrollmentGradeStatusById(
    String enrollmentId,
  ) async => null;

  @override
  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) async {}

  @override
  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  }) => throw UnimplementedError();

  @override
  Future<int> countScoredStudentsForAssignment(String assignmentId) =>
      throw UnimplementedError();

  @override
  Future<AssignmentDto> createAssignment({
    required String teacherId,
    required String subjectClassId,
    String? categoryId,
    required String title,
    String description = '',
    required double maxScore,
    bool isMandatory = false,
    DateTime? dueDate,
    int? sortOrder,
  }) => throw UnimplementedError();

  @override
  Future<ScoreCategoryDto> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteAssignment(String assignmentId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteScoreCategory(String categoryId) =>
      throw UnimplementedError();

  @override
  Future<StudentPinStatusDto> fetchStudentPinStatus(String id) =>
      throw UnimplementedError();

  @override
  Future<void> resetStudentPin(String id) => throw UnimplementedError();

  @override
  Future<AssignmentDto> updateAssignment({
    required String assignmentId,
    required int expectedVersion,
    String? categoryId,
    required String title,
    required String description,
    required double maxScore,
    required bool isMandatory,
    DateTime? dueDate,
    int? sortOrder,
  }) => throw UnimplementedError();

  @override
  Future<GradingScaleConfigDto> updateGradingScaleConfig(
    GradingScaleConfig config,
  ) => throw UnimplementedError();

  @override
  Future<ScoreCategoryDto> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) => throw UnimplementedError();
}

class _FakeAuthRemote implements AuthRemoteDataSource {
  _FakeAuthRemote(this._userId);

  String? _userId;
  bool signedOutCalled = false;

  @override
  String? get currentUserId => _userId;

  @override
  Future<void> signOut() async {
    signedOutCalled = true;
    _userId = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late LocalCacheStore cacheStore;
  late SyncQueueRepositoryImpl queueRepo;
  late AttendanceLocalDataSourceImpl attendanceLocal;
  late GradingLocalDataSourceImpl gradingLocal;
  late HomeroomRosterLocalDataSourceImpl rosterLocal;
  late DashboardLocalDataSourceImpl dashboardLocal;
  late _FakeDashboardRemote dashboardRemote;
  late _FakeAttendanceRemote attendanceRemote;
  late _FakeGradingRemote gradingRemote;
  late SyncEngineService syncEngine;

  var online = true;
  const teacherId = 'teacher-A';

  setUp(() {
    online = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cacheStore = LocalCacheStore(db);
    queueRepo = SyncQueueRepositoryImpl(
      localDataSource: SyncQueueLocalDataSource(db),
    );
    attendanceLocal = AttendanceLocalDataSourceImpl(db, cacheStore);
    gradingLocal = GradingLocalDataSourceImpl(db, cacheStore);
    rosterLocal = HomeroomRosterLocalDataSourceImpl(cacheStore);
    dashboardLocal = DashboardLocalDataSourceImpl(cacheStore);
    dashboardRemote = _FakeDashboardRemote();
    attendanceRemote = _FakeAttendanceRemote();
    gradingRemote = _FakeGradingRemote();
    syncEngine = SyncEngineService(
      queueRepository: queueRepo,
      remoteExecutor: SyncRemoteExecutorImpl(
        attendanceRemote: attendanceRemote,
        attendanceLocal: attendanceLocal,
        gradingRemote: gradingRemote,
        gradingLocal: gradingLocal,
        homeroomRosterLocal: rosterLocal,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Offline-First Repositories + Drift + SyncEngine Integration', () {
    test('Read Cache Fallback: Dashboard loads from Drift after going offline', () async {
      dashboardRemote.items = const <DashboardClassItemDto>[
        DashboardClassItemDto(
          subjectClassId: 'class-1',
          subjectId: 'sub-1',
          subjectCode: 'ว31101',
          subjectName: 'วิทยาศาสตร์',
          roomName: 'ม.4/1',
          teachingDays: <int>[1, 3],
          isPinned: true,
          activeStudentCount: 35,
          todayAttendance: null,
        ),
      ];
      final repo = DashboardRepositoryImpl(
        remoteDataSource: dashboardRemote,
        localDataSource: dashboardLocal,
        currentTeacherId: () => teacherId,
        isOnline: () => online,
      );

      final today = DateTime(2026, 11, 25);
      final onlineItems = await repo.fetchDashboardClasses(
        termId: 'term-1',
        referenceDate: today,
      );
      expect(onlineItems, hasLength(1));

      // Go offline -> reads cached Dashboard seamlessly
      online = false;
      dashboardRemote.shouldFailNetwork = true;
      final offlineItems = await repo.fetchDashboardClasses(
        termId: 'term-1',
        referenceDate: today,
      );
      expect(offlineItems, hasLength(1));
      expect(offlineItems.first.subjectCode, 'ว31101');
      expect(offlineItems.first.roomName, 'ม.4/1');
      expect(offlineItems.first.activeStudentCount, 35);
    });

    test(
      'Offline Attendance Flow: create session + 4 statuses offline -> Drift isDirty=true -> online sync pushes exact Client UUIDs and empties queue',
      () async {
        final repo = AttendanceRepositoryImpl(
          remoteDataSource: attendanceRemote,
          localDataSource: attendanceLocal,
          syncQueueRepository: queueRepo,
          currentTeacherId: () => teacherId,
          isOnline: () => online,
        );

        online = false;
        final session = await repo.createSession(
          teacherId: teacherId,
          subjectClassId: 'class-1',
          sessionDate: DateTime(2026, 11, 25),
          note: 'สอนออฟไลน์',
        );
        final savedRecords = await repo.saveSessionRecords(
          teacherId: teacherId,
          sessionId: session.id,
          inputs: const <AttendanceRecordInput>[
            AttendanceRecordInput(
              enrollmentId: 'e-1',
              status: AttendanceStatus.present,
            ),
            AttendanceRecordInput(
              enrollmentId: 'e-2',
              status: AttendanceStatus.late,
            ),
            AttendanceRecordInput(
              enrollmentId: 'e-3',
              status: AttendanceStatus.leave,
            ),
            AttendanceRecordInput(
              enrollmentId: 'e-4',
              status: AttendanceStatus.absent,
            ),
          ],
        );

        expect(savedRecords, hasLength(4));
        expect(attendanceRemote.sessions, isEmpty);
        expect(await queueRepo.fetchAllItems(teacherId), hasLength(5));

        final localSessBefore = await (db.select(
          db.localAttendanceSessions,
        )..where((t) => t.id.equals(session.id))).getSingle();
        expect(localSessBefore.isDirty, isTrue);

        // Come back online and sync
        online = true;
        final summary = await syncEngine.syncPendingItems(teacherId: teacherId);
        expect(summary.syncedCount, 5);
        expect(summary.conflictCount, 0);
        expect(await queueRepo.fetchAllItems(teacherId), isEmpty);

        // Remote received exact Client UUIDs
        expect(attendanceRemote.sessions.containsKey(session.id), isTrue);
        expect(attendanceRemote.records.length, 4);
        for (final r in savedRecords) {
          expect(attendanceRemote.records.containsKey(r.id), isTrue);
        }

        // Drift rows now have isDirty == false
        final localSessAfter = await (db.select(
          db.localAttendanceSessions,
        )..where((t) => t.id.equals(session.id))).getSingle();
        expect(localSessAfter.isDirty, isFalse);
      },
    );

    test(
      'Offline Grading Coalescing + Dirty Preservation: 2 offline edits coalesce with expectedVersion=1, remote refresh does NOT clobber dirty local score, and sync updates to v2',
      () async {
        final now = DateTime.utc(2026, 11, 25, 9, 0);
        gradingRemote.scores['sc-1'] = StudentScoreDto(
          id: 'sc-1',
          teacherId: teacherId,
          assignmentId: 'a-1',
          enrollmentId: 'e-1',
          submissionStatus: SubmissionStatus.submitted,
          score: 7.0,
          note: '',
          version: 1,
          updatedAt: now,
        );

        final repo = GradingRepositoryImpl(
          remoteDataSource: gradingRemote,
          localDataSource: gradingLocal,
          homeroomRosterLocalDataSource: rosterLocal,
          syncQueueRepository: queueRepo,
          currentTeacherId: () => teacherId,
          isOnline: () => online,
        );

        // 1) Initial online fetch caches sc-1 (v1, score 7.0) into Drift
        final initial = await repo.fetchStudentScoresByClass('class-1');
        expect(initial.single.score, 7.0);
        expect(initial.single.version, 1);

        // 2) Go offline and edit same cell TWICE (8.0 -> 9.25)
        online = false;
        final edit1 = await repo.upsertStudentScore(
          teacherId: teacherId,
          assignmentId: 'a-1',
          enrollmentId: 'e-1',
          existingScoreId: 'sc-1',
          expectedVersion: 1,
          submissionStatus: SubmissionStatus.submitted,
          score: 8.0,
        );
        expect(edit1.version, 2);

        final edit2 = await repo.upsertStudentScore(
          teacherId: teacherId,
          assignmentId: 'a-1',
          enrollmentId: 'e-1',
          existingScoreId: 'sc-1',
          expectedVersion: 2,
          submissionStatus: SubmissionStatus.submitted,
          score: 9.25,
        );
        expect(edit2.score, 9.25);

        // Queue coalesced into 1 item preserving ORIGINAL expectedVersion = 1
        final queuedItems = await queueRepo.fetchAllItems(teacherId);
        expect(queuedItems, hasLength(1));
        expect(queuedItems.single.expectedVersion, 1);
        expect(queuedItems.single.payload['score'], 9.25);

        // 3) Simulate online fetch BEFORE sync finishes: server still has 7.0,
        //    but dirty local row (9.25) MUST NOT be overwritten!
        online = true;
        final mergedBeforeSync = await repo.fetchStudentScoresByClass('class-1');
        expect(mergedBeforeSync.single.score, 9.25);

        // 4) Sync queue -> remote receives expectedVersion = 1 -> server v2 = 9.25
        final summary = await syncEngine.syncPendingItems(teacherId: teacherId);
        expect(summary.syncedCount, 1);
        expect(gradingRemote.receivedExpectedVersions.last, 1);
        expect(gradingRemote.scores['sc-1']!.score, 9.25);
        expect(gradingRemote.scores['sc-1']!.version, 2);

        final localAfterSync = await (db.select(
          db.localStudentScores,
        )..where((t) => t.id.equals('sc-1'))).getSingle();
        expect(localAfterSync.isDirty, isFalse);
        expect(localAfterSync.version, 2);
        expect(localAfterSync.score, 9.25);
        expect(await queueRepo.fetchAllItems(teacherId), isEmpty);
      },
    );

    test('Auth Sign-Out wipes only signed-out teacher Drift cache and queue', () async {
      await cacheStore.writeJson(
        teacherId: 'teacher-A',
        cacheKey: 'k1',
        entityGroup: 'dashboard',
        jsonPayload: const <String, dynamic>{'v': 1},
      );
      await cacheStore.writeJson(
        teacherId: 'teacher-B',
        cacheKey: 'k1',
        entityGroup: 'dashboard',
        jsonPayload: const <String, dynamic>{'v': 2},
      );

      final fakeAuthRemote = _FakeAuthRemote('teacher-A');
      final authRepo = AuthRepositoryImpl(
        remoteDataSource: fakeAuthRemote,
        onClearTeacherLocalData: db.clearAllDataForTeacher,
      );

      await authRepo.signOut();

      expect(fakeAuthRemote.signedOutCalled, isTrue);
      expect(
        await cacheStore.readJson(teacherId: 'teacher-A', cacheKey: 'k1'),
        isNull,
      );
      expect(
        await cacheStore.readJson(teacherId: 'teacher-B', cacheKey: 'k1'),
        isNotNull,
      );
    });
  });
}
