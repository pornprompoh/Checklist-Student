import '../constants/app_routes.dart';

/// Pure Dart route redirect evaluator separating Teacher App (`/teacher/...`)
/// and public Student Portal (`/student/:teacherCode`) without redirect loops.
String? evaluateAuthRedirect({
  required String matchedPath,
  required bool isLoading,
  required bool isAuthenticated,
}) {
  // Normalize in case a raw URI with query parameters is passed in.
  final path = Uri.tryParse(matchedPath)?.path ?? matchedPath;

  // Always permit Student Portal routes regardless of teacher auth or loading
  // state, allowing teachers to preview their own student portal link as well.
  if (path == '/student' || path.startsWith('/student/')) {
    return null;
  }

  // Wait until session loading settles before forcing redirects.
  if (isLoading) {
    return null;
  }

  if (path == '/' || path == AppRoutes.teacherRoot) {
    return isAuthenticated
        ? AppRoutes.teacherDashboard
        : AppRoutes.teacherLogin;
  }

  if (path == AppRoutes.teacherLogin) {
    return isAuthenticated ? AppRoutes.teacherDashboard : null;
  }

  if (path.startsWith('${AppRoutes.teacherRoot}/')) {
    return isAuthenticated ? null : AppRoutes.teacherLogin;
  }

  return null;
}
