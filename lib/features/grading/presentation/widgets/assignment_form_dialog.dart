import 'package:flutter/material.dart';

import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/services/score_calculator_service.dart';

/// Result returned when submitting [AssignmentFormDialog].
class AssignmentFormResult {
  const AssignmentFormResult({
    required this.title,
    this.categoryId,
    required this.maxScore,
    required this.description,
    required this.isMandatory,
    this.dueDate,
  });

  final String title;
  final String? categoryId;
  final double maxScore;
  final String description;
  final bool isMandatory;
  final DateTime? dueDate;
}

/// Dialog for creating or editing an [Assignment] (`public.assignments`).
class AssignmentFormDialog extends StatefulWidget {
  const AssignmentFormDialog({
    super.key,
    required this.categories,
    this.existing,
    this.initialCategoryId,
  });

  final List<ScoreCategory> categories;
  final Assignment? existing;
  final String? initialCategoryId;

  static Future<AssignmentFormResult?> show(
    BuildContext context, {
    required List<ScoreCategory> categories,
    Assignment? existing,
    String? initialCategoryId,
  }) {
    return showDialog<AssignmentFormResult>(
      context: context,
      builder: (_) => AssignmentFormDialog(
        categories: categories,
        existing: existing,
        initialCategoryId: initialCategoryId,
      ),
    );
  }

  @override
  State<AssignmentFormDialog> createState() => _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends State<AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _maxScoreCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedCategoryId;
  bool _isMandatory = false;
  DateTime? _dueDate;

  static const _calculator = ScoreCalculatorService();

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _maxScoreCtrl = TextEditingController(
      text: item == null ? '10' : _calculator.formatExactScore(item.maxScore),
    );
    _descCtrl = TextEditingController(text: item?.description ?? '');
    final candidateCategoryId = item?.categoryId ?? widget.initialCategoryId;
    final hasCategory = widget.categories.any(
      (c) => c.id == candidateCategoryId,
    );
    _selectedCategoryId = hasCategory ? candidateCategoryId : null;
    _isMandatory = item?.isMandatory ?? false;
    _dueDate = item?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _maxScoreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'เลือกกำหนดส่งงาน',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      AssignmentFormResult(
        title: _titleCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        maxScore: double.parse(_maxScoreCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        isMandatory: _isMandatory,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      scrollable: true,
      title: Text(isEditing ? 'แก้ไขชิ้นงาน / รายการสอบ' : 'เพิ่มชิ้นงาน / รายการสอบ'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ชื่อชิ้นงาน / รายการสอบ *',
                  hintText: 'เช่น ใบงานที่ 1, สอบกลางภาค',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาระบุชื่อชิ้นงานหรือรายการสอบ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'หมวดคะแนน'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(ScoreCalculatorService.uncategorizedLabel),
                  ),
                  for (final category in widget.categories)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxScoreCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'คะแนนเต็ม *',
                  suffixText: 'คะแนน',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || !parsed.isFinite || parsed < 0) {
                    return 'กรุณากรอกตัวเลขที่ไม่ติดลบ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'คำอธิบายเพิ่มเติม (ไม่บังคับ)',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('งานบังคับส่ง'),
                subtitle: const Text(
                  'หากนักเรียนไม่ส่งงานนี้ ระบบจะแนะนำสถานะ ร ให้อัตโนมัติ',
                ),
                value: _isMandatory,
                onChanged: (value) => setState(() => _isMandatory = value),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _dueDate == null
                            ? 'กำหนดส่ง (ไม่ระบุ)'
                            : 'กำหนดส่ง: ${ThaiDateFormatter.formatShortDate(_dueDate!)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'ล้างวันที่กำหนดส่ง',
                      onPressed: () => setState(() => _dueDate = null),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (isEditing) ...[
                const SizedBox(height: 8),
                Text(
                  'หากลดคะแนนเต็มต่ำกว่าคะแนนเดิมที่มีนักเรียนได้แล้ว ระบบจะแจ้งเตือนก่อนบันทึก',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
          child: Text(isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มชิ้นงาน'),
        ),
      ],
    );
  }
}
