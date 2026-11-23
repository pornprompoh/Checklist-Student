import 'package:flutter/material.dart';

import '../../../auth/domain/entities/teacher_profile.dart';
import '../../domain/entities/teacher_profile_update.dart';

/// Card form for editing teacher profile, document header metadata, and
/// default classroom risk thresholds (`public.teachers`).
class TeacherProfileFormCard extends StatefulWidget {
  const TeacherProfileFormCard({
    super.key,
    required this.profile,
    required this.isSaving,
    required this.onDirtyChanged,
    required this.onSave,
  });

  final TeacherProfile profile;
  final bool isSaving;
  final ValueChanged<bool> onDirtyChanged;
  final Future<bool> Function(TeacherProfileUpdate update) onSave;

  @override
  State<TeacherProfileFormCard> createState() => _TeacherProfileFormCardState();
}

class _TeacherProfileFormCardState extends State<TeacherProfileFormCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _schoolNameCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _absentPctCtrl;
  late final TextEditingController _missingWorkCtrl;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController();
    _schoolNameCtrl = TextEditingController();
    _departmentCtrl = TextEditingController();
    _absentPctCtrl = TextEditingController();
    _missingWorkCtrl = TextEditingController();
    _syncFromProfile(widget.profile, notifyDirty: false);
    for (final ctrl in _controllers) {
      ctrl.addListener(_evaluateDirty);
    }
  }

  List<TextEditingController> get _controllers => [
    _displayNameCtrl,
    _schoolNameCtrl,
    _departmentCtrl,
    _absentPctCtrl,
    _missingWorkCtrl,
  ];

  @override
  void didUpdateWidget(covariant TeacherProfileFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.updatedAt != widget.profile.updatedAt ||
        oldWidget.profile.id != widget.profile.id) {
      _syncFromProfile(widget.profile, notifyDirty: true);
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl
        ..removeListener(_evaluateDirty)
        ..dispose();
    }
    super.dispose();
  }

  void _syncFromProfile(TeacherProfile profile, {required bool notifyDirty}) {
    _displayNameCtrl.text = profile.displayName;
    _schoolNameCtrl.text = profile.schoolName;
    _departmentCtrl.text = profile.department;
    _absentPctCtrl.text = _formatPercent(profile.defaultAbsentThresholdPct);
    _missingWorkCtrl.text = profile.defaultMissingWorkThreshold.toString();
    _setDirty(false, notify: notifyDirty);
  }

  void _evaluateDirty() {
    final p = widget.profile;
    final dirty =
        _displayNameCtrl.text.trim() != p.displayName.trim() ||
        _schoolNameCtrl.text.trim() != p.schoolName.trim() ||
        _departmentCtrl.text.trim() != p.department.trim() ||
        _absentPctCtrl.text.trim() !=
            _formatPercent(p.defaultAbsentThresholdPct) ||
        _missingWorkCtrl.text.trim() !=
            p.defaultMissingWorkThreshold.toString();
    _setDirty(dirty, notify: true);
  }

  void _setDirty(bool dirty, {required bool notify}) {
    if (_isDirty == dirty) return;
    setState(() => _isDirty = dirty);
    if (notify) widget.onDirtyChanged(dirty);
  }

  String _formatPercent(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final update = TeacherProfileUpdate(
      displayName: _displayNameCtrl.text.trim(),
      schoolName: _schoolNameCtrl.text.trim(),
      department: _departmentCtrl.text.trim(),
      defaultAbsentThresholdPct: double.parse(_absentPctCtrl.text.trim()),
      defaultMissingWorkThreshold: int.parse(_missingWorkCtrl.text.trim()),
    );
    final saved = await widget.onSave(update);
    if (saved && mounted) _setDirty(false, notify: true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'โปรไฟล์ครูและหัวเอกสารรายงาน',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ข้อมูลนี้จะนำไปแสดงบนหัวรายงาน PDF/Excel และเป็นค่าเริ่มต้นของห้องสอนใหม่',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ-สกุลครูผู้สอน',
                  hintText: 'เช่น ครูสมชาย ใจดี',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกชื่อ-สกุลครูผู้สอน'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _schoolNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อโรงเรียน / สถานศึกษา',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentCtrl,
                decoration: const InputDecoration(
                  labelText: 'กลุ่มสาระการเรียนรู้ / แผนกวิชา',
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final absentField = TextFormField(
                    controller: _absentPctCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'เกณฑ์เสี่ยง มส เริ่มต้น (%)',
                      suffixText: '%',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 0 || parsed > 100) {
                        return 'กรุณากรอกค่าระหว่าง 0 ถึง 100';
                      }
                      return null;
                    },
                  );
                  final missingField = TextFormField(
                    controller: _missingWorkCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'เกณฑ์งานค้างเสี่ยง ร เริ่มต้น',
                      suffixText: 'ชิ้น',
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 1) {
                        return 'กรุณากรอกจำนวนตั้งแต่ 1 ขึ้นไป';
                      }
                      return null;
                    },
                  );

                  if (constraints.maxWidth >= 520) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: absentField),
                        const SizedBox(width: 12),
                        Expanded(child: missingField),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      absentField,
                      const SizedBox(height: 12),
                      missingField,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: (!_isDirty || widget.isSaving)
                        ? null
                        : () =>
                              _syncFromProfile(widget.profile, notifyDirty: true),
                    child: const Text('คืนค่าเดิม'),
                  ),
                  FilledButton.icon(
                    onPressed: (!_isDirty || widget.isSaving) ? null : _submit,
                    icon: widget.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      widget.isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
