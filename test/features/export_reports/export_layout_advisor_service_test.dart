import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/export_reports/domain/entities/export_orientation.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_section.dart';
import 'package:checklist_student/features/export_reports/domain/services/export_layout_advisor_service.dart';

void main() {
  const service = ExportLayoutAdvisorService();

  group('ExportLayoutAdvisorService', () {
    test('selects portrait automatically when columns fit comfortably', () {
      final decision = service.resolveOrientation(
        orientationMode: ExportOrientationMode.auto,
        selectedSections: const <ExportSection>{
          ExportSection.roster,
          ExportSection.gradeSummary,
        },
        attendanceSessionCount: 15, // attendance not selected
        assignmentCount: 12, // assignments not selected
        scoreCategoryCount: 3, // < 4
      );

      expect(decision.orientation, ExportPageOrientation.portrait);
      expect(decision.isAuto, isTrue);
    });

    test('selects landscape automatically when attendance sessions > 6', () {
      final decision = service.resolveOrientation(
        orientationMode: ExportOrientationMode.auto,
        selectedSections: const <ExportSection>{ExportSection.attendance},
        attendanceSessionCount: 7,
        assignmentCount: 0,
        scoreCategoryCount: 0,
      );

      expect(decision.orientation, ExportPageOrientation.landscape);
      expect(decision.isAuto, isTrue);
      expect(decision.reasonThai, contains('7 คาบ'));
    });

    test('selects landscape automatically when assignments > 4', () {
      final decision = service.resolveOrientation(
        orientationMode: ExportOrientationMode.auto,
        selectedSections: const <ExportSection>{ExportSection.assignments},
        attendanceSessionCount: 2,
        assignmentCount: 5,
        scoreCategoryCount: 1,
      );

      expect(decision.orientation, ExportPageOrientation.landscape);
      expect(decision.reasonThai, contains('5 ชิ้น'));
    });

    test('selects landscape automatically when gradeSummary has >= 4 categories', () {
      final decision = service.resolveOrientation(
        orientationMode: ExportOrientationMode.auto,
        selectedSections: const <ExportSection>{ExportSection.gradeSummary},
        attendanceSessionCount: 0,
        assignmentCount: 2,
        scoreCategoryCount: 4,
      );

      expect(decision.orientation, ExportPageOrientation.landscape);
      expect(decision.reasonThai, contains('4 หมวด'));
    });

    test('honors manual portrait and landscape overrides', () {
      final forcedPortrait = service.resolveOrientation(
        orientationMode: ExportOrientationMode.portrait,
        selectedSections: ExportSection.values.toSet(),
        attendanceSessionCount: 20,
        assignmentCount: 15,
        scoreCategoryCount: 6,
      );
      expect(forcedPortrait.orientation, ExportPageOrientation.portrait);
      expect(forcedPortrait.isAuto, isFalse);

      final forcedLandscape = service.resolveOrientation(
        orientationMode: ExportOrientationMode.landscape,
        selectedSections: const <ExportSection>{ExportSection.roster},
        attendanceSessionCount: 0,
        assignmentCount: 0,
        scoreCategoryCount: 0,
      );
      expect(forcedLandscape.orientation, ExportPageOrientation.landscape);
      expect(forcedLandscape.isAuto, isFalse);
    });
  });
}
