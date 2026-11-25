import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
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
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: _buildBody(
              context,
              classOptionsAsync: classOptionsAsync,
              options: options,
              classId: effectiveClassId,
              isBusy: editorState.isLoading,
            ),
          ),
        ),
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
  }) {
    if (classOptionsAsync.isLoading && options.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 120),
          SizedBox(height: 14),
          SkeletonBox(height: 180),
        ],
      );
    }
    if (classOptionsAsync.hasError && options.isEmpty) {
      return AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(classOptionsAsync.error!),
        onRetry: () => ref.invalidate(allCopyableClassesProvider),
      );
    }
    if (classId == null || options.isEmpty) {
      return AppFeedbackBanner(
        type: AppFeedbackType.info,
        message:
            'ยังไม่มีห้องเรียนในระบบ กรุณาสร้างปีการศึกษา เทอม รายวิชา และห้องเรียนก่อนออกแบบแผนเก็บงาน',
        retryLabel: 'ไปหน้าโครงสร้างสอน',
        onRetry: () => context.go(AppRoutes.teacherAcademicStructure),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradingPlanHeader(
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
        ),
        if (_conflictMessage != null) ...[
          const SizedBox(height: 12),
          AppFeedbackBanner(
            type: AppFeedbackType.error,
            message: _conflictMessage!,
            retryLabel: 'โหลดข้อมูลล่าสุด',
            onRetry: () {
              setState(() => _conflictMessage = null);
              ref
                  .read(planEditorControllerProvider.notifier)
                  .refreshClassPlan(classId);
            },
          ),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
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
            if (constraints.maxWidth >= 980) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: planSection),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: scaleSection),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                planSection,
                const SizedBox(height: 16),
                scaleSection,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildScaleSection(
    BuildContext context, {
    required String classId,
    required AsyncValue<GradingScaleConfig> scaleAsync,
    required bool isBusy,
  }) {
    return scaleAsync.when(
      loading: () => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonBox(height: 40),
              SizedBox(height: 12),
              SkeletonBox(height: 180),
            ],
          ),
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
      loading: () => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonBox(height: 110),
        ),
      ),
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
