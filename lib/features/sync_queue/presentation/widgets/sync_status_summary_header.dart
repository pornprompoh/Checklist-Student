import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sync_queue_providers.dart';

/// Flat 1-row inline summary bar for `SyncQueuePage`: live connectivity badge,
/// compact metric chips (`ข้อมูลชนกัน`, `รอซิงค์`, `ล้มเหลว`), and optional
/// last sync feedback.
class SyncStatusSummaryHeader extends StatelessWidget {
  const SyncStatusSummaryHeader({
    super.key,
    required this.isOnline,
    required this.counts,
    this.lastSummaryMessage,
  });

  final bool isOnline;
  final SyncQueueStatusCounts counts;
  final String? lastSummaryMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline
                    ? semantic.successContainer
                    : semantic.warningContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    size: 15,
                    color: isOnline ? semantic.success : semantic.warning,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isOnline ? 'ออนไลน์พร้อมซิงค์' : 'กำลังออฟไลน์',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: isOnline ? semantic.success : semantic.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _InlineMetricChip(
              label: 'ข้อมูลชนกัน',
              count: counts.conflictCount,
              color: semantic.danger,
              containerColor: semantic.dangerContainer,
              icon: Icons.warning_amber_rounded,
            ),
            _InlineMetricChip(
              label: 'รอซิงค์',
              count: counts.pendingCount + counts.syncingCount,
              color: semantic.warning,
              containerColor: semantic.warningContainer,
              icon: Icons.schedule_rounded,
            ),
            _InlineMetricChip(
              label: 'ล้มเหลว',
              count: counts.failedCount,
              color: colorScheme.error,
              containerColor: colorScheme.errorContainer,
              icon: Icons.error_outline_rounded,
            ),
          ],
        ),
        if (lastSummaryMessage != null &&
            lastSummaryMessage!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'ผลการซิงค์ล่าสุด: $lastSummaryMessage',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineMetricChip extends StatelessWidget {
  const _InlineMetricChip({
    required this.label,
    required this.count,
    required this.color,
    required this.containerColor,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final Color containerColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? containerColor : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isActive ? color : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            '$label $count',
            style: textTheme.labelMedium?.copyWith(
              color: isActive ? color : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
