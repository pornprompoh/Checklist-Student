import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/audit_log_target_type.dart';
import '../../domain/entities/audit_log_year_summary.dart';
import '../../domain/entities/score_audit_log_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_local_datasource.dart';
import '../datasources/audit_log_remote_datasource.dart';

/// Repository implementation bridging [AuditLogRemoteDataSource] and future
/// Phase 6 [AuditLogLocalDataSource] (Drift).
class AuditLogRepositoryImpl implements AuditLogRepository {
  const AuditLogRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
  });

  final AuditLogRemoteDataSource? _remoteDataSource;
  // Reserved for Phase 6 Drift local caching.
  // ignore: unused_field
  final AuditLogLocalDataSource? _localDataSource;

  @override
  Future<List<ScoreAuditLogEntry>> fetchAuditLogs({
    String? academicYearId,
    String? subjectClassId,
    String? enrollmentId,
    AuditLogTargetType? targetType,
    int limit = 500,
  }) async {
    final dtos = await _requireRemote().fetchAuditLogs(
      academicYearId: academicYearId,
      subjectClassId: subjectClassId,
      enrollmentId: enrollmentId,
      targetType: targetType,
      limit: limit,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<AuditLogYearSummary>> fetchAuditLogYearSummaries() {
    return _requireRemote().fetchAuditLogYearSummaries();
  }

  @override
  Future<int> deleteAuditLogsByAcademicYear(String academicYearId) {
    return _requireRemote().deleteAuditLogsByAcademicYear(academicYearId);
  }

  AuditLogRemoteDataSource _requireRemote() {
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
