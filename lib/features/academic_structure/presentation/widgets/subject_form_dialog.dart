import 'package:flutter/material.dart';

import '../../domain/entities/subject.dart';

/// Form payload returned by [SubjectFormDialog].
class SubjectFormResult {
  const SubjectFormResult({
    required this.subjectCode,
    required this.subjectName,
  });

  final String subjectCode;
  final String subjectName;
}

/// Dialog for creating or editing a [Subject] (`subject_code`, `subject_name`).
class SubjectFormDialog extends StatefulWidget {
  const SubjectFormDialog({
    super.key,
    this.existingSubject,
  });

  final Subject? existingSubject;

  static Future<SubjectFormResult?> show(
    BuildContext context, {
    Subject? existingSubject,
  }) {
    return showDialog<SubjectFormResult>(
      context: context,
      builder: (dialogContext) =>
          SubjectFormDialog(existingSubject: existingSubject),
    );
  }

  @override
  State<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(
      text: widget.existingSubject?.subjectCode ?? '',
    );
    _nameCtrl = TextEditingController(
      text: widget.existingSubject?.subjectName ?? '',
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      SubjectFormResult(
        subjectCode: _codeCtrl.text.trim(),
        subjectName: _nameCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSubject != null;

    return AlertDialog(
      scrollable: true,
      title: Text(isEditing ? 'แก้ไขรายวิชา' : 'เพิ่มรายวิชา'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeCtrl,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'รหัสวิชา',
                  hintText: 'เช่น ว31101',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกรหัสวิชา'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อรายวิชา',
                  hintText: 'เช่น วิทยาการคำนวณ 1',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกชื่อรายวิชา'
                    : null,
                onFieldSubmitted: (_) => _submit(),
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
