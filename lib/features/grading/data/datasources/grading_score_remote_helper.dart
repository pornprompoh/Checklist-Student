import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/services/grade_evaluator_service.dart';
import '../models/grading_scale_config_dto.dart';
import '../models/student_pin_status_dto.dart';
import '../models/student_score_dto.dart';

/// Internal Supabase helper handling `public.student_scores`, grading scale
/// rules on `public.subject_classes`, RPC `copy_subject_class_plan`, and
/// special-grade columns on `public.class_enrollments`.
///
/// Never inserts into `score_audit_logs`; PostgreSQL triggers record audits.
class GradingScoreRemoteHelper {
  const GradingScoreRemoteHelper(this._client);

  final SupabaseClient _client;

  static const String _scoreColumns =
      'id, teacher_id, assignment_id, enrollment_id, submission_status, '
      'score, note, version, updated_at';
  static const String _scaleColumns =
      'id, grading_scale_type, grading_rules, missing_work_threshold';

  Future<List<StudentScoreDto>> fetchStudentScoresByClass(
    String subjectClassId,
  ) async {
    try {
      final assignmentRows = await _client
          .from('assignments')
          .select('id')
          .eq('subject_class_id', subjectClassId);
      if (assignmentRows.isEmpty) {
        return const <StudentScoreDto>[];
      }
      final assignmentIds = assignmentRows
          .map((row) => row['id'] as String)
          .toList(growable: false);
      final rows = await _client
          .from('student_scores')
          .select(_scoreColumns)
          .inFilter('assignment_id', assignmentIds);
      return rows.map(StudentScoreDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<StudentScoreDto> upsertStudentScore({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    String? existingScoreId,
    int? expectedVersion,
    required SubmissionStatus submissionStatus,
    double? score,
    String note = '',
  }) async {
    if (score != null && (!score.isFinite || score < 0)) {
      throw const ValidationException(
        'คะแนนต้องเป็นตัวเลขที่ไม่ติดลบ',
        code: 'INVALID_STUDENT_SCORE',
      );
    }
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      if (existingScoreId != null) {
        if (expectedVersion == null) {
          throw const ValidationException(
            'ไม่พบหมายเลขเวอร์ชันของคะแนนเดิม กรุณาโหลดข้อมูลใหม่',
            code: 'MISSING_EXPECTED_VERSION',
          );
        }
        final updated = await _client
            .from('student_scores')
            .update(<String, dynamic>{
              'submission_status': submissionStatus.dbValue,
              'score': score,
              'note': note.trim(),
              'version': expectedVersion + 1,
              'updated_at': nowIso,
            })
            .eq('id', existingScoreId)
            .eq('version', expectedVersion)
            .select(_scoreColumns)
            .maybeSingle();
        if (updated == null) {
          throw const ConflictException(
            'คะแนนรายการนี้ถูกแก้ไขจากอุปกรณ์อื่น กรุณาโหลดข้อมูลล่าสุดก่อนบันทึกใหม่',
            code: 'STUDENT_SCORE_VERSION_CONFLICT',
          );
        }
        return StudentScoreDto.fromJson(updated);
      }

      try {
        final inserted = await _client
            .from('student_scores')
            .insert(<String, dynamic>{
              'teacher_id': teacherId,
              'assignment_id': assignmentId,
              'enrollment_id': enrollmentId,
              'submission_status': submissionStatus.dbValue,
              'score': score,
              'note': note.trim(),
              'version': 1,
              'updated_at': nowIso,
            })
            .select(_scoreColumns)
            .single();
        return StudentScoreDto.fromJson(inserted);
      } on PostgrestException catch (error) {
        if (error.code == '23505') {
          throw ConflictException(
            'พบข้อมูลคะแนนที่ถูกบันทึกจากอุปกรณ์อื่นแล้ว กรุณาโหลดข้อมูลล่าสุดแล้วลองใหม่',
            code: 'STUDENT_SCORE_VERSION_CONFLICT',
            cause: error,
          );
        }
        rethrow;
      }
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<GradingScaleConfigDto> fetchGradingScaleConfig(
    String subjectClassId,
  ) async {
    try {
      final row = await _client
          .from('subject_classes')
          .select(_scaleColumns)
          .eq('id', subjectClassId)
          .single();
      return GradingScaleConfigDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<GradingScaleConfigDto> updateGradingScaleConfig(
    GradingScaleConfig config,
  ) async {
    final ruleError = const GradeEvaluatorService().validateGradingRules(
      config.rules,
    );
    if (ruleError != null) {
      throw ValidationException(ruleError, code: 'INVALID_GRADING_RULES');
    }
    if (config.missingWorkThreshold < 0) {
      throw const ValidationException(
        'เกณฑ์จำนวนงานค้างต้องไม่ติดลบ',
        code: 'INVALID_MISSING_WORK_THRESHOLD',
      );
    }
    try {
      final row = await _client
          .from('subject_classes')
          .update(GradingScaleConfigDto.toUpdateJson(config))
          .eq('id', config.subjectClassId)
          .select(_scaleColumns)
          .single();
      return GradingScaleConfigDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  }) async {
    try {
      final raw = await _client.rpc(
        'copy_subject_class_plan',
        params: <String, dynamic>{
          'p_source_class_id': sourceClassId,
          'p_target_class_id': targetClassId,
          'p_replace_existing': replaceExisting,
        },
      );
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      return CopyPlanResult(
        copiedCategoriesCount:
            (map['copied_categories_count'] as num?)?.toInt() ?? 0,
        copiedAssignmentsCount:
            (map['copied_assignments_count'] as num?)?.toInt() ?? 0,
        gradingScaleType:
            (map['grading_scale_type'] as String?) ??
            GradingScaleType.scale0To4.dbValue,
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) async {
    if (specialGradeOverride != null &&
        specialGradeOverride != 'ร' &&
        specialGradeOverride != 'มส') {
      throw const ValidationException(
        'สถานะเกรดพิเศษต้องเป็น ร, มส หรือยกเลิกสถานะเท่านั้น',
        code: 'INVALID_SPECIAL_GRADE_OVERRIDE',
      );
    }
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final payload = <String, dynamic>{
        'special_grade_override': specialGradeOverride,
        'version': expectedVersion + 1,
        'updated_at': nowIso,
      };
      if (markRResolved) {
        payload['was_r_resolved'] = true;
      }
      if (markMsResolved) {
        payload['was_ms_resolved'] = true;
      }
      if (markRResolved || markMsResolved) {
        payload['resolved_grade_at'] = nowIso;
      }

      final updated = await _client
          .from('class_enrollments')
          .update(payload)
          .eq('id', enrollmentId)
          .eq('version', expectedVersion)
          .select('id')
          .maybeSingle();
      if (updated == null) {
        throw const ConflictException(
          'สถานะเกรดพิเศษของนักเรียนนี้ถูกแก้ไขจากอุปกรณ์อื่น กรุณาโหลดข้อมูลล่าสุดก่อนบันทึกใหม่',
          code: 'ENROLLMENT_VERSION_CONFLICT',
        );
      }
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<StudentPinStatusDto> fetchStudentPinStatus(
    String studentIdentityId,
  ) async {
    try {
      final row = await _client
          .from('student_identities')
          .select('id, pin_hash, pin_updated_at, failed_attempts, locked_until')
          .eq('id', studentIdentityId)
          .single();
      return StudentPinStatusDto.fromJson(row);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> resetStudentPin(String studentIdentityId) async {
    try {
      await _client
          .from('student_identities')
          .update(<String, dynamic>{
            'pin_hash': null,
            'pin_updated_at': null,
            'failed_attempts': 0,
            'locked_until': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', studentIdentityId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}
