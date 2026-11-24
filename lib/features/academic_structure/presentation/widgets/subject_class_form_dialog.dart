import 'package:flutter/material.dart';

import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/subject_class.dart';

/// Form payload returned by [SubjectClassFormDialog].
class SubjectClassFormResult {
  const SubjectClassFormResult({
    required this.roomName,
    required this.teachingDays,
    required this.isPinned,
    this.autoLinkHomeroom = true,
  });

  final String roomName;
  final List<int> teachingDays;
  final bool isPinned;
  final bool autoLinkHomeroom;
}

/// Dialog for creating or editing a [SubjectClass] (`room_name`,
/// `teaching_days` `1..7`, `is_pinned`, and auto-linking to term `homerooms`).
class SubjectClassFormDialog extends StatefulWidget {
  const SubjectClassFormDialog({
    super.key,
    required this.subjectLabel,
    this.existingClass,
    this.suggestedRoomNames = const <String>[],
  });

  final String subjectLabel;
  final SubjectClass? existingClass;
  final List<String> suggestedRoomNames;

  static Future<SubjectClassFormResult?> show(
    BuildContext context, {
    required String subjectLabel,
    SubjectClass? existingClass,
    List<String> suggestedRoomNames = const <String>[],
  }) {
    return showDialog<SubjectClassFormResult>(
      context: context,
      builder: (dialogContext) => SubjectClassFormDialog(
        subjectLabel: subjectLabel,
        existingClass: existingClass,
        suggestedRoomNames: suggestedRoomNames,
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
  bool _autoLinkHomeroom = true;

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
        autoLinkHomeroom: widget.existingClass == null && _autoLinkHomeroom,
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
        constraints: const BoxConstraints(maxWidth: 440),
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
              if (!isEditing && widget.suggestedRoomNames.isNotEmpty) ...[
                Text(
                  'เลือกจากห้องที่มีอยู่แล้วในเทอมนี้ (หรือพิมพ์ใหม่ด้านล่าง)',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in widget.suggestedRoomNames)
                      ChoiceChip(
                        label: Text(name),
                        selected: _roomCtrl.text.trim() == name,
                        onSelected: (_) => setState(() => _roomCtrl.text = name),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: _roomCtrl,
                autofocus: !isEditing,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'ชื่อห้องเรียน',
                  hintText: 'เช่น ม.4/1',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกชื่อห้องเรียน'
                    : null,
              ),
              if (!isEditing) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoLinkHomeroom,
                  onChanged: (value) =>
                      setState(() => _autoLinkHomeroom = value ?? false),
                  title: const Text('ผูก/สร้างคลังรายชื่อกลางห้องนี้ให้อัตโนมัติ'),
                  subtitle: Text(
                    'ไม่ต้องไปสร้างห้องซ้ำในหน้าคลังรายชื่อ และดึงนักเรียนที่มีอยู่แล้วเข้าวิชานี้ทันที',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
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
