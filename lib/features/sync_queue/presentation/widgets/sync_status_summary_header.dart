import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../providers/sync_queue_providers.dart';

/// Header card for `SyncQueuePage` showing live connectivity status, counts by
/// category (`ข้อมูลชนกัน`, `รอซิงค์`, `ล้มเหลว`), last sync summary, and the
/// manual `"ซิงค์เดี๋ยวนี้"` trigger.
class SyncStatusSummaryHeader extends StatelessWidget {
  const SyncStatusSummaryHeader({
    super.key,
    required this.isOnline,
    required this.counts,
    required this.isSyncingNow,
    this.lastSummaryMessage,
    required this.onSyncNow,
  });

  final bool isOnline;
  final SyncQueueStatusCounts counts;
  final bool isSyncingNow;
  final String? lastSummaryMessage;
  final VoidCallback onSyncNow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final hasRunnableItems = (counts.pendingCount + counts.failedCount) > 0;
    final canPressSync = isOnline && !isSyncingNow && hasRunnableItems;

    final tooltipMessage = !isOnline
        ? 'ไม่สามารถซิงค์ได้ขณะออฟไลน์ กรุณาเชื่อมต่ออินเทอร์เน็ต'
        : (!hasRunnableItems ? 'ไม่มีรายการรอซิงค์' : 'ซิงค์รายการที่ค้างทันที');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? semantic.successContainer
                        : semantic.warningContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        size: 16,
                        color: isOnline ? semantic.success : semantic.warning,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isOnline ? 'ออนไลน์พร้อมซิงค์' : 'กำลังออฟไลน์',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: isOnline
                                ? semantic.success
                                : semantic.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: tooltipMessage,
                  child: FilledButton.icon(
                    onPressed: canPressSync ? onSyncNow : null,
                    icon: isSyncingNow
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      isSyncingNow ? 'กำลังซิงค์...' : 'ซิงค์เดี๋ยวนี้',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = constraints.maxWidth >= 520
                    ? (constraints.maxWidth - 20) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricTile(
                      width: tileWidth,
                      label: 'ข้อมูลชนกัน',
                      count: counts.conflictCount,
                      color: semantic.danger,
                      containerColor: semantic.dangerContainer,
                      icon: Icons.warning_amber_rounded,
                    ),
                    _MetricTile(
                      width: tileWidth,
                      label: 'รอซิงค์',
                      count: counts.pendingCount + counts.syncingCount,
                      color: semantic.warning,
                      containerColor: semantic.warningContainer,
                      icon: Icons.schedule_rounded,
                    ),
                    _MetricTile(
                      width: tileWidth,
                      label: 'ล้มเหลว',
                      count: counts.failedCount,
                      color: colorScheme.error,
                      containerColor: colorScheme.errorContainer,
                      icon: Icons.error_outline_rounded,
                    ),
                  ],
                );
              },
            ),
            if (lastSummaryMessage != null &&
                lastSummaryMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'ผลการซิงค์ล่าสุด: $lastSummaryMessage',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.width,
    required this.label,
    required this.count,
    required this.color,
    required this.containerColor,
    required this.icon,
  });

  final double width;
  final String label;
  final int count;
  final Color color;
  final Color containerColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: count > 0
              ? containerColor
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: count > 0
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: count > 0 ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
