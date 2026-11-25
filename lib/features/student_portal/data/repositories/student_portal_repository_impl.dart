import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/resolved_teacher_portal.dart';
import '../../domain/entities/student_pin_access_status.dart';
import '../../domain/entities/student_pin_verification_result.dart';
import '../../domain/entities/student_portal_summary.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../datasources/student_portal_local_datasource.dart';
import '../datasources/student_portal_remote_datasource.dart';

/// Concrete [StudentPortalRepository] delegating all operations to
/// [StudentPortalRemoteDataSource] (`SECURITY DEFINER` RPCs).
class StudentPortalRepositoryImpl implements StudentPortalRepository {
  const StudentPortalRepositoryImpl({
    required StudentPortalRemoteDataSource? remoteDataSource,
    StudentPortalLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final StudentPortalRemoteDataSource? _remote;
  // Reserved for 3-layer architectural parity; Student Portal intentionally
  // reads fresh server-masked data rather than caching sensitive records locally.
  // ignore: unused_field
  final StudentPortalLocalDataSource? _local;

  StudentPortalRemoteDataSource get _requireRemote {
    final remote = _remote;
    if (remote == null) {
      throw const NetworkException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อระบบ กรุณาติดต่อครูผู้สอน',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote;
  }

  @override
  Future<ResolvedTeacherPortal> resolveTeacherCode(String teacherCode) async {
    final dto = await _requireRemote.resolveTeacherCode(teacherCode);
    return dto.toEntity();
  }

  @override
  Future<StudentPinAccessStatus> checkStudentAccess({
    required String teacherCode,
    required String studentCode,
  }) async {
    final dto = await _requireRemote.checkStudentAccess(
      teacherCode: teacherCode,
      studentCode: studentCode,
    );
    return dto.toEntity();
  }

  @override
  Future<StudentPinVerificationResult> verifyOrSetPin({
    required String teacherCode,
    required String studentCode,
    required String pin,
    StudentPinAuthMode mode = StudentPinAuthMode.verify,
  }) async {
    final dto = await _requireRemote.verifyOrSetPin(
      teacherCode: teacherCode,
      studentCode: studentCode,
      pin: pin,
      mode: mode,
    );
    return dto.toEntity();
  }

  @override
  Future<StudentPortalSummary> fetchPortalSummary({
    required String teacherCode,
    required String studentCode,
    required String pin,
    String? termId,
  }) async {
    final dto = await _requireRemote.fetchPortalSummary(
      teacherCode: teacherCode,
      studentCode: studentCode,
      pin: pin,
      termId: termId,
    );
    return dto.toEntity();
  }
}
