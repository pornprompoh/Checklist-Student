import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/database/app_database.dart';
import 'package:checklist_student/features/sync_queue/data/datasources/sync_queue_local_datasource.dart';
import 'package:checklist_student/features/sync_queue/data/repositories/sync_queue_repository_impl.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_entity_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_item_status.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_operation_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_queue_item.dart';
import 'package:checklist_student/features/sync_queue/domain/repositories/sync_remote_executor.dart';
import 'package:checklist_student/features/sync_queue/domain/services/sync_engine_service.dart';

class _FakeSyncRemoteExecutor implements SyncRemoteExecutor {
  final List<SyncEntityType> executedOrder = <SyncEntityType>[];
  final List<int?> overrideVersionsUsed = <int?>[];
  final List<Map<String, dynamic>> appliedSnapshots = <Map<String, dynamic>>[];

  Future<SyncExecutionResult> Function(
    SyncQueueItem item,
    int? overrideExpectedVersion,
  )? onExecute;

  @override
  Future<SyncExecutionResult> executeItem(
    SyncQueueItem item, {
    int? overrideExpectedVersion,
  }) async {
    executedOrder.add(item.entityType);
    overrideVersionsUsed.add(overrideExpectedVersion);
    if (onExecute != null) {
      return onExecute!(item, overrideExpectedVersion);
    }
    return const SyncExecutionResult.synced();
  }

  @override
  Future<void> applyServerSnapshotLocally(
    SyncQueueItem item,
    Map<String, dynamic> serverSnapshot,
  ) async {
    appliedSnapshots.add(serverSnapshot);
  }
}

