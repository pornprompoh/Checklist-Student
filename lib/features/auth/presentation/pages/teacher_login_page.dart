import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../providers/sign_in_controller.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/login_showcase_panel.dart';

/// Teacher Google Sign-In page (`/teacher/login`).
///
/// Modern EdTech split showcase layout on desktop (`>= 840px`) and clean
/// single-column card on mobile (`320px–839px`) with direct Student Portal link.
class TeacherLoginPage extends ConsumerWidget {
  const TeacherLoginPage({super.key});

  static const double _splitBreakpoint = 840;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signInState = ref.watch(signInControllerProvider);
    final isConfigured = EnvConfig.isSupabaseConfigured;

    ref.listen<AsyncValue<void>>(signInControllerProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(
          context,
          next.error!,
          onRetry: isConfigured
              ? () => ref
                    .read(signInControllerProvider.notifier)
                    .signInWithGoogle()
              : null,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSplit = constraints.maxWidth >= _splitBreakpoint;
            final formPanel = _buildAuthForm(
              context,
              ref,
              signInState: signInState,
              isConfigured: isConfigured,
            );

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSplit ? 28 : 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isSplit ? 920 : 440),
                  child: AppSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: isSplit
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Expanded(
                                  flex: 11,
                                  child: LoginShowcasePanel(),
                                ),
                                Expanded(flex: 10, child: formPanel),
                              ],
                            ),
                          )
                        : formPanel,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthForm(
    BuildContext context,
    WidgetRef ref, {
    required AsyncValue<void> signInState,
    required bool isConfigured,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.fact_check_rounded,
                  size: 22,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Checklist-Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด',
                onPressed: () => ref
                    .read(themeModeProvider.notifier)
                    .toggleTheme(
                      platformBrightness: Theme.of(context).brightness,
                    ),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'เข้าสู่ระบบสำหรับครูผู้สอน',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'จัดการชั้นเรียน เช็คชื่อ แผนเก็บงาน ตัดเกรด และส่งออกรายงาน ปพ.5 ในที่เดียว',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (!isConfigured) ...[
            const AppFeedbackBanner(
              type: AppFeedbackType.warning,
              message:
                  'ยังไม่ได้ตั้งค่า SUPABASE_URL หรือ SUPABASE_ANON_KEY กรุณาส่งค่า Environment ผ่าน --dart-define-from-file=.env ก่อนเข้าสู่ระบบ',
            ),
            const SizedBox(height: 16),
          ],
          if (signInState.hasError) ...[
            AppFeedbackBanner(
              type: AppFeedbackType.error,
              message: ThaiErrorMapper.map(signInState.error!),
              onRetry: isConfigured
                  ? () => ref
                        .read(signInControllerProvider.notifier)
                        .signInWithGoogle()
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          GoogleSignInButton(
            enabled: isConfigured,
            isLoading: signInState.isLoading,
            onPressed: () =>
                ref.read(signInControllerProvider.notifier).signInWithGoogle(),
          ),
          const SizedBox(height: 12),
          Text(
            'ใช้บัญชี Google ของครูเพื่อเข้าถึงข้อมูลชั้นเรียนส่วนตัวแบบแยกบัญชีอย่างปลอดภัย',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: () =>
                GoRouter.maybeOf(context)?.go(AppRoutes.studentPortalRoot),
            icon: const Icon(Icons.person_search_rounded, size: 18),
            label: const Text(
              'คุณเป็นนักเรียนใช่ไหม? เข้าพอร์ทัลนักเรียน',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
