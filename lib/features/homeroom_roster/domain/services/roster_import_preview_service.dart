import '../../../../core/utils/thai_prefix_parser.dart';
import '../entities/homeroom_student.dart';
import '../entities/parsed_spreadsheet_table.dart';
import '../entities/roster_column_mapping.dart';
import '../entities/roster_import_row_preview.dart';
import 'roster_renumber_service.dart';

/// Pure Dart service transforming raw spreadsheet rows into validated
/// [RosterImportRowPreview] entries with Thai prefix parsing and duplicate
/// detection against existing homeroom students.
abstract final class RosterImportPreviewService {
  static List<RosterImportRowPreview> buildPreview({
    required ParsedSpreadsheetSheet sheet,
    required RosterColumnMapping mapping,
    required List<HomeroomStudent> existingStudents,
  }) {
    final existingByCode = <String, HomeroomStudent>{
      for (final student in existingStudents)
        student.studentCode.trim(): student,
    };
    final seenCodesInFile = <String>{};
    var autoNumberCursor = RosterRenumberService.nextStudentNumber(
      existingStudents.map((s) => s.studentNumber),
    );

    final previews = <RosterImportRowPreview>[];

    for (var rowIdx = mapping.headerRowIndex + 1; rowIdx < sheet.rows.length; rowIdx++) {
      final row = sheet.rows[rowIdx];
      if (_isEmptyRow(row)) {
        continue;
      }

      final sourceRowNumber = rowIdx + 1;
      final rawCode = _cellAt(row, mapping.studentCodeColumn).trim();
      final rawNumber = _cellAt(row, mapping.studentNumberColumn).trim();
      final parsedNumber = _parsePositiveInt(rawNumber);

      final ParsedThaiName parsedName = switch (mapping.nameMode) {
        RosterNameColumnMode.combinedFullName => ThaiPrefixParser.parseFullName(
          _cellAt(row, mapping.fullNameColumn),
        ),
        RosterNameColumnMode.separated => ThaiPrefixParser.normalizeParts(
          rawPrefix: _cellAt(row, mapping.prefixColumn),
          rawFirstName: _cellAt(row, mapping.firstNameColumn),
          rawLastName: _cellAt(row, mapping.lastNameColumn),
        ),
      };

      final assignedNumber = parsedNumber ?? autoNumberCursor;

      // Validation checks
      if (rawCode.isEmpty) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: assignedNumber,
            studentCode: '',
            prefix: parsedName.prefix,
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            status: RosterImportRowStatus.invalid,
            errorReason: 'ไม่พบรหัสนักเรียน',
          ),
        );
        continue;
      }

      if (parsedName.firstName.isEmpty) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: assignedNumber,
            studentCode: rawCode,
            prefix: parsedName.prefix,
            firstName: '',
            lastName: parsedName.lastName,
            status: RosterImportRowStatus.invalid,
            errorReason: 'ไม่พบชื่อจริงของนักเรียน',
          ),
        );
        continue;
      }

      // Duplicate within the same uploaded file
      if (!seenCodesInFile.add(rawCode)) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: assignedNumber,
            studentCode: rawCode,
            prefix: parsedName.prefix,
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            status: RosterImportRowStatus.duplicateInFile,
            errorReason: 'รหัสนักเรียนซ้ำกันเองภายในไฟล์นำเข้า',
          ),
        );
        continue;
      }

      // Duplicate against existing homeroom_students
      final existing = existingByCode[rawCode];
      if (existing != null) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: parsedNumber ?? existing.studentNumber,
            studentCode: rawCode,
            prefix: parsedName.prefix,
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            status: RosterImportRowStatus.duplicateExisting,
            existingStudent: existing,
            duplicateAction: DuplicateResolutionAction.skip,
          ),
        );
        continue;
      }

      if (parsedNumber == null) {
        autoNumberCursor++;
      } else if (parsedNumber >= autoNumberCursor) {
        autoNumberCursor = parsedNumber + 1;
      }

      previews.add(
        RosterImportRowPreview(
          sourceRowNumber: sourceRowNumber,
          studentNumber: assignedNumber,
          studentCode: rawCode,
          prefix: parsedName.prefix,
          firstName: parsedName.firstName,
          lastName: parsedName.lastName,
          status: RosterImportRowStatus.readyNew,
        ),
      );
    }

    return List<RosterImportRowPreview>.unmodifiable(previews);
  }

  static bool _isEmptyRow(List<String> row) {
    return row.every((cell) => cell.trim().isEmpty);
  }

  static String _cellAt(List<String> row, int? columnIndex) {
    if (columnIndex == null || columnIndex < 0 || columnIndex >= row.length) {
      return '';
    }
    return row[columnIndex];
  }

  static int? _parsePositiveInt(String raw) {
    if (raw.isEmpty) return null;
    final asInt = int.tryParse(raw);
    if (asInt != null && asInt > 0) return asInt;
    final asDouble = double.tryParse(raw);
    if (asDouble != null && asDouble > 0 && asDouble == asDouble.roundToDouble()) {
      return asDouble.toInt();
    }
    return null;
  }
}
