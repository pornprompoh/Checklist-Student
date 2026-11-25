import 'package:flutter/material.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_table_state.dart';

/// Assignment breakdown list shown inside [StudentProfileDrawer] with hairline
/// separators, tabular exact scores, and clear submission status badges.
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

    return AppSurfaceCard(
      title: 'รายการงานและคะแนน (${assignments.length} ชิ้น)',
      child: assignments.isEmpty
          ? Text(
              'ยังไม่มีชิ้นงานในห้องเรียนนี้',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < assignments.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
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
      SubmissionStatus.submitted => (
        semantic.successContainer,
        semantic.success,
      ),
      SubmissionStatus.late => (semantic.lateContainer, semantic.late),
      SubmissionStatus.missing => (
        colorScheme.surfaceContainer,
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
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DrawerTag(label: status.thaiLabel, bg: statusBg, fg: statusFg),
            if (assignment.isMandatory)
              _DrawerTag(
                label: 'บังคับส่ง',
                bg: semantic.warningContainer,
                fg: semantic.warning,
              ),
            if (isOverMax)
              _DrawerTag(
                label: 'คะแนนเกินเต็ม',
                bg: semantic.dangerContainer,
                fg: semantic.danger,
              ),
            if (assignment.dueDate != null)
              Text(
                'ส่ง ${ThaiDateFormatter.formatShortDate(assignment.dueDate!)}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
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

class _DrawerTag extends StatelessWidget {
  const _DrawerTag({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
