import 'package:flutter/material.dart';

import '../../../../core/utils/thai_date_formatter.dart';

/// Dialog for creating a new Academic Year in Thai Buddhist Era (2500–2700).
class AcademicYearFormDialog extends StatefulWidget {
  const AcademicYearFormDialog({super.key});

  static Future<int?> show(BuildContext context) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => const AcademicYearFormDialog(),
    );
  }

  @override
  State<AcademicYearFormDialog> createState() => _AcademicYearFormDialogState();
}

class _AcademicYearFormDialogState extends State<AcademicYearFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    final currentBe = ThaiDateFormatter.toBuddhistYear(DateTime.now().year);
    _yearController = TextEditingController(text: currentBe.toString());
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(int.parse(_yearController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('เพิ่มปีการศึกษา (พ.ศ.)'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _yearController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ปีการศึกษา (พ.ศ.)',
              hintText: 'เช่น 2569',
              helperText: 'รองรับปี พ.ศ. ตั้งแต่ 2500 ถึง 2700',
            ),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed < 2500 || parsed > 2700) {
                return 'กรุณากรอกปี พ.ศ. ระหว่าง 2500 ถึง 2700';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
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
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
