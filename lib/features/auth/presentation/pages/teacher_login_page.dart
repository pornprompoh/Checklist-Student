import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../providers/sign_in_controller.dart';
import '../widgets/google_sign_in_button.dart';

/// Teacher Google Sign-In page (`/teacher/login`).
///
/// Responsive from 390px mobile screens to desktop, supports Light/Dark modes,
/// and displays user-friendly Thai feedback via [AppFeedbackBanner].
class TeacherLoginPage extends ConsumerWidget {
  const TeacherLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fact_check_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Checklist-Student',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 16),
                      Text(
                        'เข้าสู่ระบบสำหรับครูผู้สอน',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'จัดการชั้นเรียน เช็กชื่อ แผนเก็บงาน ให้คะแนน และส่งออกรายงานในที่เดียว',
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
                      const SizedBox(height: 16),
                      Text(
                        'ใช้บัญชี Google ของครูเพื่อเข้าถึงข้อมูลชั้นเรียนส่วนตัวแบบแยกบัญชี',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
