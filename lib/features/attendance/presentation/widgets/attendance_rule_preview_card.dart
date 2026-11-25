import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/student_attendance_summary.dart';

/// Live Preview card showing how the current draft `AttendanceRuleConfig`
/// impacts students in the classroom using tabular numbers and semantic tones.
class AttendanceRulePreviewCard extends StatelessWidget {
  const AttendanceRulePreviewCard({super.key, required this.summaries});

  final Map<String, StudentAttendanceSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);

    var normalCount = 0;
    var approachingCount = 0;
    var exceededCount = 0;

    for (final summary in summaries.values) {
      switch (summary.riskLevel) {
        case AttendanceRiskLevel.normal:
          normalCount++;
        case AttendanceRiskLevel.approachingMs:
          approachingCount++;
        case AttendanceRiskLevel.exceededMs:
          exceededCount++;
      }
    }

    return AppSurfaceCard(
      title: 'ผลกระทบในห้องนี้ (Live Preview)',
      subtitle:
          'คำนวณจากประวัติการเช็คชื่อทั้งหมดของห้องนี้ตามเกณฑ์ที่กำลังปรับแต่ง',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _PreviewStatRow(
            icon: Icons.check_circle_rounded,
            label: 'ปกติ',
            value: '$normalCount คน',
            bg: semantic.successContainer,
            fg: semantic.success,
          ),
          const SizedBox(height: 8),
          _PreviewStatRow(
            icon: Icons.warning_amber_rounded,
            label: 'เสี่ยง มส',
            value: '$approachingCount คน',
            bg: semantic.warningContainer,
            fg: semantic.warning,
          ),
          const SizedBox(height: 8),
          _PreviewStatRow(
            icon: Icons.error_rounded,
            label: 'เกินเกณฑ์ มส',
            value: '$exceededCount คน',
            bg: semantic.dangerContainer,
            fg: semantic.danger,
          ),
        ],
      ),
    );
  }
}

class _PreviewStatRow extends StatelessWidget {
  const _PreviewStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(color: fg),
            ),
          ),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
