import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../domain/entities/audit_log_target_type.dart';
import '../../domain/entities/audit_log_year_summary.dart';
import '../models/score_audit_log_entry_dto.dart';

/// Remote Supabase datasource for `public.score_audit_logs`.
///
/// Only this file in `features/audit_log/` may import `supabase_flutter`.
/// Read-only for audit entries except manual yearly cleanup which deletes
/// ONLY rows inside `public.score_audit_logs` (never touches actual scores).
class AuditLogRemoteDataSource {
  const AuditLogRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _entrySelect =
      'id, teacher_id, academic_year_id, target_type, student_score_id, '
      'enrollment_id, old_value, new_value, is_initial_entry, changed_at, '
      'academic_years(year_be), '
      'class_enrollments(student_code, student_number, prefix, first_name, '
      'last_name, subject_class_id, '
      'subject_classes(room_name, subjects(subject_code, subject_name))), '
      'student_scores(assignment_id, assignments(title))';

  Future<List<ScoreAuditLogEntryDto>> fetchAuditLogs({
    String? academicYearId,
    String? subjectClassId,
    String? enrollmentId,
    AuditLogTargetType? targetType,
    int limit = 500,
  }) async {
    try {
      List<String>? classEnrollmentIds;
      if (subjectClassId != null &&
          subjectClassId.trim().isNotEmpty &&
          (enrollmentId == null || enrollmentId.trim().isEmpty)) {
        final enrollmentRows = await _client
            .from('class_enrollments')
            .select('id')
            .eq('subject_class_id', subjectClassId);
        if (enrollmentRows.isEmpty) {
          return const <ScoreAuditLogEntryDto>[];
        }
        classEnrollmentIds = enrollmentRows
            .map((row) => row['id'] as String)
            .toList(growable: false);
      }

      var query = _client.from('score_audit_logs').select(_entrySelect);
      if (academicYearId != null && academicYearId.trim().isNotEmpty) {
        query = query.eq('academic_year_id', academicYearId);
      }
      if (enrollmentId != null && enrollmentId.trim().isNotEmpty) {
        query = query.eq('enrollment_id', enrollmentId);
      } else if (classEnrollmentIds != null) {
        query = query.inFilter('enrollment_id', classEnrollmentIds);
      }
      if (targetType != null) {
        query = query.eq('target_type', targetType.dbValue);
      }

      final rows = await query
          .order('changed_at', ascending: false)
          .limit(limit);
      return rows.map(ScoreAuditLogEntryDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<AuditLogYearSummary>> fetchAuditLogYearSummaries() async {
    try {
      final rows = await _client
          .from('score_audit_logs')
          .select(
            'academic_year_id, target_type, changed_at, academic_years(year_be)',
          );

      final buckets = <String, _YearAccumulator>{};
      for (final row in rows) {
        final yearId = row['academic_year_id'] as String;
        final rawYear = row['academic_years'];
        final yearBe = rawYear is Map
            ? ((rawYear['year_be'] as num?)?.toInt() ?? 0)
            : 0;
        final targetType = row['target_type'] as String? ?? '';
        final changedAt = DateTime.parse(row['changed_at'] as String);

        final acc = buckets.putIfAbsent(
          yearId,
          () => _YearAccumulator(academicYearId: yearId, yearBe: yearBe),
        );
        acc.record(targetType: targetType, changedAt: changedAt);
      }

      final summaries = buckets.values
          .map((acc) => acc.toSummary())
          .toList(growable: false)
        ..sort((a, b) => b.yearBe.compareTo(a.yearBe));
      return List<AuditLogYearSummary>.unmodifiable(summaries);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  /// Deletes ONLY `public.score_audit_logs` rows belonging to [academicYearId].
  /// NEVER touches `student_scores` or `class_enrollments`.
  Future<int> deleteAuditLogsByAcademicYear(String academicYearId) async {
    try {
      final deleted = await _client
          .from('score_audit_logs')
          .delete()
          .eq('academic_year_id', academicYearId)
          .select('id');
      return deleted.length;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

class _YearAccumulator {
  _YearAccumulator({required this.academicYearId, required this.yearBe});

  final String academicYearId;
  final int yearBe;
  int total = 0;
  int scoreCount = 0;
  int gradeStatusCount = 0;
  DateTime? oldest;
  DateTime? newest;

  void record({required String targetType, required DateTime changedAt}) {
    total++;
    if (targetType == AuditLogTargetType.score.dbValue) {
      scoreCount++;
    } else if (targetType == AuditLogTargetType.gradeStatus.dbValue) {
      gradeStatusCount++;
    }
    if (oldest == null || changedAt.isBefore(oldest!)) {
      oldest = changedAt;
    }
    if (newest == null || changedAt.isAfter(newest!)) {
      newest = changedAt;
    }
  }

  AuditLogYearSummary toSummary() {
    return AuditLogYearSummary(
      academicYearId: academicYearId,
      yearBe: yearBe,
      totalLogsCount: total,
      scoreLogsCount: scoreCount,
      gradeStatusLogsCount: gradeStatusCount,
      oldestChangedAt: oldest,
      newestChangedAt: newest,
    );
  }
}

final auditLogRemoteDataSourceProvider = Provider<AuditLogRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return AuditLogRemoteDataSource(client);
});
