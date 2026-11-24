import 'package:flutter/material.dart';

import '../../domain/entities/parsed_spreadsheet_table.dart';
import '../../domain/entities/roster_column_mapping.dart';

/// Step 2 of the Excel/CSV import wizard: Sheet selector, SGS header-row
/// selector, name layout mode, and column mapping dropdowns.
class RosterColumnMappingStep extends StatelessWidget {
  const RosterColumnMappingStep({
    super.key,
    required this.file,
    required this.selectedSheetIndex,
    required this.mapping,
    required this.onSheetChanged,
    required this.onHeaderRowChanged,
    required this.onMappingChanged,
  });

  final ParsedSpreadsheetFile file;
  final int selectedSheetIndex;
  final RosterColumnMapping mapping;
  final ValueChanged<int> onSheetChanged;
  final ValueChanged<int> onHeaderRowChanged;
  final ValueChanged<RosterColumnMapping> onMappingChanged;

  @override
  Widget build(BuildContext context) {
    final sheet = file.sheets[selectedSheetIndex];
    final headerRow = mapping.headerRowIndex < sheet.rows.length
        ? sheet.rows[mapping.headerRowIndex]
        : const <String>[];
    final colCount = sheet.columnCount;
    final headerOptionsCount = sheet.rows.length < 10 ? sheet.rows.length : 10;

    final colItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('-- ไม่ระบุ --', overflow: TextOverflow.ellipsis),
      ),
      for (var i = 0; i < colCount; i++)
        DropdownMenuItem<int?>(
          value: i,
          child: Text(
            'คอลัมน์ ${i + 1}: ${_columnTitle(headerRow, i)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (file.sheets.length > 1) ...[
          DropdownButtonFormField<int>(
            key: ValueKey<int>(selectedSheetIndex),
            initialValue: selectedSheetIndex,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'เลือกชีต (Sheet)'),
            items: [
              for (var i = 0; i < file.sheets.length; i++)
                DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    '${file.sheets[i].name} (${file.sheets[i].rows.length} แถว)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (idx) {
              if (idx != null) onSheetChanged(idx);
            },
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<int>(
          key: ValueKey<String>('hdr-$selectedSheetIndex-${mapping.headerRowIndex}'),
          initialValue: mapping.headerRowIndex,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'แถวหัวตาราง (รองรับไฟล์ SGS ที่มีหัวรายงานด้านบน)',
          ),
          items: [
            for (var i = 0; i < headerOptionsCount; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Text(
                  'แถวที่ ${i + 1}: ${_rowSnippet(sheet.rows[i])}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (idx) {
            if (idx != null) onHeaderRowChanged(idx);
          },
        ),
        const SizedBox(height: 14),
        SegmentedButton<RosterNameColumnMode>(
          segments: const [
            ButtonSegment<RosterNameColumnMode>(
              value: RosterNameColumnMode.separated,
              label: Text('แยกคอลัมน์ชื่อ'),
            ),
            ButtonSegment<RosterNameColumnMode>(
              value: RosterNameColumnMode.combinedFullName,
              label: Text('ชื่อ-สกุลรวมช่องเดียว (SGS)'),
            ),
          ],
          selected: <RosterNameColumnMode>{mapping.nameMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onMappingChanged(mapping.copyWith(nameMode: selection.first));
            }
          },
        ),
        const SizedBox(height: 14),
        _ColumnDropdown(
          label: 'คอลัมน์ "เลขที่" (ไม่บังคับ — เว้นว่างเพื่อรันอัตโนมัติ)',
          value: mapping.studentNumberColumn,
          items: colItems,
          onChanged: (v) => onMappingChanged(
            v == null
                ? mapping.copyWith(clearStudentNumberColumn: true)
                : mapping.copyWith(studentNumberColumn: v),
          ),
        ),
        const SizedBox(height: 10),
        _ColumnDropdown(
          label: 'คอลัมน์ "รหัสนักเรียน" *',
          value: mapping.studentCodeColumn,
          items: colItems,
          onChanged: (v) => onMappingChanged(
            v == null
                ? mapping.copyWith(clearStudentCodeColumn: true)
                : mapping.copyWith(studentCodeColumn: v),
          ),
        ),
        const SizedBox(height: 10),
        if (mapping.nameMode == RosterNameColumnMode.combinedFullName)
          _ColumnDropdown(
            label: 'คอลัมน์ "ชื่อ-นามสกุลรวม" * (ตัดคำนำหน้าอัตโนมัติ)',
            value: mapping.fullNameColumn,
            items: colItems,
            onChanged: (v) => onMappingChanged(
              v == null
                  ? mapping.copyWith(clearFullNameColumn: true)
                  : mapping.copyWith(fullNameColumn: v),
            ),
          )
        else ...[
          _ColumnDropdown(
            label: 'คอลัมน์ "คำนำหน้า" (ไม่บังคับ)',
            value: mapping.prefixColumn,
            items: colItems,
            onChanged: (v) => onMappingChanged(
              v == null
                  ? mapping.copyWith(clearPrefixColumn: true)
                  : mapping.copyWith(prefixColumn: v),
            ),
          ),
          const SizedBox(height: 10),
          _ColumnDropdown(
            label: 'คอลัมน์ "ชื่อจริง" *',
            value: mapping.firstNameColumn,
            items: colItems,
            onChanged: (v) => onMappingChanged(
              v == null
                  ? mapping.copyWith(clearFirstNameColumn: true)
                  : mapping.copyWith(firstNameColumn: v),
            ),
          ),
          const SizedBox(height: 10),
          _ColumnDropdown(
            label: 'คอลัมน์ "นามสกุล"',
            value: mapping.lastNameColumn,
            items: colItems,
            onChanged: (v) => onMappingChanged(
              v == null
                  ? mapping.copyWith(clearLastNameColumn: true)
                  : mapping.copyWith(lastNameColumn: v),
            ),
          ),
        ],
      ],
    );
  }

  String _columnTitle(List<String> headerRow, int index) {
    if (index < headerRow.length && headerRow[index].trim().isNotEmpty) {
      return headerRow[index].trim();
    }
    return '(ว่าง)';
  }

  String _rowSnippet(List<String> row) {
    final nonEmpty = row.where((c) => c.trim().isNotEmpty).take(4).join(' | ');
    return nonEmpty.isEmpty ? '(แถวว่าง)' : nonEmpty;
  }
}

class _ColumnDropdown extends StatelessWidget {
  const _ColumnDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<DropdownMenuItem<int?>> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      key: ValueKey<String>('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}
