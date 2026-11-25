import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/sync_entity_type.dart';
import '../../domain/entities/sync_item_status.dart';
import '../../domain/entities/sync_operation_type.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../domain/services/sync_retry_policy_service.dart';
import '../datasources/sync_queue_local_datasource.dart';
import '../models/sync_queue_item_mapper.dart';

/// Concrete [SyncQueueRepository] backed by Drift [SyncQueueLocalDataSource]
/// and Pure Dart [SyncRetryPolicyService].
class SyncQueueRepositoryImpl implements SyncQueueRepository {
  SyncQueueRepositoryImpl({
    required this.localDataSource,
    this.retryPolicy = const SyncRetryPolicyService(),
    this.mapper = const SyncQueueItemMapper(),
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final SyncQueueLocalDataSource localDataSource;
  final SyncRetryPolicyService retryPolicy;
  final SyncQueueItemMapper mapper;
  final Uuid _uuid;

  @override
  Future<SyncQueueItem?> enqueueMutation({
    required String teacherId,
    required SyncEntityType entityType,
    required String entityId,
    required String displayLabel,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
    int? expectedVersion,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final existingRow = await localDataSource.findCoalesceableItem(
      teacherId: teacherId,
      entityType: entityType.dbValue,
      entityId: entityId,
    );

    if (existingRow != null) {
      final existing = mapper.toEntity(existingRow);
      final coalesced = retryPolicy.coalesce(
        existing: existing,
        incomingOperation: operation,
        incomingPayload: payload,
        incomingExpectedVersion: expectedVersion,
        incomingDisplayLabel: displayLabel,
      );

      if (coalesced.shouldDropFromQueue) {
        await localDataSource.deleteItem(
          teacherId: teacherId,
          itemId: existing.id,
        );
        return null;
      }

      await localDataSource.updateItem(
        teacherId: teacherId,
        itemId: existing.id,
        companion: LocalSyncQueueCompanion(
          displayLabel: Value(coalesced.displayLabel),
          operation: Value(coalesced.operation.dbValue),
          payloadJson: Value(jsonEncode(coalesced.payload)),
          expectedVersion: Value(coalesced.expectedVersion),
          status: Value(SyncItemStatus.pending.dbValue),
          retryCount: const Value(0),
          nextRetryAt: const Value(null),
          lastError: const Value(null),
          updatedAt: Value(timestamp),
        ),
      );

      return existing.copyWith(
        displayLabel: coalesced.displayLabel,
        operation: coalesced.operation,
        payload: coalesced.payload,
        expectedVersion: coalesced.expectedVersion,
        status: SyncItemStatus.pending,
        retryCount: 0,
        nextRetryAt: null,
        lastError: null,
        updatedAt: timestamp,
      );
    }

    final item = SyncQueueItem(
      id: _uuid.v4(),
      teacherId: teacherId,
      entityType: entityType,
      entityId: entityId,
      displayLabel: displayLabel,
      operation: operation,
      payload: Map<String, dynamic>.unmodifiable(payload),
      expectedVersion: operation == SyncOperationType.create
          ? null
          : expectedVersion,
      status: SyncItemStatus.pending,
      retryCount: 0,
      nextRetryAt: null,
      lastError: null,
      serverSnapshot: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await localDataSource.insertItem(mapper.toInsertCompanion(item));
    return item;
  }

  @override
  Future<List<SyncQueueItem>> fetchAllItems(String teacherId) async {
    final rows = await localDataSource.fetchAll(teacherId);
    return rows.map(mapper.toEntity).toList(growable: false);
  }

  @override
  Stream<List<SyncQueueItem>> watchAllItems(String teacherId) {
    return localDataSource
        .watchAll(teacherId)
        .map((rows) => rows.map(mapper.toEntity).toList(growable: false));
  }

  @override
  Stream<int> watchPendingAndConflictCount(String teacherId) {
    return localDataSource.watchAttentionCount(teacherId);
  }

  @override
  Future<List<SyncQueueItem>> fetchReadyPendingItems(
    String teacherId, {
    DateTime? now,
  }) async {
    final items = await fetchAllItems(teacherId);
    return items
        .where((item) => retryPolicy.canRetry(item, now: now))
        .toList(growable: false);
  }

  @override
  Future<void> markSyncing({
    required String teacherId,
    required String itemId,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return localDataSource.updateItem(
      teacherId: teacherId,
      itemId: itemId,
      companion: LocalSyncQueueCompanion(
        status: Value(SyncItemStatus.syncing.dbValue),
        updatedAt: Value(timestamp),
      ),
    );
  }

  @override
  Future<void> markSucceededAndRemove({
    required String teacherId,
    required String itemId,
  }) {
    return localDataSource.deleteItem(teacherId: teacherId, itemId: itemId);
  }

  @override
  Future<void> markConflict({
    required String teacherId,
    required String itemId,
    required String errorMessage,
    Map<String, dynamic>? serverSnapshot,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return localDataSource.updateItem(
      teacherId: teacherId,
      itemId: itemId,
      companion: LocalSyncQueueCompanion(
        status: Value(SyncItemStatus.conflict.dbValue),
        nextRetryAt: const Value(null),
        lastError: Value(errorMessage),
        serverSnapshotJson: Value(
          serverSnapshot == null ? null : jsonEncode(serverSnapshot),
        ),
        updatedAt: Value(timestamp),
      ),
    );
  }

  @override
  Future<void> markFailed({
    required String teacherId,
    required String itemId,
    required String errorMessage,
    DateTime? now,
  }) async {
    final existing = await localDataSource.findById(
      teacherId: teacherId,
      itemId: itemId,
    );
    if (existing == null) return;

    final timestamp = (now ?? DateTime.now()).toUtc();
    final nextRetryCount = existing.retryCount + 1;
    final nextRetryAt = retryPolicy.computeNextRetryAt(
      nextRetryCount,
      now: timestamp,
    );

    await localDataSource.updateItem(
      teacherId: teacherId,
      itemId: itemId,
      companion: LocalSyncQueueCompanion(
        status: Value(SyncItemStatus.failed.dbValue),
        retryCount: Value(nextRetryCount),
        nextRetryAt: Value(nextRetryAt),
        lastError: Value(errorMessage),
        updatedAt: Value(timestamp),
      ),
    );
  }

  @override
  Future<void> resetItemToPending({
    required String teacherId,
    required String itemId,
    int? updatedExpectedVersion,
    Map<String, dynamic>? updatedPayload,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return localDataSource.updateItem(
      teacherId: teacherId,
      itemId: itemId,
      companion: LocalSyncQueueCompanion(
        status: Value(SyncItemStatus.pending.dbValue),
        retryCount: const Value(0),
        nextRetryAt: const Value(null),
        lastError: const Value(null),
        serverSnapshotJson: const Value(null),
        expectedVersion: updatedExpectedVersion == null
            ? const Value.absent()
            : Value(updatedExpectedVersion),
        payloadJson: updatedPayload == null
            ? const Value.absent()
            : Value(jsonEncode(updatedPayload)),
        updatedAt: Value(timestamp),
      ),
    );
  }

  @override
  Future<void> removeItem({required String teacherId, required String itemId}) {
    return localDataSource.deleteItem(teacherId: teacherId, itemId: itemId);
  }

  @override
  Future<void> clearForTeacher(String teacherId) {
    return localDataSource.deleteAllForTeacher(teacherId);
  }
}
