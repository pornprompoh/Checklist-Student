import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/roster_import_result.dart';
import '../../domain/entities/roster_import_row_preview.dart';
import 'homeroom_roster_providers.dart';

/// Controller handling Excel/CSV bulk student import commits into
/// `public.homeroom_students` and invalidating affected providers.
class RosterImportController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<RosterImportResult?> commitImport({
    required String homeroomId,
    required List<RosterImportRowPreview> rows,
    required bool syncOverwrittenToLinkedClasses,
    required List<String> linkedClassIds,
    bool autoEnrollNewToLinkedClasses = false,
    DateTime? enrolledAt,
  }) async {
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
      final result = await ref
          .read(homeroomRosterRepositoryProvider)
          .importHomeroomStudents(
            teacherId: teacherId,
            homeroomId: homeroomId,
            rows: rows,
            syncOverwrittenToLinkedClasses: syncOverwrittenToLinkedClasses,
            autoEnrollNewToLinkedClasses: autoEnrollNewToLinkedClasses,
            enrolledAt: enrolledAt,
          );
      ref.invalidate(homeroomStudentsProvider(homeroomId));
      if (syncOverwrittenToLinkedClasses || autoEnrollNewToLinkedClasses) {
        for (final classId in linkedClassIds) {
          ref.invalidate(classEnrollmentsProvider(classId));
        }
      }
      if (ref.mounted) {
        state = const AsyncData<void>(null);
      }
      return result;
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

final rosterImportControllerProvider =
    AsyncNotifierProvider<RosterImportController, void>(
      RosterImportController.new,
    );
