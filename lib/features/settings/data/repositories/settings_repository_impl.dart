import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/entities/teacher_profile.dart';
import '../../domain/entities/teacher_code_history_entry.dart';
import '../../domain/entities/teacher_profile_update.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';

/// Repository implementation bridging [SettingsRemoteDataSource] and future
/// Phase 6 [SettingsLocalDataSource] (Drift).
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
  });

  final SettingsRemoteDataSource? _remoteDataSource;
  // Reserved for Phase 6 Drift local caching.
  // ignore: unused_field
  final SettingsLocalDataSource? _localDataSource;

  @override
  Future<TeacherProfile> updateTeacherProfile({
    required String teacherId,
    required TeacherProfileUpdate update,
  }) async {
    final remote = _requireRemote();
    final dto = await remote.updateTeacherProfile(
      teacherId: teacherId,
      update: update,
    );
    return dto.toEntity();
  }

  @override
  Future<TeacherProfile> updateTeacherCode({
    required String teacherId,
    required String newTeacherCode,
  }) async {
    final remote = _requireRemote();
    final dto = await remote.updateTeacherCode(
      teacherId: teacherId,
      newTeacherCode: newTeacherCode,
    );
    return dto.toEntity();
  }

  @override
  Future<List<TeacherCodeHistoryEntry>> fetchTeacherCodeHistory(
    String teacherId,
  ) async {
    final remote = _remoteDataSource;
    if (remote == null) {
      return const <TeacherCodeHistoryEntry>[];
    }
    final dtos = await remote.fetchTeacherCodeHistory(teacherId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  SettingsRemoteDataSource _requireRemote() {
    final remote = _remoteDataSource;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนบันทึกข้อมูล',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote;
  }
}
