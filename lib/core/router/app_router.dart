import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/academic_structure/presentation/pages/academic_structure_page.dart';
import '../../features/attendance/presentation/pages/attendance_check_in_page.dart';
import '../../features/attendance/presentation/pages/attendance_rule_settings_page.dart';
import '../../features/audit_log/presentation/pages/audit_log_page.dart';
import '../../features/auth/domain/entities/auth_state.dart';
import '../../features/auth/presentation/pages/teacher_login_page.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/dashboard/presentation/pages/teacher_dashboard_page.dart';
import '../../features/export_reports/presentation/pages/export_reports_page.dart';
import '../../features/grading/presentation/pages/grading_plan_page.dart';
import '../../features/grading/presentation/pages/grading_table_page.dart';
import '../../features/homeroom_roster/presentation/pages/homeroom_roster_page.dart';
import '../../features/settings/presentation/pages/teacher_settings_page.dart';
import '../../features/student_portal/presentation/pages/student_portal_entry_page.dart';
import '../../features/sync_queue/presentation/pages/sync_queue_page.dart';
import '../constants/app_routes.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/app_splash_view.dart';
import 'auth_redirect_guard.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Application-wide [GoRouter] configured with [evaluateAuthRedirect] and
/// a responsive [ShellRoute] wrapping authenticated `/teacher/...` routes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref.listen<AuthSessionState>(authStateProvider, (previous, next) {
    if (previous?.status != next.status) {
      refreshNotifier.notify();
    }
  });

  final router = GoRouter(
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      return evaluateAuthRedirect(
        matchedPath: state.uri.path,
        isLoading: authState.isLoading,
        isAuthenticated: authState.isAuthenticated,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppSplashView()),
      GoRoute(
        path: AppRoutes.teacherRoot,
        builder: (context, state) => const AppSplashView(),
      ),
      GoRoute(
        path: AppRoutes.teacherLogin,
        builder: (context, state) => const TeacherLoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.teacherDashboard,
            builder: (context, state) => const TeacherDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.teacherAcademicStructure,
            builder: (context, state) => const AcademicStructurePage(),
          ),
          GoRoute(
            path: AppRoutes.teacherHomeroomRoster,
            builder: (context, state) => const HomeroomRosterPage(),
          ),
          GoRoute(
            path: AppRoutes.teacherAttendance,
            builder: (context, state) => AttendanceCheckInPage(
              initialClassId: state.uri.queryParameters['classId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherAttendanceRules,
            builder: (context, state) => AttendanceRuleSettingsPage(
              subjectClassId: state.uri.queryParameters['classId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherGradingPlan,
            builder: (context, state) => GradingPlanPage(
              initialClassId: state.uri.queryParameters['classId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherGrading,
            builder: (context, state) => GradingTablePage(
              initialClassId: state.uri.queryParameters['classId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherAuditLog,
            builder: (context, state) => AuditLogPage(
              initialClassId: state.uri.queryParameters['classId'],
              initialEnrollmentId: state.uri.queryParameters['enrollmentId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherExportReports,
            builder: (context, state) => ExportReportsPage(
              initialClassId: state.uri.queryParameters['classId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherSyncQueue,
            builder: (context, state) => const SyncQueuePage(),
          ),
          GoRoute(
            path: AppRoutes.teacherSettings,
            builder: (context, state) => const TeacherSettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.studentPortalRoot,
        builder: (context, state) => const StudentPortalEntryPage(),
      ),
      GoRoute(
        path: AppRoutes.studentPortalPattern,
        builder: (context, state) => StudentPortalEntryPage(
          initialTeacherCode: state.pathParameters['teacherCode'],
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});
