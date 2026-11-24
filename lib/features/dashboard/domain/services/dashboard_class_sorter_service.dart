import '../entities/dashboard_class_item.dart';

/// Pure Dart service implementing Teacher Dashboard smart sorting and filtering.
///
/// Priority buckets (highest first):
/// 0. `teachesToday && isPinned`
/// 1. `teachesToday && !isPinned`
/// 2. `!teachesToday && isPinned`
/// 3. `!teachesToday && !isPinned`
///
/// Tie-breaker within the same bucket: `subjectCode ASC`, then `roomName ASC`.
class DashboardClassSorterService {
  const DashboardClassSorterService();

  List<DashboardClassItem> sortClasses(
    List<DashboardClassItem> items, {
    required int todayIsoWeekday,
  }) {
    final sorted = List<DashboardClassItem>.of(items);
    sorted.sort((a, b) {
      final bucketCompare = _priorityBucket(
        a,
        todayIsoWeekday,
      ).compareTo(_priorityBucket(b, todayIsoWeekday));
      if (bucketCompare != 0) {
        return bucketCompare;
      }

      final codeCompare = a.subjectCode.toLowerCase().compareTo(
        b.subjectCode.toLowerCase(),
      );
      if (codeCompare != 0) {
        return codeCompare;
      }

      return a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase());
    });
    return List<DashboardClassItem>.unmodifiable(sorted);
  }

  List<DashboardClassItem> filterClasses(
    List<DashboardClassItem> items, {
    required int todayIsoWeekday,
    required bool onlyToday,
    required bool onlyPinned,
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return List<DashboardClassItem>.unmodifiable(
      items.where((item) {
        if (onlyToday && !item.teachesOnWeekday(todayIsoWeekday)) {
          return false;
        }
        if (onlyPinned && !item.isPinned) {
          return false;
        }
        if (normalizedQuery.isNotEmpty) {
          final haystack =
              '${item.subjectCode} ${item.subjectName} ${item.roomName}'
                  .toLowerCase();
          if (!haystack.contains(normalizedQuery)) {
            return false;
          }
        }
        return true;
      }),
    );
  }

  int _priorityBucket(DashboardClassItem item, int todayIsoWeekday) {
    final teachesToday = item.teachesOnWeekday(todayIsoWeekday);
    if (teachesToday && item.isPinned) return 0;
    if (teachesToday) return 1;
    if (item.isPinned) return 2;
    return 3;
  }
}
