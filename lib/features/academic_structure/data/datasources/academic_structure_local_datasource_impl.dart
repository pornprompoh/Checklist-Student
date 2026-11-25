import '../../../../core/database/local_cache_store.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import '../../domain/entities/term.dart';
import '../models/academic_year_dto.dart';
import '../models/subject_class_dto.dart';
import '../models/subject_dto.dart';
import '../models/term_dto.dart';
import 'academic_structure_local_datasource.dart';

/// Drift-backed read-through cache for Academic Structure scoped per teacher.
class AcademicStructureLocalDataSourceImpl
    implements AcademicStructureLocalDataSource {
  const AcademicStructureLocalDataSourceImpl(this._cache);

  final LocalCacheStore _cache;
  static const String _group = 'academic_structure';

  @override
  Future<void> saveAcademicYears(String teacherId, List<AcademicYear> years) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'academic_years',
      entityGroup: _group,
      jsonPayload: years.map(_yearToJson).toList(growable: false),
    );
  }

  @override
  Future<List<AcademicYear>?> readAcademicYears(String teacherId) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'academic_years',
    );
    return _decodeList(raw, (m) => AcademicYearDto.fromJson(m).toEntity());
  }

  @override
  Future<void> saveTerms(
    String teacherId,
    List<Term> terms, {
    String? academicYearId,
  }) {
    final key = academicYearId == null ? 'terms_all' : 'terms_$academicYearId';
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: key,
      entityGroup: _group,
      jsonPayload: terms.map(_termToJson).toList(growable: false),
    );
  }

  @override
  Future<List<Term>?> readTerms(
    String teacherId, {
    String? academicYearId,
  }) async {
    final key = academicYearId == null ? 'terms_all' : 'terms_$academicYearId';
    final raw = await _cache.readJson(teacherId: teacherId, cacheKey: key);
    final exact = _decodeList(raw, (m) => TermDto.fromJson(m).toEntity());
    if (exact != null || academicYearId == null) return exact;
    final allRaw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'terms_all',
    );
    final all = _decodeList(allRaw, (m) => TermDto.fromJson(m).toEntity());
    return all
        ?.where((t) => t.academicYearId == academicYearId)
        .toList(growable: false);
  }

  @override
  Future<void> saveSubjects(
    String teacherId,
    String termId,
    List<Subject> subjects,
  ) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'subjects_$termId',
      entityGroup: _group,
      jsonPayload: subjects.map(_subjectToJson).toList(growable: false),
    );
  }

  @override
  Future<List<Subject>?> readSubjects(String teacherId, String termId) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'subjects_$termId',
    );
    return _decodeList(raw, (m) => SubjectDto.fromJson(m).toEntity());
  }

  @override
  Future<void> saveSubjectClasses(
    String teacherId,
    String subjectId,
    List<SubjectClass> classes,
  ) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'subject_classes_subject_$subjectId',
      entityGroup: _group,
      jsonPayload: classes.map(_classToJson).toList(growable: false),
    );
  }

  @override
  Future<List<SubjectClass>?> readSubjectClasses(
    String teacherId,
    String subjectId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'subject_classes_subject_$subjectId',
    );
    return _decodeList(raw, (m) => SubjectClassDto.fromJson(m).toEntity());
  }

  @override
  Future<void> saveSubjectClassesByTerm(
    String teacherId,
    String termId,
    List<SubjectClass> classes,
  ) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'subject_classes_term_$termId',
      entityGroup: _group,
      jsonPayload: classes.map(_classToJson).toList(growable: false),
    );
  }

  @override
  Future<List<SubjectClass>?> readSubjectClassesByTerm(
    String teacherId,
    String termId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'subject_classes_term_$termId',
    );
    return _decodeList(raw, (m) => SubjectClassDto.fromJson(m).toEntity());
  }

  List<T>? _decodeList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (raw is! List) return null;
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => mapper(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Map<String, dynamic> _yearToJson(AcademicYear y) => <String, dynamic>{
    'id': y.id,
    'teacher_id': y.teacherId,
    'year_be': y.yearBe,
    'created_at': y.createdAt.toUtc().toIso8601String(),
    'updated_at': y.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _termToJson(Term t) => <String, dynamic>{
    'id': t.id,
    'teacher_id': t.teacherId,
    'academic_year_id': t.academicYearId,
    'term_label': t.termLabel,
    'start_date': ThaiDateFormatter.toIsoDate(t.startDate),
    'end_date': ThaiDateFormatter.toIsoDate(t.endDate),
    'is_pinned_active': t.isPinnedActive,
    'created_at': t.createdAt.toUtc().toIso8601String(),
    'updated_at': t.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _subjectToJson(Subject s) => <String, dynamic>{
    'id': s.id,
    'teacher_id': s.teacherId,
    'term_id': s.termId,
    'subject_code': s.subjectCode,
    'subject_name': s.subjectName,
    'created_at': s.createdAt.toUtc().toIso8601String(),
    'updated_at': s.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _classToJson(SubjectClass c) => <String, dynamic>{
    'id': c.id,
    'teacher_id': c.teacherId,
    'subject_id': c.subjectId,
    'homeroom_id': c.homeroomId,
    'room_name': c.roomName,
    'teaching_days': c.teachingDays,
    'is_pinned': c.isPinned,
    'show_score_to_student': c.showScoreToStudent,
    'show_grade_to_student': c.showGradeToStudent,
    'absent_threshold_pct': c.absentThresholdPct,
    'missing_work_threshold': c.missingWorkThreshold,
    'late_to_absent_ratio': c.lateToAbsentRatio,
    'count_leave_as_absent': c.countLeaveAsAbsent,
    'attendance_score_weight': c.attendanceScoreWeight,
    'grading_scale_type': c.gradingScaleType,
    'grading_rules': c.gradingRules
        .map((r) => <String, dynamic>{'grade': r.grade, 'min': r.min})
        .toList(growable: false),
    'created_at': c.createdAt.toUtc().toIso8601String(),
    'updated_at': c.updatedAt.toUtc().toIso8601String(),
  };
}
