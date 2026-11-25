import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_providers.dart';

/// Responsive header for `GradingPlanPage`: class switcher, exact-decimal plan
/// summary metrics, over-max alert banner, and primary action buttons.
class GradingPlanHeader extends StatelessWidget {
  const GradingPlanHeader({
    super.key,
    required this.classOptions,
    required this.selectedClassId,
    required this.categories,
    required this.assignments,
    required this.overMaxCounts,
    required this.isBusy,
    required this.onSelectClass,
    required this.onAddCategory,
    required this.onAddAssignment,
    required this.onCopyPlan,
    required this.onOpenGradingTable,
  });

  final List<CopyPlanSourceClassOption> classOptions;
  final String? selectedClassId;
  final List<ScoreCategory> categories;
  final List<Assignment> assignments;
  final Map<String, int> overMaxCounts;
  final bool isBusy;
  final ValueChanged<String> onSelectClass;
  final VoidCallback onAddCategory;
  final VoidCallback onAddAssignment;
  final VoidCallback onCopyPlan;
  final VoidCallback onOpenGradingTable;

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
    final totalMaxScore = totalMaxCents / 100.0;
    final mandatoryCount = assignments.where((a) => a.isMandatory).length;
    final overMaxAssignmentCount = overMaxCounts.values
        .where((count) => count > 0)
        .length;
    final overMaxStudentEntries = overMaxCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    final validClassId = classOptions.any(
      (opt) => opt.subjectClassId == selectedClassId,
    )
        ? selectedClassId
        : null;

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
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ออกแบบแผนเก็บงานและเกณฑ์ตัดเกรด',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'กำหนดหมวดคะแนน ชิ้นงานบังคับส่ง เกณฑ์ตัดเกรด และคัดลอกแผนข้ามห้องได้ทันที',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (validClassId != null)
                  OutlinedButton.icon(
                    onPressed: onOpenGradingTable,
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: const Text('ตารางคะแนน'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (classOptions.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey<String?>(validClassId),
                initialValue: validClassId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'เลือกห้องเรียนที่ต้องการจัดการแผน',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                items: [
                  for (final option in classOptions)
                    DropdownMenuItem<String>(
                      value: option.subjectClassId,
                      child: Text(
                        '${option.displayLabel} (${option.termGroupLabel})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null && value != validClassId) {
                    onSelectClass(value);
                  }
                },
              ),
            if (validClassId != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    icon: Icons.calculate_outlined,
                    label:
                        'คะแนนเต็มรวม ${_calculator.formatExactScore(totalMaxScore)} คะแนน',
                    background: colorScheme.primaryContainer,
                    foreground: colorScheme.onPrimaryContainer,
                  ),
                  _MetricChip(
                    icon: Icons.folder_outlined,
                    label: 'หมวดคะแนน ${categories.length} หมวด',
                    background: colorScheme.surfaceContainerHighest,
                    foreground: colorScheme.onSurface,
                  ),
                  _MetricChip(
                    icon: Icons.assignment_outlined,
                    label:
                        'ชิ้นงาน ${assignments.length} ชิ้น (บังคับส่ง $mandatoryCount ชิ้น)',
                    background: colorScheme.surfaceContainerHighest,
                    foreground: colorScheme.onSurface,
                  ),
                  if (overMaxAssignmentCount > 0)
                    _MetricChip(
                      icon: Icons.warning_amber_rounded,
                      label: 'คะแนนเกินเต็ม $overMaxAssignmentCount งาน',
                      background: semantic.dangerContainer,
                      foreground: semantic.danger,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: isBusy ? null : onAddCategory,
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    label: const Text('+ เพิ่มหมวดคะแนน'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: isBusy ? null : onAddAssignment,
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('+ เพิ่มชิ้นงาน'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onCopyPlan,
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text('คัดลอกแผนและเกณฑ์'),
                  ),
                ],
              ),
              if (overMaxAssignmentCount > 0) ...[
                const SizedBox(height: 12),
                AppFeedbackBanner(
                  type: AppFeedbackType.warning,
                  message:
                      'พบคะแนนนักเรียนสูงกว่าคะแนนเต็มใน $overMaxAssignmentCount ชิ้นงาน '
                      '(รวม $overMaxStudentEntries รายการ) กรุณาตรวจสอบและปรับแก้คะแนนในตารางคะแนน',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
