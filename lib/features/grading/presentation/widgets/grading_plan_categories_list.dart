import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/score_category.dart';
import '../providers/plan_editor_controller.dart';
import 'grading_plan_actions.dart';
import 'score_category_section_card.dart';

/// Vertical list of [ScoreCategorySectionCard] sections (plus uncategorized
/// assignments) rendered inside `GradingPlanPage`.
class GradingPlanCategoriesList extends ConsumerWidget {
  const GradingPlanCategoriesList({
    super.key,
    required this.classId,
    required this.categoriesAsync,
    required this.assignmentsAsync,
    required this.overMaxCounts,
    required this.isBusy,
  });

  final String classId;
  final AsyncValue<List<ScoreCategory>> categoriesAsync;
  final AsyncValue<List<Assignment>> assignmentsAsync;
  final Map<String, int> overMaxCounts;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if ((categoriesAsync.isLoading && !categoriesAsync.hasValue) ||
        (assignmentsAsync.isLoading && !assignmentsAsync.hasValue)) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 120),
          SizedBox(height: 12),
          SkeletonBox(height: 140),
        ],
      );
    }
    if (categoriesAsync.hasError || assignmentsAsync.hasError) {
      return AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(
          categoriesAsync.error ?? assignmentsAsync.error!,
        ),
        onRetry: () => ref
            .read(planEditorControllerProvider.notifier)
            .refreshClassPlan(classId),
      );
    }

    final categories = categoriesAsync.value ?? const <ScoreCategory>[];
    final assignments = assignmentsAsync.value ?? const <Assignment>[];
    final validCatIds = <String>{for (final cat in categories) cat.id};
    final uncategorized = assignments
        .where(
          (item) =>
              item.categoryId == null || !validCatIds.contains(item.categoryId),
        )
        .toList(growable: false);

    if (categories.isEmpty && uncategorized.isEmpty) {
      return const AppFeedbackBanner(
        type: AppFeedbackType.info,
        message:
            'ยังไม่มีหมวดคะแนนและชิ้นงานในห้องนี้ กด "+ เพิ่มหมวดคะแนน", "+ เพิ่มชิ้นงาน" หรือ "คัดลอกแผนและเกณฑ์" จากห้องอื่นได้เลย',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in categories) ...[
          _buildCategoryCard(
            context,
            ref,
            categories: categories,
            category: category,
            items: assignments
                .where((item) => item.categoryId == category.id)
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        if (uncategorized.isNotEmpty)
          _buildCategoryCard(
            context,
            ref,
            categories: categories,
            category: null,
            items: uncategorized,
          ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref, {
    required List<ScoreCategory> categories,
    required ScoreCategory? category,
    required List<Assignment> items,
  }) {
    return ScoreCategorySectionCard(
      category: category,
      assignments: items,
      overMaxCounts: overMaxCounts,
      isBusy: isBusy,
      onAddAssignment: () => GradingPlanActions.handleAddOrEditAssignment(
        context,
        ref,
        classId: classId,
        categories: categories,
        initialCategoryId: category?.id,
      ),
      onEditCategory: category == null
          ? null
          : () => GradingPlanActions.handleAddOrEditCategory(
              context,
              ref,
              classId: classId,
              existing: category,
            ),
      onDeleteCategory: category == null
          ? null
          : () => GradingPlanActions.handleDeleteCategory(
              context,
              ref,
              classId: classId,
              category: category,
              assignmentCount: items.length,
            ),
      onEditAssignment: (item) => GradingPlanActions.handleAddOrEditAssignment(
        context,
        ref,
        classId: classId,
        categories: categories,
        existing: item,
      ),
      onDeleteAssignment: (item) => GradingPlanActions.handleDeleteAssignment(
        context,
        ref,
        classId: classId,
        assignment: item,
      ),
    );
  }
}
