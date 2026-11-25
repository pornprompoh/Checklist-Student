import '../entities/sync_entity_type.dart';
import '../entities/sync_item_status.dart';
import '../entities/sync_queue_item.dart';
import '../entities/sync_run_summary.dart';
import '../repositories/sync_queue_repository.dart';
import '../repositories/sync_remote_executor.dart';
import 'sync_retry_policy_service.dart';

/// Pure Dart Background Sync Engine orchestrating dependency-ordered FIFO
/// processing, concurrency mutex, Optimistic Locking conflict capture, and
/// explicit teacher conflict resolution (`Keep Mine` / `Use Server`).
class SyncEngineService {
  SyncEngineService({
    required this.queueRepository,
    required this.remoteExecutor,
    this.retryPolicy = const SyncRetryPolicyService(),
  });

  final SyncQueueRepository queueRepository;
  final SyncRemoteExecutor remoteExecutor;
  final SyncRetryPolicyService retryPolicy;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Processes all ready `pending` / `failed` items for [teacherId] in strict
  /// dependency order (`attendanceSession` -> `attendanceRecord` ->
  /// `studentScore` -> `specialGradeStatus`) then FIFO (`createdAt ASC`).
  Future<SyncRunSummary> syncPendingItems({
    required String teacherId,
    DateTime? now,
  }) async {
    if (_isSyncing) {
      final all = await queueRepository.fetchAllItems(teacherId);
      final remaining = all
          .where(
            (i) =>
                i.status == SyncItemStatus.pending ||
                i.status == SyncItemStatus.failed,
          )
          .length;
      return SyncRunSummary(
        syncedCount: 0,
        conflictCount: 0,
        failedCount: 0,
        remainingPendingCount: remaining,
        wasSkippedDueToLock: true,
      );
    }

    _isSyncing = true;
    var syncedCount = 0;
    var conflictCount = 0;
    var failedCount = 0;

    try {
      final referenceNow = (now ?? DateTime.now()).toUtc();
      final ready = await queueRepository.fetchReadyPendingItems(
        teacherId,
        now: referenceNow,
      );
      final ordered = List<SyncQueueItem>.of(ready)..sort(_compareExecutionOrder);

      for (final item in ordered) {
        await queueRepository.markSyncing(
          teacherId: teacherId,
          itemId: item.id,
          now: referenceNow,
        );

        final result = await remoteExecutor.executeItem(item);
        switch (result.outcome) {
          case SyncExecutionOutcome.synced:
            await queueRepository.markSucceededAndRemove(
              teacherId: teacherId,
              itemId: item.id,
            );
            syncedCount++;
          case SyncExecutionOutcome.conflict:
            await queueRepository.markConflict(
              teacherId: teacherId,
              itemId: item.id,
              errorMessage:
                  result.errorMessage ??
                  'ข้อมูลถูกแก้ไขจากอุปกรณ์อื่น กรุณาตรวจสอบและเลือกค่าที่ต้องการ',
              serverSnapshot: result.serverSnapshot,
              now: referenceNow,
            );
            conflictCount++;
          case SyncExecutionOutcome.transientError:
          case SyncExecutionOutcome.fatalError:
            await queueRepository.markFailed(
              teacherId: teacherId,
              itemId: item.id,
              errorMessage:
                  result.errorMessage ?? 'ซิงค์ข้อมูลไม่สำเร็จ ระบบจะลองใหม่อัตโนมัติ',
              now: referenceNow,
            );
            failedCount++;
        }
      }

      final afterAll = await queueRepository.fetchAllItems(teacherId);
      final remaining = afterAll
          .where(
            (i) =>
                i.status == SyncItemStatus.pending ||
                i.status == SyncItemStatus.failed,
          )
          .length;

      return SyncRunSummary(
        syncedCount: syncedCount,
        conflictCount: conflictCount,
        failedCount: failedCount,
        remainingPendingCount: remaining,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Resolves a conflicted queue item by intentionally overwriting the server
  /// with the teacher's local payload using the latest `version` from
  /// `item.serverSnapshot`.
  Future<SyncExecutionResult> resolveConflictKeepMine({
    required String teacherId,
    required String itemId,
    DateTime? now,
  }) async {
    final referenceNow = (now ?? DateTime.now()).toUtc();
    final items = await queueRepository.fetchAllItems(teacherId);
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) {
      return const SyncExecutionResult.fatalError(
        'ไม่พบรายการคิวที่ต้องการแก้ไขความขัดแย้ง',
      );
    }

    final snapshotVersion = (item.serverSnapshot?['version'] as num?)?.toInt();
    final targetVersion = snapshotVersion ?? item.expectedVersion;

    await queueRepository.markSyncing(
      teacherId: teacherId,
      itemId: item.id,
      now: referenceNow,
    );

    final result = await remoteExecutor.executeItem(
      item,
      overrideExpectedVersion: targetVersion,
    );
    switch (result.outcome) {
      case SyncExecutionOutcome.synced:
        await queueRepository.markSucceededAndRemove(
          teacherId: teacherId,
          itemId: item.id,
        );
      case SyncExecutionOutcome.conflict:
        await queueRepository.markConflict(
          teacherId: teacherId,
          itemId: item.id,
          errorMessage:
              result.errorMessage ?? 'ข้อมูลบนเซิร์ฟเวอร์มีการเปลี่ยนแปลงอีกครั้ง',
          serverSnapshot: result.serverSnapshot ?? item.serverSnapshot,
          now: referenceNow,
        );
      case SyncExecutionOutcome.transientError:
      case SyncExecutionOutcome.fatalError:
        await queueRepository.markConflict(
          teacherId: teacherId,
          itemId: item.id,
          errorMessage:
              result.errorMessage ?? 'ไม่สามารถบันทึกทับข้อมูลบนเซิร์ฟเวอร์ได้',
          serverSnapshot: item.serverSnapshot,
          now: referenceNow,
        );
    }
    return result;
  }

  /// Resolves a conflicted queue item by discarding the local offline edit and
  /// restoring the latest authoritative `serverSnapshot` into local Drift.
  Future<void> resolveConflictUseServer({
    required String teacherId,
    required String itemId,
  }) async {
    final items = await queueRepository.fetchAllItems(teacherId);
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;

    final snapshot = item.serverSnapshot;
    if (snapshot != null) {
      await remoteExecutor.applyServerSnapshotLocally(item, snapshot);
    }
    await queueRepository.removeItem(teacherId: teacherId, itemId: item.id);
  }

  static int _dependencyRank(SyncEntityType type) => switch (type) {
    SyncEntityType.attendanceSession => 0,
    SyncEntityType.attendanceRecord => 1,
    SyncEntityType.studentScore => 2,
    SyncEntityType.specialGradeStatus => 3,
  };

  static int _compareExecutionOrder(SyncQueueItem a, SyncQueueItem b) {
    final rankDiff = _dependencyRank(a.entityType) - _dependencyRank(b.entityType);
    if (rankDiff != 0) return rankDiff;
    final timeDiff = a.createdAt.compareTo(b.createdAt);
    if (timeDiff != 0) return timeDiff;
    return a.id.compareTo(b.id);
  }
}
