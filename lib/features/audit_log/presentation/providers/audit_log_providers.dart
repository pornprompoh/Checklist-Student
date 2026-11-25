import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/datasources/audit_log_remote_datasource.dart';
import '../../data/repositories/audit_log_repository_impl.dart';
import '../../domain/entities/audit_log_filter.dart';
import '../../domain/entities/audit_log_target_type.dart';
import '../../domain/entities/audit_log_year_summary.dart';
import '../../domain/entities/score_audit_log_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/services/audit_log_cleanup_advisor_service.dart';
import '../../domain/services/audit_log_export_service.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final remote = EnvConfig.isSupabaseConfigured
      ? ref.watch(auditLogRemoteDataSourceProvider)
      : null;
  return AuditLogRepositoryImpl(remoteDataSource: remote);
});

final auditLogExportServiceProvider = Provider<AuditLogExportService>(
  (ref) => const AuditLogExportService(),
);

final auditLogCleanupAdvisorServiceProvider =
    Provider<AuditLogCleanupAdvisorService>(
      (ref) => const AuditLogCleanupAdvisorService(),
    );

class AuditLogFilterNotifier extends Notifier<AuditLogFilter> {
  @override
  AuditLogFilter build() => const AuditLogFilter();

  void applyInitial({String? subjectClassId, String? enrollmentId}) {
    state = AuditLogFilter(
      subjectClassId: subjectClassId,
      enrollmentId: enrollmentId,
    );
  }

  void setAcademicYearId(String? yearId) {
    state = state.copyWith(academicYearId: yearId);
  }

  void setSubjectClassId(String? classId) {
    state = state.copyWith(subjectClassId: classId, enrollmentId: null);
  }

  void clearEnrollmentFilter() {
    state = state.copyWith(enrollmentId: null);
  }

  void setTargetType(AuditLogTargetType? type) {
    state = state.copyWith(targetType: type);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = const AuditLogFilter();
  }
}

final auditLogFilterProvider =
    NotifierProvider<AuditLogFilterNotifier, AuditLogFilter>(
      AuditLogFilterNotifier.new,
    );

/// Tracks academic year IDs exported during the current browser session so the
/// UI can confirm backup readiness before manual cleanup.
class ExportedAuditLogYearsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void markExported(String academicYearId) {
    state = <String>{...state, academicYearId};
  }
}

final exportedAuditLogYearIdsProvider =
    NotifierProvider<ExportedAuditLogYearsNotifier, Set<String>>(
      ExportedAuditLogYearsNotifier.new,
    );

/// Fetches filtered audit log entries from Supabase based on server-side
/// filter fields (client-side search runs in UI without extra round-trips).
final auditLogEntriesProvider =
    FutureProvider.autoDispose<List<ScoreAuditLogEntry>>((ref) async {
      final userId = ref.watch(authStateProvider.select((s) => s.userId));
      if (userId == null) {
        return const <ScoreAuditLogEntry>[];
      }
      final filter = ref.watch(
        auditLogFilterProvider.select(
          (f) => (
            yearId: f.academicYearId,
            classId: f.subjectClassId,
            enrollmentId: f.enrollmentId,
            targetType: f.targetType,
          ),
        ),
      );
      return ref
          .watch(auditLogRepositoryProvider)
          .fetchAuditLogs(
            academicYearId: filter.yearId,
            subjectClassId: filter.classId,
            enrollmentId: filter.enrollmentId,
            targetType: filter.targetType,
          );
    });

/// Loads per-academic-year audit log counts & oldest/newest timestamps.
final auditLogYearSummariesProvider =
    FutureProvider.autoDispose<List<AuditLogYearSummary>>((ref) async {
      final userId = ref.watch(authStateProvider.select((s) => s.userId));
      if (userId == null) {
        return const <AuditLogYearSummary>[];
      }
      return ref.watch(auditLogRepositoryProvider).fetchAuditLogYearSummaries();
    });

/// Evaluates whether any academic year needs export + manual cleanup warning
/// on Teacher Dashboard and Audit Log Page.
final auditLogCleanupAlertsProvider =
    Provider.autoDispose<List<AuditLogCleanupAlert>>((ref) {
      final summaries =
          ref.watch(auditLogYearSummariesProvider).asData?.value ??
          const <AuditLogYearSummary>[];
      if (summaries.isEmpty) {
        return const <AuditLogCleanupAlert>[];
      }

      final years = ref.watch(academicYearsProvider).asData?.value;
      final activeTerm = ref.watch(activeTermProvider);
      int? currentActiveYearBe;
      if (years != null && years.isNotEmpty) {
        if (activeTerm != null) {
          for (final year in years) {
            if (year.id == activeTerm.academicYearId) {
              currentActiveYearBe = year.yearBe;
              break;
            }
          }
        }
        currentActiveYearBe ??= years.first.yearBe;
      }

      return ref
          .watch(auditLogCleanupAdvisorServiceProvider)
          .evaluateCleanupAlerts(
            summaries: summaries,
            currentActiveYearBe: currentActiveYearBe,
          );
    });
