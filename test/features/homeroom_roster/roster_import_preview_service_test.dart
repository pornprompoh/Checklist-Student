import 'dart:convert';
import 'dart:typed_data';

import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom_student.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/roster_column_mapping.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/roster_import_row_preview.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/roster_import_preview_service.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/roster_spreadsheet_parser_service.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/roster_template_builder_service.dart';
import 'package:flutter_test/flutter_test.dart';

HomeroomStudent _existingStudent({
  required String id,
  required int number,
  required String code,
  required String firstName,
}) {
  final ts = DateTime(2026, 5, 16);
  return HomeroomStudent(
    id: id,
    teacherId: 'teacher-1',
    homeroomId: 'hr-1',
    studentIdentityId: 'ident-$code',
    studentCode: code,
    studentNumber: number,
    prefix: 'ด.ช.',
    firstName: firstName,
    lastName: 'เดิม',
    status: StudentLifecycleStatus.active,
    transferredOutAt: null,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('RosterSpreadsheetParserService & RosterImportPreviewService', () {
    test('auto-detects SGS multi-row header, combined name column, and Thai prefix splitting', () {
      const sgsCsv =
          '\uFEFFโรงเรียนตัวอย่างวิทยา,,,\n'
          'รายชื่อนักเรียน ม.4/1 ปีการศึกษา 2569,,,\n'
          'เลขที่,เลขประจำตัว,ชื่อ-สกุล\n'
          '1,65001,ด.ช.สมชาย ใจดี\n'
          '2,65002,เด็กหญิงนภา ณ อยุธยา\n'
          '3,65002,เด็กหญิงนภา ซ้ำในไฟล์\n'
          '4,,ด.ช.ไม่มีรหัส ใจดี\n';

      final parsed = RosterSpreadsheetParserService.parseBytes(
        filename: 'sgs_m4_1.csv',
        bytes: Uint8List.fromList(utf8.encode(sgsCsv)),
      );
      final sheet = parsed.sheets.first;
      final mapping = RosterSpreadsheetParserService.suggestColumnMapping(sheet);

      expect(mapping.headerRowIndex, 2);
      expect(mapping.nameMode, RosterNameColumnMode.combinedFullName);
      expect(mapping.studentNumberColumn, 0);
      expect(mapping.studentCodeColumn, 1);
      expect(mapping.fullNameColumn, 2);

      final preview = RosterImportPreviewService.buildPreview(
        sheet: sheet,
        mapping: mapping,
        existingStudents: <HomeroomStudent>[
          _existingStudent(id: 'hs-1', number: 1, code: '65001', firstName: 'สมชายเดิม'),
        ],
      );

      expect(preview.length, 4);

      // Row 1: duplicateExisting (defaults to skip, can toggle to overwrite)
      expect(preview[0].status, RosterImportRowStatus.duplicateExisting);
      expect(preview[0].duplicateAction, DuplicateResolutionAction.skip);
      expect(preview[0].prefix, 'ด.ช.');
      expect(preview[0].firstName, 'สมชาย');
      expect(preview[0].lastName, 'ใจดี');
      expect(
        preview[0]
            .copyWith(duplicateAction: DuplicateResolutionAction.overwrite)
            .duplicateAction,
        DuplicateResolutionAction.overwrite,
      );

      // Row 2: readyNew with multi-word surname
      expect(preview[1].status, RosterImportRowStatus.readyNew);
      expect(preview[1].prefix, 'เด็กหญิง');
      expect(preview[1].firstName, 'นภา');
      expect(preview[1].lastName, 'ณ อยุธยา');

      // Row 3: duplicateInFile
      expect(preview[2].status, RosterImportRowStatus.duplicateInFile);

      // Row 4: invalid (missing student_code)
      expect(preview[3].status, RosterImportRowStatus.invalid);
      expect(preview[3].errorReason, contains('รหัสนักเรียน'));
    });

    test('round-trips standard .xlsx and UTF-8 BOM .csv templates cleanly', () {
      final csvBytes = RosterTemplateBuilderService.buildCsvTemplateBytes();
      // UTF-8 BOM bytes: EF BB BF
      expect(csvBytes.take(3).toList(), <int>[0xEF, 0xBB, 0xBF]);

      final parsedCsv = RosterSpreadsheetParserService.parseBytes(
        filename: 'template.csv',
        bytes: csvBytes,
      );
      final csvMapping = RosterSpreadsheetParserService.suggestColumnMapping(
        parsedCsv.sheets.first,
      );
      final csvPreview = RosterImportPreviewService.buildPreview(
        sheet: parsedCsv.sheets.first,
        mapping: csvMapping,
        existingStudents: const <HomeroomStudent>[],
      );
      expect(csvPreview.length, 2);
      expect(csvPreview.first.studentCode, '65001');
      expect(csvPreview.first.prefix, 'ด.ช.');

      final xlsxBytes = RosterTemplateBuilderService.buildExcelTemplateBytes();
      final parsedXlsx = RosterSpreadsheetParserService.parseBytes(
        filename: 'template.xlsx',
        bytes: xlsxBytes,
      );
      final xlsxMapping = RosterSpreadsheetParserService.suggestColumnMapping(
        parsedXlsx.sheets.first,
      );
      final xlsxPreview = RosterImportPreviewService.buildPreview(
        sheet: parsedXlsx.sheets.first,
        mapping: xlsxMapping,
        existingStudents: const <HomeroomStudent>[],
      );
      expect(xlsxPreview.length, 2);
      expect(xlsxPreview.last.studentCode, '65002');
      expect(xlsxPreview.last.firstName, 'สุดา');
    });
  });
}
