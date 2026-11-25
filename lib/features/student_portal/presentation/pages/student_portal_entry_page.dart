import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/in_app_browser_detector.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';
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
      GoRouter.maybeOf(
        context,
      )?.go(AppRoutes.studentPortalForTeacher(currentCode));
    });
  }

  @override
  Widget build(BuildContext context) {
    final portalState = ref.watch(studentPortalControllerProvider);
    final controller = ref.read(studentPortalControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final browserInfo = widget.browserInfoOverride ?? detectInAppBrowser();
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    _maybeRedirectToCurrentTeacherCode(portalState);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fact_check_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Student Portal',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'ระบบตรวจสอบผลการเรียนและเวลาเรียน',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด',
              onPressed: () => ref
                  .read(themeModeProvider.notifier)
                  .toggleTheme(platformBrightness: Theme.of(context).brightness),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 16,
              vertical: isWide ? 24 : 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (browserInfo.isInAppBrowser) ...[
                    LineBrowserRedirectBanner(
                      browserInfoOverride: widget.browserInfoOverride,
                    ),
                    const SizedBox(height: 16),
                  ],
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
        return const AppSurfaceCard(
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
          return const AppSurfaceCard(child: SkeletonBox(height: 240));
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
