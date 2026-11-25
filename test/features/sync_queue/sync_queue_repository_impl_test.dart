import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/database/app_database.dart';
import 'package:checklist_student/features/sync_queue/data/datasources/sync_queue_local_datasource.dart';
import 'package:checklist_student/features/sync_queue/data/repositories/sync_queue_repository_impl.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_entity_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_item_status.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_operation_type.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepositoryImpl repository;
  final t0 = DateTime.utc(2026, 11, 25, 9, 0, 0);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SyncQueueRepositoryImpl(
      localDataSource: SyncQueueLocalDataSource(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncQueueRepositoryImpl (Drift In-Memory SQLite)', () {
    test(
      'coalesces repeated offline updates on the same score cell into 1 row preserving expectedVersion = 1',
      () async {
        final first = await repository.enqueueMutation(
          teacherId: 'teacher-A',
          entityType: SyncEntityType.studentScore,
          entityId: 'score-101',
          displayLabel: 'คะแนน ด.ช.สมชาย — ใบงานที่ 1',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'score': 7.5},
          expectedVersion: 1,
          now: t0,
        );
        expect(first, isNotNull);

        final second = await repository.enqueueMutation(
          teacherId: 'teacher-A',
          entityType: SyncEntityType.studentScore,
          entityId: 'score-101',
          displayLabel: 'คะแนน ด.ช.สมชาย — ใบงานที่ 1',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'score': 9.25},
          expectedVersion: 2,
          now: t0.add(const Duration(seconds: 10)),
        );
        expect(second, isNotNull);
        expect(second!.id, first!.id);

        final all = await repository.fetchAllItems('teacher-A');
        expect(all, hasLength(1));
        expect(all.first.operation, SyncOperationType.update);
        expect(all.first.payload['score'], 9.25);
        expect(all.first.expectedVersion, 1);
      },
    );

    test('create followed by delete removes unsynced item from queue', () async {
      await repository.enqueueMutation(
        teacherId: 'teacher-A',
        entityType: SyncEntityType.attendanceSession,
        entityId: 'sess-local-1',
        displayLabel: 'เช็คชื่อ ม.4/1 (25 พ.ย. 2569)',
        operation: SyncOperationType.create,
        payload: const <String, dynamic>{'session_date': '2026-11-25'},
        now: t0,
      );

      final result = await repository.enqueueMutation(
        teacherId: 'teacher-A',
        entityType: SyncEntityType.attendanceSession,
        entityId: 'sess-local-1',
        displayLabel: 'เช็คชื่อ ม.4/1 (25 พ.ย. 2569)',
        operation: SyncOperationType.delete,
        payload: const <String, dynamic>{},
        now: t0.add(const Duration(seconds: 5)),
      );

      expect(result, isNull);
      expect(await repository.fetchAllItems('teacher-A'), isEmpty);
    });

    test(
      'supports markConflict with serverSnapshotJson, markFailed with backoff, resetItemToPending, and FIFO ready fetch',
      () async {
        final item = (await repository.enqueueMutation(
          teacherId: 'teacher-A',
          entityType: SyncEntityType.studentScore,
          entityId: 'score-202',
          displayLabel: 'คะแนน ด.ญ.มานี — สอบย่อย 1',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'score': 8.5},
          expectedVersion: 2,
          now: t0,
        ))!;

        await repository.markSyncing(
          teacherId: 'teacher-A',
          itemId: item.id,
          now: t0.add(const Duration(seconds: 1)),
        );
        expect(
          await repository.fetchReadyPendingItems('teacher-A', now: t0),
          isEmpty,
        );

        await repository.markFailed(
          teacherId: 'teacher-A',
          itemId: item.id,
          errorMessage: 'เครือข่ายขัดข้อง',
          now: t0.add(const Duration(seconds: 2)),
        );
        final failed = (await repository.fetchAllItems('teacher-A')).single;
        expect(failed.status, SyncItemStatus.failed);
        expect(failed.retryCount, 1);
        expect(
          failed.nextRetryAt,
          t0.add(const Duration(seconds: 7)),
        );

        // Before backoff expires -> not ready; at backoff -> ready
        expect(
          await repository.fetchReadyPendingItems(
            'teacher-A',
            now: t0.add(const Duration(seconds: 6)),
          ),
          isEmpty,
        );
        expect(
          await repository.fetchReadyPendingItems(
            'teacher-A',
            now: t0.add(const Duration(seconds: 7)),
          ),
          hasLength(1),
        );

        await repository.markConflict(
          teacherId: 'teacher-A',
          itemId: item.id,
          errorMessage: 'ข้อมูลถูกแก้ไขจากอุปกรณ์อื่น',
          serverSnapshot: const <String, dynamic>{'score': 9.0, 'version': 3},
          now: t0.add(const Duration(seconds: 10)),
        );
        final conflicted = (await repository.fetchAllItems('teacher-A')).single;
        expect(conflicted.status, SyncItemStatus.conflict);
        expect(conflicted.serverSnapshot, isNotNull);
        expect(conflicted.serverSnapshot!['score'], 9.0);
        expect(conflicted.serverSnapshot!['version'], 3);

        await repository.resetItemToPending(
          teacherId: 'teacher-A',
          itemId: item.id,
          updatedExpectedVersion: 3,
          now: t0.add(const Duration(seconds: 20)),
        );
        final reset = (await repository.fetchAllItems('teacher-A')).single;
        expect(reset.status, SyncItemStatus.pending);
        expect(reset.retryCount, 0);
        expect(reset.nextRetryAt, isNull);
        expect(reset.lastError, isNull);
        expect(reset.serverSnapshot, isNull);
        expect(reset.expectedVersion, 3);

        await repository.markSucceededAndRemove(
          teacherId: 'teacher-A',
          itemId: item.id,
        );
        expect(await repository.fetchAllItems('teacher-A'), isEmpty);
      },
    );

    test(
      'watchPendingAndConflictCount streams live counts and clearForTeacher is multi-tenant isolated',
      () async {
        final stream = repository.watchPendingAndConflictCount('teacher-A');
        final counts = <int>[];
        final sub = stream.listen(counts.add);

        await pumpEventQueue();

        final a1 = (await repository.enqueueMutation(
          teacherId: 'teacher-A',
          entityType: SyncEntityType.attendanceRecord,
          entityId: 'rec-1',
          displayLabel: 'เช็คชื่อ เลขที่ 1',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'status': 'late'},
          expectedVersion: 1,
          now: t0,
        ))!;
        await repository.enqueueMutation(
          teacherId: 'teacher-B',
          entityType: SyncEntityType.attendanceRecord,
          entityId: 'rec-b1',
          displayLabel: 'เช็คชื่อครู B',
          operation: SyncOperationType.update,
          payload: const <String, dynamic>{'status': 'absent'},
          expectedVersion: 1,
          now: t0,
        );
        await pumpEventQueue();

        await repository.markConflict(
          teacherId: 'teacher-A',
          itemId: a1.id,
          errorMessage: 'ชนเวอร์ชัน',
          now: t0.add(const Duration(seconds: 2)),
        );
        await pumpEventQueue();

        expect(counts.first, 0);
        expect(counts.last, 1);

        await repository.clearForTeacher('teacher-A');
        await pumpEventQueue();

        expect(counts.last, 0);
        expect(await repository.fetchAllItems('teacher-A'), isEmpty);
        expect(await repository.fetchAllItems('teacher-B'), hasLength(1));

        await sub.cancel();
      },
    );
  });
}
