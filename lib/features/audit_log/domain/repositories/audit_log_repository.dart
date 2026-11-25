import '../entities/audit_log_target_type.dart';
import '../entities/audit_log_year_summary.dart';
import '../entities/score_audit_log_entry.dart';

/// Read-and-yearly-cleanup repository contract for `public.score_audit_logs`.
///
/// Pure Dart interface. NEVER exposes write/edit methods for audit entries
/// because PostgreSQL triggers maintain audit integrity automatically.
abstract interface class AuditLogRepository {
  Future<List<ScoreAuditLogEntry>> fetchAuditLogs({
    String? academicYearId,
    String? subjectClassId,
    String? enrollmentId,
    AuditLogTargetType? targetType,
    int limit = 500,
  });

  Future<List<AuditLogYearSummary>> fetchAuditLogYearSummaries();

  /// Deletes ONLY `public.score_audit_logs` rows for [academicYearId] and
  /// returns the number of deleted log rows. Never touches `student_scores`
  /// or `class_enrollments`.
  Future<int> deleteAuditLogsByAcademicYear(String academicYearId);
}
