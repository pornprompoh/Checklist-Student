import '../entities/audit_log_year_summary.dart';

/// Advisory item indicating an academic year whose audit logs should be
/// exported and manually cleaned up before automatic 1-year `pg_cron` deletion.
class AuditLogCleanupAlert {
  const AuditLogCleanupAlert({
    required this.summary,
    required this.isPastAcademicYear,
    required this.hasLogsNearExpiry,
    required this.oldestLogAgeDays,
    required this.reason,
  });

  final AuditLogYearSummary summary;
  final bool isPastAcademicYear;
  final bool hasLogsNearExpiry;
  final int oldestLogAgeDays;
  final String reason;
}

/// Pure Dart advisor inspecting per-year audit log summaries to warn teachers
/// about past academic years or logs approaching the 1-year `pg_cron` TTL.
class AuditLogCleanupAdvisorService {
  const AuditLogCleanupAdvisorService();

  /// Warn teachers once the oldest log reaches 330 days (~1 month before
  /// the 365-day `pg_cron` auto-purge).
  static const int nearExpiryAgeDays = 330;

  List<AuditLogCleanupAlert> evaluateCleanupAlerts({
    required List<AuditLogYearSummary> summaries,
    int? currentActiveYearBe,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    final alerts = <AuditLogCleanupAlert>[];

    for (final summary in summaries) {
      if (summary.totalLogsCount <= 0) {
        continue;
      }

      final isPastYear =
          currentActiveYearBe != null && summary.yearBe < currentActiveYearBe;
      final oldestAt = summary.oldestChangedAt?.toUtc();
      final ageDays = oldestAt == null
          ? 0
          : reference.difference(oldestAt).inDays;
      final nearExpiry = oldestAt != null && ageDays >= nearExpiryAgeDays;

      if (!isPastYear && !nearExpiry) {
        continue;
      }

      final reasons = <String>[
        if (isPastYear) 'เป็นประวัติของปีการศึกษาที่ผ่านมาแล้ว (พ.ศ. ${summary.yearBe})',
        if (nearExpiry) 'มีรายการประวัติเก่าสุดอายุ $ageDays วัน (ใกล้ครบ 1 ปี)',
      ];
      alerts.add(
        AuditLogCleanupAlert(
          summary: summary,
          isPastAcademicYear: isPastYear,
          hasLogsNearExpiry: nearExpiry,
          oldestLogAgeDays: ageDays,
          reason: reasons.join(' · '),
        ),
      );
    }

    alerts.sort((a, b) => a.summary.yearBe.compareTo(b.summary.yearBe));
    return List<AuditLogCleanupAlert>.unmodifiable(alerts);
  }
}
