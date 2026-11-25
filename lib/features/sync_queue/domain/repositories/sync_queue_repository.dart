import '../entities/sync_entity_type.dart';
import '../entities/sync_operation_type.dart';
import '../entities/sync_queue_item.dart';

/// Domain repository contract for managing the persistent offline sync queue.
///
/// Pure Dart interface (zero Flutter, Drift, or Supabase dependencies).
abstract interface class SyncQueueRepository {
  /// Enqueues an offline mutation, automatically coalescing with any existing
  /// `pending` or `failed` queue item for the same `(entityType, entityId)`.
  ///
  /// Returns `null` if an unsynced `create` was cancelled out by a `delete`.
  Future<SyncQueueItem?> enqueueMutation({
    required String teacherId,
    required SyncEntityType entityType,
    required String entityId,
    required String displayLabel,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
    int? expectedVersion,
    DateTime? now,
  });

  Future<List<SyncQueueItem>> fetchAllItems(String teacherId);

  Stream<List<SyncQueueItem>> watchAllItems(String teacherId);

  /// Emits the live count of items requiring attention (`pending`, `syncing`,
  /// `failed`, and `conflict`) for header badges and sync indicators.
  Stream<int> watchPendingAndConflictCount(String teacherId);

  /// Returns `pending` / `failed` items eligible to run right now (respecting
  /// `maxRetryCount` and `nextRetryAt`) in FIFO (`createdAt ASC`) order.
  Future<List<SyncQueueItem>> fetchReadyPendingItems(
    String teacherId, {
    DateTime? now,
  });

  Future<void> markSyncing({
    required String teacherId,
    required String itemId,
    DateTime? now,
  });

  Future<void> markSucceededAndRemove({
    required String teacherId,
    required String itemId,
  });

  Future<void> markConflict({
    required String teacherId,
    required String itemId,
    required String errorMessage,
    Map<String, dynamic>? serverSnapshot,
    DateTime? now,
  });

  Future<void> markFailed({
    required String teacherId,
    required String itemId,
    required String errorMessage,
    DateTime? now,
  });

  Future<void> resetItemToPending({
    required String teacherId,
    required String itemId,
    int? updatedExpectedVersion,
    Map<String, dynamic>? updatedPayload,
    DateTime? now,
  });

  Future<void> removeItem({required String teacherId, required String itemId});

  Future<void> clearForTeacher(String teacherId);
}
