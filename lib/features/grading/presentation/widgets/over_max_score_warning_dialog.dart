import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/plan_editor_controller.dart';

/// Confirmation dialog warning the teacher before reducing an assignment's
/// `maxScore` below existing recorded student scores.
class OverMaxScoreWarningDialog extends StatelessWidget {
  const OverMaxScoreWarningDialog({
    super.key,
    required this.assignmentTitle,
    required this.newMaxScore,
    required this.affectedStudents,
  });

  final String assignmentTitle;
  final double newMaxScore;
  final List<OverMaxScoreDetail> affectedStudents;

  static const _calculator = ScoreCalculatorService();

  static Future<bool> show(
    BuildContext context, {
    required String assignmentTitle,
    required double newMaxScore,
    required List<OverMaxScoreDetail> affectedStudents,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => OverMaxScoreWarningDialog(
        assignmentTitle: assignmentTitle,
        newMaxScore: newMaxScore,
        affectedStudents: affectedStudents,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final formattedNewMax = _calculator.formatExactScore(newMaxScore);
    final previewItems = affectedStudents.take(5).toList(growable: false);
    final remainingCount = affectedStudents.length - previewItems.length;

    return AlertDialog(
      scrollable: true,
      icon: Icon(
        Icons.warning_amber_rounded,
        color: semantic.warning,
        size: 32,
      ),
      title: const Text('พบคะแนนเดิมสูงกว่าคะแนนเต็มใหม่'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชิ้นงาน "$assignmentTitle" พบนักเรียน ${affectedStudents.length} คน '
              'ที่มีคะแนนสูงกว่าคะแนนเต็มใหม่ ($formattedNewMax คะแนน)',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: semantic.warningContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: semantic.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ตัวอย่างนักเรียนที่คะแนนเกินเต็ม:',
                    style: textTheme.labelMedium?.copyWith(
                      color: semantic.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final item in previewItems)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.studentLabel,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: semantic.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ได้ ${_calculator.formatExactScore(item.currentScore)} คะแนน',
                            style: textTheme.bodySmall?.copyWith(
                              color: semantic.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (remainingCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'และอีก $remainingCount คน',
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ระบบจะไม่ลบหรือตัดคะแนนเดิมอัตโนมัติ แต่จะไฮไลต์แจ้งเตือนบนชิ้นงานและช่องคะแนนให้คุณครูเข้าไปปรับแก้เอง',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: semantic.warning,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('ยืนยันลดคะแนนเต็ม'),
        ),
      ],
    );
  }
}
