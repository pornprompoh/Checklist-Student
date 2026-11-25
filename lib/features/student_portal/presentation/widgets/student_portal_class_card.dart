import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../../domain/entities/student_portal_class_detail.dart';
import 'student_portal_class_assignments_section.dart';
import 'student_portal_class_attendance_section.dart';

/// Responsive subject-class card for Student Portal displaying attendance,
/// server-masked/visible exact scores & grade, and assignment checklist.
class StudentPortalClassCard extends StatelessWidget {
  const StudentPortalClassCard({super.key, required this.detail});

  final StudentPortalClassDetail detail;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detail.subjectCode} ${detail.subjectName}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'ห้อง ${detail.roomName} · เลขที่ ${detail.studentNumber}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (detail.enrollmentStatus == 'transferred_out')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: semantic.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ย้ายออกแล้ว',
                      style: textTheme.labelSmall?.copyWith(
                        color: semantic.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildScoreAndGradeSection(context, colorScheme, textTheme, semantic),
            const Divider(height: 24),
            StudentPortalClassAttendanceSection(
              summary: detail.attendanceSummary,
              records: detail.attendanceRecords,
            ),
            const Divider(height: 24),
            StudentPortalClassAssignmentsSection(
              assignments: detail.assignments,
              showScoreToStudent: detail.showScoreToStudent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreAndGradeSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSemanticColors semantic,
  ) {
    final isSpecialGrade =
        detail.displayedGrade == 'ร' || detail.displayedGrade == 'มส';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final scoreBox = _ScoreSummaryBox(
              showScore: detail.showScoreToStudent,
              totalScore: detail.totalScore,
              totalMaxScore: detail.totalMaxScore,
              calculator: _calculator,
            );
            final gradeBox = _GradeSummaryBox(
              showGrade: detail.showGradeToStudent,
              displayedGrade: detail.displayedGrade,
              isSpecialGrade: isSpecialGrade,
              semantic: semantic,
            );
            if (constraints.maxWidth < 400) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [scoreBox, const SizedBox(height: 8), gradeBox],
              );
            }
            return Row(
              children: [
                Expanded(child: scoreBox),
                const SizedBox(width: 10),
                Expanded(child: gradeBox),
              ],
            );
          },
        ),
        if (detail.showScoreToStudent && detail.categoryScores.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cat in detail.categoryScores)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cat.categoryName}: '
                    '${cat.earnedScore == null ? '-' : _calculator.formatExactScore(cat.earnedScore!)}'
                    '/${_calculator.formatExactScore(cat.maxScore)}',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ScoreSummaryBox extends StatelessWidget {
  const _ScoreSummaryBox({
    required this.showScore,
    required this.totalScore,
    required this.totalMaxScore,
    required this.calculator,
  });

  final bool showScore;
  final double? totalScore;
  final double totalMaxScore;
  final ScoreCalculatorService calculator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'คะแนนรวม',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (!showScore || totalScore == null)
            Text(
              'ครูยังไม่เปิดเผยคะแนนของวิชานี้',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              '${calculator.formatExactScore(totalScore!)} / '
              '${calculator.formatExactScore(totalMaxScore)}',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _GradeSummaryBox extends StatelessWidget {
  const _GradeSummaryBox({
    required this.showGrade,
    required this.displayedGrade,
    required this.isSpecialGrade,
    required this.semantic,
  });

  final bool showGrade;
  final String? displayedGrade;
  final bool isSpecialGrade;
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSpecialGrade
            ? semantic.dangerContainer
            : colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ผลการเรียน (เกรด)',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (!showGrade || displayedGrade == null)
            Text(
              'ครูยังไม่เปิดเผยเกรดของวิชานี้',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              displayedGrade!,
              style: textTheme.titleLarge?.copyWith(
                color: isSpecialGrade ? semantic.danger : colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}
