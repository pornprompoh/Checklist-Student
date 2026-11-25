import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/grading_table_state.dart';

/// Compact toolbar pill displaying live auto-save status (`กำลังบันทึก...`,
/// `บันทึกแล้ว`, `ข้อมูลชนกัน`, or `บันทึกไม่สำเร็จ`) with tabular timestamps.
class SaveStatusIndicator extends StatelessWidget {
  const SaveStatusIndicator({
    super.key,
    required this.status,
    this.lastSavedAt,
    this.onRetry,
    this.onReloadLatest,
  });

  final CellSaveStatus status;
  final DateTime? lastSavedAt;
  final VoidCallback? onRetry;
  final VoidCallback? onReloadLatest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (status == CellSaveStatus.idle) {
      return const SizedBox.shrink();
    }

    final (
      Color bg,
      Color fg,
      Widget leading,
      String label,
      String? actionLabel,
      VoidCallback? actionCallback,
    ) = switch (status) {
      CellSaveStatus.saving => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        'กำลังบันทึก...',
        null,
        null,
      ),
      CellSaveStatus.saved => (
        semantic.successContainer,
        semantic.success,
        Icon(Icons.check_circle_rounded, size: 15, color: semantic.success),
        _savedLabel(),
        null,
        null,
      ),
      CellSaveStatus.conflict => (
        semantic.warningContainer,
        semantic.warning,
        Icon(Icons.sync_problem_rounded, size: 15, color: semantic.warning),
        'ข้อมูลชนกัน',
        'โหลดล่าสุด',
        onReloadLatest,
      ),
      CellSaveStatus.error => (
        semantic.dangerContainer,
        semantic.danger,
        Icon(Icons.error_outline_rounded, size: 15, color: semantic.danger),
        'บันทึกไม่สำเร็จ',
        'ลองใหม่',
        onRetry,
      ),
      CellSaveStatus.idle => (
        colorScheme.surfaceContainer,
        colorScheme.onSurfaceVariant,
        const SizedBox.shrink(),
        '',
        null,
        null,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          if (actionLabel != null && actionCallback != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: actionCallback,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  actionLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _savedLabel() {
    final savedAt = lastSavedAt;
    if (savedAt == null) return 'บันทึกแล้ว';
    final local = savedAt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return 'บันทึกแล้ว ($hh:$mm น.)';
  }
}
