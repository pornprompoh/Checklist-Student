import 'package:flutter/material.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../../domain/entities/student_portal_class_detail.dart';

/// Assignment status summary and per-assignment list inside
/// `StudentPortalClassCard`, showing exact scores only when allowed by server.
class StudentPortalClassAssignmentsSection extends StatelessWidget {
  const StudentPortalClassAssignmentsSection({
    super.key,
    required this.assignments,
    required this.showScoreToStudent,
  });

  final List<StudentPortalAssignmentItem> assignments;
  final bool showScoreToStudent;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    final submittedCount = assignments
        .where((a) => a.submissionStatus == SubmissionStatus.submitted)
        .length;
    final lateCount = assignments
        .where((a) => a.submissionStatus == SubmissionStatus.late)
        .length;
    final missingCount = assignments
        .where((a) => a.submissionStatus == SubmissionStatus.missing)
        .length;

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
              'รายการงานทั้งหมด (${assignments.length} ชิ้น)',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _MiniTag(
                  label: 'ส่งแล้ว $submittedCount',
                  bg: semantic.successContainer,
                  fg: semantic.success,
                ),
                if (lateCount > 0)
                  _MiniTag(
                    label: 'ส่งช้า $lateCount',
                    bg: semantic.warningContainer,
                    fg: semantic.warning,
                  ),
                _MiniTag(
                  label: 'ค้างส่ง $missingCount',
                  bg: missingCount > 0
                      ? semantic.dangerContainer
                      : colorScheme.surfaceContainerHighest,
                  fg: missingCount > 0
                      ? semantic.danger
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (assignments.isEmpty)
          Text(
            'ยังไม่มีรายการงานหรือการสอบในรายวิชานี้',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (var i = 0; i < assignments.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _AssignmentCardRow(
              item: assignments[i],
              showScoreToStudent: showScoreToStudent,
              calculator: _calculator,
            ),
          ],
      ],
    );
  }
}

class _AssignmentCardRow extends StatelessWidget {
  const _AssignmentCardRow({
    required this.item,
    required this.showScoreToStudent,
    required this.calculator,
  });

  final StudentPortalAssignmentItem item;
  final bool showScoreToStudent;
  final ScoreCalculatorService calculator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    final (Color statusBg, Color statusFg) = switch (item.submissionStatus) {
      SubmissionStatus.submitted => (
        semantic.successContainer,
        semantic.success,
      ),
      SubmissionStatus.late => (semantic.warningContainer, semantic.warning),
      SubmissionStatus.missing => (semantic.dangerContainer, semantic.danger),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MiniTag(
                label: item.submissionStatus.thaiLabel,
                bg: statusBg,
                fg: statusFg,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniTag(
                label: item.categoryName,
                bg: colorScheme.surfaceContainerHighest,
                fg: colorScheme.onSurfaceVariant,
              ),
              if (item.isMandatory)
                _MiniTag(
                  label: 'บังคับส่ง',
                  bg: semantic.warningContainer,
                  fg: semantic.warning,
                ),
              if (item.dueDate != null)
                Text(
                  'กำหนดส่ง ${ThaiDateFormatter.formatShortDate(item.dueDate!)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (showScoreToStudent)
                _MiniTag(
                  label: item.score == null
                      ? 'รอตรวจ / เต็ม ${calculator.formatExactScore(item.maxScore)}'
                      : '${calculator.formatExactScore(item.score!)} / ${calculator.formatExactScore(item.maxScore)}',
                  bg: colorScheme.primaryContainer,
                  fg: colorScheme.onPrimaryContainer,
                ),
            ],
          ),
          if (item.note.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'หมายเหตุ: ${item.note}',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
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
