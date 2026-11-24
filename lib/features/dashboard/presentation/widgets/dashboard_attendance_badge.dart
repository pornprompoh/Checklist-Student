import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/today_attendance_summary.dart';

/// Reusable pill badge used across Teacher Dashboard cards.
class DashboardTagPill extends StatelessWidget {
  const DashboardTagPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Renders the "เช็คแล้ววันนี้" badge (with lock icon when locked), 4-state
/// attendance summary pills (`มา / สาย / ลา / ขาด`), and secondary edit action.
class DashboardCheckedAttendanceSection extends StatelessWidget {
  const DashboardCheckedAttendanceSection({
    super.key,
    required this.summary,
    required this.onOpenAttendance,
  });

  final TodayAttendanceSummary summary;
  final VoidCallback onOpenAttendance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: semantic.successContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    summary.isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 15,
                    color: semantic.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'เช็คแล้ววันนี้',
                    style: textTheme.labelMedium?.copyWith(
                      color: semantic.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
                  '${AttendanceStatus.present.thaiLabel} ${summary.presentCount}',
              background: semantic.presentContainer,
              foreground: semantic.present,
            ),
            DashboardTagPill(
              label: '${AttendanceStatus.late.thaiLabel} ${summary.lateCount}',
              background: semantic.lateContainer,
              foreground: semantic.late,
            ),
            DashboardTagPill(
              label:
                  '${AttendanceStatus.leave.thaiLabel} ${summary.leaveCount}',
              background: semantic.leaveContainer,
              foreground: semantic.leave,
            ),
            DashboardTagPill(
              label:
                  '${AttendanceStatus.absent.thaiLabel} ${summary.absentCount}',
              background: semantic.absentContainer,
              foreground: semantic.absent,
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenAttendance,
          icon: const Icon(Icons.edit_calendar_outlined, size: 18),
          label: const Text('ดู / แก้ไขเช็คชื่อ'),
        ),
      ],
    );
  }
}
