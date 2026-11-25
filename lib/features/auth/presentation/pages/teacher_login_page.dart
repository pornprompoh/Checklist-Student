import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../providers/sign_in_controller.dart';
import '../widgets/google_sign_in_button.dart';

/// Minimal, teacher-only Google Sign-In page (`/teacher/login`).
///
/// Students access their portal directly via the teacher's shared
/// `/student/:teacherCode` link rather than from this screen.
class TeacherLoginPage extends ConsumerWidget {
  const TeacherLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signInState = ref.watch(signInControllerProvider);
    final isConfigured = EnvConfig.isSupabaseConfigured;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: IconButton(
                  tooltip: isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    minimumSize: const Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => ref
                      .read(themeModeProvider.notifier)
                      .toggleTheme(
                        platformBrightness: Theme.of(context).brightness,
                      ),
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AppSurfaceCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.fact_check_rounded,
                                size: 26,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Checklist-Student',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'เข้าสู่ระบบสำหรับครูผู้สอน',
                            textAlign: TextAlign.center,
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
                            onPressed: () => ref
                                .read(signInControllerProvider.notifier)
                                .signInWithGoogle(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
