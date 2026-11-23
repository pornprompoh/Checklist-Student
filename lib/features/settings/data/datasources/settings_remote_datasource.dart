import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/data/models/teacher_profile_dto.dart';
import '../../domain/entities/teacher_profile_update.dart';
import '../models/teacher_code_history_dto.dart';

/// Remote data source communicating with `public.teachers` and
/// `public.teacher_code_history`.
///
/// Only this file in `features/settings/` is allowed to import `supabase_flutter`.
class SettingsRemoteDataSource {
  const SettingsRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _teacherColumns =
      'id, email, display_name, school_name, department, teacher_code, '
      'default_absent_threshold_pct, default_missing_work_threshold, '
      'created_at, updated_at';

  Future<TeacherProfileDto> updateTeacherProfile({
    required String teacherId,
    required TeacherProfileUpdate update,
  }) async {
    try {
      final data = await _client
          .from('teachers')
          .update(<String, dynamic>{
            'display_name': update.displayName.trim(),
            'school_name': update.schoolName.trim(),
            'department': update.department.trim(),
            'default_absent_threshold_pct': update.defaultAbsentThresholdPct,
            'default_missing_work_threshold':
                update.defaultMissingWorkThreshold,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', teacherId)
          .select(_teacherColumns)
          .maybeSingle();

      if (data == null) {
        throw const ValidationException(
          'ไม่พบข้อมูลโปรไฟล์ครูในฐานข้อมูล หรือไม่มีสิทธิ์แก้ไข กรุณาตรวจสอบสิทธิ์ฐานข้อมูลแล้วลองใหม่',
          code: 'TEACHER_PROFILE_NOT_UPDATED',
        );
      }

      return TeacherProfileDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<TeacherProfileDto> updateTeacherCode({
    required String teacherId,
    required String newTeacherCode,
  }) async {
    try {
      final data = await _client
          .from('teachers')
          .update(<String, dynamic>{
            'teacher_code': newTeacherCode,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', teacherId)
          .select(_teacherColumns)
          .maybeSingle();

      if (data == null) {
        throw const ValidationException(
          'ไม่สามารถเปลี่ยนรหัสครูได้ เนื่องจากไม่พบข้อมูลบัญชีครูหรือไม่มีสิทธิ์แก้ไข',
          code: 'TEACHER_CODE_NOT_UPDATED',
        );
      }

      return TeacherProfileDto.fromJson(data);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw ValidationException(
          'รหัสครูนี้ถูกใช้งานแล้ว กรุณาเลือกรหัสอื่น',
          code: '23505',
          cause: error,
        );
      }
      if (error.message.contains('รหัสนี้เคยถูกใช้งานแล้ว')) {
        throw ValidationException(
          'รหัสนี้เคยถูกใช้งานแล้ว กรุณาเลือกรหัสอื่น',
          code: 'TEACHER_CODE_TAKEN',
          cause: error,
        );
      }
      throw ThaiErrorMapper.toAppException(error);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<TeacherCodeHistoryDto>> fetchTeacherCodeHistory(
    String teacherId,
  ) async {
    try {
      final rows = await _client
          .from('teacher_code_history')
          .select('old_code, teacher_id, changed_at')
          .eq('teacher_id', teacherId)
          .order('changed_at', ascending: false);

      return rows
          .map<TeacherCodeHistoryDto>(TeacherCodeHistoryDto.fromJson)
          .toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return SettingsRemoteDataSource(client);
});
