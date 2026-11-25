import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../models/teacher_feature_flags_dto.dart';
import '../models/teacher_profile_dto.dart';

/// Remote data source communicating with Supabase Auth, `public.teachers`,
/// and `public.teacher_feature_flags`.
///
/// Only this file in `features/auth/` is allowed to import `supabase_flutter`.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const int _initialProfileRetryCount = 2;
  static const Duration _retryDelay = Duration(milliseconds: 300);

  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<String?> watchAuthenticatedUserId() {
    return _client.auth.onAuthStateChange.map((event) => event.session?.user.id);
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? '${Uri.base.origin}${AppRoutes.teacherDashboard}'
            : null,
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<TeacherProfileDto?> fetchTeacherProfile(String userId) async {
    try {
      for (var attempt = 0; attempt <= _initialProfileRetryCount; attempt++) {
        final data = await _client
            .from('teachers')
            .select(
              'id, email, display_name, school_name, department, teacher_code, '
              'default_absent_threshold_pct, default_missing_work_threshold, '
              'created_at, updated_at',
            )
            .eq('id', userId)
            .maybeSingle();

        if (data != null) {
          return TeacherProfileDto.fromJson(data);
        }
        if (attempt < _initialProfileRetryCount) {
          await Future<void>.delayed(_retryDelay);
        }
      }
      return null;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<TeacherFeatureFlagsDto?> fetchTeacherFeatureFlags(
    String userId,
  ) async {
    try {
      for (var attempt = 0; attempt <= _initialProfileRetryCount; attempt++) {
        final data = await _client
            .from('teacher_feature_flags')
            .select('teacher_id, can_use_ai, updated_at')
            .eq('teacher_id', userId)
            .maybeSingle();

        if (data != null) {
          return TeacherFeatureFlagsDto.fromJson(data);
        }
        if (attempt < _initialProfileRetryCount) {
          await Future<void>.delayed(_retryDelay);
        }
      }
      return null;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRemoteDataSource(client);
});
