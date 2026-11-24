import 'package:flutter/material.dart';

import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/term.dart';

/// Form payload returned by [TermFormDialog].
class TermFormResult {
  const TermFormResult({
    required this.academicYearId,
    required this.termLabel,
    required this.startDate,
    required this.endDate,
  });

  final String academicYearId;
  final String termLabel;
  final DateTime startDate;
  final DateTime endDate;
}

/// Dialog for creating or editing a [Term] with Buddhist Era date pickers
/// and `endDate >= startDate` validation.
class TermFormDialog extends StatefulWidget {
  const TermFormDialog({
    super.key,
    required this.academicYears,
    this.initialYearId,
    this.existingTerm,
  });

  final List<AcademicYear> academicYears;
  final String? initialYearId;
  final Term? existingTerm;

  static Future<TermFormResult?> show(
    BuildContext context, {
    required List<AcademicYear> academicYears,
    String? initialYearId,
    Term? existingTerm,
  }) {
    return showDialog<TermFormResult>(
      context: context,
      builder: (dialogContext) => TermFormDialog(
        academicYears: academicYears,
        initialYearId: initialYearId,
        existingTerm: existingTerm,
      ),
    );
  }

  @override
  State<TermFormDialog> createState() => _TermFormDialogState();
}

class _TermFormDialogState extends State<TermFormDialog> {
  static const List<String> _presets = <String>['1', '2', 'ฤดูร้อน'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late String _selectedYearId;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _dateError;

  bool get _isEditing => widget.existingTerm != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTerm;
    final today = DateTime.now();
    _selectedYearId =
        existing?.academicYearId ??
        widget.initialYearId ??
        widget.academicYears.first.id;
    _labelCtrl = TextEditingController(text: existing?.termLabel ?? '1');
    _startDate =
        existing?.startDate ?? DateTime(today.year, today.month, today.day);
    _endDate =
        existing?.endDate ??
        DateTime(today.year, today.month, today.day).add(const Duration(days: 140));
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2150),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = _dateOnly(picked);
      } else {
        _endDate = _dateOnly(picked);
      }
      _validateDates();
    });
  }

  bool _validateDates() {
    if (_dateOnly(_endDate).isBefore(_dateOnly(_startDate))) {
      _dateError = 'วันสิ้นสุดเทอมต้องไม่ก่อนวันเริ่มต้นเทอม';
      return false;
    }
    _dateError = null;
    return true;
  }

  void _submit() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final datesValid = _validateDates();
    setState(() {});
    if (!formValid || !datesValid) return;

    Navigator.of(context).pop(
      TermFormResult(
        academicYearId: _selectedYearId,
        termLabel: _labelCtrl.text.trim(),
        startDate: _dateOnly(_startDate),
        endDate: _dateOnly(_endDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      scrollable: true,
      title: Text(_isEditing ? 'แก้ไขข้อมูลเทอม' : 'เพิ่มเทอมใหม่'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedYearId,
                decoration: const InputDecoration(
                  labelText: 'ปีการศึกษา (พ.ศ.)',
                ),
                items: [
                  for (final year in widget.academicYears)
                    DropdownMenuItem<String>(
                      value: year.id,
                      child: Text('ปีการศึกษา ${year.yearBe}'),
                    ),
                ],
                onChanged: _isEditing
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedYearId = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final preset in _presets)
                    ChoiceChip(
                      label: Text('เทอม $preset'),
                      selected: _labelCtrl.text.trim() == preset,
                      onSelected: (_) => setState(() => _labelCtrl.text = preset),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเทอม',
                  hintText: 'เช่น 1, 2 หรือ ฤดูร้อน',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกชื่อเทอม'
                    : null,
              ),
              const SizedBox(height: 14),
              _DatePickerFieldTile(
                label: 'วันเริ่มต้นเทอม',
                valueText: ThaiDateFormatter.formatShortDate(_startDate),
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 10),
              _DatePickerFieldTile(
                label: 'วันสิ้นสุดเทอม',
                valueText: ThaiDateFormatter.formatShortDate(_endDate),
                onTap: () => _pickDate(isStart: false),
              ),
              if (_dateError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _dateError!,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
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

class _DatePickerFieldTile extends StatelessWidget {
  const _DatePickerFieldTile({
    required this.label,
    required this.valueText,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        child: Text(valueText),
      ),
    );
  }
}
