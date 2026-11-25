import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../../domain/entities/student_portal_class_detail.dart';

/// Zone 1 of `StudentPortalClassCard`: exact unrounded score & grade summary
/// with calm, polite privacy-masking boxes when hidden by the teacher.
class StudentPortalScoreGradeStrip extends StatelessWidget {
  const StudentPortalScoreGradeStrip({super.key, required this.detail});

  final StudentPortalClassDetail detail;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final isSpecialGrade =
        detail.displayedGrade == 'ร' || detail.displayedGrade == 'มส';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final scoreBox = _ScoreBox(
              showScore: detail.showScoreToStudent,
              totalScore: detail.totalScore,
              totalMaxScore: detail.totalMaxScore,
              calculator: _calculator,
            );
            final gradeBox = _GradeBox(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: scoreBox),
                const SizedBox(width: 12),
                Expanded(child: gradeBox),
              ],
            );
          },
        ),
        if (detail.showScoreToStudent && detail.categoryScores.isNotEmpty) ...[
          const SizedBox(height: 10),
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
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cat.categoryName}: '
                    '${cat.earnedScore == null ? '-' : _calculator.formatExactScore(cat.earnedScore!)}'
                    '/${_calculator.formatExactScore(cat.maxScore)}',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: AppTheme.tabularFigures,
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

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
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
    final isVisible = showScore && totalScore != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVisible
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isVisible
              ? colorScheme.primary.withValues(alpha: 0.22)
              : colorScheme.outlineVariant,
        ),
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
          if (!isVisible)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.visibility_off_outlined,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ครูยังไม่เปิดเผยคะแนนของวิชานี้',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              '${calculator.formatExactScore(totalScore!)} / '
              '${calculator.formatExactScore(totalMaxScore)}',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
        ],
      ),
    );
  }
}

class _GradeBox extends StatelessWidget {
  const _GradeBox({
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
    final isVisible = showGrade && displayedGrade != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: !isVisible
            ? colorScheme.surfaceContainerLow
            : (isSpecialGrade
                  ? semantic.dangerContainer
                  : colorScheme.secondaryContainer.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: !isVisible
              ? colorScheme.outlineVariant
              : (isSpecialGrade
                    ? semantic.danger.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant),
        ),
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
          if (!isVisible)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.visibility_off_outlined,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ครูยังไม่เปิดเผยเกรดของวิชานี้',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              displayedGrade!,
              style: textTheme.titleLarge?.copyWith(
                color: isSpecialGrade ? semantic.danger : colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
        ],
      ),
    );
  }
}
