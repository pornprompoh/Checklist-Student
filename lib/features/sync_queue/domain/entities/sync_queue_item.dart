import 'sync_entity_type.dart';
import 'sync_item_status.dart';
import 'sync_operation_type.dart';

/// Immutable domain entity representing one queued offline write mutation.
///
/// Pure Dart entity (zero Flutter, Drift, or Supabase imports).
class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.teacherId,
    required this.entityType,
    required this.entityId,
    required this.displayLabel,
    required this.operation,
    required this.payload,
    required this.expectedVersion,
    required this.status,
    required this.retryCount,
    required this.nextRetryAt,
    required this.lastError,
    required this.serverSnapshot,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final SyncEntityType entityType;
  final String entityId;
  final String displayLabel;
  final SyncOperationType operation;
  final Map<String, dynamic> payload;
  final int? expectedVersion;
  final SyncItemStatus status;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final Map<String, dynamic>? serverSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const Object _sentinel = Object();

  SyncQueueItem copyWith({
    String? id,
    String? teacherId,
    SyncEntityType? entityType,
    String? entityId,
    String? displayLabel,
    SyncOperationType? operation,
    Map<String, dynamic>? payload,
    Object? expectedVersion = _sentinel,
    SyncItemStatus? status,
    int? retryCount,
    Object? nextRetryAt = _sentinel,
    Object? lastError = _sentinel,
    Object? serverSnapshot = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      displayLabel: displayLabel ?? this.displayLabel,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      expectedVersion: identical(expectedVersion, _sentinel)
          ? this.expectedVersion
          : expectedVersion as int?,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: identical(nextRetryAt, _sentinel)
          ? this.nextRetryAt
          : nextRetryAt as DateTime?,
      lastError: identical(lastError, _sentinel)
          ? this.lastError
          : lastError as String?,
      serverSnapshot: identical(serverSnapshot, _sentinel)
          ? this.serverSnapshot
          : serverSnapshot as Map<String, dynamic>?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
