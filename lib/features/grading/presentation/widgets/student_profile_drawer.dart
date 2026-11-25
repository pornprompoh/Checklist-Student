import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/student_score.dart';
import '../providers/grading_filter_provider.dart';
import '../providers/student_profile_drawer_controller.dart';
import 'student_drawer_actions_section.dart';
import 'student_drawer_assignments_section.dart';
import 'student_drawer_summary_section.dart';

/// Slide-over individual student profile panel opened ONLY from the explicit
/// trailing icon button (`ValueKey('open_profile_<id>')`) in [FrozenGradeGrid].
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = math.min(MediaQuery.sizeOf(context).width * 0.92, 460.0);
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isBusy = ref.watch(studentProfileDrawerControllerProvider).isLoading;
    final enrollment = rowData.enrollment;

    return Drawer(
      width: width,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${enrollment.studentNumber}',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontFeatures: AppTheme.tabularFigures,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'รหัส ${enrollment.studentCode}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: enrollment.isTransferredOut
                                    ? semantic.warningContainer
                                    : semantic.successContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                enrollment.isTransferredOut
                                    ? 'ย้ายออก'
                                    : 'กำลังเรียน',
                                style: textTheme.labelSmall?.copyWith(
                                  color: enrollment.isTransferredOut
                                      ? semantic.warning
                                      : semantic.success,
                                  fontWeight: FontWeight.w600,
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
                            fontWeight: FontWeight.w500,
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
                  StudentDrawerSummarySection(
                    rowData: rowData,
                    isBusy: isBusy,
                    onManageSpecialGrade: onManageSpecialGrade,
                    onOpenStudentAuditLog: onOpenStudentAuditLog,
                  ),
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
}
