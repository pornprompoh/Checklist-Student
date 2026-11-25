import 'today_attendance_summary.dart';

/// Enriched teaching class card item displayed on the Teacher Dashboard.
///
/// Pure Dart entity combining `subjects`, `subject_classes`, active
/// `class_enrollments` count, and today's `attendance_sessions` summary.
class DashboardClassItem {
  const DashboardClassItem({
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

  final String subjectClassId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String roomName;

  /// ISO weekday integers (`1` = Monday ... `7` = Sunday).
  final List<int> teachingDays;
  final bool isPinned;
  final int activeStudentCount;
  final TodayAttendanceSummary? todayAttendance;

  /// Returns `true` when this class is scheduled on [isoWeekday] (`1..7`).
  bool teachesOnWeekday(int isoWeekday) => teachingDays.contains(isoWeekday);

  /// Returns `true` when an attendance session already exists for today.
  bool get isCheckedToday => todayAttendance != null;

  DashboardClassItem copyWith({
    bool? isPinned,
    TodayAttendanceSummary? todayAttendance,
  }) {
    return DashboardClassItem(
      subjectClassId: subjectClassId,
      subjectId: subjectId,
      subjectCode: subjectCode,
      subjectName: subjectName,
      roomName: roomName,
      teachingDays: teachingDays,
      isPinned: isPinned ?? this.isPinned,
      activeStudentCount: activeStudentCount,
      todayAttendance: todayAttendance ?? this.todayAttendance,
    );
  }
}
