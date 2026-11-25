import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../attendance/data/datasources/attendance_remote_datasource.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../grading/data/datasources/grading_remote_datasource.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../data/datasources/sync_queue_local_datasource.dart';
import '../../data/datasources/sync_remote_executor_impl.dart';
import '../../data/repositories/sync_queue_repository_impl.dart';
import '../../domain/entities/sync_item_status.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../domain/repositories/sync_remote_executor.dart';
import '../../domain/services/sync_conflict_field_formatter.dart';
import '../../domain/services/sync_engine_service.dart';

/// Live aggregated counts across the signed-in teacher's offline sync queue.
class SyncQueueStatusCounts {
  const SyncQueueStatusCounts({
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.conflictCount = 0,
    this.failedCount = 0,
  });

  static const SyncQueueStatusCounts empty = SyncQueueStatusCounts();

  final int pendingCount;
  final int syncingCount;
  final int conflictCount;
  final int failedCount;

  int get totalAttentionCount =>
      pendingCount + syncingCount + conflictCount + failedCount;

  bool get hasConflicts => conflictCount > 0;

  bool get hasAnyItems => totalAttentionCount > 0;
}

final syncConflictFieldFormatterProvider = Provider<SyncConflictFieldFormatter>(
  (ref) => const SyncConflictFieldFormatter(),
);

final syncQueueLocalDataSourceProvider = Provider<SyncQueueLocalDataSource>((
  ref,
) {
  return SyncQueueLocalDataSource(ref.watch(appDatabaseProvider));
});

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepositoryImpl(
    localDataSource: ref.watch(syncQueueLocalDataSourceProvider),
  );
});

final syncRemoteExecutorProvider = Provider<SyncRemoteExecutor>((ref) {
  final isConfigured = EnvConfig.isSupabaseConfigured;
  return SyncRemoteExecutorImpl(
    attendanceRemote: isConfigured
        ? ref.watch(attendanceRemoteDataSourceProvider)
        : null,
    attendanceLocal: ref.watch(attendanceLocalDataSourceProvider),
    gradingRemote: isConfigured
        ? ref.watch(gradingRemoteDataSourceProvider)
        : null,
    gradingLocal: ref.watch(gradingLocalDataSourceProvider),
    homeroomRosterLocal: ref.watch(homeroomRosterLocalDataSourceProvider),
  );
});

final syncEngineServiceProvider = Provider<SyncEngineService>((ref) {
  return SyncEngineService(
    queueRepository: ref.watch(syncQueueRepositoryProvider),
    remoteExecutor: ref.watch(syncRemoteExecutorProvider),
  );
});

/// Live stream of all queue items belonging to the signed-in teacher.
final syncQueueItemsStreamProvider = StreamProvider<List<SyncQueueItem>>((ref) {
  final userId = ref.watch(authStateProvider.select((s) => s.userId));
  if (userId == null || userId.isEmpty) {
    return Stream<List<SyncQueueItem>>.value(const <SyncQueueItem>[]);
  }
  return ref.watch(syncQueueRepositoryProvider).watchAllItems(userId);
});

/// Live status breakdown derived from [syncQueueItemsStreamProvider].
final syncQueueStatusCountsProvider = Provider<SyncQueueStatusCounts>((ref) {
  final items =
      ref.watch(syncQueueItemsStreamProvider).asData?.value ??
      const <SyncQueueItem>[];
  if (items.isEmpty) return SyncQueueStatusCounts.empty;
  var pending = 0;
  var syncing = 0;
  var conflict = 0;
  var failed = 0;
  for (final item in items) {
    switch (item.status) {
      case SyncItemStatus.pending:
        pending++;
      case SyncItemStatus.syncing:
        syncing++;
      case SyncItemStatus.conflict:
        conflict++;
      case SyncItemStatus.failed:
        failed++;
    }
  }
  return SyncQueueStatusCounts(
    pendingCount: pending,
    syncingCount: syncing,
    conflictCount: conflict,
    failedCount: failed,
  );
});

/// Live stream of queued + conflicted item count for the signed-in teacher
/// (consumed by header badges and `/teacher/sync-queue` in Step 6.3).
final pendingAndConflictCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(authStateProvider.select((s) => s.userId));
  if (userId == null) {
    return Stream<int>.value(0);
  }
  return ref
      .watch(syncQueueRepositoryProvider)
      .watchPendingAndConflictCount(userId);
});

/// Headless coordinator watched by [ChecklistStudentApp] that listens for
/// `offline -> online` transitions on [connectivityStatusProvider] and runs
/// [SyncEngineService.syncPendingItems] automatically, invalidating classroom
/// providers when items succeed.
final syncEngineAutoCoordinatorProvider = Provider<void>((ref) {
  bool? lastOnline;

  Future<void> triggerSync(String teacherId) async {
    final summary = await ref
        .read(syncEngineServiceProvider)
        .syncPendingItems(teacherId: teacherId);
    if (!ref.mounted || summary.syncedCount <= 0) return;

    ref
      ..invalidate(dashboardOverviewProvider)
      ..invalidate(attendanceSessionsProvider)
      ..invalidate(attendanceClassRecordsProvider)
      ..invalidate(studentScoresByClassProvider)
      ..invalidate(classEnrollmentsProvider);
  }

  ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
    final isNowOnline = next.asData?.value;
    if (isNowOnline == null) return;
    final wasOffline = lastOnline == false;
    lastOnline = isNowOnline;
    if (wasOffline && isNowOnline) {
      final teacherId = ref.read(authStateProvider).userId;
      if (teacherId != null && teacherId.isNotEmpty) {
        unawaited(triggerSync(teacherId));
      }
    }
  }, fireImmediately: true);

  // Also drain any leftover pending queue items on app launch when online.
  ref.listen<String?>(
    authStateProvider.select((s) => s.userId),
    (previous, nextUserId) {
      if (nextUserId == null || nextUserId.isEmpty) return;
      final isOnline =
          ref.read(connectivityStatusProvider).asData?.value ?? true;
      if (isOnline) {
        unawaited(triggerSync(nextUserId));
      }
    },
    fireImmediately: true,
  );
});
