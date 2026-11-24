/// Summary returned after committing a homeroom Excel/CSV or AI roster import.
/// Pure Dart entity.
class RosterImportResult {
  const RosterImportResult({
    required this.insertedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.syncedEnrollmentsCount,
    this.autoEnrolledClassesCount = 0,
    this.autoEnrolledStudentsCount = 0,
  });

  final int insertedCount;
  final int updatedCount;
  final int skippedCount;
  final int syncedEnrollmentsCount;
  final int autoEnrolledClassesCount;
  final int autoEnrolledStudentsCount;
}
