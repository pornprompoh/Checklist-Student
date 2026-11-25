import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
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
  _SyncQueueFilter _filter = _SyncQueueFilter.all;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(syncQueueItemsStreamProvider);
    final counts = ref.watch(syncQueueStatusCountsProvider);
    final actionState = ref.watch(syncQueueControllerProvider);
    final isOnline =
        ref.watch(connectivityStatusProvider).asData?.value ?? true;
    final controller = ref.read(syncQueueControllerProvider.notifier);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'สถานะการซิงค์ข้อมูลออฟไลน์',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ตรวจสอบรายการเช็คชื่อและคะแนนที่รอส่งขึ้นระบบ พร้อมเปรียบเทียบและแก้ไขกรณีข้อมูลชนกัน',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              SyncStatusSummaryHeader(
                isOnline: isOnline,
                counts: counts,
                isSyncingNow: actionState.isSyncingNow,
                lastSummaryMessage: actionState.lastFeedbackMessage,
                onSyncNow: () async {
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
                },
              ),
              const SizedBox(height: 14),
              Wrap(
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
              ),
              const SizedBox(height: 14),
              itemsAsync.when(
                loading: () => const Column(
                  children: [
                    SkeletonBox(height: 96),
                    SizedBox(height: 10),
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
                    return _buildEmptyState(context);
                  }
                  final sorted = _sortAndFilter(items);
                  if (sorted.isEmpty) {
                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'ไม่พบรายการในตัวกรองที่เลือก',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final item in sorted) ...[
                        SyncQueueItemCard(
                          item: item,
                          isBusy: actionState.isItemBusy(item.id),
                          isOnline: isOnline,
                          onResolveConflict: () =>
                              _openConflictDialog(context, item),
                          onRetry: () => _handleRetry(context, item.id),
                          onDiscard: () => _confirmDiscard(context, item),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(_SyncQueueFilter filter, String label) {
    return FilterChip(
      selected: _filter == filter,
      label: Text(label),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.cloud_done_rounded,
              size: 44,
              color: semantic.success,
            ),
            const SizedBox(height: 10),
            Text(
              'ข้อมูลทั้งหมดซิงค์ขึ้นระบบเรียบร้อยแล้ว — ไม่มีรายการค้าง',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
                : (result.errorMessage ?? 'ข้อมูลบนเซิร์ฟเวอร์เปลี่ยนแปลงอีกครั้ง'),
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
