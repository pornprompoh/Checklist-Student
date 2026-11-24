import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_rule_config.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/student_attendance_summary.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/services/attendance_statistics_service.dart';

/// Provides [AttendanceRepository] backed by Supabase when configured.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final remote = EnvConfig.isSupabaseConfigured
      ? ref.watch(attendanceRemoteDataSourceProvider)
      : null;
  return AttendanceRepositoryImpl(remoteDataSource: remote);
});

/// Provides Pure Dart [AttendanceStatisticsService].
final attendanceStatisticsServiceProvider =
    Provider<AttendanceStatisticsService>(
      (ref) => const AttendanceStatisticsService(),
    );

/// Loads all sessions of [subjectClassId] ordered newest-first.
final attendanceSessionsProvider = FutureProvider.autoDispose
    .family<List<AttendanceSession>, String>((ref, subjectClassId) {
      return ref
          .watch(attendanceRepositoryProvider)
          .fetchSessions(subjectClassId);
    });

/// Batch-loads all attendance records across every session of [subjectClassId].
final attendanceClassRecordsProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, String>((ref, subjectClassId) {
      return ref
          .watch(attendanceRepositoryProvider)
          .fetchRecordsByClass(subjectClassId);
    });

/// Loads attendance rule configuration for [subjectClassId].
final attendanceRuleConfigProvider = FutureProvider.autoDispose
    .family<AttendanceRuleConfig, String>((ref, subjectClassId) {
      return ref
          .watch(attendanceRepositoryProvider)
          .fetchRuleConfig(subjectClassId);
    });

/// Computes per-student attendance summaries & `มส` risk levels for every
/// enrollment in [subjectClassId].
final classAttendanceSummariesProvider = Provider.autoDispose
    .family<Map<String, StudentAttendanceSummary>, String>((
      ref,
      subjectClassId,
    ) {
      final enrollments = ref
          .watch(classEnrollmentsProvider(subjectClassId))
          .asData
          ?.value;
      final sessions = ref
          .watch(attendanceSessionsProvider(subjectClassId))
          .asData
          ?.value;
      final records = ref
          .watch(attendanceClassRecordsProvider(subjectClassId))
          .asData
          ?.value;
      final ruleConfig = ref
          .watch(attendanceRuleConfigProvider(subjectClassId))
          .asData
          ?.value;

      if (enrollments == null ||
          sessions == null ||
          records == null ||
          ruleConfig == null) {
        return const <String, StudentAttendanceSummary>{};
      }

      return ref
          .watch(attendanceStatisticsServiceProvider)
          .calculateClassSummaries(
            enrollments: enrollments,
            sessions: sessions,
            records: records,
            ruleConfig: ruleConfig,
          );
    });
