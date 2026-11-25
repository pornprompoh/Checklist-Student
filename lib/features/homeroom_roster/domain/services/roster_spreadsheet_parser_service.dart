import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../../../core/errors/app_exception.dart';
import '../entities/parsed_spreadsheet_table.dart';
import '../entities/roster_column_mapping.dart';

/// Pure Dart service decoding `.xlsx` and `.csv` files into raw tables and
/// auto-detecting Thai / SGS report header rows and column mappings.
abstract final class RosterSpreadsheetParserService {
  static const List<String> _headerKeywords = <String>[
    'เลขที่',
    'รหัสนักเรียน',
    'เลขประจำตัว',
    'รหัสประจำตัว',
    'รหัส',
    'คำนำหน้า',
    'ชื่อ-สกุล',
    'ชื่อ - สกุล',
    'ชื่อ-นามสกุล',
    'ชื่อ - นามสกุล',
    'ชื่อสกุล',
    'ชื่อนักเรียน',
    'ชื่อ',
    'นามสกุล',
    'สกุล',
    'student_code',
    'first_name',
    'last_name',
  ];

  /// Parses raw bytes of an `.xlsx` or `.csv` file into [ParsedSpreadsheetFile].
  static ParsedSpreadsheetFile parseBytes({
    required String filename,
    required Uint8List bytes,
  }) {
    final lower = filename.toLowerCase().trim();
    if (lower.endsWith('.csv')) {
      return _parseCsv(filename, bytes);
    }
    if (lower.endsWith('.xlsx')) {
      return _parseExcel(filename, bytes);
    }
    throw const ValidationException(
      'รองรับเฉพาะไฟล์ .xlsx (Excel) และ .csv เท่านั้น',
      code: 'UNSUPPORTED_FILE_TYPE',
    );
  }

