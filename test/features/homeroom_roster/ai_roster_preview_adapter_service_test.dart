import 'package:checklist_student/features/homeroom_roster/domain/entities/ai_parsed_roster_row.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom_student.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/roster_import_row_preview.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/ai_roster_preview_adapter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiRosterPreviewAdapterService', () {
    final existing = <HomeroomStudent>[
      HomeroomStudent(
        id: 'hs-1',
        teacherId: 't-1',
        homeroomId: 'hr-1',
        studentIdentityId: 'sid-1',
        studentCode: '65001',
        studentNumber: 1,
        prefix: 'ด.ช.',
        firstName: 'สมชาย',
        lastName: 'ใจดี',
        status: StudentLifecycleStatus.active,
        transferredOutAt: null,
        createdAt: DateTime(2026, 5, 16),
        updatedAt: DateTime(2026, 5, 16),
      ),
    ];

    test('normalizes Thai names via ThaiPrefixParser and classifies statuses', () {
      const aiRows = <AiParsedRosterRow>[
        // Existing duplicate code -> duplicateExisting (defaults to skip)
        AiParsedRosterRow(
          studentNumber: 1,
          studentCode: '65001',
          prefix: 'เด็กชาย',
          firstName: 'สมชาย',
          lastName: 'ใจดีมาก',
          rawFullName: 'เด็กชายสมชาย ใจดีมาก',
        ),
        // Only rawFullName provided with prefix stuck to first name -> readyNew
        AiParsedRosterRow(
          studentNumber: null,
          studentCode: '65002',
          prefix: '',
          firstName: '',
          lastName: '',
          rawFullName: 'น.ส.กนกวรรณ สายธาร',
        ),
        // Duplicate code inside the same scanned document -> duplicateInFile
        AiParsedRosterRow(
          studentNumber: 3,
          studentCode: '65002',
          prefix: 'นางสาว',
          firstName: 'กนกวรรณ',
          lastName: 'สายธาร',
          rawFullName: 'นางสาวกนกวรรณ สายธาร',
        ),
        // Missing student code -> invalid
        AiParsedRosterRow(
          studentNumber: 4,
          studentCode: '  ',
          prefix: 'นาย',
          firstName: 'ธนากร',
          lastName: 'รักเรียน',
          rawFullName: 'นายธนากร รักเรียน',
        ),
        // Missing first name -> invalid
        AiParsedRosterRow(
          studentNumber: 5,
          studentCode: '65005',
          prefix: 'นาย',
          firstName: '',
          lastName: '',
          rawFullName: '   ',
        ),
      ];

      final preview = AiRosterPreviewAdapterService.buildPreview(
        aiRows: aiRows,
        existingStudents: existing,
      );

      expect(preview, hasLength(5));

      // Row 0: duplicateExisting
      expect(preview[0].status, RosterImportRowStatus.duplicateExisting);
      expect(preview[0].duplicateAction, DuplicateResolutionAction.skip);
      expect(preview[0].prefix, 'เด็กชาย');
      expect(preview[0].existingStudent?.id, 'hs-1');

      // Row 1: parsed from rawFullName & auto-numbered to 2
      expect(preview[1].status, RosterImportRowStatus.readyNew);
      expect(preview[1].studentNumber, 2);
      expect(preview[1].prefix, 'น.ส.');
      expect(preview[1].firstName, 'กนกวรรณ');
      expect(preview[1].lastName, 'สายธาร');

      // Row 2: duplicateInFile
      expect(preview[2].status, RosterImportRowStatus.duplicateInFile);

      // Row 3: invalid (missing studentCode)
      expect(preview[3].status, RosterImportRowStatus.invalid);
      expect(preview[3].errorReason, contains('รหัสนักเรียน'));

      // Row 4: invalid (missing firstName)
      expect(preview[4].status, RosterImportRowStatus.invalid);
      expect(preview[4].errorReason, contains('ชื่อจริง'));
    });
  });
}
