import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/dashboard_class_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Repository implementation bridging [DashboardRemoteDataSource] and future
/// Phase 6 [DashboardLocalDataSource] (Drift).
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
  });

  final DashboardRemoteDataSource? _remoteDataSource;
  // Reserved for Phase 6 Drift local caching.
  // ignore: unused_field
  final DashboardLocalDataSource? _localDataSource;

  @override
  Future<List<DashboardClassItem>> fetchDashboardClasses({
    required String termId,
    required DateTime referenceDate,
  }) async {
    final remote = _remoteDataSource;
    if (remote == null) {
      return const <DashboardClassItem>[];
    }
    final dtos = await remote.fetchDashboardClasses(
      termId: termId,
      referenceDate: referenceDate,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<void> toggleClassPin({
    required String subjectClassId,
    required bool isPinned,
  }) {
    final remote = _remoteDataSource;
    if (remote == null) {
      throw const ValidationException(
        'ยังไม่ได้ตั้งค่าการเชื่อมต่อ Supabase กรุณาตรวจสอบ Environment ก่อนดำเนินการ',
        code: 'SUPABASE_NOT_CONFIGURED',
      );
    }
    return remote.toggleClassPin(
      subjectClassId: subjectClassId,
      isPinned: isPinned,
    );
  }
}
