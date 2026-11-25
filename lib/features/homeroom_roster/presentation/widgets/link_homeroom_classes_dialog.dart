import 'package:flutter/material.dart';

import '../../../../core/utils/thai_date_formatter.dart';
import '../../../academic_structure/domain/entities/subject.dart';
import '../../../academic_structure/domain/entities/subject_class.dart';

/// Selection payload returned by [LinkHomeroomClassesDialog].
class LinkHomeroomClassesResult {
  const LinkHomeroomClassesResult({
    required this.subjectClassIds,
    required this.enrolledAt,
  });

  final List<String> subjectClassIds;
  final DateTime enrolledAt;
}

/// Dialog allowing teachers to link one master homeroom to multiple
/// [SubjectClass] rooms in the same term and copy missing students into
/// `class_enrollments`.
class LinkHomeroomClassesDialog extends StatefulWidget {
  const LinkHomeroomClassesDialog({
    super.key,
    required this.homeroomId,
    required this.homeroomName,
    required this.subjects,
    required this.subjectClasses,
    this.defaultEnrolledAt,
  });

  final String homeroomId;
  final String homeroomName;
  final List<Subject> subjects;
  final List<SubjectClass> subjectClasses;
  final DateTime? defaultEnrolledAt;

  static Future<LinkHomeroomClassesResult?> show(
    BuildContext context, {
    required String homeroomId,
    required String homeroomName,
    required List<Subject> subjects,
    required List<SubjectClass> subjectClasses,
    DateTime? defaultEnrolledAt,
  }) {
    return showDialog<LinkHomeroomClassesResult>(
      context: context,
      builder: (dialogContext) => LinkHomeroomClassesDialog(
        homeroomId: homeroomId,
        homeroomName: homeroomName,
        subjects: subjects,
        subjectClasses: subjectClasses,
        defaultEnrolledAt: defaultEnrolledAt,
      ),
    );
  }

  @override
  State<LinkHomeroomClassesDialog> createState() =>
      _LinkHomeroomClassesDialogState();
}

class _LinkHomeroomClassesDialogState extends State<LinkHomeroomClassesDialog> {
  late final Set<String> _selectedIds;
  late DateTime _enrolledAt;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.subjectClasses
        .where((c) => c.homeroomId == widget.homeroomId)
        .map((c) => c.id)
        .toSet();
    final initial = widget.defaultEnrolledAt ?? DateTime.now();
    _enrolledAt = DateTime(initial.year, initial.month, initial.day);
  }

  Future<void> _pickDate() async {
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

  @override
  Widget build(BuildContext context) {
    final subjectById = <String, Subject>{
      for (final s in widget.subjects) s.id: s,
    };
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      title: Text('ผูกคลัง "${widget.homeroomName}" กับรายวิชา'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เลือกรายวิชา+ห้องที่ต้องการดึงรายชื่อจากคลังนี้ (นักเรียนที่มีรหัสอยู่แล้วจะไม่ถูกเพิ่มซ้ำ)',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'วันที่เริ่มลงทะเบียน (enrolled_at)',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(ThaiDateFormatter.formatShortDate(_enrolledAt)),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.subjectClasses.isEmpty)
              Text(
                'ยังไม่มีห้องเรียนรายวิชาในเทอมนี้ กรุณาสร้างที่หน้า "โครงสร้างสอน" ก่อน',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final sc in widget.subjectClasses)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedIds.contains(sc.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds.add(sc.id);
                      } else {
                        _selectedIds.remove(sc.id);
                      }
                    });
                  },
                  title: Text(
                    '${subjectById[sc.subjectId]?.subjectCode ?? ''} '
                    '${subjectById[sc.subjectId]?.subjectName ?? ''} — ${sc.roomName}',
                  ),
                  subtitle: Text(
                    sc.homeroomId == widget.homeroomId
                        ? 'ผูกกับคลังนี้อยู่แล้ว (กดบันทึกเพื่อซิงค์นักเรียนที่เพิ่มใหม่)'
                        : sc.homeroomId != null
                        ? 'ผูกกับคลังอื่นอยู่ (เลือกเพื่อเปลี่ยนมาผูกกับคลังนี้)'
                        : 'ยังไม่ผูกกับคลังรายชื่อ',
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  LinkHomeroomClassesResult(
                    subjectClassIds: _selectedIds.toList(growable: false),
                    enrolledAt: _enrolledAt,
                  ),
                ),
          child: Text('ผูกและซิงค์ (${_selectedIds.length} ห้อง)'),
        ),
      ],
    );
  }
}
