import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/import_file_record.dart';
import '../../domain/entities/teacher_code_history_entry.dart';
import '../../domain/repositories/settings_repository.dart';

/// Provides [SettingsRepository] backed by Supabase when configured.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final remoteDataSource = EnvConfig.isSupabaseConfigured
      ? ref.watch(settingsRemoteDataSourceProvider)
      : null;
  return SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Loads the authenticated teacher's historical short codes newest first.
final teacherCodeHistoryProvider =
    FutureProvider<List<TeacherCodeHistoryEntry>>((ref) async {
      final userId = ref.watch(
        authStateProvider.select((state) => state.userId),
      );
      if (userId == null) {
        return const <TeacherCodeHistoryEntry>[];
      }
      final repository = ref.watch(settingsRepositoryProvider);
      return repository.fetchTeacherCodeHistory(userId);
    });

/// Loads active (`deleted_at IS NULL`) `import_files` for yearly storage cleanup.
final activeImportFilesProvider =
    FutureProvider.autoDispose<List<ImportFileRecord>>((ref) async {
      final userId = ref.watch(
        authStateProvider.select((state) => state.userId),
      );
      if (userId == null) {
        return const <ImportFileRecord>[];
      }
      final repository = ref.watch(settingsRepositoryProvider);
      return repository.fetchActiveImportFiles(userId);
    });
