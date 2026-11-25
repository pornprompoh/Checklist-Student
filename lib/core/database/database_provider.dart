import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'local_cache_store.dart';

/// Singleton [AppDatabase] provider managed by Riverpod and closed on dispose.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Shared [LocalCacheStore] wrapping `AppDatabase.localEntityCaches`.
final localCacheStoreProvider = Provider<LocalCacheStore>((ref) {
  return LocalCacheStore(ref.watch(appDatabaseProvider));
});
