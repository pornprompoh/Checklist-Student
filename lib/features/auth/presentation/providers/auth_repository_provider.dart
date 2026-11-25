import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provides the [AuthRepository] implementation for the presentation layer.
///
/// When Supabase environment variables are not configured, injects a `null`
/// remote data source so the application degrades gracefully instead of crashing.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = EnvConfig.isSupabaseConfigured
      ? ref.watch(authRemoteDataSourceProvider)
      : null;

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    onClearTeacherLocalData: (teacherId) =>
        ref.read(appDatabaseProvider).clearAllDataForTeacher(teacherId),
  );
});
