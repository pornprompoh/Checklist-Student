import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/auth_state.dart';
import '../../features/auth/presentation/pages/teacher_login_page.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/settings/presentation/pages/teacher_settings_page.dart';
import '../constants/app_routes.dart';
import '../theme/app_color_scheme.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/app_splash_view.dart';
import '../widgets/skeleton_box.dart';
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
            builder: (context, state) => const _TeacherDashboardPlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.teacherAcademicStructure,
            builder: (context, state) => const _ModulePlaceholderView(
              title: 'โครงสร้างปีการศึกษาและรายวิชา',
              subtitle: 'พร้อมพัฒนาต่อใน Phase 2 (ปีการศึกษา → เทอม → วิชา → ห้องสอน)',
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherHomeroomRoster,
            builder: (context, state) => const _ModulePlaceholderView(
              title: 'คลังรายชื่อนักเรียนประจำเทอม',
              subtitle: 'พร้อมพัฒนาต่อใน Phase 2 (นำเข้า CSV / Excel / AI)',
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherExportReports,
            builder: (context, state) => const _ModulePlaceholderView(
              title: 'ส่งออกรายงาน PDF / Excel',
              subtitle: 'พร้อมพัฒนาต่อใน Phase 5 (รายงานเวลาเรียน คะแนน และ ปพ.5)',
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherSyncQueue,
            builder: (context, state) => const _ModulePlaceholderView(
              title: 'สถานะการซิงค์ข้อมูลออฟไลน์',
              subtitle: 'พร้อมพัฒนาต่อใน Phase 6 (Drift Offline-First + Sync Queue)',
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherSettings,
            builder: (context, state) => const TeacherSettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.studentPortalPattern,
        builder: (context, state) => _StudentPortalPlaceholderPage(
          teacherCode: state.pathParameters['teacherCode'] ?? '',
          openExternalBrowser: state.uri.queryParameters['openExternalBrowser'],
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

class _TeacherDashboardPlaceholder extends ConsumerWidget {
  const _TeacherDashboardPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    if (authState.isLoading) {
      return const AppSplashView(message: 'กำลังโหลดข้อมูลบัญชีครู...');
    }
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final profile = authState.profile;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'หน้าหลักครูผู้สอน (Dashboard)',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (profile == null) ...[
                    const SkeletonBox.line(width: 220, height: 18),
                    const SizedBox(height: 8),
                    const SkeletonBox.line(width: 160, height: 14),
                  ] else ...[
                    Text(
                      'ชื่อผู้สอน: ${profile.effectiveDisplayName}',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'รหัสครู (Teacher Code): ${profile.teacherCode}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Chip(
                    backgroundColor: authState.canUseAi
                        ? semantic.successContainer
                        : colorScheme.surfaceContainerHighest,
                    label: Text(
                      authState.canUseAi
                          ? 'สิทธิ์นำเข้าด้วย AI: เปิดใช้งาน'
                          : 'สิทธิ์นำเข้าด้วย AI: ปิดใช้งาน',
                      style: textTheme.labelMedium?.copyWith(
                        color: authState.canUseAi
                            ? semantic.success
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModulePlaceholderView extends StatelessWidget {
  const _ModulePlaceholderView({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction_rounded,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentPortalPlaceholderPage extends StatelessWidget {
  const _StudentPortalPlaceholderPage({
    required this.teacherCode,
    this.openExternalBrowser,
  });

  final String teacherCode;
  final String? openExternalBrowser;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พอร์ทัลตรวจสอบคะแนนนักเรียน',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'รหัสครูผู้สอน: $teacherCode',
                        style: textTheme.bodyMedium,
                      ),
                      if (openExternalBrowser != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'openExternalBrowser: $openExternalBrowser',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
