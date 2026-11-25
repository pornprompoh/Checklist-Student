import '../../../../core/database/local_cache_store.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/entities/homeroom_student.dart';
import '../models/class_enrollment_dto.dart';
import '../models/homeroom_dto.dart';
import '../models/homeroom_student_dto.dart';
import 'homeroom_roster_local_datasource.dart';

/// Drift-backed read-through cache for Homeroom Rosters & Class Enrollments.
class HomeroomRosterLocalDataSourceImpl
    implements HomeroomRosterLocalDataSource {
  const HomeroomRosterLocalDataSourceImpl(this._cache);

  final LocalCacheStore _cache;
  static const String _group = 'homeroom_roster';
  static const String _enrollmentClassMapKey = 'enrollment_class_map';

  @override
  Future<void> saveHomerooms(
    String teacherId,
    String termId,
    List<Homeroom> homerooms,
  ) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'homerooms_$termId',
      entityGroup: _group,
      jsonPayload: homerooms.map(_homeroomToJson).toList(growable: false),
    );
  }

  @override
  Future<List<Homeroom>?> readHomerooms(String teacherId, String termId) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'homerooms_$termId',
    );
    return _decodeList(raw, (m) => HomeroomDto.fromJson(m).toEntity());
  }

  @override
  Future<void> saveHomeroomStudents(
    String teacherId,
    String homeroomId,
    List<HomeroomStudent> students,
  ) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'homeroom_students_$homeroomId',
      entityGroup: _group,
      jsonPayload: students.map(_homeroomStudentToJson).toList(growable: false),
    );
  }

  @override
  Future<List<HomeroomStudent>?> readHomeroomStudents(
    String teacherId,
    String homeroomId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'homeroom_students_$homeroomId',
    );
    return _decodeList(raw, (m) => HomeroomStudentDto.fromJson(m).toEntity());
  }

  @override
  Future<void> saveClassEnrollments(
    String teacherId,
    String subjectClassId,
    List<ClassEnrollment> enrollments,
  ) async {
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'class_enrollments_$subjectClassId',
      entityGroup: _group,
      jsonPayload: enrollments.map(_enrollmentToJson).toList(growable: false),
    );
    final rawMap = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: _enrollmentClassMapKey,
    );
    final map = rawMap is Map
        ? Map<String, String>.from(
            rawMap.map((k, v) => MapEntry(k.toString(), v.toString())),
          )
        : <String, String>{};
    for (final e in enrollments) {
      map[e.id] = subjectClassId;
    }
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: _enrollmentClassMapKey,
      entityGroup: _group,
      jsonPayload: map,
    );
  }

  @override
  Future<List<ClassEnrollment>?> readClassEnrollments(
    String teacherId,
    String subjectClassId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'class_enrollments_$subjectClassId',
    );
    return _decodeList(raw, (m) => ClassEnrollmentDto.fromJson(m).toEntity());
  }

  @override
  Future<void> patchCachedEnrollmentSpecialGrade({
    required String teacherId,
    required String enrollmentId,
    required String? specialGradeOverride,
    bool? wasRResolved,
    bool? wasMsResolved,
    int? version,
    DateTime? resolvedGradeAt,
  }) async {
    final rawMap = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: _enrollmentClassMapKey,
    );
    if (rawMap is! Map) return;
    final subjectClassId = rawMap[enrollmentId]?.toString();
    if (subjectClassId == null || subjectClassId.isEmpty) return;

    final current = await readClassEnrollments(teacherId, subjectClassId);
    if (current == null || current.isEmpty) return;
    final now = DateTime.now().toUtc();
    final updated = current
        .map((item) {
          if (item.id != enrollmentId) return item;
          return ClassEnrollment(
            id: item.id,
            teacherId: item.teacherId,
            subjectClassId: item.subjectClassId,
            homeroomStudentId: item.homeroomStudentId,
            studentIdentityId: item.studentIdentityId,
            studentCode: item.studentCode,
            studentNumber: item.studentNumber,
            prefix: item.prefix,
            firstName: item.firstName,
            lastName: item.lastName,
            status: item.status,
            enrolledAt: item.enrolledAt,
            transferredOutAt: item.transferredOutAt,
            specialGradeOverride: specialGradeOverride,
            wasRResolved: wasRResolved ?? item.wasRResolved,
            wasMsResolved: wasMsResolved ?? item.wasMsResolved,
            resolvedGradeAt: resolvedGradeAt ?? item.resolvedGradeAt,
            version: version ?? item.version,
            createdAt: item.createdAt,
            updatedAt: now,
          );
        })
        .toList(growable: false);

    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'class_enrollments_$subjectClassId',
      entityGroup: _group,
      jsonPayload: updated.map(_enrollmentToJson).toList(growable: false),
    );
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

  Map<String, dynamic> _homeroomToJson(Homeroom h) => <String, dynamic>{
    'id': h.id,
    'teacher_id': h.teacherId,
    'term_id': h.termId,
    'name': h.name,
    'created_at': h.createdAt.toUtc().toIso8601String(),
    'updated_at': h.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _homeroomStudentToJson(HomeroomStudent s) =>
      <String, dynamic>{
        'id': s.id,
        'teacher_id': s.teacherId,
        'homeroom_id': s.homeroomId,
        'student_identity_id': s.studentIdentityId,
        'student_code': s.studentCode,
        'student_number': s.studentNumber,
        'prefix': s.prefix,
        'first_name': s.firstName,
        'last_name': s.lastName,
        'status': s.status.dbValue,
        'transferred_out_at': s.transferredOutAt == null
            ? null
            : ThaiDateFormatter.toIsoDate(s.transferredOutAt!),
        'created_at': s.createdAt.toUtc().toIso8601String(),
        'updated_at': s.updatedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _enrollmentToJson(ClassEnrollment e) =>
      <String, dynamic>{
        'id': e.id,
        'teacher_id': e.teacherId,
        'subject_class_id': e.subjectClassId,
        'homeroom_student_id': e.homeroomStudentId,
        'student_identity_id': e.studentIdentityId,
        'student_code': e.studentCode,
        'student_number': e.studentNumber,
        'prefix': e.prefix,
        'first_name': e.firstName,
        'last_name': e.lastName,
        'status': e.status.dbValue,
        'enrolled_at': ThaiDateFormatter.toIsoDate(e.enrolledAt),
        'transferred_out_at': e.transferredOutAt == null
            ? null
            : ThaiDateFormatter.toIsoDate(e.transferredOutAt!),
        'special_grade_override': e.specialGradeOverride,
        'was_r_resolved': e.wasRResolved,
        'was_ms_resolved': e.wasMsResolved,
        'resolved_grade_at': e.resolvedGradeAt?.toUtc().toIso8601String(),
        'version': e.version,
        'created_at': e.createdAt.toUtc().toIso8601String(),
        'updated_at': e.updatedAt.toUtc().toIso8601String(),
      };
}
