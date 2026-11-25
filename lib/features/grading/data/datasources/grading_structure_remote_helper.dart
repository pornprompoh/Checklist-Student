import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../models/assignment_dto.dart';
import '../models/score_category_dto.dart';

/// Internal Supabase helper handling `public.score_categories` and
/// `public.assignments` operations with Optimistic Locking (`version`).
class GradingStructureRemoteHelper {
  const GradingStructureRemoteHelper(this._client);

  final SupabaseClient _client;

  static const String _categoryColumns =
      'id, teacher_id, subject_class_id, name, target_max_score, sort_order, '
      'created_at, updated_at';
  static const String _assignmentColumns =
      'id, teacher_id, subject_class_id, category_id, title, description, '
      'max_score, is_mandatory, due_date, sort_order, version, created_at, '
      'updated_at';

  Future<List<ScoreCategoryDto>> fetchScoreCategories(
    String subjectClassId,
  ) async {
    try {
      final rows = await _client
          .from('score_categories')
          .select(_categoryColumns)
          .eq('subject_class_id', subjectClassId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return rows.map(ScoreCategoryDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<ScoreCategoryDto> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    final trimmedName = _validateCategoryInput(name, targetMaxScore);
    try {
      final resolvedOrder =
          sortOrder ??
          await _nextSortOrder('score_categories', subjectClassId);
      final data = await _client
          .from('score_categories')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'subject_class_id': subjectClassId,
            'name': trimmedName,
            'target_max_score': targetMaxScore,
            'sort_order': resolvedOrder,
          })
          .select(_categoryColumns)
          .single();
      return ScoreCategoryDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<ScoreCategoryDto> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    final trimmedName = _validateCategoryInput(name, targetMaxScore);
    try {
      final data = await _client
          .from('score_categories')
          .update(<String, dynamic>{
            'name': trimmedName,
            'target_max_score': targetMaxScore,
            'sort_order': ?sortOrder,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', categoryId)
          .select(_categoryColumns)
          .single();
      return ScoreCategoryDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> deleteScoreCategory(String categoryId) async {
    try {
      await _client.from('score_categories').delete().eq('id', categoryId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<AssignmentDto>> fetchAssignments(String subjectClassId) async {
    try {
      final rows = await _client
          .from('assignments')
          .select(_assignmentColumns)
          .eq('subject_class_id', subjectClassId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return rows.map(AssignmentDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AssignmentDto> createAssignment({
    required String teacherId,
    required String subjectClassId,
    String? categoryId,
    required String title,
    String description = '',
    required double maxScore,
    bool isMandatory = false,
    DateTime? dueDate,
    int? sortOrder,
  }) async {
    final trimmedTitle = _validateAssignmentInput(title, maxScore);
    try {
      final resolvedOrder =
          sortOrder ?? await _nextSortOrder('assignments', subjectClassId);
      final data = await _client
          .from('assignments')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'subject_class_id': subjectClassId,
            'category_id': categoryId,
            'title': trimmedTitle,
            'description': description.trim(),
            'max_score': maxScore,
            'is_mandatory': isMandatory,
            'due_date': dueDate == null
                ? null
                : ThaiDateFormatter.toIsoDate(dueDate),
            'sort_order': resolvedOrder,
            'version': 1,
          })
          .select(_assignmentColumns)
          .single();
      return AssignmentDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<AssignmentDto> updateAssignment({
    required String assignmentId,
    required int expectedVersion,
    String? categoryId,
    required String title,
    required String description,
    required double maxScore,
    required bool isMandatory,
    DateTime? dueDate,
    int? sortOrder,
  }) async {
    final trimmedTitle = _validateAssignmentInput(title, maxScore);
    try {
      final data = await _client
          .from('assignments')
          .update(<String, dynamic>{
            'category_id': categoryId,
            'title': trimmedTitle,
            'description': description.trim(),
            'max_score': maxScore,
            'is_mandatory': isMandatory,
            'due_date': dueDate == null
                ? null
                : ThaiDateFormatter.toIsoDate(dueDate),
            'sort_order': ?sortOrder,
            'version': expectedVersion + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', assignmentId)
          .eq('version', expectedVersion)
          .select(_assignmentColumns)
          .maybeSingle();
      if (data == null) {
        throw const ConflictException(
          'ชิ้นงานนี้ถูกแก้ไขจากอุปกรณ์อื่น กรุณาโหลดข้อมูลล่าสุดก่อนบันทึกใหม่',
          code: 'ASSIGNMENT_VERSION_CONFLICT',
        );
      }
      return AssignmentDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> countScoredStudentsForAssignment(String assignmentId) async {
    try {
      final rows = await _client
          .from('student_scores')
          .select('id')
          .eq('assignment_id', assignmentId)
          .not('score', 'is', null);
      return rows.length;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _client.from('assignments').delete().eq('id', assignmentId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  String _validateCategoryInput(String name, double? targetMaxScore) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException(
        'กรุณาระบุชื่อหมวดคะแนน',
        code: 'EMPTY_CATEGORY_NAME',
      );
    }
    if (targetMaxScore != null &&
        (!targetMaxScore.isFinite || targetMaxScore < 0)) {
      throw const ValidationException(
        'คะแนนเต็มเป้าหมายของหมวดต้องไม่ติดลบ',
        code: 'INVALID_CATEGORY_TARGET_SCORE',
      );
    }
    return trimmed;
  }

  String _validateAssignmentInput(String title, double maxScore) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException(
        'กรุณาระบุชื่อชิ้นงานหรือรายการสอบ',
        code: 'EMPTY_ASSIGNMENT_TITLE',
      );
    }
    if (!maxScore.isFinite || maxScore < 0) {
      throw const ValidationException(
        'คะแนนเต็มต้องเป็นตัวเลขที่ไม่ติดลบ',
        code: 'INVALID_ASSIGNMENT_MAX_SCORE',
      );
    }
    return trimmed;
  }

  Future<int> _nextSortOrder(String table, String subjectClassId) async {
    final row = await _client
        .from(table)
        .select('sort_order')
        .eq('subject_class_id', subjectClassId)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) {
      return 0;
    }
    return ((row['sort_order'] as num?)?.toInt() ?? -1) + 1;
  }
}
