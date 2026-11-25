import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/sync_entity_type.dart';
import '../../domain/entities/sync_item_status.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/services/sync_retry_policy_service.dart';

/// Responsive card rendering one offline queued mutation item with Thai
/// timestamp, retry/error diagnostics, and status-appropriate action buttons.
class SyncQueueItemCard extends StatelessWidget {
  const SyncQueueItemCard({
    super.key,
    required this.item,
    required this.isBusy,
    required this.isOnline,
    required this.onResolveConflict,
    required this.onRetry,
    required this.onDiscard,
  });

  final SyncQueueItem item;
  final bool isBusy;
  final bool isOnline;
  final VoidCallback onResolveConflict;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final statusStyle = _statusStyle(item.status, colorScheme, semantic);
    final isConflict = item.status == SyncItemStatus.conflict;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: isConflict ? semantic.danger : null,
      backgroundColor: isConflict
          ? semantic.dangerContainer.withValues(alpha: 0.2)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                _entityIcon(item.entityType),
                size: 18,
                color: isConflict ? semantic.danger : colorScheme.primary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.entityType.thaiLabel,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusStyle.container,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.thaiLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: statusStyle.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.displayLabel,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'บันทึกบนเครื่อง: ${ThaiDateFormatter.formatDateTime(item.updatedAt)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          if (item.status == SyncItemStatus.failed) ...[
            const SizedBox(height: 4),
            Text(
              'ลองแล้ว ${item.retryCount}/${SyncRetryPolicyService.maxRetryCount} ครั้ง'
              '${item.nextRetryAt == null ? '' : ' · ลองอัตโนมัติถัดไป: ${ThaiDateFormatter.formatDateTime(item.nextRetryAt!)}'}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ],
          if (item.lastError != null && item.lastError!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: semantic.dangerContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: semantic.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                item.lastError!,
                style: textTheme.bodySmall?.copyWith(color: semantic.danger),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: _buildActions(context, semantic),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, AppSemanticColors semantic) {
    switch (item.status) {
      case SyncItemStatus.conflict:
        return <Widget>[
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: semantic.danger),
            onPressed: isBusy ? null : onResolveConflict,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.compare_arrows_rounded, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'เปรียบเทียบและแก้ปัญหา',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ];
      case SyncItemStatus.failed:
        return <Widget>[
          TextButton.icon(
            onPressed: isBusy ? null : onDiscard,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('ยกเลิกรายการ'),
          ),
          FilledButton.tonalIcon(
            onPressed: (isBusy || !isOnline) ? null : onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('ลองซิงค์ใหม่'),
          ),
        ];
      case SyncItemStatus.pending:
        return <Widget>[
          TextButton.icon(
            onPressed: isBusy ? null : onDiscard,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('ยกเลิกรายการ'),
          ),
        ];
      case SyncItemStatus.syncing:
        return const <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('กำลังส่งข้อมูล...'),
            ],
          ),
        ];
    }
  }

  IconData _entityIcon(SyncEntityType type) => switch (type) {
    SyncEntityType.attendanceSession => Icons.event_available_outlined,
    SyncEntityType.attendanceRecord => Icons.how_to_reg_outlined,
    SyncEntityType.studentScore => Icons.edit_note_rounded,
    SyncEntityType.specialGradeStatus => Icons.assignment_late_outlined,
  };

  ({Color foreground, Color container}) _statusStyle(
    SyncItemStatus status,
    ColorScheme scheme,
    AppSemanticColors semantic,
  ) => switch (status) {
    SyncItemStatus.conflict => (
      foreground: semantic.danger,
      container: semantic.dangerContainer,
    ),
    SyncItemStatus.failed => (
      foreground: scheme.error,
      container: scheme.errorContainer,
    ),
    SyncItemStatus.pending => (
      foreground: semantic.warning,
      container: semantic.warningContainer,
    ),
    SyncItemStatus.syncing => (
      foreground: scheme.primary,
      container: scheme.primaryContainer,
    ),
  };
}
