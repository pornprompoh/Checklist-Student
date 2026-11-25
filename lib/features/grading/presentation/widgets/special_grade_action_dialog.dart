import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/services/score_calculator_service.dart';

/// Teacher decision returned from [SpecialGradeActionDialog].
class SpecialGradeActionDecision {
  const SpecialGradeActionDecision({
    required this.specialGradeOverride,
    required this.markRResolved,
    required this.markMsResolved,
    required this.feedbackMessage,
  });

  final String? specialGradeOverride;
  final bool markRResolved;
  final bool markMsResolved;
  final String feedbackMessage;
}

/// Dialog letting teachers explicitly confirm `ร` / `มส`, record resolution
/// (returning immediately to the normal evaluated grade with teacher-only tag),
/// or clear an accidental override.
class SpecialGradeActionDialog extends StatelessWidget {
  const SpecialGradeActionDialog({
    super.key,
    required this.studentLabel,
    required this.gradeResult,
  });

  final String studentLabel;
  final GradeResult gradeResult;

  static const _calculator = ScoreCalculatorService();

  static Future<SpecialGradeActionDecision?> show(
    BuildContext context, {
    required String studentLabel,
    required GradeResult gradeResult,
  }) {
    return showDialog<SpecialGradeActionDecision>(
      context: context,
      builder: (_) => SpecialGradeActionDialog(
        studentLabel: studentLabel,
        gradeResult: gradeResult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final override = gradeResult.specialGradeOverride;
    final advice = gradeResult.specialGradeAdvice;
    final totalText = _calculator.formatExactScore(gradeResult.totalScore);
    final maxText = _calculator.formatExactScore(gradeResult.totalMaxScore);

    return AlertDialog(
      scrollable: true,
      title: const Text('จัดการสถานะเกรดพิเศษ (ร / มส)'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              studentLabel,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'คะแนนรวม: $totalText / $maxText · เกรดปกติ: ${gradeResult.evaluatedGrade}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (!advice.isAllAssignmentsAssessed &&
                advice.totalAssignmentsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ระบบจะเริ่มแนะนำติด ร อัตโนมัติเมื่อกรอกคะแนนครบทุกชิ้นงานในแผน '
                        '(กรอกแล้ว ${advice.assessedAssignmentsCount}/${advice.totalAssignmentsCount} งาน)',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (advice.reasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: semantic.warningContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คำแนะนำจากระบบ:',
                      style: textTheme.labelMedium?.copyWith(
                        color: semantic.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final reason in advice.reasons)
                      Text(
                        '• $reason',
                        style: textTheme.bodySmall?.copyWith(
                          color: semantic.warning,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (override == null) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: semantic.danger,
                  foregroundColor: colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(
                  const SpecialGradeActionDecision(
                    specialGradeOverride: 'ร',
                    markRResolved: false,
                    markMsResolved: false,
                    feedbackMessage: 'ยืนยันสถานะติด "ร" เรียบร้อยแล้ว',
                  ),
                ),
                icon: const Icon(Icons.assignment_late_outlined, size: 18),
                label: const Text('ยืนยันติด ร'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pop(
                  const SpecialGradeActionDecision(
                    specialGradeOverride: 'มส',
                    markRResolved: false,
                    markMsResolved: false,
                    feedbackMessage: 'ยืนยันสถานะติด "มส" เรียบร้อยแล้ว',
                  ),
                ),
                icon: const Icon(Icons.event_busy_outlined, size: 18),
                label: const Text('ยืนยันติด มส'),
              ),
            ] else ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: semantic.success,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(
                  SpecialGradeActionDecision(
                    specialGradeOverride: null,
                    markRResolved: override == 'ร',
                    markMsResolved: override == 'มส',
                    feedbackMessage:
                        'บันทึกแก้ $override ผ่านแล้ว — แสดงเกรด ${gradeResult.evaluatedGrade} ทันที',
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  'บันทึกแก้ $override ผ่านแล้ว → เกรด ${gradeResult.evaluatedGrade}',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final nextCode = override == 'ร' ? 'มส' : 'ร';
                  Navigator.of(context).pop(
                    SpecialGradeActionDecision(
                      specialGradeOverride: nextCode,
                      markRResolved: false,
                      markMsResolved: false,
                      feedbackMessage: 'เปลี่ยนสถานะเป็น "$nextCode" แล้ว',
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text('เปลี่ยนเป็นติด ${override == 'ร' ? 'มส' : 'ร'}'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  const SpecialGradeActionDecision(
                    specialGradeOverride: null,
                    markRResolved: false,
                    markMsResolved: false,
                    feedbackMessage: 'ยกเลิกสถานะเกรดพิเศษแล้ว',
                  ),
                ),
                child: const Text('ยกเลิกสถานะ (กรณีกดผิด)'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ปิด'),
        ),
      ],
    );
  }
}
