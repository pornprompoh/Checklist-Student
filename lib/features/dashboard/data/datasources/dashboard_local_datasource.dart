import '../../domain/entities/dashboard_class_item.dart';

/// Local Drift cache contract for Teacher Dashboard offline read-through.
abstract interface class DashboardLocalDataSource {
  Future<void> saveDashboardClasses({
    required String teacherId,
    required String termId,
    required DateTime referenceDate,
    required List<DashboardClassItem> items,
  });

  Future<List<DashboardClassItem>?> readDashboardClasses({
    required String teacherId,
    required String termId,
    required DateTime referenceDate,
  });
}
