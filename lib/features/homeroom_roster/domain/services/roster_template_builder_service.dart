import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

/// Pure Dart service building standard Thai student roster templates
/// in `.xlsx` (Excel) and `.csv` (UTF-8 with BOM for Thai Windows Excel).
abstract final class RosterTemplateBuilderService {
  static const List<String> headers = <String>[
    'เลขที่',
    'รหัสนักเรียน',
    'คำนำหน้า',
    'ชื่อ',
    'นามสกุล',
  ];

  static const List<List<Object>> _sampleRows = <List<Object>>[
    <Object>[1, '65001', 'ด.ช.', 'สมชาย', 'ใจดี'],
    <Object>[2, '65002', 'ด.ญ.', 'สุดา', 'รักเรียน'],
  ];

  /// Generates UTF-8 BOM CSV bytes so Thai characters open cleanly in Excel.
  static Uint8List buildCsvTemplateBytes() {
    final rows = <List<dynamic>>[headers, ..._sampleRows];
    final csvString = Csv(fieldDelimiter: ',', addBom: true).encode(rows);
    return Uint8List.fromList(utf8.encode(csvString));
  }

  /// Generates a standard `.xlsx` workbook with headers and 2 sample rows.
  static Uint8List buildExcelTemplateBytes() {
    final workbook = Excel.createExcel();
    final defaultSheetName = workbook.getDefaultSheet();
    const targetSheetName = 'รายชื่อนักเรียน';
    if (defaultSheetName != null && defaultSheetName != targetSheetName) {
      workbook.rename(defaultSheetName, targetSheetName);
    }
    final sheet = workbook[targetSheetName];

    sheet.appendRow(headers.map<CellValue>(TextCellValue.new).toList());
    for (final row in _sampleRows) {
      sheet.appendRow(<CellValue>[
        IntCellValue(row[0] as int),
        TextCellValue(row[1] as String),
        TextCellValue(row[2] as String),
        TextCellValue(row[3] as String),
        TextCellValue(row[4] as String),
      ]);
    }

    final encoded = workbook.save();
    return Uint8List.fromList(encoded ?? const <int>[]);
  }
}
