import '../entities/sync_item_status.dart';
import '../entities/sync_operation_type.dart';
import '../entities/sync_queue_item.dart';

/// Result of coalescing an incoming offline mutation onto an existing queued
/// item for the same `(entityType, entityId)`.
class CoalescedSyncMutation {
  const CoalescedSyncMutation({
    required this.shouldDropFromQueue,
    required this.operation,
    required this.payload,
    required this.expectedVersion,
    required this.displayLabel,
  });

  /// `true` when an unsynced `create` is cancelled by a subsequent `delete`.
  final bool shouldDropFromQueue;
  final SyncOperationType operation;
  final Map<String, dynamic> payload;
  final int? expectedVersion;
  final String displayLabel;
}

/// Pure Dart retry backoff and offline mutation coalescing policy service.
///
/// Prevents duplicate network writes and preserves the original pre-edit
/// `expectedVersion` so Optimistic Locking remains sound across repeated
/// offline edits.
class SyncRetryPolicyService {
  const SyncRetryPolicyService();

  static const int maxRetryCount = 5;

  static const List<Duration> backoffSchedule = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
    Duration(seconds: 120),
    Duration(seconds: 300),
  ];

  /// Computes the exponential backoff delay for [retryCount] (1-based failure
  /// count: `1 -> 5s`, `2 -> 15s`, `3 -> 45s`, `4 -> 120s`, `>= 5 -> 300s`).
  Duration computeBackoffDelay(int retryCount) {
    if (retryCount <= 1) return backoffSchedule.first;
    final index = retryCount - 1;
    if (index >= backoffSchedule.length) return backoffSchedule.last;
    return backoffSchedule[index];
  }

  /// Computes the next automatic retry timestamp for [newRetryCount], or `null`
  /// if retries are exhausted (`newRetryCount >= maxRetryCount`).
  DateTime? computeNextRetryAt(int newRetryCount, {DateTime? now}) {
    if (newRetryCount >= maxRetryCount) return null;
    final reference = (now ?? DateTime.now()).toUtc();
    return reference.add(computeBackoffDelay(newRetryCount));
  }

  /// Returns `true` when [item] is eligible to be picked up by the sync engine
  /// at [now].
  bool canRetry(SyncQueueItem item, {DateTime? now}) {
    if (item.status != SyncItemStatus.pending &&
        item.status != SyncItemStatus.failed) {
      return false;
    }
    if (item.retryCount >= maxRetryCount) {
      return false;
    }
    final nextRetryAt = item.nextRetryAt;
    if (nextRetryAt == null) {
      return true;
    }
    final reference = (now ?? DateTime.now()).toUtc();
    return !reference.isBefore(nextRetryAt.toUtc());
  }

  /// Coalesces an incoming mutation onto an existing unsynced queue item for
  /// the same `(entityType, entityId)` while preserving Optimistic Locking
  /// semantics.
  CoalescedSyncMutation coalesce({
    required SyncQueueItem existing,
    required SyncOperationType incomingOperation,
    required Map<String, dynamic> incomingPayload,
    required int? incomingExpectedVersion,
    required String incomingDisplayLabel,
  }) {
    final normalizedPayload = Map<String, dynamic>.unmodifiable(
      incomingPayload,
    );

    if (existing.operation == SyncOperationType.create) {
      if (incomingOperation == SyncOperationType.delete) {
        return CoalescedSyncMutation(
          shouldDropFromQueue: true,
          operation: SyncOperationType.delete,
          payload: const <String, dynamic>{},
          expectedVersion: null,
          displayLabel: incomingDisplayLabel,
        );
      }
      return CoalescedSyncMutation(
        shouldDropFromQueue: false,
        operation: SyncOperationType.create,
        payload: normalizedPayload,
        expectedVersion: null,
        displayLabel: incomingDisplayLabel,
      );
    }

    if (existing.operation == SyncOperationType.update) {
      final preservedVersion =
          existing.expectedVersion ?? incomingExpectedVersion;
      if (incomingOperation == SyncOperationType.delete) {
        return CoalescedSyncMutation(
          shouldDropFromQueue: false,
          operation: SyncOperationType.delete,
          payload: normalizedPayload,
          expectedVersion: preservedVersion,
          displayLabel: incomingDisplayLabel,
        );
      }
      return CoalescedSyncMutation(
        shouldDropFromQueue: false,
        operation: SyncOperationType.update,
        payload: normalizedPayload,
        expectedVersion: preservedVersion,
        displayLabel: incomingDisplayLabel,
      );
    }

    // Existing operation is `delete`:
    final preservedVersion =
        existing.expectedVersion ?? incomingExpectedVersion;
    if (incomingOperation == SyncOperationType.delete) {
      return CoalescedSyncMutation(
        shouldDropFromQueue: false,
        operation: SyncOperationType.delete,
        payload: normalizedPayload,
        expectedVersion: preservedVersion,
        displayLabel: incomingDisplayLabel,
      );
    }
    return CoalescedSyncMutation(
      shouldDropFromQueue: false,
      operation: SyncOperationType.update,
      payload: normalizedPayload,
      expectedVersion: preservedVersion,
      displayLabel: incomingDisplayLabel,
    );
  }
}
