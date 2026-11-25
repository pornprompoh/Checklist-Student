import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../providers/attendance_check_in_controller.dart';
import '../providers/attendance_check_in_state.dart';
import '../providers/attendance_providers.dart';
import 'attendance_history_sheet.dart';
import 'attendance_note_dialog.dart';

/// Focused dialog/sheet actions for [AttendanceCheckInBody] keeping the main
/// body widget concise (`1 File = 1 Responsibility`).
abstract final class AttendanceCheckInDialogs {
  static Future<void> guardAndRun(
    BuildContext context,
    AttendanceCheckInState state,
    VoidCallback action,
  ) async {
    if (state.isDirty) {
      final discard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!discard || !context.mounted) return;
    }
    action();
  }

  static Future<void> pickDate(
    BuildContext context,
    AttendanceCheckInState state,
    AttendanceCheckInController controller,
  ) async {
    if (state.isDirty) {
      final discard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!discard || !context.mounted) return;
    }
    if (!context.mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2150),
    );
    if (picked != null) {
      await controller.loadDate(picked);
    }
  }

  static Future<void> openHistory(
    BuildContext context,
    WidgetRef ref, {
    required String subjectClassId,
    required AttendanceCheckInState state,
    required AttendanceCheckInController controller,
  }) async {
    final enrollments =
        ref.read(classEnrollmentsProvider(subjectClassId)).asData?.value ??
        const <ClassEnrollment>[];
    final activeIds = enrollments
        .where((e) => !e.isTransferredOut)
        .map((e) => e.id)
        .toSet();
    final sessions =
        ref.read(attendanceSessionsProvider(subjectClassId)).asData?.value ??
        const [];
    final records =
        (ref
                    .read(attendanceClassRecordsProvider(subjectClassId))
                    .asData
                    ?.value ??
                const [])
            .where((r) => activeIds.contains(r.enrollmentId))
            .toList(growable: false);
    await AttendanceHistorySheet.show(
      context,
      sessions: sessions,
      allRecords: records,
      selectedDate: state.selectedDate,
      onSelectDate: (date) =>
          guardAndRun(context, state, () => controller.loadDate(date)),
    );
  }

  static Future<void> editSessionNote(
    BuildContext context,
    AttendanceCheckInState state,
    AttendanceCheckInController controller,
  ) async {
    final note = await AttendanceNoteDialog.show(
      context,
      title: 'หมายเหตุประจำคาบเรียน',
      initialNote: state.sessionNote,
      quickSuggestions: const <String>['สอนชดเชย', 'สอบย่อย', 'กิจกรรมโรงเรียน'],
    );
    if (note != null) controller.setSessionNote(note);
  }

  static Future<void> editStudentNote(
    BuildContext context,
    ClassEnrollment student,
    AttendanceCheckInState state,
    AttendanceCheckInController controller,
  ) async {
    final note = await AttendanceNoteDialog.show(
      context,
      title: 'หมายเหตุการเข้าเรียน',
      subtitle: 'เลขที่ ${student.studentNumber} · ${student.fullName}',
      initialNote: state.draftNotes[student.id] ?? '',
    );
    if (note != null) controller.setStudentNote(student.id, note);
  }

  static Future<void> confirmUnlock(
    BuildContext context,
    AttendanceCheckInController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ปลดล็อกคาบเช็คชื่อเพื่อแก้ไข'),
        content: const Text(
          'คาบนี้ถูกล็อกไว้เพื่อป้องกันการแก้ทับโดยไม่ตั้งใจ ต้องการปลดล็อกเพื่อแก้ไขข้อมูลใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ปลดล็อก'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await controller.unlockSession();
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.info,
        message: 'ปลดล็อกคาบแล้ว สามารถแก้ไขและบันทึกใหม่ได้',
      );
    }
  }
}
