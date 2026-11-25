import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/class_selector_dropdown.dart';
import '../../../../core/widgets/class_workspace_bar.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_providers.dart';

enum _PlanOverflowAction { copyPlan }

/// Top workspace header for [GradingPlanPage]:
/// - Row 1 ([AppPageHeader]): title + `[+ เพิ่มหมวด]` + `[+ เพิ่มชิ้นงาน]` + `⋯`
/// - Row 2 ([ClassWorkspaceBar]): 4 underline tabs + readable class dropdown flush right
/// - Row 3 (Slim Summary Strip): compact exact-decimal plan stat pills
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

    final validClassId =
        classOptions.any((opt) => opt.subjectClassId == selectedClassId)
        ? selectedClassId
        : null;

    final selectorOptions = [
      for (final option in classOptions)
        ClassSelectorOption(
          id: option.subjectClassId,
          label: '${option.displayLabel} (${option.termGroupLabel})',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPageHeader(
          title: 'แผนเก็บงานและเกณฑ์ตัดเกรด',
          actions: [
            if (validClassId != null) ...[
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onAddCategory,
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('เพิ่มหมวด'),
              ),
              FilledButton.icon(
                onPressed: isBusy ? null : onAddAssignment,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('เพิ่มชิ้นงาน'),
              ),
              PopupMenuButton<_PlanOverflowAction>(
                tooltip: 'ตัวเลือกเพิ่มเติม',
                enabled: !isBusy,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (action) {
                  switch (action) {
                    case _PlanOverflowAction.copyPlan:
                      onCopyPlan();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _PlanOverflowAction.copyPlan,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.copy_all_rounded, size: 18),
                      title: Text('คัดลอกแผนและเกณฑ์'),
                    ),
                  ),
                ],
              ),
            ],
          ],
          bottom: validClassId == null
              ? null
              : ClassWorkspaceBar(
                  subjectClassId: validClassId,
                  activeTab: ClassWorkspaceTab.plan,
                  trailing: selectorOptions.isEmpty
                      ? null
                      : ClassSelectorDropdown(
                          options: selectorOptions,
                          selectedId: validClassId,
                          enabled: !isBusy,
                          onSelected: onSelectClass,
                        ),
                ),
        ),
        if (validClassId != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PlanStatPill(
                icon: Icons.calculate_outlined,
                label:
                    'คะแนนเต็มรวม ${_calculator.formatExactScore(totalMaxScore)}',
                background: colorScheme.primaryContainer,
                foreground: colorScheme.onPrimaryContainer,
              ),
              _PlanStatPill(
                icon: Icons.folder_outlined,
                label: '${categories.length} หมวด',
                background: colorScheme.surfaceContainer,
                foreground: colorScheme.onSurface,
              ),
              _PlanStatPill(
                icon: Icons.assignment_outlined,
                label:
                    '${assignments.length} ชิ้นงาน (บังคับส่ง $mandatoryCount)',
                background: colorScheme.surfaceContainer,
                foreground: colorScheme.onSurface,
              ),
              if (overMaxAssignmentCount > 0)
                _PlanStatPill(
                  icon: Icons.warning_amber_rounded,
                  label: 'เกินเต็ม $overMaxAssignmentCount งาน',
                  background: semantic.dangerContainer,
                  foreground: semantic.danger,
                ),
            ],
          ),
        ],
        if (validClassId != null && overMaxAssignmentCount > 0) ...[
          const SizedBox(height: 10),
          AppFeedbackBanner(
            type: AppFeedbackType.warning,
            message:
                'พบคะแนนนักเรียนสูงกว่าคะแนนเต็มใน $overMaxAssignmentCount ชิ้นงาน '
                '(รวม $overMaxStudentEntries รายการ) กรุณาตรวจสอบและปรับแก้ในตารางคะแนน',
          ),
        ],
      ],
    );
  }
}

class _PlanStatPill extends StatelessWidget {
  const _PlanStatPill({
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
