import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../attendance/domain/entities/student_attendance_summary.dart';
import '../../../attendance/presentation/widgets/attendance_risk_badge.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_filter_provider.dart';
import '../providers/student_profile_drawer_controller.dart';
import 'special_grade_badge.dart';
import 'student_drawer_actions_section.dart';
import 'student_drawer_assignments_section.dart';

/// Responsive individual student summary drawer opened ONLY from the trailing
/// icon button next to a student's name in `FrozenGradeGrid`.
class StudentProfileDrawer extends ConsumerWidget {
  const StudentProfileDrawer({
    super.key,
    required this.rowData,
    required this.assignments,
    required this.scoresByCellKey,
    required this.onManageSpecialGrade,
    this.onOpenStudentAuditLog,
  });

  final GradingTableRowData rowData;
  final List<Assignment> assignments;
  final Map<String, StudentScore> scoresByCellKey;
  final VoidCallback onManageSpecialGrade;
  final VoidCallback? onOpenStudentAuditLog;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = math.min(MediaQuery.sizeOf(context).width * 0.92, 460.0);
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isBusy = ref.watch(studentProfileDrawerControllerProvider).isLoading;

    final enrollment = rowData.enrollment;
    final gradeResult = rowData.gradeResult;
    final attendance = rowData.attendanceSummary;
    final totalText = _calculator.formatExactScore(gradeResult.totalScore);
    final maxText = _calculator.formatExactScore(gradeResult.totalMaxScore);

    return Drawer(
      width: width,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Text(
                      '${enrollment.studentNumber}',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.fullName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'รหัส ${enrollment.studentCode}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: enrollment.isTransferredOut
                                    ? semantic.warningContainer
                                    : semantic.successContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                enrollment.isTransferredOut
                                    ? 'ย้ายออก'
                                    : 'กำลังเรียน',
                                style: textTheme.labelSmall?.copyWith(
                                  color: enrollment.isTransferredOut
                                      ? semantic.warning
                                      : semantic.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'เข้าเรียนเมื่อ ${ThaiDateFormatter.formatShortDate(enrollment.enrolledAt)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'ปิดหน้าสรุปรายบุคคล',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGradeSummaryCard(
                    context,
                    totalText: totalText,
                    maxText: maxText,
                    isBusy: isBusy,
                  ),
                  const SizedBox(height: 12),
                  _buildAttendanceCard(context, attendance),
                  const SizedBox(height: 12),
                  StudentDrawerAssignmentsSection(
                    enrollmentId: enrollment.id,
                    assignments: assignments,
                    scoresByCellKey: scoresByCellKey,
                  ),
                  const SizedBox(height: 12),
                  StudentDrawerActionsSection(
                    enrollment: enrollment,
                    isBusy: isBusy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSummaryCard(
    BuildContext context, {
    required String totalText,
    required String maxText,
    required bool isBusy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final result = rowData.gradeResult;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สรุปคะแนนและเกรด',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'คะแนนรวม: $totalText / $maxText',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'เกรดปกติ: ${result.evaluatedGrade} · ค้างงาน ${result.missingAssignmentsCount} ชิ้น',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SpecialGradeBadge(
                  result: result,
                  onTap: isBusy || rowData.enrollment.isTransferredOut
                      ? null
                      : onManageSpecialGrade,
                ),
              ],
            ),
            if (!rowData.enrollment.isTransferredOut) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onManageSpecialGrade,
                icon: const Icon(Icons.grade_outlined, size: 18),
                label: const Text('จัดการเกรดพิเศษ ร / มส'),
              ),
            ],
            if (onOpenStudentAuditLog != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onOpenStudentAuditLog,
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('ดูประวัติการแก้คะแนนคนนี้'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    StudentAttendanceSummary? summary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AttendanceRiskBadge(summary: summary),
              ],
            ),
            const SizedBox(height: 10),
            if (summary == null || summary.totalEligibleSessions == 0)
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
                    label: 'มา ${summary.presentCount}',
                    bg: semantic.presentContainer,
                    fg: semantic.present,
                  ),
                  _StatPill(
                    label: 'สาย ${summary.lateCount}',
                    bg: semantic.lateContainer,
                    fg: semantic.late,
                  ),
                  _StatPill(
                    label: 'ลา ${summary.leaveCount}',
                    bg: semantic.leaveContainer,
                    fg: semantic.leave,
                  ),
                  _StatPill(
                    label: 'ขาด ${summary.absentCount}',
                    bg: semantic.absentContainer,
                    fg: semantic.absent,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ขาดเรียนสุทธิ ${summary.absentPercentage.toStringAsFixed(1)}% '
                '(${summary.effectiveAbsentCount} / ${summary.totalEligibleSessions} คาบที่มีสิทธิ์นับ)',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
