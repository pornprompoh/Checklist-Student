import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/env_config.dart';
import 'core/network/connectivity_provider.dart';
import 'core/theme/app_color_scheme.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

final _bootstrapRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _BootstrapScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Root application widget configured with [AppTheme], [themeModeProvider],
/// and a temporary bootstrap [GoRouter] until `core/router/` is added.
class ChecklistStudentApp extends ConsumerWidget {
  const ChecklistStudentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_bootstrapRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Checklist-Student',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class _BootstrapScreen extends ConsumerWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semanticColors = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isConfigured = EnvConfig.isSupabaseConfigured;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Checklist-Student',
                              style: textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: isDark
                                ? 'สลับเป็นโหมดสว่าง'
                                : 'สลับเป็นโหมดมืด',
                            onPressed: () => ref
                                .read(themeModeProvider.notifier)
                                .toggleTheme(
                                  platformBrightness: Theme.of(
                                    context,
                                  ).brightness,
                                ),
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ระบบจัดการชั้นเรียน เช็กชื่อ และให้คะแนน',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 32),
                      _StatusRow(
                        icon: isConfigured
                            ? Icons.verified_outlined
                            : Icons.warning_amber_rounded,
                        iconColor: isConfigured
                            ? semanticColors.success
                            : semanticColors.warning,
                        title: 'สถานะการตั้งค่า Supabase',
                        subtitle: isConfigured
                            ? 'พร้อมใช้งาน (ตรวจพบการตั้งค่า Environment แล้ว)'
                            : 'ยังไม่ได้ตั้งค่า SUPABASE_URL หรือ SUPABASE_ANON_KEY กรุณาส่งค่าผ่าน --dart-define-from-file=.env',
                      ),
                      const SizedBox(height: 16),
                      connectivityAsync.when(
                        data: (isOnline) => _StatusRow(
                          icon: isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          iconColor: isOnline
                              ? semanticColors.success
                              : semanticColors.danger,
                          title: 'สถานะการเชื่อมต่อเครือข่าย',
                          subtitle: isOnline
                              ? 'ออนไลน์ (เชื่อมต่อเครือข่ายแล้ว)'
                              : 'ออฟไลน์ (ไม่พบการเชื่อมต่อเครือข่าย)',
                        ),
                        loading: () => _StatusRow(
                          icon: Icons.sync_rounded,
                          iconColor: colorScheme.secondary,
                          title: 'สถานะการเชื่อมต่อเครือข่าย',
                          subtitle: 'กำลังตรวจสอบการเชื่อมต่อเครือข่าย...',
                        ),
                        error: (error, stackTrace) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatusRow(
                              icon: Icons.error_outline_rounded,
                              iconColor: colorScheme.error,
                              title: 'สถานะการเชื่อมต่อเครือข่าย',
                              subtitle: 'ไม่สามารถตรวจสอบสถานะเครือข่ายได้ในขณะนี้',
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  ref.invalidate(connectivityStatusProvider),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('ลองตรวจสอบอีกครั้ง'),
                            ),
                          ],
                        ),
                      ),
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
