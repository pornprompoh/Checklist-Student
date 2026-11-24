import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../domain/entities/delete_impact_summary.dart';
import '../../domain/entities/subject_class.dart';
import '../models/academic_year_dto.dart';
import '../models/delete_impact_summary_dto.dart';
import '../models/subject_class_dto.dart';
import '../models/subject_dto.dart';
import '../models/term_dto.dart';
import 'academic_structure_homeroom_linker.dart';

/// Remote data source communicating with the 4-level academic hierarchy tables
/// and structural RPCs in Supabase.
///
/// Only this file in `features/academic_structure/` may import `supabase_flutter`.
class AcademicStructureRemoteDataSource {
  const AcademicStructureRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _academicYearColumns =
      'id, teacher_id, year_be, created_at, updated_at';
  static const String _termColumns =
      'id, teacher_id, academic_year_id, term_label, start_date, end_date, '
      'is_pinned_active, created_at, updated_at';
  static const String _subjectColumns =
      'id, teacher_id, term_id, subject_code, subject_name, created_at, updated_at';
  static const String _subjectClassColumns =
      'id, teacher_id, subject_id, homeroom_id, room_name, teaching_days, '
      'is_pinned, show_score_to_student, show_grade_to_student, '
      'absent_threshold_pct, missing_work_threshold, late_to_absent_ratio, '
      'count_leave_as_absent, attendance_score_weight, grading_scale_type, '
      'grading_rules, created_at, updated_at';

