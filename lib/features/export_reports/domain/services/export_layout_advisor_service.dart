import '../entities/export_orientation.dart';
import '../entities/export_section.dart';

/// Pure Dart layout advisor selecting A4 Portrait vs Landscape automatically
/// based on selected report sections and actual column counts.
class ExportLayoutAdvisorService {
  const ExportLayoutAdvisorService();

  static const int maxPortraitAttendanceSessions = 6;
  static const int maxPortraitAssignments = 4;
  static const int minLandscapeScoreCategories = 4;

  OrientationDecision resolveOrientation({
    required ExportOrientationMode orientationMode,
    required Set<ExportSection> selectedSections,
    required int attendanceSessionCount,
    required int assignmentCount,
    required int scoreCategoryCount,
  }) {
    if (orientationMode == ExportOrientationMode.portrait) {
      return const OrientationDecision(
        orientation: ExportPageOrientation.portrait,
        isAuto: false,
        reasonThai: 'ครูเลือกกระดาษ A4 แนวตั้งด้วยตนเอง',
      );
    }
    if (orientationMode == ExportOrientationMode.landscape) {
      return const OrientationDecision(
        orientation: ExportPageOrientation.landscape,
        isAuto: false,
        reasonThai: 'ครูเลือกกระดาษ A4 แนวนอนด้วยตนเอง',
      );
    }

    final landscapeReasons = <String>[];
    if (selectedSections.contains(ExportSection.attendance) &&
        attendanceSessionCount > maxPortraitAttendanceSessions) {
      landscapeReasons.add('มีตารางเช็คชื่อ $attendanceSessionCount คาบ');
    }
    if (selectedSections.contains(ExportSection.assignments) &&
        assignmentCount > maxPortraitAssignments) {
      landscapeReasons.add('มีรายการงาน $assignmentCount ชิ้น');
    }
    if (selectedSections.contains(ExportSection.gradeSummary) &&
        scoreCategoryCount >= minLandscapeScoreCategories) {
      landscapeReasons.add('มีหมวดคะแนน $scoreCategoryCount หมวด');
    }

    if (landscapeReasons.isNotEmpty) {
      return OrientationDecision(
        orientation: ExportPageOrientation.landscape,
        isAuto: true,
        reasonThai:
            'แนะนำแนวนอนอัตโนมัติเนื่องจาก${landscapeReasons.join(' และ ')}',
      );
    }

    return const OrientationDecision(
      orientation: ExportPageOrientation.portrait,
      isAuto: true,
      reasonThai: 'จำนวนคอลัมน์เหมาะสมกับกระดาษ A4 แนวตั้ง',
    );
  }
}
