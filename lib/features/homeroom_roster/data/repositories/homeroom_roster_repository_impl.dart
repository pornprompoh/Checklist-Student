import 'dart:typed_data';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/entities/homeroom_student.dart';
import '../../domain/entities/roster_import_result.dart';
import '../../domain/entities/roster_import_row_preview.dart';
import '../../domain/entities/student_lifecycle_status.dart';
import '../../domain/entities/uploaded_import_file.dart';
import '../../domain/repositories/homeroom_roster_repository.dart';
import '../../domain/services/roster_renumber_service.dart';
import '../datasources/ai_roster_remote_datasource.dart';
import '../datasources/class_enrollment_remote_datasource.dart';
import '../datasources/homeroom_roster_local_datasource.dart';
import '../datasources/homeroom_roster_remote_datasource.dart';

/// Repository implementation coordinating remote datasources and future
/// Phase 6 [HomeroomRosterLocalDataSource] (Drift).
class HomeroomRosterRepositoryImpl implements HomeroomRosterRepository {
  const HomeroomRosterRepositoryImpl({
    required this._homeroomRemote,
    required this._enrollmentRemote,
    this._aiRosterRemote,
    this._localDataSource,
  });

  final HomeroomRosterRemoteDataSource? _homeroomRemote;
  final ClassEnrollmentRemoteDataSource? _enrollmentRemote;
  final AiRosterRemoteDataSource? _aiRosterRemote;
  // Reserved for Phase 6 Drift local caching (active term only).
  // ignore: unused_field
  final HomeroomRosterLocalDataSource? _localDataSource;

