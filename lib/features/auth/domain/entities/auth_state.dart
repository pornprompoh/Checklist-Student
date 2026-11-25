import 'teacher_feature_flags.dart';
import 'teacher_profile.dart';

/// High-level authentication lifecycle status for the teacher application.
enum AuthStatus { loading, authenticated, unauthenticated }

/// Immutable authentication state combining session status, teacher profile,
/// and read-only feature flags.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.userId,
    this.profile,
    this.featureFlags,
    this.errorMessage,
  });

  const AuthSessionState.loading({this.userId})
    : status = AuthStatus.loading,
      profile = null,
      featureFlags = null,
      errorMessage = null;

  const AuthSessionState.unauthenticated({this.errorMessage})
    : status = AuthStatus.unauthenticated,
      userId = null,
      profile = null,
      featureFlags = null;

  const AuthSessionState.authenticated({
    required String this.userId,
    this.profile,
    this.featureFlags,
    this.errorMessage,
  }) : status = AuthStatus.authenticated;

  final AuthStatus status;
  final String? userId;
  final TeacherProfile? profile;
  final TeacherFeatureFlags? featureFlags;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get canUseAi => featureFlags?.canUseAi ?? false;
}
