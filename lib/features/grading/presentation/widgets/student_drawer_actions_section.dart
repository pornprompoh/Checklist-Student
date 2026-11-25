import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/domain/entities/student_lifecycle_status.dart';
import '../../../homeroom_roster/presentation/widgets/sync_scope_choice_dialog.dart';
import '../../domain/entities/student_pin_status.dart';
import '../providers/student_profile_drawer_controller.dart';

/// Student Portal PIN status/reset and Soft Delete transfer status management
/// section displayed at the bottom of `StudentProfileDrawer`.
class StudentDrawerActionsSection extends ConsumerWidget {
  const StudentDrawerActionsSection({
    super.key,
    required this.enrollment,
    required this.isBusy,
  });

  final ClassEnrollment enrollment;
  final bool isBusy;

  Future<void> _confirmAndResetPin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการรีเซต PIN นักเรียน'),
        content: Text(
          'ต้องการล้างรหัส PIN ของ "${enrollment.fullName}" หรือไม่?\n\n'
          'หลังรีเซต นักเรียนจะต้องตั้งรหัส PIN 6 หลักใหม่ในครั้งถัดไปที่เข้าสู่หน้าพอร์ทัลตรวจสอบคะแนน',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ยืนยันรีเซต PIN'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref
        .read(studentProfileDrawerControllerProvider.notifier)
        .resetStudentPin(enrollment.studentIdentityId);
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'รีเซต PIN ของ ${enrollment.fullName} เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _handleTransferToggle(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nextStatus = enrollment.isTransferredOut
        ? StudentLifecycleStatus.active
        : StudentLifecycleStatus.transferredOut;
    final actionLabel = nextStatus == StudentLifecycleStatus.transferredOut
        ? 'บันทึกย้ายออก (Soft Delete)'
        : 'คืนสถานะกำลังเรียน';

    var syncAll = false;
    if (enrollment.isLinkedToHomeroom) {
      final scope = await SyncScopeChoiceDialog.show(
        context,
        studentName: enrollment.fullName,
        actionTitle: actionLabel,
      );
      if (scope == null || !context.mounted) return;
      syncAll = scope == RosterSyncScope.homeroomAndAllClasses;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(actionLabel),
          content: Text(
            nextStatus == StudentLifecycleStatus.transferredOut
                ? 'ต้องการบันทึกย้ายออกสำหรับ "${enrollment.fullName}" หรือไม่? '
                      'ระบบจะคงเลขที่ ${enrollment.studentNumber} และประวัติคะแนนเดิมไว้โดยไม่ลบข้อมูล'
                : 'ต้องการคืนสถานะกำลังเรียนให้ "${enrollment.fullName}" หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final ok = await ref
        .read(studentProfileDrawerControllerProvider.notifier)
        .updateTransferStatus(
          enrollment: enrollment,
          nextStatus: nextStatus,
          syncToHomeroomAndAllClasses: syncAll,
        );
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: nextStatus == StudentLifecycleStatus.transferredOut
            ? 'บันทึกย้ายออกเรียบร้อยแล้ว (คงเลขที่เดิมไว้)'
            : 'คืนสถานะกำลังเรียนเรียบร้อยแล้ว',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinAsync = ref.watch(
      studentPinStatusProvider(enrollment.studentIdentityId),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'รหัส PIN พอร์ทัลนักเรียน',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                pinAsync.when(
                  loading: () => const SkeletonBox(height: 24),
                  error: (error, _) => Text(
                    ThaiErrorMapper.map(error),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  data: (pinStatus) => _buildPinSummary(context, pinStatus),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => _confirmAndResetPin(context, ref),
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: const Text('รีเซต PIN นักเรียน'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'สถานะการเรียนในห้องนี้',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  enrollment.isTransferredOut
                      ? 'นักเรียนย้ายออกแล้ว (คงเลขที่ ${enrollment.studentNumber} และประวัติคะแนนเดิม)'
                      : 'กำลังเรียนปกติ — หากย้ายออกกลางเทอม ระบบจะคงเลขที่เดิมและไม่ลบประวัติคะแนน',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: enrollment.isTransferredOut
                        ? semantic.success
                        : semantic.danger,
                  ),
                  onPressed: isBusy
                      ? null
                      : () => _handleTransferToggle(context, ref),
                  icon: Icon(
                    enrollment.isTransferredOut
                        ? Icons.person_add_alt_1_outlined
                        : Icons.person_off_outlined,
                    size: 18,
                  ),
                  label: Text(
                    enrollment.isTransferredOut
                        ? 'คืนสถานะกำลังเรียน'
                        : 'บันทึกย้ายออก (Soft Delete)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinSummary(BuildContext context, StudentPinStatus status) {
    final semantic = AppSemanticColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (status.isCurrentlyLocked()) {
      final untilText = ThaiDateFormatter.formatDateTime(status.lockedUntil!);
      return Text(
        'ถูกล็อกชั่วคราวถึง $untilText (กรอกผิด ${status.failedAttempts} ครั้ง)',
        style: textTheme.bodySmall?.copyWith(
          color: semantic.danger,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (!status.hasPin) {
      return Text(
        'ยังไม่ตั้ง PIN (นักเรียนตั้ง PIN 6 หลักได้เองในการเข้าพอร์ทัลครั้งแรก)',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    final updatedSuffix = status.pinUpdatedAt == null
        ? ''
        : ' (อัปเดตเมื่อ ${ThaiDateFormatter.formatShortDate(status.pinUpdatedAt!.toLocal())})';
    return Text(
      'ตั้ง PIN แล้ว$updatedSuffix',
      style: textTheme.bodySmall?.copyWith(
        color: semantic.success,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
