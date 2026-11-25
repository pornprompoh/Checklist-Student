import 'package:flutter/material.dart';

import '../../domain/entities/score_category.dart';
import '../../domain/services/score_calculator_service.dart';

/// Result returned when submitting [ScoreCategoryFormDialog].
class ScoreCategoryFormResult {
  const ScoreCategoryFormResult({
    required this.name,
    this.targetMaxScore,
    this.sortOrder,
  });

  final String name;
  final double? targetMaxScore;
  final int? sortOrder;
}

/// Dialog for creating or editing a [ScoreCategory] (`public.score_categories`).
class ScoreCategoryFormDialog extends StatefulWidget {
  const ScoreCategoryFormDialog({super.key, this.existing});

  final ScoreCategory? existing;

  static Future<ScoreCategoryFormResult?> show(
    BuildContext context, {
    ScoreCategory? existing,
  }) {
    return showDialog<ScoreCategoryFormResult>(
      context: context,
      builder: (_) => ScoreCategoryFormDialog(existing: existing),
    );
  }

  @override
  State<ScoreCategoryFormDialog> createState() =>
      _ScoreCategoryFormDialogState();
}

class _ScoreCategoryFormDialogState extends State<ScoreCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetScoreCtrl;
  late final TextEditingController _sortOrderCtrl;

  static const _calculator = ScoreCalculatorService();

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _targetScoreCtrl = TextEditingController(
      text: item?.targetMaxScore == null
          ? ''
          : _calculator.formatExactScore(item!.targetMaxScore!),
    );
    _sortOrderCtrl = TextEditingController(
      text: item == null ? '' : '${item.sortOrder}',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetScoreCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawTarget = _targetScoreCtrl.text.trim();
    final rawOrder = _sortOrderCtrl.text.trim();
    Navigator.of(context).pop(
      ScoreCategoryFormResult(
        name: _nameCtrl.text.trim(),
        targetMaxScore: rawTarget.isEmpty ? null : double.parse(rawTarget),
        sortOrder: rawOrder.isEmpty ? null : int.parse(rawOrder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      scrollable: true,
      title: Text(isEditing ? 'แก้ไขหมวดคะแนน' : 'เพิ่มหมวดคะแนน'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ชื่อหมวดคะแนน *',
                  hintText: 'เช่น คะแนนเก็บ, สอบกลางภาค, สอบปลายภาค',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาระบุชื่อหมวดคะแนน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetScoreCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'คะแนนเต็มเป้าหมาย (ไม่บังคับ)',
                  hintText: 'เช่น 60',
                  suffixText: 'คะแนน',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return null;
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null || !parsed.isFinite || parsed < 0) {
                    return 'กรุณากรอกตัวเลขที่ไม่ติดลบ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sortOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ลำดับการแสดงผล (ไม่บังคับ)',
                  hintText: 'เว้นว่างเพื่อต่อท้ายอัตโนมัติ',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return null;
                  final parsed = int.tryParse(trimmed);
                  if (parsed == null || parsed < 0) {
                    return 'กรุณากรอกจำนวนเต็มตั้งแต่ 0 ขึ้นไป';
                  }
                  return null;
                },
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
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มหมวดคะแนน'),
        ),
      ],
    );
  }
}
