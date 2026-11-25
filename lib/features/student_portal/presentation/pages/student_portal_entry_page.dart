import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/in_app_browser_detector.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../providers/student_portal_controller.dart';
import '../providers/student_portal_providers.dart';
import '../widgets/line_browser_redirect_banner.dart';
import '../widgets/student_code_lookup_card.dart';
import '../widgets/student_pin_entry_card.dart';
import '../widgets/student_portal_summary_view.dart';
import '../widgets/teacher_code_entry_card.dart';

/// Standalone public Student Portal entry page (`/student` & `/student/:teacherCode`).
///
/// Never wrapped in Teacher `AppShellScaffold` and never requires Google login.
class StudentPortalEntryPage extends ConsumerStatefulWidget {
  const StudentPortalEntryPage({
    super.key,
    this.initialTeacherCode,
    this.browserInfoOverride,
  });

  final String? initialTeacherCode;
  final InAppBrowserInfo? browserInfoOverride;

  @override
  ConsumerState<StudentPortalEntryPage> createState() =>
      _StudentPortalEntryPageState();
}

class _StudentPortalEntryPageState
    extends ConsumerState<StudentPortalEntryPage> {
  final _teacherCodeCtrl = TextEditingController();
  bool _hasRedirectedUrl = false;

  @override
  void initState() {
    super.initState();
    _scheduleInitialize(widget.initialTeacherCode);
  }

  @override
  void didUpdateWidget(covariant StudentPortalEntryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCode = oldWidget.initialTeacherCode?.trim() ?? '';
    final nextCode = widget.initialTeacherCode?.trim() ?? '';
    if (oldCode != nextCode) {
      final currentResolved = ref
          .read(studentPortalControllerProvider)
          .resolvedTeacher
          ?.currentTeacherCode;
      // Avoid resetting the redirect banner when GoRouter completes our own redirect.
      if (currentResolved != null && currentResolved == nextCode) {
        return;
      }
      _hasRedirectedUrl = false;
      _scheduleInitialize(nextCode);
    }
  }

  void _scheduleInitialize(String? teacherCode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(studentPortalControllerProvider.notifier).initialize(teacherCode);
    });
  }

  @override
  void dispose() {
    _teacherCodeCtrl.dispose();
    super.dispose();
  }

  void _maybeRedirectToCurrentTeacherCode(StudentPortalState portalState) {
    if (_hasRedirectedUrl) return;
    final resolved = portalState.resolvedTeacher;
    final currentCode = resolved?.currentTeacherCode;
    if (resolved == null || !resolved.isRedirected || currentCode == null) {
      return;
    }
    _hasRedirectedUrl = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      router?.go(AppRoutes.studentPortalForTeacher(currentCode));
    });
  }

  @override
  Widget build(BuildContext context) {
    final portalState = ref.watch(studentPortalControllerProvider);
    final controller = ref.read(studentPortalControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    _maybeRedirectToCurrentTeacherCode(portalState);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.fact_check_rounded, color: colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Student Portal',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด',
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .toggleTheme(platformBrightness: Theme.of(context).brightness),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LineBrowserRedirectBanner(
                    browserInfoOverride: widget.browserInfoOverride,
                  ),
                  if ((widget.browserInfoOverride ?? detectInAppBrowser())
                      .isInAppBrowser)
                    const SizedBox(height: 14),
                  _buildStepBody(context, portalState, controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(
    BuildContext context,
    StudentPortalState state,
    StudentPortalController controller,
  ) {
    switch (state.step) {
      case StudentPortalStep.resolvingTeacher:
        return const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonBox(height: 28),
                SizedBox(height: 12),
                SkeletonBox(height: 52),
                SizedBox(height: 12),
                SkeletonBox(height: 44),
              ],
            ),
          ),
        );

      case StudentPortalStep.enterTeacherCode:
      case StudentPortalStep.teacherNotFound:
        return TeacherCodeEntryCard(
          controller: _teacherCodeCtrl,
          isBusy: state.isBusy,
          errorMessage: state.errorMessage,
          onSubmit: () => _submitTeacherCode(controller),
        );

      case StudentPortalStep.enterStudentCode:
        final teacher = state.resolvedTeacher;
        if (teacher == null) {
          return TeacherCodeEntryCard(
            controller: _teacherCodeCtrl,
            isBusy: state.isBusy,
            errorMessage: state.errorMessage,
            onSubmit: () => _submitTeacherCode(controller),
          );
        }
        return StudentCodeLookupCard(
          teacher: teacher,
          isBusy: state.isBusy,
          infoMessage: state.infoMessage,
          errorMessage: state.errorMessage,
          onSubmitStudentCode: controller.lookupStudentCode,
        );

      case StudentPortalStep.setupPin:
      case StudentPortalStep.verifyPin:
        return StudentPinEntryCard(
          studentCode: state.studentCode,
          isSetupMode: state.step == StudentPortalStep.setupPin,
          isBusy: state.isBusy,
          remainingAttempts: state.remainingAttempts,
          lockedUntil: state.lockedUntil,
          errorMessage: state.errorMessage,
          onSubmitSetup: (pin, confirmPin) =>
              controller.submitPinSetup(pin: pin, confirmPin: confirmPin),
          onSubmitVerify: controller.submitPinVerify,
          onLockoutExpired: controller.clearExpiredLockout,
          onChangeStudent: controller.changeStudent,
        );

      case StudentPortalStep.authenticated:
        final summary = state.summary;
        if (summary == null) {
          return const SkeletonBox(height: 240);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorMessage != null) ...[
              AppFeedbackBanner(
                type: AppFeedbackType.error,
                message: state.errorMessage!,
                onRetry: controller.refreshSummary,
              ),
              const SizedBox(height: 12),
            ],
            StudentPortalSummaryView(
              summary: summary,
              isBusy: state.isBusy,
              onSelectTerm: controller.selectTerm,
              onRefresh: controller.refreshSummary,
              onSignOut: controller.signOut,
            ),
          ],
        );
    }
  }

  void _submitTeacherCode(StudentPortalController controller) {
    final code = _teacherCodeCtrl.text.trim();
    if (code.isEmpty) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.studentPortalForTeacher(code));
    } else {
      controller.initialize(code);
    }
  }
}
