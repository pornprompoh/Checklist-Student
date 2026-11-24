import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/delete_impact_summary.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import '../../domain/entities/term.dart';
import '../../domain/repositories/academic_structure_repository.dart';
import '../datasources/academic_structure_local_datasource.dart';
import '../datasources/academic_structure_remote_datasource.dart';

/// Repository implementation coordinating [AcademicStructureRemoteDataSource]
/// and future Phase 6 [AcademicStructureLocalDataSource] (Drift).
class AcademicStructureRepositoryImpl implements AcademicStructureRepository {
  const AcademicStructureRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
  });

  final AcademicStructureRemoteDataSource? _remoteDataSource;
  // Reserved for Phase 6 Drift local caching (active term only).
  // ignore: unused_field
  final AcademicStructureLocalDataSource? _localDataSource;

  @override
  Future<List<AcademicYear>> fetchAcademicYears() async {
    final dtos = await _requireRemote().fetchAcademicYears();
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<AcademicYear> createAcademicYear({
    required String teacherId,
    required int yearBe,
  }) async {
    final dto = await _requireRemote().createAcademicYear(
      teacherId: teacherId,
      yearBe: yearBe,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteAcademicYear(String academicYearId) {
    return _requireRemote().deleteAcademicYear(academicYearId);
  }

  @override
  Future<List<Term>> fetchTerms({String? academicYearId}) async {
    final dtos = await _requireRemote().fetchTerms(
      academicYearId: academicYearId,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<Term> createTerm({
    required String teacherId,
    required String academicYearId,
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dto = await _requireRemote().createTerm(
      teacherId: teacherId,
      academicYearId: academicYearId,
      termLabel: termLabel,
      startDate: startDate,
      endDate: endDate,
    );
    return dto.toEntity();
  }

  @override
  Future<Term> updateTerm({
    required String termId,
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dto = await _requireRemote().updateTerm(
      termId: termId,
      termLabel: termLabel,
      startDate: startDate,
      endDate: endDate,
    );
    return dto.toEntity();
  }

  @override
  Future<void> setPinnedActiveTerm(String? termId) {
    return _requireRemote().setPinnedActiveTerm(termId);
  }

  @override
  Future<void> deleteTerm(String termId) {
    return _requireRemote().deleteTerm(termId);
  }

  @override
  Future<List<Subject>> fetchSubjects(String termId) async {
    final dtos = await _requireRemote().fetchSubjects(termId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<Subject> createSubject({
    required String teacherId,
    required String termId,
    required String subjectCode,
    required String subjectName,
  }) async {
    final dto = await _requireRemote().createSubject(
      teacherId: teacherId,
      termId: termId,
      subjectCode: subjectCode,
      subjectName: subjectName,
    );
    return dto.toEntity();
  }

  @override
  Future<Subject> updateSubject({
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) async {
    final dto = await _requireRemote().updateSubject(
      subjectId: subjectId,
      subjectCode: subjectCode,
      subjectName: subjectName,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteSubject(String subjectId) {
    return _requireRemote().deleteSubject(subjectId);
  }

  @override
  Future<List<SubjectClass>> fetchSubjectClasses(String subjectId) async {
    final dtos = await _requireRemote().fetchSubjectClasses(subjectId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<SubjectClass>> fetchSubjectClassesByTerm(String termId) async {
    final dtos = await _requireRemote().fetchSubjectClassesByTerm(termId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<SubjectClass> createSubjectClass({
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
    final dto = await _requireRemote().createSubjectClass(
      teacherId: teacherId,
      subjectId: subjectId,
      termId: termId,
      homeroomId: homeroomId,
      roomName: roomName,
      autoLinkHomeroom: autoLinkHomeroom,
      defaultEnrolledAt: defaultEnrolledAt,
      teachingDays: teachingDays,
      isPinned: isPinned,
      absentThresholdPct: absentThresholdPct,
      missingWorkThreshold: missingWorkThreshold,
    );
    return dto.toEntity();
  }

  @override
  Future<SubjectClass> updateSubjectClass(SubjectClass subjectClass) async {
    final dto = await _requireRemote().updateSubjectClass(subjectClass);
    return dto.toEntity();
  }

  @override
  Future<void> deleteSubjectClass(String subjectClassId) {
    return _requireRemote().deleteSubjectClass(subjectClassId);
  }

  @override
  Future<DeleteImpactSummary> getDeleteImpactSummary({
    required StructuralEntityType entityType,
    required String entityId,
  }) async {
    final dto = await _requireRemote().getDeleteImpactSummary(
      entityType: entityType,
      entityId: entityId,
    );
    return dto.toEntity();
  }

  AcademicStructureRemoteDataSource _requireRemote() {
    final remote = _remoteDataSource;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนดำเนินการ',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote;
  }
}
