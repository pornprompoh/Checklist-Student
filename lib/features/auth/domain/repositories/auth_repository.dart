import '../entities/teacher_feature_flags.dart';
import '../entities/teacher_profile.dart';

/// Abstract repository contract for teacher authentication, profile lookup,
/// and read-only feature flag retrieval.
///
/// Pure Dart interface following the Repository Pattern.
abstract interface class AuthRepository {
  /// Emits the authenticated teacher's UUID whenever the auth session changes,
  /// or `null` when signed out.
  Stream<String?> watchAuthenticatedUserId();

  /// Returns the currently authenticated teacher's UUID, or `null`.
  String? get currentUserId;

  /// Initiates Google OAuth sign-in flow.
  Future<void> signInWithGoogle();

  /// Signs out the active teacher session.
  Future<void> signOut();

  /// Fetches the teacher's profile row from `public.teachers`.
  Future<TeacherProfile?> fetchTeacherProfile(String userId);

  /// Fetches the teacher's read-only flags from `public.teacher_feature_flags`.
  Future<TeacherFeatureFlags?> fetchTeacherFeatureFlags(String userId);
}
