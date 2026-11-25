import 'package:flutter/material.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/services/score_calculator_service.dart';

/// Result returned when submitting [ScoreCellDetailDialog].
class ScoreCellDetailResult {
  const ScoreCellDetailResult({
    required this.status,
    required this.score,
    required this.note,
  });

  final SubmissionStatus status;
  final double? score;
  final String note;
}

/// Dialog allowing teachers to edit submission status (`ส่งแล้ว` / `ส่งช้า` /
/// `ยังไม่ส่ง`), exact decimal score, and per-cell note for one student cell.
class ScoreCellDetailDialog extends StatefulWidget {
  const ScoreCellDetailDialog({
    super.key,
    required this.studentLabel,
    required this.assignment,
    this.existingScore,
  });

  final String studentLabel;
  final Assignment assignment;
  final StudentScore? existingScore;

  static Future<ScoreCellDetailResult?> show(
    BuildContext context, {
    required String studentLabel,
    required Assignment assignment,
    StudentScore? existingScore,
  }) {
    return showDialog<ScoreCellDetailResult>(
      context: context,
      builder: (_) => ScoreCellDetailDialog(
        studentLabel: studentLabel,
        assignment: assignment,
        existingScore: existingScore,
      ),
    );
  }

  @override
  State<ScoreCellDetailDialog> createState() => _ScoreCellDetailDialogState();
}

class _ScoreCellDetailDialogState extends State<ScoreCellDetailDialog> {
  static const _calculator = ScoreCalculatorService();

  final _formKey = GlobalKey<FormState>();
  late SubmissionStatus _status;
  late TextEditingController _scoreCtrl;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingScore;
    _status = existing?.submissionStatus ?? SubmissionStatus.missing;
    _scoreCtrl = TextEditingController(
      text: existing?.score == null
          ? ''
          : _calculator.formatExactScore(existing!.score!),
    );
    _noteCtrl = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawScore = _scoreCtrl.text.trim();
    final parsedScore = rawScore.isEmpty ? null : double.parse(rawScore);
    final effectiveStatus =
        parsedScore != null && _status == SubmissionStatus.missing
        ? SubmissionStatus.submitted
        : _status;
    Navigator.of(context).pop(
      ScoreCellDetailResult(
        status: effectiveStatus,
        score: parsedScore,
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final maxText = _calculator.formatExactScore(widget.assignment.maxScore);
    final parsedNow = double.tryParse(_scoreCtrl.text.trim());
    final isOverMax =
        parsedNow != null &&
        (parsedNow * 100).round() > (widget.assignment.maxScore * 100).round();

    return AlertDialog(
      scrollable: true,
      title: Text(widget.assignment.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.studentLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<SubmissionStatus>(
                showSelectedIcon: false,
                segments: [
                  for (final status in SubmissionStatus.values)
                    ButtonSegment<SubmissionStatus>(
                      value: status,
                      label: Text(status.thaiLabel),
                    ),
                ],
                selected: <SubmissionStatus>{_status},
                onSelectionChanged: (selection) =>
                    setState(() => _status = selection.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _scoreCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'คะแนนที่ได้ (ไม่บังคับ)',
                  suffixText: '/ เต็ม $maxText',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return null;
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null || !parsed.isFinite || parsed < 0) {
                    return 'กรุณากรอกคะแนนเป็นตัวเลขที่ไม่ติดลบ';
                  }
                  return null;
                },
              ),
              if (isOverMax) ...[
                const SizedBox(height: 6),
                Text(
                  'คำเตือน: คะแนนสูงกว่าคะแนนเต็ม ($maxText คะแนน) ช่องนี้จะถูกไฮไลต์เตือนในตาราง',
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุรายช่อง (ไม่บังคับ)',
                  hintText: 'เช่น ส่งแก้งานครั้งที่ 2, ขาดอุปกรณ์',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(onPressed: _submit, child: const Text('บันทึก')),
      ],
    );
  }
}
