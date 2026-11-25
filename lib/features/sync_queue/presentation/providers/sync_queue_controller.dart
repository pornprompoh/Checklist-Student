import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../domain/entities/sync_run_summary.dart';
import '../../domain/repositories/sync_remote_executor.dart';
import 'sync_queue_providers.dart';

/// UI action state for `/teacher/sync-queue` (manual sync trigger, per-item
/// loading guards, and last sync summary feedback).
class SyncQueueActionState {
  const SyncQueueActionState({
    this.isSyncingNow = false,
    this.busyItemIds = const <String>{},
    this.lastRunSummary,
    this.lastFeedbackMessage,
  });

  final bool isSyncingNow;
  final Set<String> busyItemIds;
  final SyncRunSummary? lastRunSummary;
  final String? lastFeedbackMessage;

  static const Object _sentinel = Object();

  bool isItemBusy(String itemId) => busyItemIds.contains(itemId);

  SyncQueueActionState copyWith({
    bool? isSyncingNow,
    Set<String>? busyItemIds,
    Object? lastRunSummary = _sentinel,
    Object? lastFeedbackMessage = _sentinel,
  }) {
    return SyncQueueActionState(
      isSyncingNow: isSyncingNow ?? this.isSyncingNow,
      busyItemIds: busyItemIds ?? this.busyItemIds,
      lastRunSummary: identical(lastRunSummary, _sentinel)
          ? this.lastRunSummary
          : lastRunSummary as SyncRunSummary?,
      lastFeedbackMessage: identical(lastFeedbackMessage, _sentinel)
          ? this.lastFeedbackMessage
          : lastFeedbackMessage as String?,
    );
  }
}

/// Controller coordinating manual sync runs, single-item retry/discard, and
/// teacher-approved conflict resolution (`Keep Mine` / `Use Server`).
class SyncQueueController extends Notifier<SyncQueueActionState> {
  @override
  SyncQueueActionState build() => const SyncQueueActionState();

  Future<SyncRunSummary?> syncNow() async {
    final teacherId = ref.read(authStateProvider).userId;
    if (teacherId == null || teacherId.isEmpty || state.isSyncingNow) {
      return null;
    }
    state = state.copyWith(isSyncingNow: true, lastFeedbackMessage: null);
    try {
      final summary = await ref
          .read(syncEngineServiceProvider)
          .syncPendingItems(teacherId: teacherId);
      if (summary.syncedCount > 0) {
        _invalidateClassroomProviders();
      }
      if (!ref.mounted) return summary;
      state = state.copyWith(
        isSyncingNow: false,
        lastRunSummary: summary,
        lastFeedbackMessage: _formatRunSummary(summary),
      );
      return summary;
    } catch (error) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isSyncingNow: false,
        lastFeedbackMessage: ThaiErrorMapper.map(error),
      );
      return null;
    }
  }

  Future<String?> retryItem(String itemId) async {
    final teacherId = ref.read(authStateProvider).userId;
    if (teacherId == null || teacherId.isEmpty || state.isItemBusy(itemId)) {
      return null;
    }
    _setItemBusy(itemId, true);
    try {
      await ref
          .read(syncQueueRepositoryProvider)
          .resetItemToPending(teacherId: teacherId, itemId: itemId);
      final isOnline =
          ref.read(connectivityStatusProvider).asData?.value ?? true;
      if (isOnline) {
        final summary = await syncNow();
        return summary == null ? null : _formatRunSummary(summary);
      }
      return 'นำรายการกลับเข้าคิวรอซิงค์แล้ว ระบบจะส่งอัตโนมัติเมื่อออนไลน์';
    } catch (error) {
      return ThaiErrorMapper.map(error);
    } finally {
      _setItemBusy(itemId, false);
    }
  }

  Future<SyncExecutionResult?> resolveConflictKeepMine(String itemId) async {
    final teacherId = ref.read(authStateProvider).userId;
    if (teacherId == null || teacherId.isEmpty || state.isItemBusy(itemId)) {
      return null;
    }
    _setItemBusy(itemId, true);
    try {
      final result = await ref
          .read(syncEngineServiceProvider)
          .resolveConflictKeepMine(teacherId: teacherId, itemId: itemId);
      if (result.isSynced) {
        _invalidateClassroomProviders();
      }
      return result;
    } finally {
      _setItemBusy(itemId, false);
    }
  }

  Future<void> resolveConflictUseServer(String itemId) async {
    final teacherId = ref.read(authStateProvider).userId;
    if (teacherId == null || teacherId.isEmpty || state.isItemBusy(itemId)) {
      return;
    }
    _setItemBusy(itemId, true);
    try {
      await ref
          .read(syncEngineServiceProvider)
          .resolveConflictUseServer(teacherId: teacherId, itemId: itemId);
      _invalidateClassroomProviders();
    } finally {
      _setItemBusy(itemId, false);
    }
  }

  Future<void> discardItem(String itemId) async {
    final teacherId = ref.read(authStateProvider).userId;
    if (teacherId == null || teacherId.isEmpty || state.isItemBusy(itemId)) {
      return;
    }
    _setItemBusy(itemId, true);
    try {
      await ref
          .read(syncQueueRepositoryProvider)
          .removeItem(teacherId: teacherId, itemId: itemId);
      _invalidateClassroomProviders();
    } finally {
      _setItemBusy(itemId, false);
    }
  }

  void _setItemBusy(String itemId, bool busy) {
    if (!ref.mounted) return;
    final next = Set<String>.of(state.busyItemIds);
    if (busy) {
      next.add(itemId);
    } else {
      next.remove(itemId);
    }
    state = state.copyWith(busyItemIds: Set<String>.unmodifiable(next));
  }

  void _invalidateClassroomProviders() {
    ref
      ..invalidate(dashboardOverviewProvider)
      ..invalidate(attendanceSessionsProvider)
      ..invalidate(attendanceClassRecordsProvider)
      ..invalidate(studentScoresByClassProvider)
      ..invalidate(classEnrollmentsProvider);
  }

  String _formatRunSummary(SyncRunSummary summary) {
    if (summary.wasSkippedDueToLock) {
      return 'กำลังซิงค์ข้อมูลอยู่ในขณะนี้';
    }
    final parts = <String>[];
    if (summary.syncedCount > 0) {
      parts.add('ซิงค์สำเร็จ ${summary.syncedCount} รายการ');
    }
    if (summary.conflictCount > 0) {
      parts.add('ข้อมูลชนกัน ${summary.conflictCount} รายการ');
    }
    if (summary.failedCount > 0) {
      parts.add('ล้มเหลว ${summary.failedCount} รายการ');
    }
    if (parts.isEmpty) {
      return 'ไม่มีรายการที่พร้อมซิงค์ในขณะนี้';
    }
    return parts.join(' · ');
  }
}

final syncQueueControllerProvider =
    NotifierProvider<SyncQueueController, SyncQueueActionState>(
      SyncQueueController.new,
    );
