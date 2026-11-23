import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import 'auth_repository_provider.dart';

/// Controller handling user-initiated Google Sign-In and Sign-Out actions.
class SignInController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> signInWithGoogle() async {
    if (state.isLoading) {
      return;
    }

    state = const AsyncLoading<void>();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!ref.mounted) {
        return;
      }
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      state = AsyncError<void>(
        ThaiErrorMapper.toAppException(error),
        stackTrace,
      );
    }
  }

  Future<void> signOut() async {
    if (state.isLoading) {
      return;
    }

    state = const AsyncLoading<void>();
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (!ref.mounted) {
        return;
      }
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      state = AsyncError<void>(
        ThaiErrorMapper.toAppException(error),
        stackTrace,
      );
    }
  }
}

final signInControllerProvider =
    AsyncNotifierProvider<SignInController, void>(SignInController.new);
