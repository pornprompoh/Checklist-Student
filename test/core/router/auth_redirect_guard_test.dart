import 'package:checklist_student/core/constants/app_routes.dart';
import 'package:checklist_student/core/router/auth_redirect_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateAuthRedirect', () {
    test('always allows Student Portal routes regardless of auth state', () {
      expect(
        evaluateAuthRedirect(
          matchedPath: '/student/t-8492',
          isLoading: false,
          isAuthenticated: false,
        ),
        isNull,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: '/student/t-8492',
          isLoading: false,
          isAuthenticated: true,
        ),
        isNull,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: '/student/t-8492',
          isLoading: true,
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('does not redirect while auth state is loading', () {
      expect(
        evaluateAuthRedirect(
          matchedPath: '/',
          isLoading: true,
          isAuthenticated: false,
        ),
        isNull,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherDashboard,
          isLoading: true,
          isAuthenticated: false,
        ),
        isNull,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherLogin,
          isLoading: true,
          isAuthenticated: true,
        ),
        isNull,
      );
    });

    test('redirects root and /teacher based on authentication state', () {
      expect(
        evaluateAuthRedirect(
          matchedPath: '/',
          isLoading: false,
          isAuthenticated: false,
        ),
        AppRoutes.teacherLogin,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: '/',
          isLoading: false,
          isAuthenticated: true,
        ),
        AppRoutes.teacherDashboard,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherRoot,
          isLoading: false,
          isAuthenticated: false,
        ),
        AppRoutes.teacherLogin,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherRoot,
          isLoading: false,
          isAuthenticated: true,
        ),
        AppRoutes.teacherDashboard,
      );
    });

    test('protects teacher routes when unauthenticated and allows when authenticated', () {
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherDashboard,
          isLoading: false,
          isAuthenticated: false,
        ),
        AppRoutes.teacherLogin,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherGrading,
          isLoading: false,
          isAuthenticated: false,
        ),
        AppRoutes.teacherLogin,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherDashboard,
          isLoading: false,
          isAuthenticated: true,
        ),
        isNull,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherSettings,
          isLoading: false,
          isAuthenticated: true,
        ),
        isNull,
      );
    });

    test('redirects /teacher/login to dashboard only when authenticated', () {
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherLogin,
          isLoading: false,
          isAuthenticated: false,
        ),
        isNull,
      );
      expect(
        evaluateAuthRedirect(
          matchedPath: AppRoutes.teacherLogin,
          isLoading: false,
          isAuthenticated: true,
        ),
        AppRoutes.teacherDashboard,
      );
    });
  });
}
