import '../entities/dashboard_class_item.dart';

/// Abstract repository contract for the Teacher Dashboard feature.
///
/// Pure Dart interface following the Repository Pattern.
abstract interface class DashboardRepository {
  /// Loads all teaching classes in [termId] enriched with active student counts
  /// and today's attendance summary for [referenceDate].
  Future<List<DashboardClassItem>> fetchDashboardClasses({
    required String termId,
    required DateTime referenceDate,
  });

  /// Updates `public.subject_classes.is_pinned` for [subjectClassId].
  Future<void> toggleClassPin({
    required String subjectClassId,
    required bool isPinned,
  });
}
