import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/today_attendance_summary.dart';
import '../models/dashboard_class_item_dto.dart';

/// Remote data source for Teacher Dashboard using batched queries (no N+1).
///
/// Only this file in `features/dashboard/` may import `supabase_flutter`.
class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<DashboardClassItemDto>> fetchDashboardClasses({
    required String termId,
    required DateTime referenceDate,
  }) async {
    try {
      final subjectRows = await _client
          .from('subjects')
          .select('id, subject_code, subject_name')
          .eq('term_id', termId)
          .order('subject_code', ascending: true);

      if (subjectRows.isEmpty) {
        return const <DashboardClassItemDto>[];
      }

      final subjectById = <String, Map<String, dynamic>>{
        for (final row in subjectRows) row['id'] as String: row,
      };
      final subjectIds = subjectById.keys.toList(growable: false);

      final classRows = await _client
          .from('subject_classes')
          .select('id, subject_id, room_name, teaching_days, is_pinned')
          .inFilter('subject_id', subjectIds)
          .order('room_name', ascending: true);

      if (classRows.isEmpty) {
        return const <DashboardClassItemDto>[];
      }

      final classIds = classRows
          .map((row) => row['id'] as String)
          .toList(growable: false);
      final todayIso = ThaiDateFormatter.toIsoDate(referenceDate);

      final batchResults = await Future.wait<List<Map<String, dynamic>>>([
        _client
            .from('class_enrollments')
            .select('subject_class_id')
            .inFilter('subject_class_id', classIds)
            .eq('status', 'active'),
        _client
            .from('attendance_sessions')
            .select('id, subject_class_id, is_locked')
            .inFilter('subject_class_id', classIds)
            .eq('session_date', todayIso),
      ]);

      final activeCountByClass = <String, int>{};
      for (final row in batchResults[0]) {
        final classId = row['subject_class_id'] as String;
        activeCountByClass[classId] = (activeCountByClass[classId] ?? 0) + 1;
      }

      final sessionByClass = <String, Map<String, dynamic>>{};
      final sessionIds = <String>[];
      for (final session in batchResults[1]) {
        final classId = session['subject_class_id'] as String;
        final sessionId = session['id'] as String;
        sessionByClass[classId] = session;
        sessionIds.add(sessionId);
      }

      final countsBySession = <String, _AttendanceCounters>{};
      if (sessionIds.isNotEmpty) {
        final recordRows = await _client
            .from('attendance_records')
            .select('session_id, status')
            .inFilter('session_id', sessionIds);
        for (final row in recordRows) {
          final sessionId = row['session_id'] as String;
          final status = AttendanceStatus.tryFromDbValue(
            row['status'] as String?,
          );
          if (status == null) continue;
          final counter = countsBySession.putIfAbsent(
            sessionId,
            _AttendanceCounters.new,
          );
          counter.increment(status);
        }
      }

      return classRows
          .map((classJson) {
            final classId = classJson['id'] as String;
            final subjectId = classJson['subject_id'] as String;
            final subjectJson =
                subjectById[subjectId] ?? const <String, dynamic>{};
            final session = sessionByClass[classId];
            TodayAttendanceSummary? summary;
            if (session != null) {
              final sessionId = session['id'] as String;
              final counter = countsBySession[sessionId];
              summary = TodayAttendanceSummary(
                sessionId: sessionId,
                isLocked: session['is_locked'] as bool? ?? false,
                presentCount: counter?.present ?? 0,
                lateCount: counter?.late ?? 0,
                leaveCount: counter?.leave ?? 0,
                absentCount: counter?.absent ?? 0,
              );
            }

            return DashboardClassItemDto.fromRecords(
              classJson: classJson,
              subjectJson: subjectJson,
              activeStudentCount: activeCountByClass[classId] ?? 0,
              todayAttendance: summary,
            );
          })
          .toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> toggleClassPin({
    required String subjectClassId,
    required bool isPinned,
  }) async {
    try {
      await _client
          .from('subject_classes')
          .update(<String, dynamic>{
            'is_pinned': isPinned,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', subjectClassId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

class _AttendanceCounters {
  int present = 0;
  int late = 0;
  int leave = 0;
  int absent = 0;

  void increment(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        present++;
      case AttendanceStatus.late:
        late++;
      case AttendanceStatus.leave:
        leave++;
      case AttendanceStatus.absent:
        absent++;
    }
  }
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRemoteDataSource(client);
});
