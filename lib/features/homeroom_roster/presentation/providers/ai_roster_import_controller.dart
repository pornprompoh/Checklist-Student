import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/uploaded_import_file.dart';
import 'homeroom_roster_providers.dart';

/// Controller orchestrating upload to `import-sources` and AI extraction via
/// the `parse-roster-ai` Edge Function.
class AiRosterImportController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<UploadedImportFileResult?> uploadAndParse({
    required String academicYearId,
    required String homeroomId,
    required String originalFilename,
    required Uint8List compressedBytes,
    required String mimeType,
    required String fileExtension,
  }) async {
    final authState = ref.read(authStateProvider);
    final teacherId = authState.userId;
    if (teacherId == null) {
      state = AsyncError<void>(
        const AuthException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง'),
        StackTrace.current,
      );
      return null;
    }
    if (!authState.canUseAi) {
      state = AsyncError<void>(
        const ValidationException(
          'บัญชีนี้ยังไม่ได้เปิดสิทธิ์ใช้งานฟีเจอร์นำเข้าด้วย AI',
          code: 'AI_FEATURE_DISABLED',
        ),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading<void>();
    try {
      final result = await ref
          .read(homeroomRosterRepositoryProvider)
          .uploadAndParseRosterWithAi(
            teacherId: teacherId,
            academicYearId: academicYearId,
            homeroomId: homeroomId,
            originalFilename: originalFilename,
            compressedBytes: compressedBytes,
            mimeType: mimeType,
            fileExtension: fileExtension,
          );
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

final aiRosterImportControllerProvider =
    AsyncNotifierProvider<AiRosterImportController, void>(
      AiRosterImportController.new,
    );
