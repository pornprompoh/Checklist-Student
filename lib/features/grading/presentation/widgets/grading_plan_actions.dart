import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/typed_confirm_dialog.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/score_category.dart';
import '../providers/plan_editor_controller.dart';
import 'assignment_form_dialog.dart';
import 'copy_plan_dialog.dart';
import 'over_max_score_warning_dialog.dart';
import 'score_category_form_dialog.dart';

/// UI action workflows for `GradingPlanPage`, including mid-term safety guards
/// (scored-student check + [TypedConfirmDialog] on delete, and
/// [OverMaxScoreWarningDialog] when lowering `maxScore`).
abstract final class GradingPlanActions {
  static Future<void> handleAddOrEditCategory(
    BuildContext context,
    WidgetRef ref, {
    required String classId,
    ScoreCategory? existing,
  }) async {
    final result = await ScoreCategoryFormDialog.show(
      context,
      existing: existing,
    );
    if (result == null || !context.mounted) return;

    final controller = ref.read(planEditorControllerProvider.notifier);
    final saved = existing == null
        ? await controller.createCategory(
            subjectClassId: classId,
            name: result.name,
            targetMaxScore: result.targetMaxScore,
            sortOrder: result.sortOrder,
          )
        : await controller.updateCategory(
            subjectClassId: classId,
            categoryId: existing.id,
            name: result.name,
            targetMaxScore: result.targetMaxScore,
            sortOrder: result.sortOrder,
          );
    if (saved != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: existing == null
            ? 'เพิ่มหมวดคะแนน "${saved.name}" เรียบร้อยแล้ว'
            : 'บันทึกการแก้ไขหมวดคะแนน "${saved.name}" แล้ว',
      );
    }
  }

  static Future<void> handleDeleteCategory(
    BuildContext context,
    WidgetRef ref, {
    required String classId,
    required ScoreCategory category,
    required int assignmentCount,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบหมวดคะแนน'),
        content: Text(
          assignmentCount > 0
              ? 'ต้องการลบหมวด "${category.name}" หรือไม่? '
                    'ชิ้นงานในหมวดนี้ $assignmentCount ชิ้นจะไม่ถูกลบ แต่จะย้ายไปยังกลุ่ม "ไม่ระบุหมวด"'
              : 'ต้องการลบหมวดคะแนน "${category.name}" หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ลบหมวดคะแนน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(planEditorControllerProvider.notifier)
        .deleteCategory(subjectClassId: classId, categoryId: category.id);
    if (deleted && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'ลบหมวดคะแนน "${category.name}" เรียบร้อยแล้ว',
      );
    }
  }

  static Future<void> handleAddOrEditAssignment(
    BuildContext context,
    WidgetRef ref, {
    required String classId,
    required List<ScoreCategory> categories,
    Assignment? existing,
    String? initialCategoryId,
  }) async {
    final result = await AssignmentFormDialog.show(
      context,
      categories: categories,
      existing: existing,
      initialCategoryId: initialCategoryId,
    );
    if (result == null || !context.mounted) return;

    final controller = ref.read(planEditorControllerProvider.notifier);
    if (existing != null &&
        (result.maxScore * 100).round() < (existing.maxScore * 100).round()) {
      final affected = await controller.findOverMaxScoresForNewMax(
        subjectClassId: classId,
        assignmentId: existing.id,
        newMaxScore: result.maxScore,
      );
      if (affected.isNotEmpty && context.mounted) {
        final confirmed = await OverMaxScoreWarningDialog.show(
          context,
          assignmentTitle: result.title,
          newMaxScore: result.maxScore,
          affectedStudents: affected,
        );
        if (!confirmed || !context.mounted) return;
      }
    }

    final saved = existing == null
        ? await controller.createAssignment(
            subjectClassId: classId,
            categoryId: result.categoryId,
            title: result.title,
            description: result.description,
            maxScore: result.maxScore,
            isMandatory: result.isMandatory,
            dueDate: result.dueDate,
          )
        : await controller.updateAssignment(
            subjectClassId: classId,
            assignmentId: existing.id,
            expectedVersion: existing.version,
            categoryId: result.categoryId,
            title: result.title,
            description: result.description,
            maxScore: result.maxScore,
            isMandatory: result.isMandatory,
            dueDate: result.dueDate,
          );
    if (saved != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: existing == null
            ? 'เพิ่มชิ้นงาน "${saved.title}" เรียบร้อยแล้ว'
            : 'บันทึกการแก้ไขชิ้นงาน "${saved.title}" แล้ว',
      );
    }
  }

  /// Checks scored student count before deleting [assignment].
  /// Uses [TypedConfirmDialog] when `scoredCount > 0`, else a normal dialog.
  static Future<bool> confirmAssignmentDeletion(
    BuildContext context, {
    required Assignment assignment,
    required int scoredCount,
  }) async {
    if (scoredCount > 0) {
      return TypedConfirmDialog.show(
        context,
        title: 'ยืนยันการลบชิ้นงานที่มีคะแนนแล้ว',
        description:
            'มีนักเรียนที่มีคะแนนในงานนี้แล้ว $scoredCount คน — '
            'หากลบชิ้นงานนี้ คะแนนและประวัติการแก้ไขของงานนี้จะถูกลบถาวร',
        expectedText: assignment.title,
        impactSummary: <DeleteImpactItem>[
          DeleteImpactItem(
            label: 'นักเรียนที่มีคะแนนในงานนี้แล้ว',
            count: scoredCount,
          ),
        ],
        confirmLabel: 'ลบชิ้นงานและคะแนนถาวร',
      );
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบชิ้นงาน'),
        content: Text('ต้องการลบชิ้นงาน "${assignment.title}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ลบชิ้นงาน'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  static Future<void> handleDeleteAssignment(
    BuildContext context,
    WidgetRef ref, {
    required String classId,
    required Assignment assignment,
  }) async {
    final controller = ref.read(planEditorControllerProvider.notifier);
    final scoredCount = await controller.countScoredStudents(assignment.id);
    if (scoredCount == null || !context.mounted) return;

    final confirmed = await confirmAssignmentDeletion(
      context,
      assignment: assignment,
      scoredCount: scoredCount,
    );
    if (!confirmed || !context.mounted) return;

    final deleted = await controller.deleteAssignment(
      subjectClassId: classId,
      assignmentId: assignment.id,
    );
    if (deleted && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'ลบชิ้นงาน "${assignment.title}" เรียบร้อยแล้ว',
      );
    }
  }

  static Future<void> handleCopyPlan(
    BuildContext context,
    WidgetRef ref, {
    required String targetClassId,
    required bool targetHasExistingPlan,
  }) async {
    final selection = await CopyPlanDialog.show(
      context,
      targetClassId: targetClassId,
      targetHasExistingPlan: targetHasExistingPlan,
    );
    if (selection == null || !context.mounted) return;

    final result = await ref
        .read(planEditorControllerProvider.notifier)
        .copyPlanFromClass(
          sourceClassId: selection.sourceClassId,
          targetClassId: targetClassId,
          replaceExisting: selection.replaceExisting,
        );
    if (result != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message:
            'คัดลอกแผนเรียบร้อยแล้ว (${result.copiedCategoriesCount} หมวดคะแนน, '
            '${result.copiedAssignmentsCount} ชิ้นงาน)',
      );
    }
  }
}
