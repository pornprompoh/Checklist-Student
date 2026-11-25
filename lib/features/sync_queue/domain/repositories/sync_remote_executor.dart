import '../entities/sync_queue_item.dart';

/// Outcome classification returned by [SyncRemoteExecutor.executeItem].
enum SyncExecutionOutcome { synced, conflict, transientError, fatalError }

/// Structured outcome of executing a single [SyncQueueItem] against the backend.
///
/// Pure Dart value object.
class SyncExecutionResult {
  const SyncExecutionResult._({
    required this.outcome,
    this.errorMessage,
    this.serverSnapshot,
  });

  const SyncExecutionResult.synced() : this._(outcome: SyncExecutionOutcome.synced);

  const SyncExecutionResult.conflict({
    required String message,
    Map<String, dynamic>? serverSnapshot,
  }) : this._(
         outcome: SyncExecutionOutcome.conflict,
         errorMessage: message,
         serverSnapshot: serverSnapshot,
       );

  const SyncExecutionResult.transientError(String message)
    : this._(outcome: SyncExecutionOutcome.transientError, errorMessage: message);

  const SyncExecutionResult.fatalError(String message)
    : this._(outcome: SyncExecutionOutcome.fatalError, errorMessage: message);

  final SyncExecutionOutcome outcome;
  final String? errorMessage;
  final Map<String, dynamic>? serverSnapshot;

  bool get isSynced => outcome == SyncExecutionOutcome.synced;
  bool get isConflict => outcome == SyncExecutionOutcome.conflict;
}

/// Abstract backend executor invoked by [SyncEngineService].
///
/// Pure Dart interface (zero Flutter, Drift, or Supabase imports).
abstract interface class SyncRemoteExecutor {
  /// Sends [item] to the backend and updates local Drift storage (`isDirty = false`)
  /// upon success. When [overrideExpectedVersion] is provided (during explicit
  /// conflict resolution), uses that server version for Optimistic Locking.
  Future<SyncExecutionResult> executeItem(
    SyncQueueItem item, {
    int? overrideExpectedVersion,
  });

  /// Writes [serverSnapshot] over the local Drift cache (`isDirty = false`)
  /// when the teacher chooses `"ใช้ข้อมูลล่าสุดจากเซิร์ฟเวอร์"`.
  Future<void> applyServerSnapshotLocally(
    SyncQueueItem item,
    Map<String, dynamic> serverSnapshot,
  );
}
