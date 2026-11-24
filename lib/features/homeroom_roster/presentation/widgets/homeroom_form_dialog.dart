import 'package:flutter/material.dart';

/// Dialog for creating or renaming a master [Homeroom] (e.g. `ม.4/1`).
class HomeroomFormDialog extends StatefulWidget {
  const HomeroomFormDialog({
    super.key,
    this.initialName,
  });

  final String? initialName;

  static Future<String?> show(BuildContext context, {String? initialName}) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => HomeroomFormDialog(initialName: initialName),
    );
  }

  @override
  State<HomeroomFormDialog> createState() => _HomeroomFormDialogState();
}

class _HomeroomFormDialogState extends State<HomeroomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_nameCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return AlertDialog(
      scrollable: true,
      title: Text(isEditing ? 'เปลี่ยนชื่อคลังห้องเรียน' : 'สร้างคลังห้องเรียนใหม่'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'ชื่อห้องเรียน',
              hintText: 'เช่น ม.4/1',
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'กรุณากรอกชื่อห้องเรียน'
                : null,
            onFieldSubmitted: (_) => _submit(),
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
