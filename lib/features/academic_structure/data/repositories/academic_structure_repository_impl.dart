import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/delete_impact_summary.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import '../../domain/entities/term.dart';
import '../../domain/repositories/academic_structure_repository.dart';
import '../datasources/academic_structure_local_datasource.dart';
import '../datasources/academic_structure_remote_datasource.dart';

/// Offline-first repository coordinating [AcademicStructureRemoteDataSource]
/// with Drift read-through caching via [AcademicStructureLocalDataSource].
class AcademicStructureRepositoryImpl implements AcademicStructureRepository {
  const AcademicStructureRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
    this._currentTeacherId,
    this._isOnline,
  });

  final AcademicStructureRemoteDataSource? _remoteDataSource;
  final AcademicStructureLocalDataSource? _localDataSource;
  final String? Function()? _currentTeacherId;
  final bool Function()? _isOnline;

  bool get _online => _isOnline?.call() ?? true;
  String? get _teacherId => _currentTeacherId?.call();

  @override
  Future<List<AcademicYear>> fetchAcademicYears() {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dtos = await _requireRemote().fetchAcademicYears();
        return dtos.map((dto) => dto.toEntity()).toList(growable: false);
      },
      saveLocal: (tid, data) => _localDataSource!.saveAcademicYears(tid, data),
      readLocal: (tid) => _localDataSource!.readAcademicYears(tid),
    );
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
  Future<List<Term>> fetchTerms({String? academicYearId}) {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dtos = await _requireRemote().fetchTerms(
          academicYearId: academicYearId,
        );
        return dtos.map((dto) => dto.toEntity()).toList(growable: false);
      },
      saveLocal: (tid, data) => _localDataSource!.saveTerms(
        tid,
        data,
        academicYearId: academicYearId,
      ),
      readLocal: (tid) => _localDataSource!.readTerms(
        tid,
        academicYearId: academicYearId,
      ),
    );
  }

  @override
  Future<Term> createTerm({
    required String teacherId,
    required String academicYearId,
    required String termLabel,
    DateTime? startDate,
    DateTime? endDate,
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
    DateTime? startDate,
    DateTime? endDate,
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
  Future<List<Subject>> fetchSubjects(String termId) {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dtos = await _requireRemote().fetchSubjects(termId);
        return dtos.map((dto) => dto.toEntity()).toList(growable: false);
      },
      saveLocal: (tid, data) =>
          _localDataSource!.saveSubjects(tid, termId, data),
      readLocal: (tid) => _localDataSource!.readSubjects(tid, termId),
    );
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
  Future<List<SubjectClass>> fetchSubjectClasses(String subjectId) {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dtos = await _requireRemote().fetchSubjectClasses(subjectId);
        return dtos.map((dto) => dto.toEntity()).toList(growable: false);
      },
      saveLocal: (tid, data) =>
          _localDataSource!.saveSubjectClasses(tid, subjectId, data),
      readLocal: (tid) => _localDataSource!.readSubjectClasses(tid, subjectId),
    );
  }

  @override
  Future<List<SubjectClass>> fetchSubjectClassesByTerm(String termId) {
    return _readWithCacheFallback(
      fetchRemote: () async {
        final dtos = await _requireRemote().fetchSubjectClassesByTerm(termId);
        return dtos.map((dto) => dto.toEntity()).toList(growable: false);
      },
      saveLocal: (tid, data) =>
          _localDataSource!.saveSubjectClassesByTerm(tid, termId, data),
      readLocal: (tid) =>
          _localDataSource!.readSubjectClassesByTerm(tid, termId),
    );
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

  Future<T> _readWithCacheFallback<T>({
    required Future<T> Function() fetchRemote,
    required Future<void> Function(String teacherId, T data) saveLocal,
    required Future<T?> Function(String teacherId) readLocal,
  }) async {
    final tid = _teacherId;
    final local = _localDataSource;
    if (_online && _remoteDataSource != null) {
      try {
        final fresh = await fetchRemote();
        if (local != null && tid != null) {
          await saveLocal(tid, fresh);
        }
        return fresh;
      } on NetworkException {
        if (local != null && tid != null) {
          final cached = await readLocal(tid);
          if (cached != null) return cached;
        }
        rethrow;
      }
    }
    if (local != null && tid != null) {
      final cached = await readLocal(tid);
      if (cached != null) return cached;
    }
    throw const NetworkException(
      'ขณะนี้ออฟไลน์และยังไม่มีข้อมูลโครงสร้างสอนที่แคชไว้ในเครื่อง กรุณาเชื่อมต่ออินเทอร์เน็ตก่อนเปิดดูครั้งแรก',
      code: 'OFFLINE_NO_LOCAL_CACHE',
    );
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
