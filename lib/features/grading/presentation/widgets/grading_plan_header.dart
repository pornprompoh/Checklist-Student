import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/class_workspace_bar.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_providers.dart';

/// Top workspace header for [GradingPlanPage]:
/// [AppPageHeader] with 1 primary CTA (`+ เพิ่มชิ้นงาน`), [ClassWorkspaceBar],
/// class switcher, and compact exact-decimal plan summary strip.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPageHeader(
          title: 'ออกแบบแผนเก็บงานและเกณฑ์ตัดเกรด',
          actions: [
            if (validClassId != null) ...[
              OutlinedButton.icon(
                onPressed: isBusy ? null : onCopyPlan,
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('คัดลอกแผนและเกณฑ์'),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onAddCategory,
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('เพิ่มหมวดคะแนน'),
              ),
              FilledButton.icon(
                onPressed: isBusy ? null : onAddAssignment,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('เพิ่มชิ้นงาน'),
              ),
            ],
          ],
          bottom: validClassId == null
              ? null
              : ClassWorkspaceBar(
                  subjectClassId: validClassId,
                  activeTab: ClassWorkspaceTab.plan,
                ),
        ),
        const SizedBox(height: 12),
        if (classOptions.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String?>(validClassId),
                  initialValue: validClassId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ห้องเรียน',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
              ),
              if (validClassId != null)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
          ),
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
