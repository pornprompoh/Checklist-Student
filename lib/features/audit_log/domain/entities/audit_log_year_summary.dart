/// Aggregated audit log volume per academic year (พ.ศ.) used for yearly
/// Free-Tier storage management and cleanup advisor checks.
///
/// Pure Dart entity.
class AuditLogYearSummary {
  const AuditLogYearSummary({
    required this.academicYearId,
    required this.yearBe,
    required this.totalLogsCount,
    required this.scoreLogsCount,
    required this.gradeStatusLogsCount,
    this.oldestChangedAt,
    this.newestChangedAt,
  });

  final String academicYearId;
  final int yearBe;
  final int totalLogsCount;
  final int scoreLogsCount;
  final int gradeStatusLogsCount;
  final DateTime? oldestChangedAt;
  final DateTime? newestChangedAt;
}
