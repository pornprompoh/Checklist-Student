/// Summary returned after committing a homeroom Excel/CSV roster import.
/// Pure Dart entity.
class RosterImportResult {
  const RosterImportResult({
    required this.insertedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.syncedEnrollmentsCount,
  });

  final int insertedCount;
  final int updatedCount;
  final int skippedCount;
  final int syncedEnrollmentsCount;
}
