import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/services/score_calculator_service.dart';

/// Card displaying one [ScoreCategory] (or uncategorized group when [category]
/// is `null`) and its assignments, highlighting any assignment with over-max
/// student scores.
class ScoreCategorySectionCard extends StatelessWidget {
  const ScoreCategorySectionCard({
    super.key,
    required this.category,
    required this.assignments,
    required this.overMaxCounts,
    required this.isBusy,
    required this.onAddAssignment,
    this.onEditCategory,
    this.onDeleteCategory,
    required this.onEditAssignment,
    required this.onDeleteAssignment,
  });

  final ScoreCategory? category;
  final List<Assignment> assignments;
  final Map<String, int> overMaxCounts;
  final bool isBusy;
  final VoidCallback onAddAssignment;
  final VoidCallback? onEditCategory;
  final VoidCallback? onDeleteCategory;
  final ValueChanged<Assignment> onEditAssignment;
  final ValueChanged<Assignment> onDeleteAssignment;

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
    final totalMax = totalMaxCents / 100.0;
    final targetMax = category?.targetMaxScore;
    final totalText = targetMax == null
        ? 'รวม ${_calculator.formatExactScore(totalMax)} คะแนน'
        : 'รวม ${_calculator.formatExactScore(totalMax)} / เป้าหมาย '
              '${_calculator.formatExactScore(targetMax)} คะแนน';
    final exceedsTarget =
        targetMax != null && totalMaxCents > (targetMax * 100).round();

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
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ??
                          ScoreCalculatorService.uncategorizedLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalText · ${assignments.length} งาน',
                      style: textTheme.bodySmall?.copyWith(
                        color: exceedsTarget
                            ? semantic.warning
                            : colorScheme.onSurfaceVariant,
                        fontWeight: exceedsTarget ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: isBusy ? null : onAddAssignment,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('เพิ่มงาน'),
                    ),
                    if (category != null && onEditCategory != null)
                      IconButton(
                        tooltip: 'แก้ไขหมวดคะแนน',
                        onPressed: isBusy ? null : onEditCategory,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    if (category != null && onDeleteCategory != null)
                      IconButton(
                        tooltip: 'ลบหมวดคะแนน',
                        onPressed: isBusy ? null : onDeleteCategory,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: semantic.danger,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            if (assignments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'ยังไม่มีชิ้นงานในหมวดนี้ กด "+ เพิ่มงาน" เพื่อเริ่มต้น',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < assignments.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _AssignmentTile(
                      assignment: assignments[i],
                      overMaxCount: overMaxCounts[assignments[i].id] ?? 0,
                      isBusy: isBusy,
                      onEdit: () => onEditAssignment(assignments[i]),
                      onDelete: () => onDeleteAssignment(assignments[i]),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    required this.assignment,
    required this.overMaxCount,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final Assignment assignment;
  final int overMaxCount;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final hasOverMax = overMaxCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasOverMax
            ? semantic.warningContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasOverMax ? semantic.danger : colorScheme.outlineVariant,
          width: hasOverMax ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (assignment.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    assignment.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PillBadge(
                      label:
                          'เต็ม ${_calculator.formatExactScore(assignment.maxScore)} คะแนน',
                      background: colorScheme.primaryContainer,
                      foreground: colorScheme.onPrimaryContainer,
                    ),
                    if (assignment.isMandatory)
                      _PillBadge(
                        label: 'บังคับส่ง',
                        background: semantic.warningContainer,
                        foreground: semantic.warning,
                      ),
                    if (assignment.dueDate != null)
                      _PillBadge(
                        label:
                            'ส่ง ${ThaiDateFormatter.formatShortDate(assignment.dueDate!)}',
                        background: colorScheme.surfaceContainerHighest,
                        foreground: colorScheme.onSurfaceVariant,
                      ),
                    if (hasOverMax)
                      _PillBadge(
                        label: 'คะแนนเกินเต็ม $overMaxCount คน',
                        background: semantic.dangerContainer,
                        foreground: semantic.danger,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'แก้ไขชิ้นงาน',
                visualDensity: VisualDensity.compact,
                onPressed: isBusy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'ลบชิ้นงาน',
                visualDensity: VisualDensity.compact,
                onPressed: isBusy ? null : onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: semantic.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
