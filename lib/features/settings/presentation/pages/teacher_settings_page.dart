import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/teacher_settings_controller.dart';
import '../widgets/appearance_settings_card.dart';
import '../widgets/storage_cleanup_section_card.dart';
import '../widgets/teacher_code_section_card.dart';
import '../widgets/teacher_profile_form_card.dart';

/// Teacher profile, short-code, and appearance settings page (`/teacher/settings`).
///
/// Wrapped in [UnsavedChangesGuard] to protect unsaved profile and teacher-code edits.
class TeacherSettingsPage extends ConsumerStatefulWidget {
  const TeacherSettingsPage({super.key});

  @override
  ConsumerState<TeacherSettingsPage> createState() =>
      _TeacherSettingsPageState();
}

class _TeacherSettingsPageState extends ConsumerState<TeacherSettingsPage> {
  bool _hasUnsavedProfileChanges = false;
  bool _hasUnsavedCodeChanges = false;

  bool get _hasAnyUnsavedChanges =>
      _hasUnsavedProfileChanges || _hasUnsavedCodeChanges;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authStateProvider);
    final controllerState = ref.watch(teacherSettingsControllerProvider);
    final profile = authState.profile;

    ref.listen<AsyncValue<void>>(teacherSettingsControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasAnyUnsavedChanges,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'โปรไฟล์และการตั้งค่าครู',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'จัดการข้อมูลหัวเอกสาร เกณฑ์ความเสี่ยงเริ่มต้น รหัสครูสำหรับนักเรียน และโหมดสีของแอพ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (authState.errorMessage != null) ...[
                  AppFeedbackBanner(
                    type: AppFeedbackType.error,
                    message: authState.errorMessage!,
                    onRetry: () =>
                        ref.read(authStateProvider.notifier).refreshProfile(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (controllerState.hasError) ...[
                  AppFeedbackBanner(
                    type: AppFeedbackType.error,
                    message: ThaiErrorMapper.map(controllerState.error!),
                  ),
                  const SizedBox(height: 16),
                ],
                if (authState.isLoading) ...[
                  const _SettingsSkeletonView(),
                ] else if (profile == null) ...[
                  AppFeedbackBanner(
                    type: AppFeedbackType.warning,
                    message:
                        'ไม่พบข้อมูลโปรไฟล์ครูในตาราง teachers กรุณาตรวจสอบ Trigger สร้างบัญชีครูหรือสิทธิ์ฐานข้อมูลแล้วกดลองใหม่',
                    onRetry: () =>
                        ref.read(authStateProvider.notifier).refreshProfile(),
                  ),
                ] else ...[
                  TeacherProfileFormCard(
                    profile: profile,
                    isSaving: controllerState.isLoading,
                    onDirtyChanged: (dirty) {
                      if (_hasUnsavedProfileChanges != dirty) {
                        setState(() => _hasUnsavedProfileChanges = dirty);
                      }
                    },
                    onSave: (update) async {
                      final ok = await ref
                          .read(teacherSettingsControllerProvider.notifier)
                          .saveProfile(update);
                      if (ok && context.mounted) {
                        AppFeedbackBanner.showSnackBar(
                          context,
                          type: AppFeedbackType.success,
                          message: 'บันทึกข้อมูลโปรไฟล์เรียบร้อยแล้ว',
                        );
                      }
                      return ok;
                    },
                  ),
                  const SizedBox(height: 16),
                  TeacherCodeSectionCard(
                    currentCode: profile.teacherCode,
                    isSaving: controllerState.isLoading,
                    onDirtyChanged: (dirty) {
                      if (_hasUnsavedCodeChanges != dirty) {
                        setState(() => _hasUnsavedCodeChanges = dirty);
                      }
                    },
                    onChangeCode: (newCode) async {
                      final ok = await ref
                          .read(teacherSettingsControllerProvider.notifier)
                          .changeTeacherCode(newCode);
                      if (ok && context.mounted) {
                        AppFeedbackBanner.showSnackBar(
                          context,
                          type: AppFeedbackType.success,
                          message:
                              'เปลี่ยนรหัสครูเรียบร้อยแล้ว ลิงก์เดิมจะ Redirect อัตโนมัติ',
                        );
                      }
                      return ok;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                StorageCleanupSectionCard(canUseAi: authState.canUseAi),
                const SizedBox(height: 16),
                AppearanceSettingsCard(canUseAi: authState.canUseAi),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSkeletonView extends StatelessWidget {
  const _SettingsSkeletonView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox.line(width: 200, height: 18),
                SizedBox(height: 16),
                SkeletonBox(height: 48),
                SizedBox(height: 12),
                SkeletonBox(height: 48),
                SizedBox(height: 12),
                SkeletonBox(height: 48),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox.line(width: 220, height: 18),
                SizedBox(height: 12),
                SkeletonBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
