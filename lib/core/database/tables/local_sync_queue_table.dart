import 'package:drift/drift.dart';

/// Persistent offline write queue tracking pending, syncing, conflicted, and
/// failed mutations per teacher with FIFO ordering and conflict snapshots.
class LocalSyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get displayLabel => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  IntColumn get expectedVersion => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get serverSnapshotJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
