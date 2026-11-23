import '../constants/app_routes.dart';

/// Pure Dart route redirect evaluator separating Teacher App (`/teacher/...`)
/// and public Student Portal (`/student/:teacherCode`) without redirect loops.
String? evaluateAuthRedirect({
  required String matchedPath,
  required bool isLoading,
  required bool isAuthenticated,
}) {
  // Always permit Student Portal routes regardless of teacher auth state,
  // allowing teachers to preview their own student portal link as well.
  if (matchedPath == '/student' || matchedPath.startsWith('/student/')) {
    return null;
  }

  // Wait until session loading settles before forcing redirects.
  if (isLoading) {
    return null;
  }

  if (matchedPath == '/' || matchedPath == AppRoutes.teacherRoot) {
    return isAuthenticated
        ? AppRoutes.teacherDashboard
        : AppRoutes.teacherLogin;
  }

  if (matchedPath == AppRoutes.teacherLogin) {
    return isAuthenticated ? AppRoutes.teacherDashboard : null;
  }

  if (matchedPath.startsWith('${AppRoutes.teacherRoot}/')) {
    return isAuthenticated ? null : AppRoutes.teacherLogin;
  }

  return null;
}
