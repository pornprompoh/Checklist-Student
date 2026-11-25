import 'package:flutter/material.dart';

import '../../../../core/utils/thai_date_formatter.dart';

/// Form payload returned by [StudentFormDialog].
class StudentFormResult {
  const StudentFormResult({
    required this.studentNumber,
    required this.studentCode,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    required this.enrolledAt,
    required this.alsoAddToHomeroom,
    this.syncToLinkedClasses = false,
  });

  final int studentNumber;
  final String studentCode;
  final String prefix;
  final String firstName;
  final String lastName;
  final DateTime enrolledAt;
  final bool alsoAddToHomeroom;
  final bool syncToLinkedClasses;
}

/// Dialog for adding or editing a student in either a master homeroom or
/// a subject class (with mid-term `enrolled_at` date in Buddhist Era).
class StudentFormDialog extends StatefulWidget {
  const StudentFormDialog({
    super.key,
    required this.title,
    required this.initialStudentNumber,
    this.initialStudentCode = '',
    this.initialPrefix = '',
    this.initialFirstName = '',
    this.initialLastName = '',
    this.initialEnrolledAt,
    this.showEnrolledAt = false,
    this.showAddToHomeroomOption = false,
    this.showSyncToLinkedClassesOption = false,
    this.linkedClassCount = 0,
  });

  final String title;
  final int initialStudentNumber;
  final String initialStudentCode;
  final String initialPrefix;
  final String initialFirstName;
  final String initialLastName;
  final DateTime? initialEnrolledAt;
  final bool showEnrolledAt;
  final bool showAddToHomeroomOption;
  final bool showSyncToLinkedClassesOption;
  final int linkedClassCount;

  static Future<StudentFormResult?> show(
    BuildContext context, {
    required String title,
    required int initialStudentNumber,
    String initialStudentCode = '',
    String initialPrefix = '',
    String initialFirstName = '',
    String initialLastName = '',
    DateTime? initialEnrolledAt,
    bool showEnrolledAt = false,
    bool showAddToHomeroomOption = false,
    bool showSyncToLinkedClassesOption = false,
    int linkedClassCount = 0,
  }) {
    return showDialog<StudentFormResult>(
      context: context,
      builder: (dialogContext) => StudentFormDialog(
        title: title,
        initialStudentNumber: initialStudentNumber,
        initialStudentCode: initialStudentCode,
        initialPrefix: initialPrefix,
        initialFirstName: initialFirstName,
        initialLastName: initialLastName,
        initialEnrolledAt: initialEnrolledAt,
        showEnrolledAt: showEnrolledAt,
        showAddToHomeroomOption: showAddToHomeroomOption,
        showSyncToLinkedClassesOption: showSyncToLinkedClassesOption,
        linkedClassCount: linkedClassCount,
      ),
    );
  }

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  static const List<String> _prefixShortcuts = <String>[
    'ด.ช.',
    'ด.ญ.',
    'นาย',
    'นางสาว',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late DateTime _enrolledAt;
  bool _alsoAddToHomeroom = true;
  bool _syncToLinkedClasses = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _numberCtrl = TextEditingController(
      text: widget.initialStudentNumber.toString(),
    );
    _codeCtrl = TextEditingController(text: widget.initialStudentCode);
    _prefixCtrl = TextEditingController(text: widget.initialPrefix);
    _firstCtrl = TextEditingController(text: widget.initialFirstName);
    _lastCtrl = TextEditingController(text: widget.initialLastName);
    _enrolledAt =
        widget.initialEnrolledAt ??
        DateTime(today.year, today.month, today.day);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _codeCtrl.dispose();
    _prefixCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEnrolledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _enrolledAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2150),
    );
    if (picked != null && mounted) {
      setState(() {
        _enrolledAt = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      StudentFormResult(
        studentNumber: int.parse(_numberCtrl.text.trim()),
        studentCode: _codeCtrl.text.trim(),
        prefix: _prefixCtrl.text.trim(),
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        enrolledAt: _enrolledAt,
        alsoAddToHomeroom:
            widget.showAddToHomeroomOption && _alsoAddToHomeroom,
        syncToLinkedClasses:
            widget.showSyncToLinkedClassesOption && _syncToLinkedClasses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      controller: _numberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'เลขที่'),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return (n == null || n <= 0) ? 'ระบุ > 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'เลขประจำตัวนักเรียน',
                        hintText: 'เช่น 65001',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกเลขประจำตัว'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final item in _prefixShortcuts)
                    ChoiceChip(
                      label: Text(item),
                      selected: _prefixCtrl.text.trim() == item,
                      onSelected: (_) => setState(() => _prefixCtrl.text = item),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prefixCtrl,
                decoration: const InputDecoration(
                  labelText: 'คำนำหน้า',
                  hintText: 'เช่น ด.ช., ด.ญ., นาย, นางสาว',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อจริง'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'กรุณากรอกชื่อจริง'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastCtrl,
                decoration: const InputDecoration(labelText: 'นามสกุล'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'กรุณากรอกนามสกุล'
                    : null,
              ),
              if (widget.showEnrolledAt) ...[
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickEnrolledDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'วันที่เข้าเรียน (ย้ายเข้ากลางเทอม)',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(ThaiDateFormatter.formatShortDate(_enrolledAt)),
                  ),
                ),
              ],
              if (widget.showAddToHomeroomOption) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _alsoAddToHomeroom,
                  onChanged: (v) =>
                      setState(() => _alsoAddToHomeroom = v ?? false),
                  title: const Text('เพิ่มนักเรียนคนนี้เข้าคลังห้องเรียนกลางด้วย'),
                ),
              ],
              if (widget.showSyncToLinkedClassesOption) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _syncToLinkedClasses,
                  onChanged: (v) =>
                      setState(() => _syncToLinkedClasses = v ?? false),
                  title: Text(
                    widget.linkedClassCount > 0
                        ? 'เพิ่มนักเรียนใหม่เข้าทุกรายวิชาที่ผูกกับห้องนี้อัตโนมัติ (${widget.linkedClassCount} วิชา)'
                        : 'เพิ่มนักเรียนใหม่เข้าทุกรายวิชาที่ผูกกับห้องนี้อัตโนมัติ',
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
        FilledButton(onPressed: _submit, child: const Text('บันทึก')),
      ],
    );
  }
}
