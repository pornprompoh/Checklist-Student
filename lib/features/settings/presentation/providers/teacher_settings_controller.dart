import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/teacher_profile_update.dart';
import '../../domain/services/teacher_code_validator_service.dart';
import 'settings_providers.dart';

/// Controller coordinating teacher profile updates and short code changes.
class TeacherSettingsController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> saveProfile(TeacherProfileUpdate update) async {
    final userId = ref.read(authStateProvider).userId;
    if (userId == null) {
      state = AsyncError<void>(
        const AuthException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading<void>();
    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateTeacherProfile(teacherId: userId, update: update);
      await ref.read(authStateProvider.notifier).refreshProfile();
      if (!ref.mounted) {
        return true;
      }
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return false;
      }
      state = AsyncError<void>(
        ThaiErrorMapper.toAppException(error),
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> changeTeacherCode(String rawCode) async {
    final validationError = TeacherCodeValidatorService.validate(rawCode);
    if (validationError != null) {
      state = AsyncError<void>(
        ValidationException(validationError, code: 'INVALID_TEACHER_CODE'),
        StackTrace.current,
      );
      return false;
    }

    final userId = ref.read(authStateProvider).userId;
    if (userId == null) {
      state = AsyncError<void>(
        const AuthException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง'),
        StackTrace.current,
      );
      return false;
    }

    final normalizedCode = TeacherCodeValidatorService.normalize(rawCode);
    state = const AsyncLoading<void>();
    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateTeacherCode(
            teacherId: userId,
            newTeacherCode: normalizedCode,
          );
      await ref.read(authStateProvider.notifier).refreshProfile();
      ref.invalidate(teacherCodeHistoryProvider);
      if (!ref.mounted) {
        return true;
      }
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return false;
      }
      state = AsyncError<void>(
        ThaiErrorMapper.toAppException(error),
        stackTrace,
      );
      return false;
    }
  }
}

final teacherSettingsControllerProvider =
    AsyncNotifierProvider<TeacherSettingsController, void>(
      TeacherSettingsController.new,
    );
