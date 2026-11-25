import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/attendance_record_input.dart';
import '../../domain/entities/attendance_rule_config.dart';
import '../models/attendance_record_dto.dart';
import '../models/attendance_rule_config_dto.dart';
import '../models/attendance_session_dto.dart';

/// Remote data source managing `public.attendance_sessions`,
/// `public.attendance_records`, and rule columns on `public.subject_classes`
/// with strict Optimistic Locking (`version`).
///
/// Only this file in `features/attendance/` may import `supabase_flutter`.
class AttendanceRemoteDataSource {
  const AttendanceRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _sessionColumns =
      'id, teacher_id, subject_class_id, session_date, is_locked, note, '
      'version, created_at, updated_at';
  static const String _recordColumns =
      'id, teacher_id, session_id, enrollment_id, status, note, version, '
      'updated_at';
  static const String _ruleColumns =
      'id, absent_threshold_pct, late_to_absent_ratio, '
      'count_leave_as_absent, attendance_score_weight';

  Future<List<AttendanceSessionDto>> fetchSessions(
    String subjectClassId,
  ) async {
    try {
      final rows = await _client
          .from('attendance_sessions')
          .select(_sessionColumns)
          .eq('subject_class_id', subjectClassId)
          .order('session_date', ascending: false);
      return rows.map(AttendanceSessionDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceSessionDto?> fetchSessionByDate({
    required String subjectClassId,
    required DateTime sessionDate,
  }) async {
    try {
      final row = await _client
          .from('attendance_sessions')
          .select(_sessionColumns)
          .eq('subject_class_id', subjectClassId)
          .eq('session_date', ThaiDateFormatter.toIsoDate(sessionDate))
          .maybeSingle();
      return row == null ? null : AttendanceSessionDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<AttendanceRecordDto>> fetchRecordsBySession(
    String sessionId,
  ) async {
    try {
      final rows = await _client
          .from('attendance_records')
          .select(_recordColumns)
          .eq('session_id', sessionId);
      return rows.map(AttendanceRecordDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<AttendanceRecordDto>> fetchRecordsByClass(
    String subjectClassId,
  ) async {
    try {
      final sessionRows = await _client
          .from('attendance_sessions')
          .select('id')
          .eq('subject_class_id', subjectClassId);
      if (sessionRows.isEmpty) {
        return const <AttendanceRecordDto>[];
      }
      final sessionIds = sessionRows
          .map((row) => row['id'] as String)
          .toList(growable: false);
      final rows = await _client
          .from('attendance_records')
          .select(_recordColumns)
          .inFilter('session_id', sessionIds);
      return rows.map(AttendanceRecordDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceSessionDto?> fetchSessionById(String sessionId) async {
    try {
      final row = await _client
          .from('attendance_sessions')
          .select(_sessionColumns)
          .eq('id', sessionId)
          .maybeSingle();
      return row == null ? null : AttendanceSessionDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceRecordDto?> fetchRecordById(String recordId) async {
    try {
      final row = await _client
          .from('attendance_records')
          .select(_recordColumns)
          .eq('id', recordId)
          .maybeSingle();
      return row == null ? null : AttendanceRecordDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceRecordDto?> fetchRecordByCell({
    required String sessionId,
    required String enrollmentId,
  }) async {
    try {
      final row = await _client
          .from('attendance_records')
          .select(_recordColumns)
          .eq('session_id', sessionId)
          .eq('enrollment_id', enrollmentId)
          .maybeSingle();
      return row == null ? null : AttendanceRecordDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceSessionDto> createSession({
    String? clientId,
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
    String note = '',
    bool isLocked = false,
  }) async {
    try {
      final data = await _client
          .from('attendance_sessions')
          .insert(<String, dynamic>{
            'id': ?clientId,
            'teacher_id': teacherId,
            'subject_class_id': subjectClassId,
            'session_date': ThaiDateFormatter.toIsoDate(sessionDate),
            'is_locked': isLocked,
            'note': note.trim(),
            'version': 1,
          })
          .select(_sessionColumns)
          .single();
      return AttendanceSessionDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceSessionDto> updateSession({
    required String sessionId,
    required String note,
    required bool isLocked,
    required int expectedVersion,
  }) async {
    try {
      final data = await _client
          .from('attendance_sessions')
          .update(<String, dynamic>{
            'note': note.trim(),
            'is_locked': isLocked,
            'version': expectedVersion + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId)
          .eq('version', expectedVersion)
          .select(_sessionColumns)
          .maybeSingle();

      if (data == null) {
        throw const ConflictException(
          'คาบเช็คชื่อนี้ถูกแก้ไขจากอุปกรณ์อื่น กรุณาโหลดข้อมูลล่าสุดก่อนบันทึกใหม่',
          code: 'ATTENDANCE_SESSION_VERSION_CONFLICT',
        );
      }
      return AttendanceSessionDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<AttendanceRecordDto>> saveSessionRecords({
    required String teacherId,
    required String sessionId,
    required List<AttendanceRecordInput> inputs,
  }) async {
    if (inputs.isEmpty) {
      return const <AttendanceRecordDto>[];
    }
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final saved = <AttendanceRecordDto>[];
      final insertPayload = <Map<String, dynamic>>[];

      for (final input in inputs) {
        if (input.isUpdate) {
          final updated = await _client
              .from('attendance_records')
              .update(<String, dynamic>{
                'status': input.status.dbValue,
                'note': input.note.trim(),
                'version': input.expectedVersion! + 1,
                'updated_at': nowIso,
              })
              .eq('id', input.existingRecordId!)
              .eq('version', input.expectedVersion!)
              .select(_recordColumns)
              .maybeSingle();
          if (updated == null) {
            throw const ConflictException(
              'ข้อมูลการเช็คชื่อบางรายการถูกแก้ไขจากอุปกรณ์อื่น กรุณาโหลดข้อมูลล่าสุดแล้วลองบันทึกใหม่',
              code: 'ATTENDANCE_RECORD_VERSION_CONFLICT',
            );
          }
          saved.add(AttendanceRecordDto.fromJson(updated));
        } else {
          insertPayload.add(<String, dynamic>{
            'id': ?input.clientId,
            'teacher_id': teacherId,
            'session_id': sessionId,
            'enrollment_id': input.enrollmentId,
            'status': input.status.dbValue,
            'note': input.note.trim(),
            'version': 1,
            'updated_at': nowIso,
          });
        }
      }

      if (insertPayload.isNotEmpty) {
        try {
          final inserted = await _client
              .from('attendance_records')
              .insert(insertPayload)
              .select(_recordColumns);
          saved.addAll(inserted.map(AttendanceRecordDto.fromJson));
        } on PostgrestException catch (error) {
          if (error.code == '23505') {
            throw ConflictException(
              'พบข้อมูลการเช็คชื่อที่ถูกบันทึกจากอุปกรณ์อื่นแล้ว กรุณาโหลดข้อมูลล่าสุดแล้วลองใหม่',
              code: 'ATTENDANCE_RECORD_VERSION_CONFLICT',
              cause: error,
            );
          }
          rethrow;
        }
      }

      return List<AttendanceRecordDto>.unmodifiable(saved);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceRuleConfigDto> fetchRuleConfig(String subjectClassId) async {
    try {
      final row = await _client
          .from('subject_classes')
          .select(_ruleColumns)
          .eq('id', subjectClassId)
          .single();
      return AttendanceRuleConfigDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AttendanceRuleConfigDto> updateRuleConfig(
    AttendanceRuleConfig config,
  ) async {
    final validationError = config.validate();
    if (validationError != null) {
      throw ValidationException(
        validationError,
        code: 'INVALID_ATTENDANCE_RULE',
      );
    }
    try {
      final row = await _client
          .from('subject_classes')
          .update(AttendanceRuleConfigDto.toUpdateJson(config))
          .eq('id', config.subjectClassId)
          .select(_ruleColumns)
          .single();
      return AttendanceRuleConfigDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return AttendanceRemoteDataSource(client);
  },
);
