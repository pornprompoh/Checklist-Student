import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/today_attendance_summary.dart';

/// Compact status pill badge with optional 6px dot indicator and tabular digits.
class DashboardTagPill extends StatelessWidget {
  const DashboardTagPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.showDot = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's attendance status strip inside [DashboardClassCard] using a
/// concentric `8px` inner radius (`outer: 16`, `padding: 16 → inner: 8`).
class DashboardTodayStatusStrip extends StatelessWidget {
  const DashboardTodayStatusStrip({
    super.key,
    required this.summary,
    required this.teachesToday,
  });

  final TodayAttendanceSummary? summary;
  final bool teachesToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final current = summary;

    if (current == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: teachesToday
              ? semantic.warningContainer.withValues(alpha: 0.65)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: teachesToday
                ? semantic.warning.withValues(alpha: 0.35)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              teachesToday
                  ? Icons.schedule_rounded
                  : Icons.event_available_outlined,
              size: 16,
              color: teachesToday
                  ? semantic.warning
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                teachesToday
                    ? 'ยังไม่เช็คชื่อวันนี้'
                    : 'ยังไม่มีการเช็คชื่อวันนี้',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: teachesToday
                      ? semantic.warning
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                current.isLocked
                    ? Icons.lock_rounded
                    : Icons.check_circle_rounded,
                size: 15,
                color: semantic.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  current.isLocked
                      ? 'เช็คแล้ววันนี้ (ล็อกแล้ว)'
                      : 'เช็คแล้ววันนี้',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: semantic.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              DashboardTagPill(
                label:
                    '${AttendanceStatus.present.thaiLabel} ${current.presentCount}',
                background: semantic.presentContainer,
                foreground: semantic.present,
              ),
              DashboardTagPill(
                label:
                    '${AttendanceStatus.late.thaiLabel} ${current.lateCount}',
                background: semantic.lateContainer,
                foreground: semantic.late,
              ),
              DashboardTagPill(
                label:
                    '${AttendanceStatus.leave.thaiLabel} ${current.leaveCount}',
                background: semantic.leaveContainer,
                foreground: semantic.leave,
              ),
              DashboardTagPill(
                label:
                    '${AttendanceStatus.absent.thaiLabel} ${current.absentCount}',
                background: semantic.absentContainer,
                foreground: semantic.absent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
