import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/teacher_feature_flags.dart';
import '../../domain/entities/teacher_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Repository implementation coordinating [AuthRemoteDataSource] and future
/// Phase 6 [AuthLocalDataSource] (Drift).
///
/// Safely degrades to unauthenticated state when [remoteDataSource] is `null`
/// (e.g., running locally without `--dart-define` Supabase credentials).
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
    this._onClearTeacherLocalData,
  });

  final AuthRemoteDataSource? _remoteDataSource;
  // Reserved for Phase 6 Drift local caching.
  // ignore: unused_field
  final AuthLocalDataSource? _localDataSource;
  final Future<void> Function(String teacherId)? _onClearTeacherLocalData;

  @override
  String? get currentUserId => _remoteDataSource?.currentUserId;

  @override
  Stream<String?> watchAuthenticatedUserId() {
    final remote = _remoteDataSource;
    if (remote == null) {
      return Stream<String?>.value(null);
    }
    return remote.watchAuthenticatedUserId();
  }

  @override
  Future<void> signInWithGoogle() async {
    final remote = _remoteDataSource;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาส่งค่า SUPABASE_URL และ SUPABASE_ANON_KEY',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    await remote.signInWithGoogle();
  }

  @override
  Future<void> signOut() async {
    final teacherId = _remoteDataSource?.currentUserId;
    if (teacherId != null && teacherId.isNotEmpty) {
      await _onClearTeacherLocalData?.call(teacherId);
    }
    final remote = _remoteDataSource;
    if (remote == null) {
      return;
    }
    await remote.signOut();
  }

  @override
  Future<TeacherProfile?> fetchTeacherProfile(String userId) async {
    final remote = _remoteDataSource;
    if (remote == null) {
      return null;
    }
    final dto = await remote.fetchTeacherProfile(userId);
    return dto?.toEntity();
  }

  @override
  Future<TeacherFeatureFlags?> fetchTeacherFeatureFlags(String userId) async {
    final remote = _remoteDataSource;
    if (remote == null) {
      return null;
    }
    final dto = await remote.fetchTeacherFeatureFlags(userId);
    return dto?.toEntity();
  }
}