  // --- Level 1: Academic Years ---
  Future<List<AcademicYearDto>> fetchAcademicYears() async {
    try {
      final rows = await _client
          .from('academic_years')
          .select(_academicYearColumns)
          .order('year_be', ascending: false);
      return rows.map(AcademicYearDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AcademicYearDto> createAcademicYear({
    required String teacherId,
    required int yearBe,
  }) async {
    try {
      final data = await _client
          .from('academic_years')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'year_be': yearBe,
          })
          .select(_academicYearColumns)
          .single();
      return AcademicYearDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> deleteAcademicYear(String academicYearId) async {
    try {
      await _client.from('academic_years').delete().eq('id', academicYearId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  // --- Level 2: Terms ---
  Future<List<TermDto>> fetchTerms({String? academicYearId}) async {
    try {
      var query = _client.from('terms').select(_termColumns);
      if (academicYearId != null) {
        query = query.eq('academic_year_id', academicYearId);
      }
      final rows = await query.order('start_date', ascending: false);
      return rows.map(TermDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<TermDto> createTerm({
    required String teacherId,
    required String academicYearId,
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = await _client
          .from('terms')
          .insert(
            TermDto.toInsertJson(
              teacherId: teacherId,
              academicYearId: academicYearId,
              termLabel: termLabel,
              startDate: startDate,
              endDate: endDate,
            ),
          )
          .select(_termColumns)
          .single();
      return TermDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<TermDto> updateTerm({
    required String termId,
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = await _client
          .from('terms')
          .update(
            TermDto.toUpdateJson(
              termLabel: termLabel,
              startDate: startDate,
              endDate: endDate,
            ),
          )
          .eq('id', termId)
          .select(_termColumns)
          .single();
      return TermDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> setPinnedActiveTerm(String? termId) async {
    try {
      await _client.rpc<void>(
        'set_pinned_active_term',
        params: <String, dynamic>{'p_term_id': termId},
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> deleteTerm(String termId) async {
    try {
      await _client.from('terms').delete().eq('id', termId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  // --- Level 3: Subjects ---
  Future<List<SubjectDto>> fetchSubjects(String termId) async {
    try {
      final rows = await _client
          .from('subjects')
          .select(_subjectColumns)
          .eq('term_id', termId)
          .order('subject_code', ascending: true);
      return rows.map(SubjectDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<SubjectDto> createSubject({
    required String teacherId,
    required String termId,
    required String subjectCode,
    required String subjectName,
  }) async {
    try {
      final data = await _client
          .from('subjects')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'term_id': termId,
            'subject_code': subjectCode.trim(),
            'subject_name': subjectName.trim(),
          })
          .select(_subjectColumns)
          .single();
      return SubjectDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<SubjectDto> updateSubject({
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) async {
    try {
      final data = await _client
          .from('subjects')
          .update(<String, dynamic>{
            'subject_code': subjectCode.trim(),
            'subject_name': subjectName.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', subjectId)
          .select(_subjectColumns)
          .single();
      return SubjectDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _client.from('subjects').delete().eq('id', subjectId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  // --- Level 4: Subject Classes ---
  Future<List<SubjectClassDto>> fetchSubjectClasses(String subjectId) async {
    try {
      final rows = await _client
          .from('subject_classes')
          .select(_subjectClassColumns)
          .eq('subject_id', subjectId)
          .order('is_pinned', ascending: false)
          .order('room_name', ascending: true);
      return rows.map(SubjectClassDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<SubjectClassDto>> fetchSubjectClassesByTerm(String termId) async {
    try {
      final rows = await _client
          .from('subject_classes')
          .select('$_subjectClassColumns, subjects!inner(term_id)')
          .eq('subjects.term_id', termId)
          .order('is_pinned', ascending: false)
          .order('room_name', ascending: true);
      return rows.map(SubjectClassDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<SubjectClassDto> createSubjectClass({
    required String teacherId,
    required String subjectId,
    String? termId,
    String? homeroomId,
    required String roomName,
    bool autoLinkHomeroom = false,
    DateTime? defaultEnrolledAt,
    List<int> teachingDays = const <int>[],
    bool isPinned = false,
    double? absentThresholdPct,
    int? missingWorkThreshold,
  }) async {
    try {
      var resolvedHomeroomId = homeroomId;
      if (autoLinkHomeroom && resolvedHomeroomId == null && termId != null) {
        resolvedHomeroomId =
            await AcademicStructureHomeroomLinker.ensureHomeroomId(
              client: _client,
              teacherId: teacherId,
              termId: termId,
              roomName: roomName,
            );
      }

      final payload = <String, dynamic>{
        'teacher_id': teacherId,
        'subject_id': subjectId,
        'homeroom_id': resolvedHomeroomId,
        'room_name': roomName.trim(),
        'teaching_days': teachingDays,
        'is_pinned': isPinned,
        'absent_threshold_pct': ?absentThresholdPct,
        'missing_work_threshold': ?missingWorkThreshold,
      };
      final data = await _client
          .from('subject_classes')
          .insert(payload)
          .select(_subjectClassColumns)
          .single();
      final createdDto = SubjectClassDto.fromJson(data);

      if (autoLinkHomeroom && resolvedHomeroomId != null) {
        await AcademicStructureHomeroomLinker.copyActiveHomeroomStudentsToClass(
          client: _client,
          teacherId: teacherId,
          homeroomId: resolvedHomeroomId,
          subjectClassId: createdDto.id,
          enrolledAt: defaultEnrolledAt ?? DateTime.now(),
        );
      }

      return createdDto;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<SubjectClassDto> updateSubjectClass(SubjectClass subjectClass) async {
    try {
      final data = await _client
          .from('subject_classes')
          .update(SubjectClassDto.toUpdateJson(subjectClass))
          .eq('id', subjectClass.id)
          .select(_subjectClassColumns)
          .single();
      return SubjectClassDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> deleteSubjectClass(String subjectClassId) async {
    try {
      await _client.from('subject_classes').delete().eq('id', subjectClassId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  // --- Structural Deletion Impact RPC ---
  Future<DeleteImpactSummaryDto> getDeleteImpactSummary({
    required StructuralEntityType entityType,
    required String entityId,
  }) async {
    try {
      final response = await _client.rpc<dynamic>(
        'get_delete_impact_summary',
        params: <String, dynamic>{
          'p_entity_type': entityType.dbValue,
          'p_entity_id': entityId,
        },
      );
      return DeleteImpactSummaryDto.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

final academicStructureRemoteDataSourceProvider =
    Provider<AcademicStructureRemoteDataSource>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return AcademicStructureRemoteDataSource(client);
    });
