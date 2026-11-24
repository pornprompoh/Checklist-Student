import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/data/models/teacher_profile_dto.dart';
import '../../domain/entities/teacher_profile_update.dart';
import '../models/import_file_record_dto.dart';
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

  static const String _importSourcesBucket = 'import-sources';
  static const int _signedUrlExpirySeconds = 60;

  Future<List<ImportFileRecordDto>> fetchActiveImportFiles(
    String teacherId,
  ) async {
    try {
      final rows = await _client
          .from('import_files')
          .select(
            'id, teacher_id, academic_year_id, homeroom_id, storage_path, '
            'original_filename, mime_type, file_size_bytes, created_at, '
            'deleted_at, academic_years(year_be)',
          )
          .eq('teacher_id', teacherId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return rows
          .map<ImportFileRecordDto>(ImportFileRecordDto.fromJson)
          .toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<String> createImportFileSignedUrl(String storagePath) async {
    try {
      return await _client.storage
          .from(_importSourcesBucket)
          .createSignedUrl(storagePath, _signedUrlExpirySeconds);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> cleanupImportFilesByAcademicYear({
    required String teacherId,
    required String academicYearId,
  }) async {
    try {
      final rows = await _client
          .from('import_files')
          .select('id, storage_path')
          .eq('teacher_id', teacherId)
          .eq('academic_year_id', academicYearId)
          .isFilter('deleted_at', null);

      if (rows.isEmpty) {
        return 0;
      }

      final ids = <String>[];
      final storagePaths = <String>[];
      for (final row in rows) {
        final id = row['id'] as String?;
        final path = row['storage_path'] as String?;
        if (id != null && id.isNotEmpty) {
          ids.add(id);
        }
        if (path != null && path.isNotEmpty) {
          storagePaths.add(path);
        }
      }

      if (storagePaths.isNotEmpty) {
        await _client.storage.from(_importSourcesBucket).remove(storagePaths);
      }

      if (ids.isNotEmpty) {
        await _client
            .from('import_files')
            .update(<String, dynamic>{
              'deleted_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('teacher_id', teacherId)
            .inFilter('id', ids);
      }

      return ids.length;
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
