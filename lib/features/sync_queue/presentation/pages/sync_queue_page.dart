import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../domain/entities/sync_item_status.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../providers/sync_queue_controller.dart';
import '../providers/sync_queue_providers.dart';
import '../widgets/sync_conflict_resolution_dialog.dart';
import '../widgets/sync_queue_item_card.dart';
import '../widgets/sync_status_summary_header.dart';

enum _SyncQueueFilter { all, conflict, pending, failed }

/// Real-time offline sync queue status & conflict resolution page
/// (`/teacher/sync-queue`).
class SyncQueuePage extends ConsumerStatefulWidget {
  const SyncQueuePage({super.key});

  @override
  ConsumerState<SyncQueuePage> createState() => _SyncQueuePageState();
}

class _SyncQueuePageState extends ConsumerState<SyncQueuePage> {
  final ScrollController _listScrollController = ScrollController();
  _SyncQueueFilter _filter = _SyncQueueFilter.all;

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(syncQueueItemsStreamProvider);
    final counts = ref.watch(syncQueueStatusCountsProvider);
    final actionState = ref.watch(syncQueueControllerProvider);
    final isOnline =
        ref.watch(connectivityStatusProvider).asData?.value ?? true;
    final controller = ref.read(syncQueueControllerProvider.notifier);

    final hasRunnableItems = (counts.pendingCount + counts.failedCount) > 0;
    final canPressSync = isOnline && !actionState.isSyncingNow && hasRunnableItems;
    final syncTooltip = !isOnline
        ? 'ไม่สามารถซิงค์ได้ขณะออฟไลน์ กรุณาเชื่อมต่ออินเทอร์เน็ต'
        : (!hasRunnableItems ? 'ไม่มีรายการรอซิงค์' : 'ซิงค์รายการที่ค้างทันที');

