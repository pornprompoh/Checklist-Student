import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../attendance/presentation/widgets/attendance_risk_badge.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_filter_provider.dart';
import 'special_grade_badge.dart';

/// Top KPI metrics (`คะแนนรวม`, `เกรด`, `เวลาเรียน`), special-grade action, and
/// attendance breakdown inside [StudentProfileDrawer].
class StudentDrawerSummarySection extends StatelessWidget {
  const StudentDrawerSummarySection({
    super.key,
    required this.rowData,
    required this.isBusy,
    required this.onManageSpecialGrade,
    this.onOpenStudentAuditLog,
  });

  final GradingTableRowData rowData;
  final bool isBusy;
  final VoidCallback onManageSpecialGrade;
  final VoidCallback? onOpenStudentAuditLog;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final enrollment = rowData.enrollment;
    final result = rowData.gradeResult;
    final attendance = rowData.attendanceSummary;
    final totalText = _calculator.formatExactScore(result.totalScore);
    final maxText = _calculator.formatExactScore(result.totalMaxScore);
    final absentPctLabel =
        attendance == null || attendance.totalEligibleSessions == 0
        ? '-'
        : '${attendance.absentPercentage.toStringAsFixed(1)}%';

    final metricTiles = <Widget>[
      _DrawerMetricTile(
        label: 'คะแนนรวม',
        value: totalText,
        caption: 'เต็ม $maxText',
      ),
      _DrawerMetricTile(
        label: 'เกรด',
        valueWidget: SpecialGradeBadge(
          result: result,
          compact: true,
          onTap: isBusy || enrollment.isTransferredOut
              ? null
              : onManageSpecialGrade,
        ),
        caption: 'ค้าง ${result.missingAssignmentsCount} ชิ้น',
      ),
      _DrawerMetricTile(
        label: 'ขาดเรียน',
        value: absentPctLabel,
        caption: attendance == null
            ? 'ยังไม่มีคาบ'
            : '${attendance.totalEligibleSessions} คาบ',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 320 ? 3 : 2;
            const spacing = 8.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final tile in metricTiles)
                  SizedBox(width: tileWidth, child: tile),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (!enrollment.isTransferredOut || onOpenStudentAuditLog != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!enrollment.isTransferredOut)
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onManageSpecialGrade,
                  icon: const Icon(Icons.grade_outlined, size: 18),
                  label: const Text('จัดการเกรดพิเศษ ร / มส'),
                ),
              if (onOpenStudentAuditLog != null)
                OutlinedButton.icon(
                  onPressed: onOpenStudentAuditLog,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('ดูประวัติการแก้คะแนนคนนี้'),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'สถิติการเข้าเรียน',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AttendanceRiskBadge(summary: attendance),
                ],
              ),
              const SizedBox(height: 12),
              if (attendance == null || attendance.totalEligibleSessions == 0)
                Text(
                  'ยังไม่มีข้อมูลการเช็คชื่อในห้องเรียนนี้',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatPill(
                      label: 'มา ${attendance.presentCount}',
                      bg: semantic.presentContainer,
                      fg: semantic.present,
                    ),
                    _StatPill(
                      label: 'สาย ${attendance.lateCount}',
                      bg: semantic.lateContainer,
                      fg: semantic.late,
                    ),
                    _StatPill(
                      label: 'ลา ${attendance.leaveCount}',
                      bg: semantic.leaveContainer,
                      fg: semantic.leave,
                    ),
                    _StatPill(
                      label: 'ขาด ${attendance.absentCount}',
                      bg: semantic.absentContainer,
                      fg: semantic.absent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ขาดเรียนสุทธิ ${attendance.absentPercentage.toStringAsFixed(1)}% '
                  '(${attendance.effectiveAbsentCount} / ${attendance.totalEligibleSessions} คาบที่มีสิทธิ์นับ)',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerMetricTile extends StatelessWidget {
  const _DrawerMetricTile({
    required this.label,
    this.value,
    this.valueWidget,
    required this.caption,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (valueWidget != null)
            valueWidget!
          else
            Text(
              value ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
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
