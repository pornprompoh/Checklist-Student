import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/sync_entity_type.dart';
import '../../domain/entities/sync_item_status.dart';
import '../../domain/entities/sync_operation_type.dart';
import '../../domain/entities/sync_queue_item.dart';

/// Maps between Drift [LocalSyncQueueData] rows and domain [SyncQueueItem].
class SyncQueueItemMapper {
  const SyncQueueItemMapper();

  SyncQueueItem toEntity(LocalSyncQueueData row) {
    return SyncQueueItem(
      id: row.id,
      teacherId: row.teacherId,
      entityType: SyncEntityType.fromDbValue(row.entityType),
      entityId: row.entityId,
      displayLabel: row.displayLabel,
      operation: SyncOperationType.fromDbValue(row.operation),
      payload: decodeJsonMap(row.payloadJson),
      expectedVersion: row.expectedVersion,
      status: SyncItemStatus.fromDbValue(row.status),
      retryCount: row.retryCount,
      nextRetryAt: row.nextRetryAt?.toUtc(),
      lastError: row.lastError,
      serverSnapshot: row.serverSnapshotJson == null
          ? null
          : decodeJsonMap(row.serverSnapshotJson!),
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }

  LocalSyncQueueCompanion toInsertCompanion(SyncQueueItem item) {
    return LocalSyncQueueCompanion.insert(
      id: item.id,
      teacherId: item.teacherId,
      entityType: item.entityType.dbValue,
      entityId: item.entityId,
      displayLabel: item.displayLabel,
      operation: item.operation.dbValue,
      payloadJson: jsonEncode(item.payload),
      expectedVersion: Value(item.expectedVersion),
      status: Value(item.status.dbValue),
      retryCount: Value(item.retryCount),
      nextRetryAt: Value(item.nextRetryAt),
      lastError: Value(item.lastError),
      serverSnapshotJson: Value(
        item.serverSnapshot == null ? null : jsonEncode(item.serverSnapshot),
      ),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  Map<String, dynamic> decodeJsonMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return Map<String, dynamic>.unmodifiable(decoded);
    }
    if (decoded is Map) {
      return Map<String, dynamic>.unmodifiable(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    throw FormatException('Expected JSON object in sync queue payload: $raw');
  }
}
