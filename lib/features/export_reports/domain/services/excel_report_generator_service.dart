import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../entities/export_report_bundle.dart';
import '../entities/export_section.dart';
import 'excel_sheet_section_builders.dart';

/// Pure Dart Excel (`.xlsx`) workbook generator turning an [ExportReportBundle]
/// into multi-sheet Excel bytes with exact `DoubleCellValue` decimals.
class ExcelReportGeneratorService {
  const ExcelReportGeneratorService({
    this.sectionBuilders = const ExcelSheetSectionBuilders(),
  });

  final ExcelSheetSectionBuilders sectionBuilders;

  Uint8List generate(ExportReportBundle bundle) {
    final excel = Excel.createExcel();
    final selected = bundle.options.selectedSections;

    if (selected.contains(ExportSection.roster)) {
      sectionBuilders.buildRosterSheet(excel, bundle);
    }
    if (selected.contains(ExportSection.attendance)) {
      sectionBuilders.buildAttendanceSheet(excel, bundle);
    }
    if (selected.contains(ExportSection.assignments)) {
      sectionBuilders.buildAssignmentsSheet(excel, bundle);
    }
    if (selected.contains(ExportSection.gradeSummary)) {
      sectionBuilders.buildGradeSummarySheet(excel, bundle);
    }

    // Remove the empty default 'Sheet1' created by package:excel.
    if (excel.tables.containsKey('Sheet1') && excel.tables.length > 1) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('ไม่สามารถเข้ารหัสไฟล์ Excel (.xlsx) ได้');
    }
    return Uint8List.fromList(encoded);
  }
}
