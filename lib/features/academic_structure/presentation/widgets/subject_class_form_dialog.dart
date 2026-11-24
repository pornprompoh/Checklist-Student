import 'package:flutter/material.dart';

import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/subject_class.dart';

/// Form payload returned by [SubjectClassFormDialog].
class SubjectClassFormResult {
  const SubjectClassFormResult({
    required this.roomName,
    required this.teachingDays,
    required this.isPinned,
  });

  final String roomName;
  final List<int> teachingDays;
  final bool isPinned;
}

/// Dialog for creating or editing a [SubjectClass] (`room_name`,
/// `teaching_days` `1..7`, and `is_pinned`).
class SubjectClassFormDialog extends StatefulWidget {
  const SubjectClassFormDialog({
    super.key,
    required this.subjectLabel,
    this.existingClass,
  });

  final String subjectLabel;
  final SubjectClass? existingClass;

  static Future<SubjectClassFormResult?> show(
    BuildContext context, {
    required String subjectLabel,
    SubjectClass? existingClass,
  }) {
    return showDialog<SubjectClassFormResult>(
      context: context,
      builder: (dialogContext) => SubjectClassFormDialog(
        subjectLabel: subjectLabel,
        existingClass: existingClass,
      ),
    );
  }

  @override
  State<SubjectClassFormDialog> createState() => _SubjectClassFormDialogState();
}

class _SubjectClassFormDialogState extends State<SubjectClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomCtrl;
  late final Set<int> _selectedDays;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingClass;
    _roomCtrl = TextEditingController(text: existing?.roomName ?? '');
    _selectedDays = Set<int>.of(existing?.teachingDays ?? const <int>[]);
    _isPinned = existing?.isPinned ?? false;
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  void _toggleDay(int day, bool selected) {
    setState(() {
      if (selected) {
        _selectedDays.add(day);
      } else {
        _selectedDays.remove(day);
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sortedDays = _selectedDays.toList()..sort();
    Navigator.of(context).pop(
      SubjectClassFormResult(
        roomName: _roomCtrl.text.trim(),
        teachingDays: List<int>.unmodifiable(sortedDays),
        isPinned: _isPinned,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingClass != null;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      title: Text(isEditing ? 'แก้ไขห้องเรียน' : 'เพิ่มห้องเรียน'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subjectLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roomCtrl,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'ชื่อห้องเรียน',
                  hintText: 'เช่น ม.4/1',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกชื่อห้องเรียน'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'วันที่มีสอน (ใช้จัดลำดับการ์ดบนหน้าหลัก)',
                style: textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(
                        ThaiDateFormatter.weekdayThaiName(day, short: true),
                      ),
                      selected: _selectedDays.contains(day),
                      onSelected: (selected) => _toggleDay(day, selected),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ปักหมุดห้องนี้บนหน้าหลัก (Dashboard)'),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
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
