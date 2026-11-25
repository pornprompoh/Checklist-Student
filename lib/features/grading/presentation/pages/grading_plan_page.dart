import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_portal_visibility_config.dart';
import '../providers/grading_providers.dart';
import '../providers/plan_editor_controller.dart';
import '../widgets/grading_plan_actions.dart';
import '../widgets/grading_plan_categories_list.dart';
import '../widgets/grading_plan_header.dart';
import '../widgets/grading_scale_editor_card.dart';
import '../widgets/student_portal_visibility_card.dart';

/// Grading plan & scale designer page (`/teacher/grading/plan?classId=...`).
///
/// Protected by [UnsavedChangesGuard] when the grading scale form has unsaved
/// edits, and highlights mid-term over-max scores immediately.
class GradingPlanPage extends ConsumerStatefulWidget {
  const GradingPlanPage({super.key, this.initialClassId});

  final String? initialClassId;

  @override
  ConsumerState<GradingPlanPage> createState() => _GradingPlanPageState();
}

class _GradingPlanPageState extends ConsumerState<GradingPlanPage> {
  final ScrollController _assignmentsScrollController = ScrollController();
  final ScrollController _rulesScrollController = ScrollController();
  String? _selectedClassId;
  bool _hasUnsavedScaleChanges = false;
  String? _conflictMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialClassId?.trim();
    _selectedClassId = (initial == null || initial.isEmpty) ? null : initial;
  }

  @override
  void dispose() {
    _assignmentsScrollController.dispose();
    _rulesScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GradingPlanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextInitial = widget.initialClassId?.trim();
    if (nextInitial != null &&
        nextInitial.isNotEmpty &&
        nextInitial != oldWidget.initialClassId?.trim()) {
      setState(() {
        _selectedClassId = nextInitial;
        _hasUnsavedScaleChanges = false;
        _conflictMessage = null;
      });
    }
  }

  Future<void> _selectClass(String nextClassId) async {
    if (_hasUnsavedScaleChanges) {
      final discard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!discard || !mounted) return;
    }
    setState(() {
      _selectedClassId = nextClassId;
      _hasUnsavedScaleChanges = false;
      _conflictMessage = null;
    });
  }

  Future<void> _openGradingTable(String classId) async {
    if (_hasUnsavedScaleChanges) {
      final discard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!discard || !mounted) return;
    }
    if (!mounted) return;
    context.go(AppRoutes.teacherGradingForClass(classId));
  }

  @override
  Widget build(BuildContext context) {
    final classOptionsAsync = ref.watch(allCopyableClassesProvider);
    final editorState = ref.watch(planEditorControllerProvider);

    ref.listen<AsyncValue<void>>(planEditorControllerProvider, (prev, next) {
      if (next.hasError && prev?.error != next.error) {
        final err = next.error!;
        if (err is ConflictException) {
          setState(() => _conflictMessage = ThaiErrorMapper.map(err));
        } else {
          AppFeedbackBanner.showErrorSnackBar(context, err);
        }
      }
    });

    final options =
        classOptionsAsync.asData?.value ?? const <CopyPlanSourceClassOption>[];
    final effectiveClassId = _resolveEffectiveClassId(options);

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedScaleChanges,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSplitPane =
              constraints.maxWidth >= 900 && constraints.maxHeight >= 520;
          return _buildBody(
            context,
            classOptionsAsync: classOptionsAsync,
            options: options,
            classId: effectiveClassId,
            isBusy: editorState.isLoading,
            isSplitPane: isSplitPane,
          );
        },
      ),
    );
  }

  String? _resolveEffectiveClassId(List<CopyPlanSourceClassOption> options) {
    if (options.isEmpty) return _selectedClassId;
    if (_selectedClassId != null &&
        options.any((opt) => opt.subjectClassId == _selectedClassId)) {
      return _selectedClassId;
    }
    return options.first.subjectClassId;
  }

  Widget _buildBody(
    BuildContext context, {
    required AsyncValue<List<CopyPlanSourceClassOption>> classOptionsAsync,
    required List<CopyPlanSourceClassOption> options,
    required String? classId,
    required bool isBusy,
    required bool isSplitPane,
  }) {
    const fallbackHeader = AppPageHeader(
      title: 'แผนเก็บงานและเกณฑ์ตัดเกรด',
    );
    if (classOptionsAsync.isLoading && options.isEmpty) {
      return const AppPageContainer.scrollable(
        header: fallbackHeader,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(height: 120),
            SizedBox(height: 14),
            SkeletonBox(height: 180),
          ],
        ),
      );
    }
    if (classOptionsAsync.hasError && options.isEmpty) {
      return AppPageContainer.scrollable(
        header: fallbackHeader,
        child: AppFeedbackBanner(
          type: AppFeedbackType.error,
          message: ThaiErrorMapper.map(classOptionsAsync.error!),
          onRetry: () => ref.invalidate(allCopyableClassesProvider),
        ),
      );
    }
    if (classId == null || options.isEmpty) {
      return AppPageContainer.scrollable(
        header: fallbackHeader,
        child: AppEmptyState(
          icon: Icons.assignment_outlined,
          title: 'ยังไม่มีห้องเรียนในระบบ',
          description:
              'สร้างปีการศึกษา เทอม รายวิชา และห้องเรียนก่อนออกแบบแผนเก็บงาน',
          actionLabel: 'ไปหน้าโครงสร้างสอน',
          onAction: () => context.go(AppRoutes.teacherAcademicStructure),
        ),
      );
    }

    final categoriesAsync = ref.watch(scoreCategoriesProvider(classId));
    final assignmentsAsync = ref.watch(assignmentsProvider(classId));
    final scaleAsync = ref.watch(gradingScaleConfigProvider(classId));
    final visibilityAsync = ref.watch(studentPortalVisibilityProvider(classId));
    final overMaxCounts = ref.watch(
      overMaxScoreCountsByAssignmentProvider(classId),
    );
    final categories =
        categoriesAsync.asData?.value ?? const <ScoreCategory>[];
    final assignments = assignmentsAsync.asData?.value ?? const <Assignment>[];

    final planHeader = GradingPlanHeader(
      classOptions: options,
      selectedClassId: classId,
      categories: categories,
      assignments: assignments,
      overMaxCounts: overMaxCounts,
      isBusy: isBusy,
      onSelectClass: _selectClass,
      onAddCategory: () => GradingPlanActions.handleAddOrEditCategory(
        context,
        ref,
        classId: classId,
      ),
      onAddAssignment: () => GradingPlanActions.handleAddOrEditAssignment(
        context,
        ref,
        classId: classId,
        categories: categories,
      ),
      onCopyPlan: () => GradingPlanActions.handleCopyPlan(
        context,
        ref,
        targetClassId: classId,
        targetHasExistingPlan:
            categories.isNotEmpty || assignments.isNotEmpty,
      ),
      onOpenGradingTable: () => _openGradingTable(classId),
    );
    final conflictBanner = _conflictMessage == null
        ? null
        : AppFeedbackBanner(
            type: AppFeedbackType.error,
            message: _conflictMessage!,
            retryLabel: 'โหลดล่าสุด',
            onRetry: () {
              setState(() => _conflictMessage = null);
              ref
                  .read(planEditorControllerProvider.notifier)
                  .refreshClassPlan(classId);
            },
          );
    final planSection = GradingPlanCategoriesList(
      classId: classId,
      categoriesAsync: categoriesAsync,
      assignmentsAsync: assignmentsAsync,
      overMaxCounts: overMaxCounts,
      isBusy: isBusy,
    );
    final scaleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScaleSection(
          context,
          classId: classId,
          scaleAsync: scaleAsync,
          isBusy: isBusy,
        ),
        const SizedBox(height: 16),
        _buildVisibilitySection(
          context,
          classId: classId,
          visibilityAsync: visibilityAsync,
          isBusy: isBusy,
        ),
      ],
    );

    if (isSplitPane) {
      return AppPageContainer.viewport(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            planHeader,
            if (conflictBanner != null) ...[
              const SizedBox(height: 12),
              conflictBanner,
            ],
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: AppSubtleScrollbar(
                      controller: _assignmentsScrollController,
                      child: SingleChildScrollView(
                        controller: _assignmentsScrollController,
                        primary: false,
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: planSection,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: AppSubtleScrollbar(
                      controller: _rulesScrollController,
                      child: SingleChildScrollView(
                        controller: _rulesScrollController,
                        primary: false,
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: scaleSection,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppPageContainer.scrollable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          planHeader,
          if (conflictBanner != null) ...[
            const SizedBox(height: 12),
            conflictBanner,
          ],
          const SizedBox(height: 16),
          planSection,
          const SizedBox(height: 16),
          scaleSection,
        ],
      ),
    );
  }

  Widget _buildScaleSection(
    BuildContext context, {
    required String classId,
    required AsyncValue<GradingScaleConfig> scaleAsync,
    required bool isBusy,
  }) {
    return scaleAsync.when(
      loading: () => const AppSurfaceCard(
        child: Column(
          children: [
            SkeletonBox(height: 40),
            SizedBox(height: 12),
            SkeletonBox(height: 180),
          ],
        ),
      ),
      error: (error, _) => AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(error),
        onRetry: () => ref.invalidate(gradingScaleConfigProvider(classId)),
      ),
      data: (config) => GradingScaleEditorCard(
        initialConfig: config,
        isSaving: isBusy,
        onDirtyChanged: (dirty) {
          if (mounted && _hasUnsavedScaleChanges != dirty) {
            setState(() => _hasUnsavedScaleChanges = dirty);
          }
        },
        onSave: (draft) async {
          final saved = await ref
              .read(planEditorControllerProvider.notifier)
              .saveGradingScaleConfig(draft);
          if (saved != null && context.mounted) {
            AppFeedbackBanner.showSnackBar(
              context,
              type: AppFeedbackType.success,
              message: 'บันทึกเกณฑ์ตัดเกรดและเกณฑ์งานค้างเรียบร้อยแล้ว',
            );
            return true;
          }
          return false;
        },
      ),
    );
  }

  Widget _buildVisibilitySection(
    BuildContext context, {
    required String classId,
    required AsyncValue<StudentPortalVisibilityConfig> visibilityAsync,
    required bool isBusy,
  }) {
    return visibilityAsync.when(
      loading: () => const AppSurfaceCard(child: SkeletonBox(height: 110)),
      error: (error, _) => AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(error),
        onRetry: () => ref.invalidate(studentPortalVisibilityProvider(classId)),
      ),
      data: (config) => StudentPortalVisibilityCard(
        config: config,
        isBusy: isBusy,
        onToggleShowScore: (value) => _updateVisibility(
          context,
          config.copyWith(showScoreToStudent: value),
        ),
        onToggleShowGrade: (value) => _updateVisibility(
          context,
          config.copyWith(showGradeToStudent: value),
        ),
      ),
    );
  }

  Future<void> _updateVisibility(
    BuildContext context,
    StudentPortalVisibilityConfig nextConfig,
  ) async {
    final saved = await ref
        .read(planEditorControllerProvider.notifier)
        .saveStudentPortalVisibility(nextConfig);
    if (saved != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'อัปเดตสิทธิ์การมองเห็นบน Student Portal เรียบร้อยแล้ว',
      );
    }
  }
}
