import '../../domain/entities/dashboard_class_item.dart';
import '../../domain/entities/today_attendance_summary.dart';

/// Data transfer object assembling a [DashboardClassItem] from batched
/// `subjects`, `subject_classes`, `class_enrollments`, and attendance rows.
class DashboardClassItemDto {
  const DashboardClassItemDto({
    required this.subjectClassId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.roomName,
    required this.teachingDays,
    required this.isPinned,
    required this.activeStudentCount,
    required this.todayAttendance,
  });

  factory DashboardClassItemDto.fromRecords({
    required Map<String, dynamic> classJson,
    required Map<String, dynamic> subjectJson,
    required int activeStudentCount,
    required TodayAttendanceSummary? todayAttendance,
  }) {
    final rawDays = (classJson['teaching_days'] as List<dynamic>?) ?? const [];
    final parsedDays =
        rawDays
            .map((value) => (value as num).toInt())
            .where((day) => day >= 1 && day <= 7)
            .toList()
          ..sort();

    return DashboardClassItemDto(
      subjectClassId: classJson['id'] as String,
      subjectId: classJson['subject_id'] as String,
      subjectCode: (subjectJson['subject_code'] as String? ?? '').trim(),
      subjectName: (subjectJson['subject_name'] as String? ?? '').trim(),
      roomName: (classJson['room_name'] as String? ?? '').trim(),
      teachingDays: List<int>.unmodifiable(parsedDays),
      isPinned: classJson['is_pinned'] as bool? ?? false,
      activeStudentCount: activeStudentCount,
      todayAttendance: todayAttendance,
    );
  }

  final String subjectClassId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String roomName;
  final List<int> teachingDays;
  final bool isPinned;
  final int activeStudentCount;
  final TodayAttendanceSummary? todayAttendance;

  DashboardClassItem toEntity() {
    return DashboardClassItem(
      subjectClassId: subjectClassId,
      subjectId: subjectId,
      subjectCode: subjectCode,
      subjectName: subjectName,
      roomName: roomName,
      teachingDays: teachingDays,
      isPinned: isPinned,
      activeStudentCount: activeStudentCount,
      todayAttendance: todayAttendance,
    );
  }
}
