import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/sync_item_status.dart';

/// Drift local datasource for `local_sync_queue`.
///
/// Every query enforces strict `teacherId` isolation and FIFO (`createdAt ASC`)
/// ordering.
class SyncQueueLocalDataSource {
  const SyncQueueLocalDataSource(this._db);

  final AppDatabase _db;

  static final List<String> _coalesceableStatuses = <String>[
    SyncItemStatus.pending.dbValue,
    SyncItemStatus.failed.dbValue,
  ];

  static final List<String> _attentionStatuses = <String>[
    SyncItemStatus.pending.dbValue,
    SyncItemStatus.syncing.dbValue,
    SyncItemStatus.conflict.dbValue,
    SyncItemStatus.failed.dbValue,
  ];

  Future<List<LocalSyncQueueData>> fetchAll(String teacherId) {
    return (_db.select(_db.localSyncQueue)
          ..where((t) => t.teacherId.equals(teacherId))
          ..orderBy(<OrderingTerm Function($LocalSyncQueueTable)>[
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Stream<List<LocalSyncQueueData>> watchAll(String teacherId) {
    return (_db.select(_db.localSyncQueue)
          ..where((t) => t.teacherId.equals(teacherId))
          ..orderBy(<OrderingTerm Function($LocalSyncQueueTable)>[
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Stream<int> watchAttentionCount(String teacherId) {
    final countExp = _db.localSyncQueue.id.count();
    final query = _db.selectOnly(_db.localSyncQueue)
      ..addColumns(<Expression<Object>>[countExp])
      ..where(
        _db.localSyncQueue.teacherId.equals(teacherId) &
            _db.localSyncQueue.status.isIn(_attentionStatuses),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<LocalSyncQueueData?> findById({
    required String teacherId,
    required String itemId,
  }) {
    return (_db.select(_db.localSyncQueue)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.id.equals(itemId),
          ))
        .getSingleOrNull();
  }

  Future<LocalSyncQueueData?> findCoalesceableItem({
    required String teacherId,
    required String entityType,
    required String entityId,
  }) {
    return (_db.select(_db.localSyncQueue)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.entityType.equals(entityType) &
                t.entityId.equals(entityId) &
                t.status.isIn(_coalesceableStatuses),
          )
          ..orderBy(<OrderingTerm Function($LocalSyncQueueTable)>[
            (t) => OrderingTerm.asc(t.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> insertItem(LocalSyncQueueCompanion companion) async {
    await _db.into(_db.localSyncQueue).insert(companion);
  }

  Future<void> updateItem({
    required String teacherId,
    required String itemId,
    required LocalSyncQueueCompanion companion,
  }) async {
    await (_db.update(_db.localSyncQueue)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.id.equals(itemId),
          ))
        .write(companion);
  }

  Future<void> deleteItem({
    required String teacherId,
    required String itemId,
  }) async {
    await (_db.delete(_db.localSyncQueue)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.id.equals(itemId),
          ))
        .go();
  }

  Future<void> deleteAllForTeacher(String teacherId) async {
    await (_db.delete(
      _db.localSyncQueue,
    )..where((t) => t.teacherId.equals(teacherId))).go();
  }
}