  /// Scans up to the first 10 rows to locate the header row (handles SGS
  /// report files with 2–5 title rows at the top).
  static int detectHeaderRowIndex(ParsedSpreadsheetSheet sheet) {
    final limit = sheet.rows.length < 10 ? sheet.rows.length : 10;
    var bestRowIndex = 0;
    var bestScore = -1;

    for (var i = 0; i < limit; i++) {
      var score = 0;
      for (final rawCell in sheet.rows[i]) {
        final cell = _normalizeHeader(rawCell);
        if (cell.isEmpty) continue;
        for (final keyword in _headerKeywords) {
          if (cell.contains(_normalizeHeader(keyword))) {
            score++;
            break;
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestRowIndex = i;
      }
    }

    return bestScore > 0 ? bestRowIndex : 0;
  }

  /// Suggests initial [RosterColumnMapping] based on header keywords.
  static RosterColumnMapping suggestColumnMapping(
    ParsedSpreadsheetSheet sheet, {
    int? headerRowIndex,
  }) {
    final resolvedHeaderIdx = headerRowIndex ?? detectHeaderRowIndex(sheet);
    final headerRow = resolvedHeaderIdx < sheet.rows.length
        ? sheet.rows[resolvedHeaderIdx]
        : const <String>[];

    int? numberCol;
    int? codeCol;
    int? prefixCol;
    int? firstCol;
    int? lastCol;
    int? fullNameCol;

    for (var i = 0; i < headerRow.length; i++) {
      final cell = _normalizeHeader(headerRow[i]);
      if (cell.isEmpty) continue;

      if (numberCol == null &&
          (cell == 'ที่' ||
              cell.contains('เลขที่') ||
              cell == 'no' ||
              cell == 'number')) {
        numberCol = i;
      } else if (codeCol == null &&
          (cell.contains('รหัสนักเรียน') ||
              cell.contains('เลขประจำตัว') ||
              cell.contains('รหัสประจำตัว') ||
              cell.contains('student_code') ||
              cell == 'รหัส' ||
              cell == 'code')) {
        codeCol = i;
      } else if (fullNameCol == null &&
          (cell.contains('ชื่อ-สกุล') ||
              cell.contains('ชื่อ-นามสกุล') ||
              cell.contains('ชื่อสกุล') ||
              cell.contains('ชื่อและนามสกุล') ||
              cell.contains('full_name') ||
              cell.contains('fullname'))) {
        fullNameCol = i;
      } else if (prefixCol == null &&
          (cell.contains('คำนำหน้า') ||
              cell.contains('prefix') ||
              cell.contains('title'))) {
        prefixCol = i;
      } else if (lastCol == null &&
          (cell.contains('นามสกุล') ||
              cell == 'สกุล' ||
              cell.contains('last_name') ||
              cell.contains('surname'))) {
        lastCol = i;
      } else if (firstCol == null &&
          (cell == 'ชื่อ' ||
              cell.contains('ชื่อจริง') ||
              cell.contains('ชื่อนักเรียน') ||
              cell.contains('first_name'))) {
        firstCol = i;
      }
    }

    final useCombined = fullNameCol != null && lastCol == null;
    return RosterColumnMapping(
      headerRowIndex: resolvedHeaderIdx,
      nameMode: useCombined
          ? RosterNameColumnMode.combinedFullName
          : RosterNameColumnMode.separated,
      studentNumberColumn: numberCol,
      studentCodeColumn: codeCol,
      prefixColumn: useCombined ? null : prefixCol,
      firstNameColumn: useCombined ? null : firstCol,
      lastNameColumn: useCombined ? null : lastCol,
      fullNameColumn: useCombined ? fullNameCol : (fullNameCol ?? firstCol),
    );
  }

  static ParsedSpreadsheetFile _parseCsv(String filename, Uint8List bytes) {
    try {
      var text = utf8.decode(bytes, allowMalformed: true);
      if (text.startsWith('\uFEFF')) {
        text = text.substring(1);
      }
      final rawRows = Csv(autoDetect: true, skipEmptyLines: false).decode(text);
      final normalized = _trimTrailingEmptyRows(
        rawRows
            .map(
              (row) => row
                  .map((cell) => cell == null ? '' : cell.toString().trim())
                  .toList(growable: false),
            )
            .toList(growable: false),
      );

      if (normalized.isEmpty) {
        throw const ValidationException('ไม่พบข้อมูลในไฟล์ CSV');
      }
      return ParsedSpreadsheetFile(
        filename: filename,
        sheets: <ParsedSpreadsheetSheet>[
          ParsedSpreadsheetSheet(name: 'CSV', rows: normalized),
        ],
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw ValidationException(
        'ไม่สามารถอ่านไฟล์ CSV ได้ กรุณาตรวจสอบรูปแบบไฟล์อีกครั้ง',
        cause: error,
      );
    }
  }

  static ParsedSpreadsheetFile _parseExcel(String filename, Uint8List bytes) {
    try {
      final workbook = Excel.decodeBytes(bytes);
      final sheets = <ParsedSpreadsheetSheet>[];

      for (final entry in workbook.tables.entries) {
        final table = entry.value;
        final rawRows = table.rows
            .map(
              (row) => row
                  .map((cell) => _formatExcelCell(cell?.value))
                  .toList(growable: false),
            )
            .toList(growable: false);
        final trimmed = _trimTrailingEmptyRows(rawRows);
        if (trimmed.isNotEmpty) {
          sheets.add(ParsedSpreadsheetSheet(name: entry.key, rows: trimmed));
        }
      }

      if (sheets.isEmpty) {
        throw const ValidationException('ไม่พบข้อมูลในไฟล์ Excel');
      }
      return ParsedSpreadsheetFile(filename: filename, sheets: sheets);
    } on AppException {
      rethrow;
    } catch (error) {
      throw ValidationException(
        'ไม่สามารถอ่านไฟล์ Excel (.xlsx) ได้ กรุณาตรวจสอบว่าไฟล์ไม่เสียหาย',
        cause: error,
      );
    }
  }

  static String _formatExcelCell(CellValue? value) {
    if (value == null) return '';
    return switch (value) {
      TextCellValue(:final value) => value.toString().trim(),
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) =>
        value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString(),
      BoolCellValue(:final value) => value.toString(),
      FormulaCellValue(:final formula) => formula.trim(),
      _ => value.toString().trim(),
    };
  }

  static List<List<String>> _trimTrailingEmptyRows(List<List<String>> rows) {
    var end = rows.length;
    while (end > 0 && rows[end - 1].every((c) => c.trim().isEmpty)) {
      end--;
    }
    return rows.sublist(0, end);
  }

  static String _normalizeHeader(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r'\s+'), '').trim();
  }
}
