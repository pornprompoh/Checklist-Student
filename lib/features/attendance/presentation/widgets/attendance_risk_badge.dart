import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/student_attendance_summary.dart';

/// Compact semantic badge indicating a student's `มส` attendance risk level
/// with a detailed tooltip breakdown. Renders nothing when `normal`.
class AttendanceRiskBadge extends StatelessWidget {
  const AttendanceRiskBadge({super.key, required this.summary});

  final StudentAttendanceSummary? summary;

  @override
  Widget build(BuildContext context) {
    final data = summary;
    if (data == null || data.riskLevel == AttendanceRiskLevel.normal) {
      return const SizedBox.shrink();
    }

    final semantic = AppSemanticColors.of(context);
    final isExceeded = data.riskLevel == AttendanceRiskLevel.exceededMs;
    final fg = isExceeded ? semantic.danger : semantic.warning;
    final bg = isExceeded ? semantic.dangerContainer : semantic.warningContainer;
    final pctText = data.absentPercentage.toStringAsFixed(1);
    final label = isExceeded
        ? 'เกินเกณฑ์ มส ($pctText%)'
        : 'เสี่ยง มส ($pctText%)';

    final tooltip =
        'ขาด ${data.absentCount}'
        ' · สาย→ขาด ${data.convertedLateAbsentCount}'
        ' · ลา→ขาด ${data.countedLeaveAbsentCount}'
        ' / รวม ${data.totalEligibleSessions} คาบ';

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExceeded
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
              size: 13,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
