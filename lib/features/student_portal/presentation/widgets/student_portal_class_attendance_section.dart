import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../../domain/entities/student_portal_class_detail.dart';

/// Zone 2 of `StudentPortalClassCard`: attendance summary pills with tabular
/// numbers, `%` absence risk indicator, and expandable Buddhist Era history.
class StudentPortalClassAttendanceSection extends StatelessWidget {
  const StudentPortalClassAttendanceSection({
    super.key,
    required this.summary,
    required this.records,
  });

  final StudentPortalAttendanceSummary summary;
  final List<StudentPortalAttendanceRecord> records;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final pctText = _calculator.formatExactScore(summary.absentPercentage);
    final thresholdText = _calculator.formatExactScore(
      summary.absentThresholdPct,
    );
    final isApproaching =
        !summary.isExceededThreshold &&
        summary.totalEligibleSessions > 0 &&
        summary.absentPercentage >= (summary.absentThresholdPct * 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'เวลาเรียน (${summary.recordedSessions}/${summary.totalEligibleSessions} คาบ)',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: summary.isExceededThreshold
                    ? semantic.dangerContainer
                    : (isApproaching
                          ? semantic.warningContainer
                          : semantic.successContainer),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary.isExceededThreshold
                    ? 'ขาด $pctText% (เกินเกณฑ์ มส $thresholdText%)'
                    : (isApproaching
                          ? 'ขาด $pctText% (เสี่ยง มส)'
                          : 'ขาด $pctText% (ปกติ)'),
                style: textTheme.labelSmall?.copyWith(
                  color: summary.isExceededThreshold
                      ? semantic.danger
                      : (isApproaching ? semantic.warning : semantic.success),
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTheme.tabularFigures,
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
            _AttendancePill(
              label: 'มา ${summary.presentCount}',
              bg: semantic.presentContainer,
              fg: semantic.present,
            ),
            _AttendancePill(
              label: 'สาย ${summary.lateCount}',
              bg: semantic.lateContainer,
              fg: semantic.late,
            ),
            _AttendancePill(
              label: 'ลา ${summary.leaveCount}',
              bg: semantic.leaveContainer,
              fg: semantic.leave,
            ),
            _AttendancePill(
              label: 'ขาด ${summary.absentCount}',
              bg: semantic.absentContainer,
              fg: semantic.absent,
            ),
          ],
        ),
        if (records.isNotEmpty) ...[
          const SizedBox(height: 10),
          Material(
            color: colorScheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              dense: true,
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              title: Text(
                'ดูประวัติเช็คชื่อรายคาบ (${records.length} ครั้ง)',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ThaiDateFormatter.formatShortDate(
                                  records[i].sessionDate,
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: AppTheme.tabularFigures,
                                ),
                              ),
                              if (records[i].note.trim().isNotEmpty)
                                Text(
                                  records[i].note,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(context, records[i].status, semantic),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusBadge(
    BuildContext context,
    AttendanceStatus status,
    AppSemanticColors semantic,
  ) {
    final (Color bg, Color fg) = switch (status) {
      AttendanceStatus.present => (semantic.presentContainer, semantic.present),
      AttendanceStatus.late => (semantic.lateContainer, semantic.late),
      AttendanceStatus.leave => (semantic.leaveContainer, semantic.leave),
      AttendanceStatus.absent => (semantic.absentContainer, semantic.absent),
    };
    return _AttendancePill(label: status.thaiLabel, bg: bg, fg: fg);
  }
}

class _AttendancePill extends StatelessWidget {
  const _AttendancePill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontFeatures: AppTheme.tabularFigures,
        ),
      ),
    );
  }
}
