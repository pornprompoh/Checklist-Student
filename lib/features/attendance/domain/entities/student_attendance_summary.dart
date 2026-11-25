/// Attendance risk classification relative to a subject-class `มส` threshold.
enum AttendanceRiskLevel {
  /// Normal attendance (below 75% of the `absentThresholdPct` limit).
  normal,

  /// Approaching `มส` risk (`>= 75%` of threshold up to and including threshold).
  approachingMs,

  /// Exceeded `มส` threshold (strictly `> absentThresholdPct`).
  exceededMs,
}

/// Aggregated per-student attendance statistics computed by
/// `AttendanceStatisticsService`.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class StudentAttendanceSummary {
  const StudentAttendanceSummary({
    required this.enrollmentId,
    required this.totalEligibleSessions,
    required this.recordedSessions,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.convertedLateAbsentCount,
    required this.countedLeaveAbsentCount,
    required this.effectiveAbsentCount,
    required this.absentPercentage,
    required this.riskLevel,
  });

  final String enrollmentId;
  final int totalEligibleSessions;
  final int recordedSessions;
  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final int convertedLateAbsentCount;
  final int countedLeaveAbsentCount;
  final int effectiveAbsentCount;
  final double absentPercentage;
  final AttendanceRiskLevel riskLevel;

  bool get isAtRiskOrExceededMs => riskLevel != AttendanceRiskLevel.normal;

  bool get exceedsMsThreshold => riskLevel == AttendanceRiskLevel.exceededMs;
}
