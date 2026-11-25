import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/export_document_header.dart';

/// Per-export document header customization card.
///
/// Updates ONLY the in-memory [ExportDocumentHeader] of the current preview
/// and NEVER writes back to `public.teachers`.
class ExportDocumentHeaderCard extends StatefulWidget {
  const ExportDocumentHeaderCard({
    super.key,
    required this.header,
    required this.hasCustomOverride,
    required this.previewXlsxFilename,
    required this.previewPdfFilename,
    required this.previewDocxFilename,
    required this.onHeaderChanged,
    required this.onResetToProfile,
  });

  final ExportDocumentHeader header;
  final bool hasCustomOverride;
  final String previewXlsxFilename;
  final String previewPdfFilename;
  final String previewDocxFilename;
  final ValueChanged<ExportDocumentHeader> onHeaderChanged;
  final VoidCallback onResetToProfile;

  @override
  State<ExportDocumentHeaderCard> createState() =>
      _ExportDocumentHeaderCardState();
}

class _ExportDocumentHeaderCardState extends State<ExportDocumentHeaderCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _schoolCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _teacherCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.header.reportTitle);
    _schoolCtrl = TextEditingController(text: widget.header.schoolName);
    _deptCtrl = TextEditingController(text: widget.header.department);
    _teacherCtrl = TextEditingController(text: widget.header.teacherName);
  }

  @override
  void didUpdateWidget(covariant ExportDocumentHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_titleCtrl, widget.header.reportTitle);
    _syncController(_schoolCtrl, widget.header.schoolName);
    _syncController(_deptCtrl, widget.header.department);
    _syncController(_teacherCtrl, widget.header.teacherName);
  }

  void _syncController(TextEditingController ctrl, String nextText) {
    if (ctrl.text != nextText) {
      ctrl.value = ctrl.value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _schoolCtrl.dispose();
    _deptCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  void _emitUpdated({DateTime? exportedAt}) {
    widget.onHeaderChanged(
      widget.header.copyWith(
        reportTitle: _titleCtrl.text,
        schoolName: _schoolCtrl.text,
        department: _deptCtrl.text,
        teacherName: _teacherCtrl.text,
        exportedAt: exportedAt ?? widget.header.exportedAt,
      ),
    );
  }

  Future<void> _pickExportDate() async {
    final current = widget.header.exportedAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 5),
      helpText: 'เลือกวันที่ออกเอกสาร',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null && mounted) {
      _emitUpdated(exportedAt: DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '2. หัวเอกสารเฉพาะใบนี้',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: widget.hasCustomOverride
                    ? widget.onResetToProfile
                    : null,
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: const Text('คืนค่าตามโปรไฟล์ครู'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'แก้ไขเฉพาะเอกสารใบนี้เท่านั้น ไม่เขียนทับข้อมูลโปรไฟล์ครูในระบบ',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => _emitUpdated(),
            decoration: const InputDecoration(
              labelText: 'ชื่อเอกสาร',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _schoolCtrl,
            onChanged: (_) => _emitUpdated(),
            decoration: const InputDecoration(
              labelText: 'ชื่อสถานศึกษา / โรงเรียน',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deptCtrl,
            onChanged: (_) => _emitUpdated(),
            decoration: const InputDecoration(
              labelText: 'กลุ่มสาระการเรียนรู้ / แผนก',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _teacherCtrl,
            onChanged: (_) => _emitUpdated(),
            decoration: const InputDecoration(
              labelText: 'ชื่อครูผู้สอน (หรือผู้สอนร่วม)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickExportDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 17),
            label: Text(
              'วันที่ออกเอกสาร: ${ThaiDateFormatter.formatFullDate(widget.header.exportedAt)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFeatures: AppTheme.tabularFigures),
            ),
          ),
          const Divider(height: 24),
          Text(
            'ตัวอย่างชื่อไฟล์ส่งออก (ปลอดภัยทุก OS)',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilenameRow(label: 'PDF', name: widget.previewPdfFilename),
                const SizedBox(height: 4),
                _FilenameRow(label: 'Excel', name: widget.previewXlsxFilename),
                const SizedBox(height: 4),
                _FilenameRow(label: 'Word', name: widget.previewDocxFilename),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilenameRow extends StatelessWidget {
  const _FilenameRow({required this.label, required this.name});

  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            '$label:',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            name,
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