    final pageHeader = AppPageHeader(
      title: 'สถานะการซิงค์ข้อมูลออฟไลน์',
      actions: [
        Tooltip(
          message: syncTooltip,
          child: FilledButton.icon(
            onPressed: canPressSync
                ? () async {
                    final summary = await controller.syncNow();
                    if (!context.mounted || summary == null) return;
                    final msg = ref
                        .read(syncQueueControllerProvider)
                        .lastFeedbackMessage;
                    if (msg != null) {
                      AppFeedbackBanner.showSnackBar(
                        context,
                        type: summary.conflictCount > 0
                            ? AppFeedbackType.warning
                            : AppFeedbackType.success,
                        message: msg,
                      );
                    }
                  }
                : null,
            icon: actionState.isSyncingNow
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: Text(
              actionState.isSyncingNow ? 'กำลังซิงค์...' : 'ซิงค์เดี๋ยวนี้',
            ),
          ),
        ),
      ],
    );
    final summaryHeader = SyncStatusSummaryHeader(
      isOnline: isOnline,
      counts: counts,
      lastSummaryMessage: actionState.lastFeedbackMessage,
    );
    final filterChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          _SyncQueueFilter.all,
          'ทั้งหมด (${counts.totalAttentionCount})',
        ),
        _buildFilterChip(
          _SyncQueueFilter.conflict,
          'ข้อมูลชนกัน (${counts.conflictCount})',
        ),
        _buildFilterChip(
          _SyncQueueFilter.pending,
          'รอซิงค์ (${counts.pendingCount + counts.syncingCount})',
        ),
        _buildFilterChip(
          _SyncQueueFilter.failed,
          'ล้มเหลว (${counts.failedCount})',
        ),
      ],
    );
    final itemsBody = itemsAsync.when(
      loading: () => const Column(
        children: [
          SkeletonBox(height: 96),
          SizedBox(height: 12),
          SkeletonBox(height: 96),
        ],
      ),
      error: (error, _) => AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(error),
        onRetry: () => ref.invalidate(syncQueueItemsStreamProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(
            icon: Icons.cloud_done_rounded,
            title:
                'ข้อมูลทั้งหมดซิงค์ขึ้นระบบเรียบร้อยแล้ว — ไม่มีรายการค้าง',
            description:
                'ข้อมูลเช็คชื่อและคะแนนล่าสุดของคุณถูกส่งขึ้นระบบครบถ้วนแล้ว',
          );
        }
        final sorted = _sortAndFilter(items);
        if (sorted.isEmpty) {
          return const AppEmptyState(
            icon: Icons.filter_list_off_rounded,
            title: 'ไม่พบรายการในตัวกรองที่เลือก',
            description:
                'ลองสลับตัวกรองด้านบนเพื่อตรวจสอบรายการซิงค์ในสถานะอื่น',
          );
        }
        return Column(
          children: [
            for (final item in sorted) ...[
              SyncQueueItemCard(
                item: item,
                isBusy: actionState.isItemBusy(item.id),
                isOnline: isOnline,
                onResolveConflict: () => _openConflictDialog(context, item),
                onRetry: () => _handleRetry(context, item.id),
                onDiscard: () => _confirmDiscard(context, item),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPinnedLayout =
            constraints.maxWidth >= 900 && constraints.maxHeight >= 520;
        if (isPinnedLayout) {
          return AppPageContainer.viewport(
            header: pageHeader,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summaryHeader,
                const SizedBox(height: 16),
                filterChips,
                const SizedBox(height: 16),
                Expanded(
                  child: AppSubtleScrollbar(
                    controller: _listScrollController,
                    child: SingleChildScrollView(
                      controller: _listScrollController,
                      primary: false,
                      padding: const EdgeInsets.only(right: 6, bottom: 8),
                      child: itemsBody,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AppPageContainer.scrollable(
          header: pageHeader,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryHeader,
              const SizedBox(height: 16),
              filterChips,
              const SizedBox(height: 16),
              itemsBody,
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(_SyncQueueFilter filter, String label) {
    return FilterChip(
      selected: _filter == filter,
      label: Text(
        label,
        style: const TextStyle(fontFeatures: AppTheme.tabularFigures),
      ),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  List<SyncQueueItem> _sortAndFilter(List<SyncQueueItem> items) {
    final filtered = items.where((item) {
      return switch (_filter) {
        _SyncQueueFilter.all => true,
        _SyncQueueFilter.conflict => item.status == SyncItemStatus.conflict,
        _SyncQueueFilter.pending =>
          item.status == SyncItemStatus.pending ||
              item.status == SyncItemStatus.syncing,
        _SyncQueueFilter.failed => item.status == SyncItemStatus.failed,
      };
    }).toList();

    int rank(SyncItemStatus status) => switch (status) {
      SyncItemStatus.conflict => 0,
      SyncItemStatus.failed => 1,
      SyncItemStatus.syncing => 2,
      SyncItemStatus.pending => 3,
    };

    filtered.sort((a, b) {
      final cmp = rank(a.status).compareTo(rank(b.status));
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return filtered;
  }

  Future<void> _openConflictDialog(
    BuildContext context,
    SyncQueueItem item,
  ) async {
    final controller = ref.read(syncQueueControllerProvider.notifier);
    final formatter = ref.read(syncConflictFieldFormatterProvider);
    await showDialog<bool>(
      context: context,
      builder: (_) => SyncConflictResolutionDialog(
        item: item,
        formatter: formatter,
        onKeepMine: () async {
          final result = await controller.resolveConflictKeepMine(item.id);
          if (!context.mounted || result == null) return false;
          AppFeedbackBanner.showSnackBar(
            context,
            type: result.isSynced
                ? AppFeedbackType.success
                : AppFeedbackType.warning,
            message: result.isSynced
                ? 'บันทึกทับด้วยค่าของคุณเรียบร้อยแล้ว'
                : (result.errorMessage ??
                      'ข้อมูลบนเซิร์ฟเวอร์เปลี่ยนแปลงอีกครั้ง'),
          );
          return result.isSynced;
        },
        onUseServer: () async {
          await controller.resolveConflictUseServer(item.id);
          if (!context.mounted) return false;
          AppFeedbackBanner.showSnackBar(
            context,
            type: AppFeedbackType.info,
            message: 'อัปเดตข้อมูลในเครื่องตามค่าล่าสุดบนเซิร์ฟเวอร์แล้ว',
          );
          return true;
        },
      ),
    );
  }

  Future<void> _handleRetry(BuildContext context, String itemId) async {
    final msg = await ref
        .read(syncQueueControllerProvider.notifier)
        .retryItem(itemId);
    if (!context.mounted || msg == null) return;
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.info,
      message: msg,
    );
  }

  Future<void> _confirmDiscard(BuildContext context, SyncQueueItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันยกเลิกรายการที่ยังไม่ซิงค์'),
        content: Text(
          'ต้องการลบ "${item.displayLabel}" ออกจากคิวซิงค์ใช่หรือไม่? '
          'การแก้ไขในรายการนี้จะไม่ถูกส่งขึ้นเซิร์ฟเวอร์',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('เก็บไว้'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ยืนยันยกเลิก'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(syncQueueControllerProvider.notifier).discardItem(item.id);
    if (!context.mounted) return;
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.info,
      message: 'ยกเลิกรายการออกจากคิวซิงค์แล้ว',
    );
  }
}
