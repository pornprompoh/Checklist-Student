import '../../../../core/utils/thai_prefix_parser.dart';
import '../entities/ai_parsed_roster_row.dart';
import '../entities/homeroom_student.dart';
import '../entities/roster_import_row_preview.dart';
import 'roster_renumber_service.dart';

/// Pure Dart adapter converting AI-extracted [AiParsedRosterRow] entries into
/// [RosterImportRowPreview] rows compatible with the Step 2.4 preview screen.
abstract final class AiRosterPreviewAdapterService {
  static List<RosterImportRowPreview> buildPreview({
    required List<AiParsedRosterRow> aiRows,
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

    for (var i = 0; i < aiRows.length; i++) {
      final row = aiRows[i];
      final sourceRowNumber = i + 1;
      final code = row.studentCode.trim();
      final parsedName = _parseName(row);
      final parsedNumber =
          (row.studentNumber != null && row.studentNumber! > 0)
          ? row.studentNumber
          : null;
      final assignedNumber = parsedNumber ?? autoNumberCursor;

      if (code.isEmpty) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: assignedNumber,
            studentCode: '',
            prefix: parsedName.prefix,
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            status: RosterImportRowStatus.invalid,
            errorReason: 'AI ไม่พบรหัสนักเรียนในแถวนี้',
          ),
        );
        continue;
      }

      if (parsedName.firstName.isEmpty) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: assignedNumber,
            studentCode: code,
            prefix: parsedName.prefix,
            firstName: '',
            lastName: parsedName.lastName,
            status: RosterImportRowStatus.invalid,
            errorReason: 'AI ไม่พบชื่อจริงของนักเรียนในแถวนี้',
          ),
        );
        continue;
      }

      if (!seenCodesInFile.add(code)) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: assignedNumber,
            studentCode: code,
            prefix: parsedName.prefix,
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            status: RosterImportRowStatus.duplicateInFile,
            errorReason: 'รหัสนักเรียนซ้ำกันเองภายในเอกสารที่สแกน',
          ),
        );
        continue;
      }

      final existing = existingByCode[code];
      if (existing != null) {
        previews.add(
          RosterImportRowPreview(
            sourceRowNumber: sourceRowNumber,
            studentNumber: parsedNumber ?? existing.studentNumber,
            studentCode: code,
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
          studentCode: code,
          prefix: parsedName.prefix,
          firstName: parsedName.firstName,
          lastName: parsedName.lastName,
          status: RosterImportRowStatus.readyNew,
        ),
      );
    }

    return List<RosterImportRowPreview>.unmodifiable(previews);
  }

  static ParsedThaiName _parseName(AiParsedRosterRow row) {
    if (row.firstName.trim().isNotEmpty) {
      return ThaiPrefixParser.normalizeParts(
        rawPrefix: row.prefix,
        rawFirstName: row.firstName,
        rawLastName: row.lastName,
      );
    }
    return ThaiPrefixParser.parseFullName(row.rawFullName);
  }
}
