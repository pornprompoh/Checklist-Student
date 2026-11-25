import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sync_queue_providers.dart';

/// Semantic numeric badge showing pending/failed/conflict sync queue counts.
///
/// Renders `AppSemanticColors.danger` when any conflict exists, otherwise
/// `AppSemanticColors.warning`. Collapses to [SizedBox.shrink] when count is `0`.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    super.key,
    required this.counts,
    this.compact = false,
  });

  final SyncQueueStatusCounts counts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = counts.totalAttentionCount;
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final isDanger = counts.hasConflicts;
    final bgColor = isDanger ? semantic.danger : semantic.warning;
    final fgColor =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final label = total > 99 ? '99+' : '$total';

    return Semantics(
      label: isDanger
          ? 'มีข้อมูลชนกัน ${counts.conflictCount} รายการ จากทั้งหมด $total รายการ'
          : 'มีรายการรอซิงค์ $total รายการ',
      child: Container(
        constraints: BoxConstraints(
          minWidth: compact ? 18 : 22,
          minHeight: compact ? 18 : 20,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6,
          vertical: compact ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTheme.tabularFigures,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
