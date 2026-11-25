import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/services/score_calculator_service.dart';

/// Frozen top header row for [FrozenGradeGrid] keeping the left student header
/// locked while syncing horizontal scroll with assignment and summary columns.
class FrozenGradeGridHeader extends StatelessWidget {
  const FrozenGradeGridHeader({
    super.key,
    required this.assignments,
    required this.leftColumnWidth,
    required this.assignmentColWidth,
    required this.totalColWidth,
    required this.gradeColWidth,
    required this.headerHeight,
    required this.horizontalController,
  });

  final List<Assignment> assignments;
  final double leftColumnWidth;
  final double assignmentColWidth;
  final double totalColWidth;
  final double gradeColWidth;
  final double headerHeight;
  final ScrollController horizontalController;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final totalMaxCents = assignments.fold<int>(
      0,
      (sum, item) => sum + (item.maxScore * 100).round(),
    );
    final totalMaxLabel = _calculator.formatExactScore(totalMaxCents / 100.0);

    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          Container(
            width: leftColumnWidth,
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                right: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
                bottom: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
              ),
            ),
            child: Text(
              'เลขที่ / ชื่อ-นามสกุล',
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final assignment in assignments)
                    Tooltip(
                      message: _assignmentTooltip(assignment),
                      child: Container(
                        width: assignmentColWidth,
                        height: headerHeight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          border: Border(
                            right: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            bottom: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              assignment.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'เต็ม ${_calculator.formatExactScore(assignment.maxScore)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (assignment.isMandatory) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: semantic.warningContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'บังคับ',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: semantic.warning,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (assignment.dueDate != null)
                              Text(
                                ThaiDateFormatter.formatShortDate(
                                  assignment.dueDate!,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  _SummaryHeaderCell(
                    width: totalColWidth,
                    height: headerHeight,
                    title: 'รวม',
                    subtitle: 'เต็ม $totalMaxLabel',
                  ),
                  _SummaryHeaderCell(
                    width: gradeColWidth,
                    height: headerHeight,
                    title: 'เกรด',
                    subtitle: 'ผลประเมิน',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _assignmentTooltip(Assignment assignment) {
    final maxText = _calculator.formatExactScore(assignment.maxScore);
    final parts = <String>[
      assignment.title,
      'คะแนนเต็ม $maxText',
      if (assignment.isMandatory) 'งานบังคับส่ง',
      if (assignment.dueDate != null)
        'กำหนดส่ง ${ThaiDateFormatter.formatShortDate(assignment.dueDate!)}',
    ];
    return parts.join(' · ');
  }
}

class _SummaryHeaderCell extends StatelessWidget {
  const _SummaryHeaderCell({
    required this.width,
    required this.height,
    required this.title,
    required this.subtitle,
  });

  final double width;
  final double height;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
