import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/dashboard_class_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Offline-first repository coordinating [DashboardRemoteDataSource] with
/// Drift read-through caching via [DashboardLocalDataSource].
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({
    required this._remoteDataSource,
    this._localDataSource,
    this._currentTeacherId,
    this._isOnline,
  });

  final DashboardRemoteDataSource? _remoteDataSource;
  final DashboardLocalDataSource? _localDataSource;
  final String? Function()? _currentTeacherId;
  final bool Function()? _isOnline;

  @override
  Future<List<DashboardClassItem>> fetchDashboardClasses({
    required String termId,
    required DateTime referenceDate,
  }) async {
    final remote = _remoteDataSource;
    final local = _localDataSource;
    final teacherId = _currentTeacherId?.call();
    final online = _isOnline?.call() ?? true;

    if (online && remote != null) {
      try {
        final dtos = await remote.fetchDashboardClasses(
          termId: termId,
          referenceDate: referenceDate,
        );
        final items = dtos.map((dto) => dto.toEntity()).toList(growable: false);
        if (local != null && teacherId != null) {
          await local.saveDashboardClasses(
            teacherId: teacherId,
            termId: termId,
            referenceDate: referenceDate,
            items: items,
          );
        }
        return items;
      } on NetworkException {
        if (local != null && teacherId != null) {
          final cached = await local.readDashboardClasses(
            teacherId: teacherId,
            termId: termId,
            referenceDate: referenceDate,
          );
          if (cached != null) return cached;
        }
        rethrow;
      }
    }

    if (local != null && teacherId != null) {
      final cached = await local.readDashboardClasses(
        teacherId: teacherId,
        termId: termId,
        referenceDate: referenceDate,
      );
      if (cached != null) return cached;
    }
    if (remote == null && local == null) {
      return const <DashboardClassItem>[];
    }
    throw const NetworkException(
      'ขณะนี้ออฟไลน์และยังไม่มีข้อมูลหน้าแดชบอร์ดที่แคชไว้สำหรับเทอมนี้ กรุณาเชื่อมต่ออินเทอร์เน็ตก่อนเปิดดูครั้งแรก',
      code: 'OFFLINE_NO_LOCAL_CACHE',
    );
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
