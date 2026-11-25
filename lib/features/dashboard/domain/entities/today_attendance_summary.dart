/// Aggregated 4-state classroom attendance summary for a single
/// `attendance_sessions` record on the reference date.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class TodayAttendanceSummary {
  const TodayAttendanceSummary({
    required this.sessionId,
    required this.isLocked,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
  });

  final String sessionId;
  final bool isLocked;
  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;

  /// Total recorded students across all 4 attendance statuses.
  int get totalRecorded => presentCount + lateCount + leaveCount + absentCount;
}
