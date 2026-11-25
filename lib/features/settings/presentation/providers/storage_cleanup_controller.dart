import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/utils/web_file_downloader.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import 'settings_providers.dart';

/// Controller managing 60-second Signed URL previews and yearly cleanup of
/// `import-sources` files + `public.import_files.deleted_at`.
class StorageCleanupController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> openImportFile(String storagePath) async {
    state = const AsyncLoading<void>();
    try {
      final signedUrl = await ref
          .read(settingsRepositoryProvider)
          .createImportFileSignedUrl(storagePath);
      final opened = openUrlInBrowser(signedUrl);
      if (ref.mounted) {
        state = const AsyncData<void>(null);
      }
      return opened;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(
          ThaiErrorMapper.toAppException(error),
          stackTrace,
        );
      }
      return false;
    }
  }

  Future<int?> cleanupAcademicYear(String academicYearId) async {
    final teacherId = ref.read(authStateProvider).userId;
    if (teacherId == null) {
      state = AsyncError<void>(
        const AuthException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading<void>();
    try {
      final deletedCount = await ref
          .read(settingsRepositoryProvider)
          .cleanupImportFilesByAcademicYear(
            teacherId: teacherId,
            academicYearId: academicYearId,
          );
      ref.invalidate(activeImportFilesProvider);
      if (ref.mounted) {
        state = const AsyncData<void>(null);
      }
      return deletedCount;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(
          ThaiErrorMapper.toAppException(error),
          stackTrace,
        );
      }
      return null;
    }
  }
}

final storageCleanupControllerProvider =
    AsyncNotifierProvider<StorageCleanupController, void>(
      StorageCleanupController.new,
    );