void main() {
  late AppDatabase db;
  late SyncQueueRepositoryImpl queueRepo;
  late _FakeSyncRemoteExecutor executor;
  late SyncEngineService engine;
  final t0 = DateTime.utc(2026, 11, 25, 10, 0, 0);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queueRepo = SyncQueueRepositoryImpl(
      localDataSource: SyncQueueLocalDataSource(db),
    );
    executor = _FakeSyncRemoteExecutor();
    engine = SyncEngineService(
      queueRepository: queueRepo,
      remoteExecutor: executor,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngineService', () {
    test(
      'executes queued items in strict dependency order (session -> record -> score -> specialGrade)',
      () async {
        // Enqueue intentionally in reverse timestamp order to prove dependency rank wins.
        await queueRepo.enqueueMutation(
          teacherId: 't-1',
          entityType: SyncEntityType.specialGradeStatus,
          entityId: 'enr-1',
          displayLabel: 'เกรดพิเศษ',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'special_grade_override': 'ร'},
          expectedVersion: 1,
          now: t0,
        );
        await queueRepo.enqueueMutation(
          teacherId: 't-1',
          entityType: SyncEntityType.studentScore,
          entityId: 'score-1',
          displayLabel: 'คะแนน',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'score': 8.5},
          expectedVersion: 1,
          now: t0.add(const Duration(seconds: 1)),
        );
        await queueRepo.enqueueMutation(
          teacherId: 't-1',
          entityType: SyncEntityType.attendanceRecord,
          entityId: 'rec-1',
          displayLabel: 'เช็คชื่อ',
          operation: SyncOperationType.create,
          payload: const <String, dynamic>{'status': 'present'},
          now: t0.add(const Duration(seconds: 2)),
        );
        await queueRepo.enqueueMutation(
          teacherId: 't-1',
          entityType: SyncEntityType.attendanceSession,
          entityId: 'sess-1',
          displayLabel: 'คาบเช็คชื่อ',
          operation: SyncOperationType.create,
          payload: const <String, dynamic>{'session_date': '2026-11-25'},
          now: t0.add(const Duration(seconds: 3)),
        );

        final summary = await engine.syncPendingItems(
          teacherId: 't-1',
          now: t0.add(const Duration(seconds: 10)),
        );

        expect(summary.syncedCount, 4);
        expect(summary.conflictCount, 0);
        expect(summary.failedCount, 0);
        expect(summary.remainingPendingCount, 0);
        expect(executor.executedOrder, const <SyncEntityType>[
          SyncEntityType.attendanceSession,
          SyncEntityType.attendanceRecord,
          SyncEntityType.studentScore,
          SyncEntityType.specialGradeStatus,
        ]);
        expect(await queueRepo.fetchAllItems('t-1'), isEmpty);
      },
    );

    test(
      'transient error marks item failed with incremented retryCount and backoff nextRetryAt',
      () async {
        await queueRepo.enqueueMutation(
          teacherId: 't-1',
          entityType: SyncEntityType.studentScore,
          entityId: 'score-1',
          displayLabel: 'คะแนน 8.5',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'score': 8.5},
          expectedVersion: 1,
          now: t0,
        );
        executor.onExecute = (_, _) async =>
            const SyncExecutionResult.transientError('ไม่สามารถติดต่อเซิร์ฟเวอร์');

        final syncTime = t0.add(const Duration(seconds: 10));
        final summary = await engine.syncPendingItems(
          teacherId: 't-1',
          now: syncTime,
        );

        expect(summary.failedCount, 1);
        expect(summary.remainingPendingCount, 1);

        final item = (await queueRepo.fetchAllItems('t-1')).single;
        expect(item.status, SyncItemStatus.failed);
        expect(item.retryCount, 1);
        expect(item.nextRetryAt, syncTime.add(const Duration(seconds: 5)));
      },
    );

    test(
      'ConflictException records conflict status + serverSnapshot (never overwrites silently) and supports Keep Mine / Use Server',
      () async {
        final queued = (await queueRepo.enqueueMutation(
          teacherId: 't-1',
          entityType: SyncEntityType.studentScore,
          entityId: 'score-77',
          displayLabel: 'คะแนน ด.ช.สมชาย',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'score': 9.25},
          expectedVersion: 2,
          now: t0,
        ))!;

        executor.onExecute = (_, overrideVersion) async {
          if (overrideVersion == null) {
            return const SyncExecutionResult.conflict(
              message: 'ข้อมูลถูกแก้ไขจากอุปกรณ์อื่น',
              serverSnapshot: <String, dynamic>{
                'id': 'score-77',
                'score': 8.0,
                'version': 4,
              },
            );
          }
          expect(overrideVersion, 4);
          return const SyncExecutionResult.synced();
        };

        final summary = await engine.syncPendingItems(
          teacherId: 't-1',
          now: t0.add(const Duration(seconds: 5)),
        );
        expect(summary.conflictCount, 1);
        expect(summary.syncedCount, 0);

        final conflicted = (await queueRepo.fetchAllItems('t-1')).single;
        expect(conflicted.status, SyncItemStatus.conflict);
        expect(conflicted.serverSnapshot?['score'], 8.0);
        expect(conflicted.serverSnapshot?['version'], 4);

        // Resolve via Keep Mine -> sends overrideExpectedVersion = 4 and removes from queue.
        final keepMineResult = await engine.resolveConflictKeepMine(
          teacherId: 't-1',
          itemId: queued.id,
          now: t0.add(const Duration(seconds: 20)),
        );
        expect(keepMineResult.isSynced, isTrue);
        expect(executor.overrideVersionsUsed.last, 4);
        expect(await queueRepo.fetchAllItems('t-1'), isEmpty);

        // Now test resolveConflictUseServer on a second conflicted item.
        final queued2 = (await queueRepo.enqueueMutation(
          teacherId: 't-1',
          entityType: SyncEntityType.studentScore,
          entityId: 'score-88',
          displayLabel: 'คะแนน ด.ญ.มานี',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'score': 6.0},
          expectedVersion: 1,
          now: t0,
        ))!;
        await queueRepo.markConflict(
          teacherId: 't-1',
          itemId: queued2.id,
          errorMessage: 'ชนเวอร์ชัน',
          serverSnapshot: const <String, dynamic>{
            'id': 'score-88',
            'score': 7.5,
            'version': 3,
          },
          now: t0,
        );

        await engine.resolveConflictUseServer(
          teacherId: 't-1',
          itemId: queued2.id,
        );
        expect(executor.appliedSnapshots, hasLength(1));
        expect(executor.appliedSnapshots.single['score'], 7.5);
        expect(await queueRepo.fetchAllItems('t-1'), isEmpty);
      },
    );

    test('mutex prevents concurrent syncPendingItems passes from double-executing', () async {
      await queueRepo.enqueueMutation(
        teacherId: 't-1',
        entityType: SyncEntityType.studentScore,
        entityId: 'score-lock',
        displayLabel: 'คะแนน',
        operation: SyncOperationType.update,
        payload: const <String, dynamic>{'score': 9.0},
        expectedVersion: 1,
        now: t0,
      );

      final gate = Completer<void>();
      executor.onExecute = (_, _) async {
        await gate.future;
        return const SyncExecutionResult.synced();
      };

      final firstFuture = engine.syncPendingItems(teacherId: 't-1', now: t0);
      await pumpEventQueue();
      expect(engine.isSyncing, isTrue);

      final secondSummary = await engine.syncPendingItems(
        teacherId: 't-1',
        now: t0,
      );
      expect(secondSummary.wasSkippedDueToLock, isTrue);
      expect(secondSummary.syncedCount, 0);

      gate.complete();
      final firstSummary = await firstFuture;
      expect(firstSummary.syncedCount, 1);
      expect(executor.executedOrder, hasLength(1));
    });
  });
}
