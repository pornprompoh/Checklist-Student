import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/student_attendance_summary.dart';

/// Live Preview card showing how the current draft `AttendanceRuleConfig`
/// impacts students in the classroom without writing to the database.
class AttendanceRulePreviewCard extends StatelessWidget {
  const AttendanceRulePreviewCard({super.key, required this.summaries});

  final Map<String, StudentAttendanceSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ตัวอย่างผลกระทบสดในห้องนี้ (Live Preview)',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'คำนวณจากประวัติการเช็คชื่อทั้งหมดของห้องนี้ตามเกณฑ์ที่กำลังปรับแต่ง',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PreviewPill(
                  label: 'ปกติ $normalCount คน',
                  bg: semantic.successContainer,
                  fg: semantic.success,
                ),
                _PreviewPill(
                  label: 'เสี่ยง มส $approachingCount คน',
                  bg: semantic.warningContainer,
                  fg: semantic.warning,
                ),
                _PreviewPill(
                  label: 'เกินเกณฑ์ มส $exceededCount คน',
                  bg: semantic.dangerContainer,
                  fg: semantic.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
