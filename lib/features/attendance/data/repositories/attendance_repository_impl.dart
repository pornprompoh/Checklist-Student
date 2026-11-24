import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_record_input.dart';
import '../../domain/entities/attendance_rule_config.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';

/// Repository implementation bridging [AttendanceRemoteDataSource] and future
/// Phase 6 [AttendanceLocalDataSource] (Drift).
class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
  });

  final AttendanceRemoteDataSource? _remoteDataSource;
  // Reserved for Phase 6 Drift local caching.
  // ignore: unused_field
  final AttendanceLocalDataSource? _localDataSource;

  @override
  Future<List<AttendanceSession>> fetchSessions(String subjectClassId) async {
    final dtos = await _requireRemote().fetchSessions(subjectClassId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<AttendanceSession?> fetchSessionByDate({
    required String subjectClassId,
    required DateTime sessionDate,
  }) async {
    final dto = await _requireRemote().fetchSessionByDate(
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
    );
    return dto?.toEntity();
  }

  @override
  Future<List<AttendanceRecord>> fetchRecordsBySession(String sessionId) async {
    final dtos = await _requireRemote().fetchRecordsBySession(sessionId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<AttendanceRecord>> fetchRecordsByClass(
    String subjectClassId,
  ) async {
    final dtos = await _requireRemote().fetchRecordsByClass(subjectClassId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<AttendanceSession> createSession({
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
    String note = '',
    bool isLocked = false,
  }) async {
    final dto = await _requireRemote().createSession(
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
      note: note,
      isLocked: isLocked,
    );
    return dto.toEntity();
  }

  @override
  Future<AttendanceSession> updateSession({
    required String sessionId,
    required String note,
    required bool isLocked,
    required int expectedVersion,
  }) async {
    final dto = await _requireRemote().updateSession(
      sessionId: sessionId,
      note: note,
      isLocked: isLocked,
      expectedVersion: expectedVersion,
    );
    return dto.toEntity();
  }

  @override
  Future<List<AttendanceRecord>> saveSessionRecords({
    required String teacherId,
    required String sessionId,
    required List<AttendanceRecordInput> inputs,
  }) async {
    final dtos = await _requireRemote().saveSessionRecords(
      teacherId: teacherId,
      sessionId: sessionId,
      inputs: inputs,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<AttendanceRuleConfig> fetchRuleConfig(String subjectClassId) async {
    final dto = await _requireRemote().fetchRuleConfig(subjectClassId);
    return dto.toEntity();
  }

  @override
  Future<AttendanceRuleConfig> updateRuleConfig(
    AttendanceRuleConfig config,
  ) async {
    final dto = await _requireRemote().updateRuleConfig(config);
    return dto.toEntity();
  }

  AttendanceRemoteDataSource _requireRemote() {
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
