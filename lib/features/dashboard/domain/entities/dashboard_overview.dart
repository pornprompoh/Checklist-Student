import 'dashboard_class_item.dart';

/// Complete dashboard snapshot for one academic term and reference date.
///
/// Pure Dart entity with aggregate counters used by dashboard metrics.
class DashboardOverview {
  const DashboardOverview({
    required this.termId,
    required this.referenceDate,
    required this.classes,
  });

  final String termId;
  final DateTime referenceDate;
  final List<DashboardClassItem> classes;

  int get totalClassesCount => classes.length;

  int get todayClassesCount =>
      classes.where((c) => c.teachesOnWeekday(referenceDate.weekday)).length;

  int get checkedTodayCount => classes.where((c) => c.isCheckedToday).length;

  int get checkedScheduledTodayCount => classes
      .where(
        (c) => c.teachesOnWeekday(referenceDate.weekday) && c.isCheckedToday,
      )
      .length;

  int get totalActiveStudentsCount =>
      classes.fold<int>(0, (sum, item) => sum + item.activeStudentCount);
}
