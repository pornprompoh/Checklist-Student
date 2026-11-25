/// Summary of one background synchronization pass over a teacher's queue.
///
/// Pure Dart value object.
class SyncRunSummary {
  const SyncRunSummary({
    required this.syncedCount,
    required this.conflictCount,
    required this.failedCount,
    required this.remainingPendingCount,
    this.wasSkippedDueToLock = false,
  });

  final int syncedCount;
  final int conflictCount;
  final int failedCount;
  final int remainingPendingCount;
  final bool wasSkippedDueToLock;

  bool get hasAnyChange => syncedCount > 0 || conflictCount > 0;
}