  @override
  Future<List<Homeroom>> fetchHomerooms(String termId) async {
    final dtos = await _requireHomeroomRemote().fetchHomerooms(termId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<Homeroom> createHomeroom({
    required String teacherId,
    required String termId,
    required String name,
  }) async {
    final dto = await _requireHomeroomRemote().createHomeroom(
      teacherId: teacherId,
      termId: termId,
      name: name,
    );
    return dto.toEntity();
  }

  @override
  Future<Homeroom> renameHomeroom({
    required String homeroomId,
    required String name,
  }) async {
    final dto = await _requireHomeroomRemote().renameHomeroom(
      homeroomId: homeroomId,
      name: name,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteHomeroom(String homeroomId) {
    return _requireHomeroomRemote().deleteHomeroom(homeroomId);
  }

  @override
  Future<List<HomeroomStudent>> fetchHomeroomStudents(String homeroomId) async {
    final dtos = await _requireHomeroomRemote().fetchHomeroomStudents(
      homeroomId,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<HomeroomStudent> addHomeroomStudent({
    required String teacherId,
    required String homeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
  }) async {
    final dto = await _requireHomeroomRemote().addHomeroomStudent(
      teacherId: teacherId,
      homeroomId: homeroomId,
      studentCode: studentCode,
      studentNumber: studentNumber,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
    );
    return dto.toEntity();
  }

  @override
  Future<int> updateHomeroomStudent({
    required String homeroomStudentId,
    required String teacherId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required bool syncLinkedClasses,
  }) {
    return _requireHomeroomRemote().updateHomeroomStudent(
      homeroomStudentId: homeroomStudentId,
      teacherId: teacherId,
      studentCode: studentCode,
      studentNumber: studentNumber,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
      syncLinkedClasses: syncLinkedClasses,
    );
  }

  @override
  Future<int> setHomeroomStudentStatus({
    required String homeroomStudentId,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncLinkedClasses,
  }) {
    return _requireHomeroomRemote().setHomeroomStudentStatus(
      homeroomStudentId: homeroomStudentId,
      status: status,
      transferredOutAt: transferredOutAt,
      syncLinkedClasses: syncLinkedClasses,
    );
  }

  @override
  Future<int> renumberHomeroomStudents({
    required List<RenumberAssignment> assignments,
    required bool syncLinkedClasses,
  }) {
    return _requireHomeroomRemote().renumberHomeroomStudents(
      assignments: assignments,
      syncLinkedClasses: syncLinkedClasses,
    );
  }

  @override
  Future<RosterImportResult> importHomeroomStudents({
    required String teacherId,
    required String homeroomId,
    required List<RosterImportRowPreview> rows,
    required bool syncOverwrittenToLinkedClasses,
  }) {
    return _requireHomeroomRemote().importHomeroomStudents(
      teacherId: teacherId,
      homeroomId: homeroomId,
      rows: rows,
      syncOverwrittenToLinkedClasses: syncOverwrittenToLinkedClasses,
    );
  }

  @override
  Future<UploadedImportFileResult> uploadAndParseRosterWithAi({
    required String teacherId,
    required String academicYearId,
    required String homeroomId,
    required String originalFilename,
    required Uint8List compressedBytes,
    required String mimeType,
    required String fileExtension,
  }) {
    final aiRemote = _aiRosterRemote;
    if (aiRemote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนดำเนินการ',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return aiRemote.uploadAndParseRosterWithAi(
      teacherId: teacherId,
      academicYearId: academicYearId,
      homeroomId: homeroomId,
      originalFilename: originalFilename,
      compressedBytes: compressedBytes,
      mimeType: mimeType,
      fileExtension: fileExtension,
    );
  }

  @override
  Future<int> linkHomeroomToSubjectClasses({
    required String teacherId,
    required String homeroomId,
    required List<String> subjectClassIds,
    required DateTime enrolledAt,
  }) {
    return _requireEnrollmentRemote().linkHomeroomToSubjectClasses(
      teacherId: teacherId,
      homeroomId: homeroomId,
      subjectClassIds: subjectClassIds,
      enrolledAt: enrolledAt,
    );
  }

  @override
  Future<List<ClassEnrollment>> fetchClassEnrollments(
    String subjectClassId,
  ) async {
    final dtos = await _requireEnrollmentRemote().fetchClassEnrollments(
      subjectClassId,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<ClassEnrollment> addClassEnrollmentMidTerm({
    required String teacherId,
    required String subjectClassId,
    String? addToHomeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
  }) async {
    final dto = await _requireEnrollmentRemote().addClassEnrollmentMidTerm(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      addToHomeroomId: addToHomeroomId,
      studentCode: studentCode,
      studentNumber: studentNumber,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
      enrolledAt: enrolledAt,
    );
    return dto.toEntity();
  }

  @override
  Future<int> updateClassEnrollment({
    required ClassEnrollment existing,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
    required bool syncToHomeroomAndAllClasses,
  }) {
    return _requireEnrollmentRemote().updateClassEnrollment(
      existing: existing,
      studentCode: studentCode,
      studentNumber: studentNumber,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
      enrolledAt: enrolledAt,
      syncToHomeroomAndAllClasses: syncToHomeroomAndAllClasses,
    );
  }

  @override
  Future<int> setClassEnrollmentStatus({
    required ClassEnrollment existing,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncToHomeroomAndAllClasses,
  }) {
    return _requireEnrollmentRemote().setClassEnrollmentStatus(
      existing: existing,
      status: status,
      transferredOutAt: transferredOutAt,
      syncToHomeroomAndAllClasses: syncToHomeroomAndAllClasses,
    );
  }

  @override
  Future<void> renumberClassEnrollments({
    required List<ClassEnrollment> currentEnrollments,
    required List<RenumberAssignment> assignments,
  }) {
    return _requireEnrollmentRemote().renumberClassEnrollments(
      currentEnrollments: currentEnrollments,
      assignments: assignments,
    );
  }

  HomeroomRosterRemoteDataSource _requireHomeroomRemote() {
    final remote = _homeroomRemote;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนดำเนินการ',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote;
  }

  ClassEnrollmentRemoteDataSource _requireEnrollmentRemote() {
    final remote = _enrollmentRemote;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนดำเนินการ',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote;
  }
}
