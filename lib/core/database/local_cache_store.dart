import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// Multi-tenant JSON key-value cache backed by `AppDatabase.localEntityCaches`.
///
/// Every read/write is strictly scoped by `teacherId` so cached records never
/// leak across accounts on shared school devices.
class LocalCacheStore {
  const LocalCacheStore(this._db);

  final AppDatabase _db;

  Future<void> writeJson({
    required String teacherId,
    required String cacheKey,
    required String entityGroup,
    required Object jsonPayload,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    await _db
        .into(_db.localEntityCaches)
        .insertOnConflictUpdate(
          LocalEntityCachesCompanion.insert(
            cacheKey: cacheKey,
            teacherId: teacherId,
            entityGroup: entityGroup,
            payloadJson: jsonEncode(jsonPayload),
            updatedAt: timestamp,
          ),
        );
  }

  Future<dynamic> readJson({
    required String teacherId,
    required String cacheKey,
  }) async {
    final row = await (_db.select(_db.localEntityCaches)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.cacheKey.equals(cacheKey),
          ))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return jsonDecode(row.payloadJson);
    } on FormatException {
      return null;
    }
  }

  Future<void> deleteByKey({
    required String teacherId,
    required String cacheKey,
  }) async {
    await (_db.delete(_db.localEntityCaches)
          ..where(
            (t) => t.teacherId.equals(teacherId) & t.cacheKey.equals(cacheKey),
          ))
        .go();
  }
}
