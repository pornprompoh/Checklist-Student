import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../domain/entities/student_pin_verification_result.dart';
import '../models/resolved_teacher_portal_dto.dart';
import '../models/student_pin_access_status_dto.dart';
import '../models/student_pin_verification_result_dto.dart';
import '../models/student_portal_summary_dto.dart';

/// Remote datasource for `features/student_portal/` invoking exclusively the
/// 4 `SECURITY DEFINER` Student Portal RPCs (zero direct table queries).
///
/// The ONLY file in `features/student_portal/` allowed to import `supabase_flutter`.
class StudentPortalRemoteDataSource {
  const StudentPortalRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<ResolvedTeacherPortalDto> resolveTeacherCode(
    String teacherCode,
  ) async {
    try {
      final response = await _client.rpc<dynamic>(
        'resolve_teacher_code',
        params: <String, dynamic>{'p_teacher_code': teacherCode.trim()},
      );
      return ResolvedTeacherPortalDto.fromJson(_requireJsonMap(response));
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<StudentPinAccessStatusDto> checkStudentAccess({
    required String teacherCode,
    required String studentCode,
  }) async {
    try {
      final response = await _client.rpc<dynamic>(
        'check_student_portal_access',
        params: <String, dynamic>{
          'p_teacher_code': teacherCode.trim(),
          'p_student_code': studentCode.trim(),
        },
      );
      return StudentPinAccessStatusDto.fromJson(_requireJsonMap(response));
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<StudentPinVerificationResultDto> verifyOrSetPin({
    required String teacherCode,
    required String studentCode,
    required String pin,
    StudentPinAuthMode mode = StudentPinAuthMode.verify,
  }) async {
    try {
      final response = await _client.rpc<dynamic>(
        'verify_or_set_student_pin',
        params: <String, dynamic>{
          'p_teacher_code': teacherCode.trim(),
          'p_student_code': studentCode.trim(),
          'p_pin': pin,
          'p_mode': mode.rpcValue,
        },
      );
      return StudentPinVerificationResultDto.fromJson(
        _requireJsonMap(response),
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<StudentPortalSummaryDto> fetchPortalSummary({
    required String teacherCode,
    required String studentCode,
    required String pin,
    String? termId,
  }) async {
    try {
      final response = await _client.rpc<dynamic>(
        'get_student_portal_summary',
        params: <String, dynamic>{
          'p_teacher_code': teacherCode.trim(),
          'p_student_code': studentCode.trim(),
          'p_pin': pin,
          'p_term_id': termId,
        },
      );
      return StudentPortalSummaryDto.fromJson(_requireJsonMap(response));
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Map<String, dynamic> _requireJsonMap(dynamic response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw const AppException(
      'รูปแบบข้อมูลตอบกลับจากระบบไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง',
      code: 'INVALID_RPC_RESPONSE',
    );
  }
}

final studentPortalRemoteDataSourceProvider =
    Provider<StudentPortalRemoteDataSource>((ref) {
      return StudentPortalRemoteDataSource(ref.watch(supabaseClientProvider));
    });
