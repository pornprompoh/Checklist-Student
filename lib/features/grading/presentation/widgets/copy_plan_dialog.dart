import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../providers/grading_providers.dart';

/// User selection confirmed from [CopyPlanDialog].
class CopyPlanSelection {
  const CopyPlanSelection({
    required this.sourceClassId,
    required this.replaceExisting,
  });

  final String sourceClassId;
  final bool replaceExisting;
}

/// Dialog allowing teachers to copy score categories, assignments, and grading
/// scale rules from another class (same term or past term/academic year) via
/// RPC `copy_subject_class_plan`.
class CopyPlanDialog extends ConsumerStatefulWidget {
  const CopyPlanDialog({
    super.key,
    required this.targetClassId,
    required this.targetHasExistingPlan,
  });

  final String targetClassId;
  final bool targetHasExistingPlan;

  static Future<CopyPlanSelection?> show(
    BuildContext context, {
    required String targetClassId,
    required bool targetHasExistingPlan,
  }) {
    return showDialog<CopyPlanSelection>(
      context: context,
      builder: (_) => CopyPlanDialog(
        targetClassId: targetClassId,
        targetHasExistingPlan: targetHasExistingPlan,
      ),
    );
  }

  @override
  ConsumerState<CopyPlanDialog> createState() => _CopyPlanDialogState();
}

class _CopyPlanDialogState extends ConsumerState<CopyPlanDialog> {
  String? _selectedSourceClassId;
  bool _replaceExisting = false;

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(allCopyableClassesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      scrollable: true,
      title: const Text('คัดลอกแผนและเกณฑ์'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: optionsAsync.when(
          loading: () => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(height: 48),
              SizedBox(height: 12),
              SkeletonBox(height: 48),
            ],
          ),
          error: (error, _) => AppFeedbackBanner(
            type: AppFeedbackType.error,
            message: ThaiErrorMapper.map(error),
            onRetry: () => ref.invalidate(allCopyableClassesProvider),
          ),
          data: (allOptions) {
            final candidates = allOptions
                .where((item) => item.subjectClassId != widget.targetClassId)
                .toList(growable: false);
            if (candidates.isEmpty) {
              return const AppFeedbackBanner(
                type: AppFeedbackType.info,
                message:
                    'ยังไม่พบห้องเรียนอื่นให้คัดลอกแผน กรุณาสร้างห้องเรียนเพิ่มเติมก่อน',
              );
            }

            final validSelection = candidates.any(
              (c) => c.subjectClassId == _selectedSourceClassId,
            )
                ? _selectedSourceClassId
                : null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'เลือกห้องเรียนต้นทาง (รองรับทั้งห้องอื่นในเทอมเดียวกันและข้ามเทอม/ปีการศึกษา)',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: validSelection,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ห้องเรียนต้นทาง *',
                  ),
                  items: [
                    for (final option in candidates)
                      DropdownMenuItem<String>(
                        value: option.subjectClassId,
                        child: Text(
                          '${option.termGroupLabel} · ${option.displayLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedSourceClassId = value),
                ),
                if (validSelection != null) ...[
                  const SizedBox(height: 12),
                  _SourceClassPreviewBox(sourceClassId: validSelection),
                ],
                const SizedBox(height: 14),
                Text(
                  'รูปแบบการคัดลอกไปยังห้องนี้',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment(value: false, label: Text('เพิ่มต่อท้ายแผนเดิม')),
                    ButtonSegment(value: true, label: Text('แทนที่แผนเดิม')),
                  ],
                  selected: <bool>{_replaceExisting},
                  onSelectionChanged: (selected) =>
                      setState(() => _replaceExisting = selected.first),
                ),
                if (_replaceExisting && widget.targetHasExistingPlan) ...[
                  const SizedBox(height: 12),
                  const AppFeedbackBanner(
                    type: AppFeedbackType.error,
                    message:
                        'คำเตือน: โหมด "แทนที่แผนเดิม" จะลบหมวดคะแนน ชิ้นงาน และคะแนนเดิมทั้งหมดของห้องปลายทางก่อนคัดลอกแผนใหม่',
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _selectedSourceClassId == null
              ? null
              : () => Navigator.of(context).pop(
                  CopyPlanSelection(
                    sourceClassId: _selectedSourceClassId!,
                    replaceExisting: _replaceExisting,
                  ),
                ),
          child: Text(
            _replaceExisting ? 'ยืนยันแทนที่แผนและเกณฑ์' : 'คัดลอกแผนและเกณฑ์',
          ),
        ),
      ],
    );
  }
}

class _SourceClassPreviewBox extends ConsumerWidget {
  const _SourceClassPreviewBox({required this.sourceClassId});

  final String sourceClassId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(classPlanSummaryProvider(sourceClassId));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: previewAsync.when(
        loading: () => const SkeletonBox(height: 20),
        error: (error, _) => Text(
          ThaiErrorMapper.map(error),
          style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        ),
        data: (summary) => Text(
          'สรุปต้นทาง: ${summary.categoryCount} หมวดคะแนน · '
          '${summary.assignmentCount} ชิ้นงาน · '
          'เกณฑ์ ${summary.gradingScaleType.thaiLabel}',
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
