import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/typed_confirm_dialog.dart';
import '../../domain/entities/delete_impact_summary.dart';
import '../providers/academic_structure_controller.dart';

/// Maps a [DeleteImpactSummary] into Thai [DeleteImpactItem] rows relevant
/// to the structural hierarchy level being deleted.
List<DeleteImpactItem> buildDeleteImpactItems(DeleteImpactSummary summary) {
  return <DeleteImpactItem>[
    if (summary.entityType == StructuralEntityType.academicYear)
      DeleteImpactItem(label: 'เทอมทั้งหมด', count: summary.termsCount),
    if (summary.entityType == StructuralEntityType.academicYear ||
        summary.entityType == StructuralEntityType.term)
      DeleteImpactItem(label: 'คลังห้องเรียน', count: summary.homeroomsCount),
    if (summary.entityType == StructuralEntityType.academicYear ||
        summary.entityType == StructuralEntityType.term)
      DeleteImpactItem(label: 'รายวิชา', count: summary.subjectsCount),
    if (summary.entityType != StructuralEntityType.subjectClass)
      DeleteImpactItem(
        label: 'ห้องเรียนที่สอน',
        count: summary.subjectClassesCount,
      ),
    DeleteImpactItem(label: 'นักเรียนที่ลงทะเบียน', count: summary.studentsCount),
    DeleteImpactItem(
      label: 'คาบเช็คชื่อที่บันทึกไว้',
      count: summary.attendanceSessionsCount,
    ),
    DeleteImpactItem(label: 'ชิ้นงานทั้งหมด', count: summary.assignmentsCount),
    DeleteImpactItem(
      label: 'ชิ้นงานที่มีคะแนนแล้ว',
      count: summary.scoredAssignmentsCount,
    ),
  ];
}

/// Fetches real cascading delete counts via `get_delete_impact_summary`,
/// prompts with [TypedConfirmDialog], and invokes [onConfirmedDelete] only
/// when the teacher types [expectedText] verbatim.
Future<bool> confirmAndDeleteStructure({
  required BuildContext context,
  required WidgetRef ref,
  required StructuralEntityType entityType,
  required String entityId,
  required String title,
  required String description,
  required String expectedText,
  required Future<bool> Function() onConfirmedDelete,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 16),
          Expanded(child: Text('กำลังตรวจสอบผลกระทบจากการลบ...')),
        ],
      ),
    ),
  );

  DeleteImpactSummary summary;
  try {
    summary = await ref
        .read(academicStructureControllerProvider.notifier)
        .fetchDeleteImpactSummary(entityType: entityType, entityId: entityId);
  } catch (error) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      AppFeedbackBanner.showErrorSnackBar(context, error);
    }
    return false;
  }

  if (!context.mounted) {
    return false;
  }
  Navigator.of(context, rootNavigator: true).pop();

  final confirmed = await TypedConfirmDialog.show(
    context,
    title: title,
    description: description,
    expectedText: expectedText,
    impactSummary: buildDeleteImpactItems(summary),
  );

  if (!confirmed || !context.mounted) {
    return false;
  }

  final deleted = await onConfirmedDelete();
  if (deleted && context.mounted) {
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message: 'ลบเรียบร้อยแล้ว',
    );
  }
  return deleted;
}
