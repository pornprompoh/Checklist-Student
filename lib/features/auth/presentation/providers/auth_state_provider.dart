import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/teacher_feature_flags.dart';
import '../../domain/entities/teacher_profile.dart';
import 'auth_repository_provider.dart';

/// Reactive authentication state controller that synchronizes Supabase auth
/// sessions with `public.teachers` and `public.teacher_feature_flags`.
class AuthStateNotifier extends Notifier<AuthSessionState> {
  int _loadGeneration = 0;

  @override
  AuthSessionState build() {
    final repository = ref.watch(authRepositoryProvider);

    final subscription = repository.watchAuthenticatedUserId().listen(
      _handleAuthUserChanged,
    );
    ref.onDispose(subscription.cancel);

    final initialUserId = repository.currentUserId;
    if (initialUserId == null) {
      return const AuthSessionState.unauthenticated();
    }

    Future<void>.microtask(() => _loadTeacherSession(initialUserId));
    return AuthSessionState.loading(userId: initialUserId);
  }

  /// Refreshes the active teacher's profile and feature flags from the server.
  Future<void> refreshProfile() async {
    final userId = state.userId ?? ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) {
      state = const AuthSessionState.unauthenticated();
      return;
    }
    await _loadTeacherSession(userId, preserveAuthenticatedStatus: true);
  }

  void _handleAuthUserChanged(String? userId) {
    if (!ref.mounted) {
      return;
    }

    if (userId == null) {
      _loadGeneration++;
      state = const AuthSessionState.unauthenticated();
      return;
    }

    if (state.isAuthenticated &&
        state.userId == userId &&
        state.profile != null) {
      return;
    }

    state = AuthSessionState.loading(userId: userId);
    unawaited(_loadTeacherSession(userId));
  }

  Future<void> _loadTeacherSession(
    String userId, {
    bool preserveAuthenticatedStatus = false,
  }) async {
    final generation = ++_loadGeneration;
    final repository = ref.read(authRepositoryProvider);

    try {
      final profileFuture = repository.fetchTeacherProfile(userId);
      final flagsFuture = repository.fetchTeacherFeatureFlags(userId);

      final TeacherProfile? profile = await profileFuture;
      final TeacherFeatureFlags? flags = await flagsFuture;

      if (!ref.mounted || _loadGeneration != generation) {
        return;
      }

      state = AuthSessionState.authenticated(
        userId: userId,
        profile: profile,
        featureFlags: flags,
      );
    } catch (error) {
      if (!ref.mounted || _loadGeneration != generation) {
        return;
      }

      state = AuthSessionState.authenticated(
        userId: userId,
        profile: preserveAuthenticatedStatus ? state.profile : null,
        featureFlags: preserveAuthenticatedStatus ? state.featureFlags : null,
        errorMessage: ThaiErrorMapper.map(error),
      );
    }
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthSessionState>(
  AuthStateNotifier.new,
);
