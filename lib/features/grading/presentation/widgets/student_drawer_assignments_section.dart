import 'package:flutter/material.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_table_state.dart';

/// Assignment breakdown list shown inside `StudentProfileDrawer`.
class StudentDrawerAssignmentsSection extends StatelessWidget {
  const StudentDrawerAssignmentsSection({
    super.key,
    required this.enrollmentId,
    required this.assignments,
    required this.scoresByCellKey,
  });

  final String enrollmentId;
  final List<Assignment> assignments;
  final Map<String, StudentScore> scoresByCellKey;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'รายการงานและคะแนน (${assignments.length} ชิ้น)',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (assignments.isEmpty)
              Text(
                'ยังไม่มีชิ้นงานในห้องเรียนนี้',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (var i = 0; i < assignments.length; i++) ...[
                if (i > 0) const Divider(height: 14),
                _buildAssignmentItem(
                  context,
                  assignment: assignments[i],
                  scoreRecord: scoresByCellKey[
                    gradingCellKey(enrollmentId, assignments[i].id)
                  ],
                  semantic: semantic,
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentItem(
    BuildContext context, {
    required Assignment assignment,
    required StudentScore? scoreRecord,
    required AppSemanticColors semantic,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = scoreRecord?.submissionStatus ?? SubmissionStatus.missing;
    final score = scoreRecord?.score;
    final note = scoreRecord?.note.trim() ?? '';
    final isOverMax =
        score != null &&
        (score * 100).round() > (assignment.maxScore * 100).round();

    final (Color statusBg, Color statusFg) = switch (status) {
      SubmissionStatus.submitted => (semantic.successContainer, semantic.success),
      SubmissionStatus.late => (semantic.lateContainer, semantic.late),
      SubmissionStatus.missing => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    final scoreLabel = score == null
        ? '- / ${_calculator.formatExactScore(assignment.maxScore)}'
        : '${_calculator.formatExactScore(score)} / '
              '${_calculator.formatExactScore(assignment.maxScore)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                assignment.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              scoreLabel,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isOverMax ? semantic.danger : colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.thaiLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: statusFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (assignment.isMandatory)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: semantic.warningContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'บังคับส่ง',
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (isOverMax)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: semantic.dangerContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'คะแนนเกินเต็ม',
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (assignment.dueDate != null)
              Text(
                'ส่ง ${ThaiDateFormatter.formatShortDate(assignment.dueDate!)}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'หมายเหตุ: $note',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
