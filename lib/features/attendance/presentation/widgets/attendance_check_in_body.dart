import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/attendance_status.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../providers/attendance_check_in_controller.dart';
import '../providers/attendance_check_in_state.dart';
import '../providers/attendance_providers.dart';
import 'attendance_history_sheet.dart';
import 'attendance_note_dialog.dart';
import 'attendance_save_bar.dart';
import 'attendance_session_header.dart';
import 'attendance_status_summary_bar.dart';
import 'attendance_student_row.dart';
import 'transferred_out_attendance_section.dart';

/// Interactive body of the daily check-in screen guarded by [UnsavedChangesGuard].
class AttendanceCheckInBody extends ConsumerWidget {
  const AttendanceCheckInBody({
    super.key,
    required this.subjectClassId,
    required this.classOptions,
    required this.lockAfterSave,
    required this.onToggleLockAfterSave,
    required this.onSwitchClass,
  });

  final String subjectClassId;
  final List<AttendanceClassOption> classOptions;
  final bool lockAfterSave;
  final ValueChanged<bool> onToggleLockAfterSave;
  final ValueChanged<String> onSwitchClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      attendanceCheckInControllerProvider(subjectClassId),
    );
    final controller = ref.read(
      attendanceCheckInControllerProvider(subjectClassId).notifier,
    );
    final enrollmentsAsync = ref.watch(
      classEnrollmentsProvider(subjectClassId),
    );
    final summaries = ref.watch(
      classAttendanceSummariesProvider(subjectClassId),
    );

    final enrollments =
        enrollmentsAsync.asData?.value ?? const <ClassEnrollment>[];
    final statsService = ref.watch(attendanceStatisticsServiceProvider);
    final activeStudents = enrollments
        .where((e) => !e.isTransferredOut)
        .toList(growable: false);
    final transferredWithHistory = enrollments
        .where(
          (e) =>
              e.isTransferredOut &&
              state.existingRecordsByEnrollment.containsKey(e.id),
        )
        .toList(growable: false);

    final eligibleIds = activeStudents
        .where(
          (e) => statsService.isEligibleForDate(
            enrollment: e,
            sessionDate: state.selectedDate,
          ),
        )
        .map((e) => e.id)
        .toList(growable: false);
    final eligibleIdSet = eligibleIds.toSet();
    final counts = _countDrafts(eligibleIds, state.draftStatuses);
    final hasAnyEligibleDraft = state.draftStatuses.keys.any(
      eligibleIdSet.contains,
    );

    return UnsavedChangesGuard(
      hasUnsavedChanges: state.isDirty,
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AttendanceSessionHeader(
                        classOptions: classOptions,
                        selectedClassId: subjectClassId,
                        selectedDate: state.selectedDate,
                        hasSavedSession: state.hasSavedSession,
                        isLocked: state.isLocked,
                        isBusy: state.isLoading || state.isSaving,
                        onSelectClass: (id) =>
                            _guardAndRun(context, state, () => onSwitchClass(id)),
                        onPreviousDay: () => _guardAndRun(
                          context,
                          state,
                          () => controller.loadDate(
                            state.selectedDate.subtract(
                              const Duration(days: 1),
                            ),
                          ),
                        ),
                        onPickDate: () => _pickDate(context, state, controller),
                        onNextDay: () => _guardAndRun(
                          context,
                          state,
                          () => controller.loadDate(
                            state.selectedDate.add(const Duration(days: 1)),
                          ),
                        ),
                        onOpenHistory: () =>
                            _openHistory(context, ref, state, controller),
                        onOpenRules: () => _guardAndRun(
                          context,
                          state,
                          () => context.go(
                            AppRoutes.teacherAttendanceRulesForClass(
                              subjectClassId,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state.isLocked) ...[
                        const AppFeedbackBanner(
                          type: AppFeedbackType.warning,
                          message:
                              'คาบเช็คชื่อนี้ถูกล็อกเพื่อป้องกันมือลั่นแก้ทับ หากต้องการแก้ไขกรุณากด "ปลดล็อกเพื่อแก้ไข"',
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.errorMessage != null) ...[
                        AppFeedbackBanner(
                          type: AppFeedbackType.error,
                          message: state.errorMessage!,
                          retryLabel: state.isConflictError
                              ? 'โหลดข้อมูลล่าสุด'
                              : 'ลองใหม่',
                          onRetry: controller.reloadCurrentDate,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (enrollmentsAsync.isLoading || state.isLoading)
                        const Column(
                          children: [
                            SkeletonBox(height: 76),
                            SizedBox(height: 10),
                            SkeletonBox(height: 88),
                            SizedBox(height: 10),
                            SkeletonBox(height: 88),
                          ],
                        )
                      else if (enrollmentsAsync.hasError)
                        AppFeedbackBanner(
                          type: AppFeedbackType.error,
                          message: ThaiErrorMapper.map(enrollmentsAsync.error!),
                          onRetry: () => ref.invalidate(
                            classEnrollmentsProvider(subjectClassId),
                          ),
                        )
                      else if (enrollments.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text('ยังไม่มีรายชื่อนักเรียนในห้องเรียนนี้'),
                                const SizedBox(height: 12),
                                FilledButton.tonal(
                                  onPressed: () => context.go(
                                    AppRoutes.teacherHomeroomRoster,
                                  ),
                                  child: const Text('ไปเพิ่มรายชื่อที่คลังรายชื่อ'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        AttendanceStatusSummaryBar(
                          presentCount: counts.present,
                          lateCount: counts.late,
                          leaveCount: counts.leave,
                          absentCount: counts.absent,
                          unmarkedCount: counts.unmarked,
                          sessionNote: state.sessionNote,
                          isLocked: state.isLocked,
                          isBusy: state.isSaving,
                          canMarkAllPresent: eligibleIds.isNotEmpty,
                          onMarkAllPresent: () =>
                              controller.markAllPresent(eligibleIds),
                          onEditSessionNote: () =>
                              _editSessionNote(context, state, controller),
                          onUnlockSession: () =>
                              _confirmUnlock(context, controller),
                        ),
                        const SizedBox(height: 12),
                        for (final student in activeStudents) ...[
                          AttendanceStudentRow(
                            enrollment: student,
                            selectedDate: state.selectedDate,
                            selectedStatus: state.draftStatuses[student.id],
                            note: state.draftNotes[student.id] ?? '',
                            summary: summaries[student.id],
                            isLocked: state.isLocked,
                            onStatusSelected: (status) =>
                                controller.setStudentStatus(student.id, status),
                            onEditNote: () => _editStudentNote(
                              context,
                              student,
                              state,
                              controller,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (transferredWithHistory.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          TransferredOutAttendanceSection(
                            students: transferredWithHistory,
                            recordsByEnrollment:
                                state.existingRecordsByEnrollment,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (activeStudents.isNotEmpty)
            AttendanceSaveBar(
              lockAfterSave: lockAfterSave,
              isLocked: state.isLocked,
              isSaving: state.isSaving,
              canSave: hasAnyEligibleDraft,
              onToggleLockAfterSave: onToggleLockAfterSave,
              onSave: () async {
                final ok = await controller.saveAttendance(
                  lockAfterSave: lockAfterSave,
                  eligibleEnrollmentIds: eligibleIdSet,
                );
                if (ok && context.mounted) {
                  AppFeedbackBanner.showSnackBar(
                    context,
                    type: AppFeedbackType.success,
                    message: lockAfterSave
                        ? 'บันทึกและล็อกคาบเช็คชื่อเรียบร้อยแล้ว'
                        : 'บันทึกการเช็คชื่อเรียบร้อยแล้ว',
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _guardAndRun(
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

  Future<void> _pickDate(
    BuildContext context,
    AttendanceCheckInState state,
    AttendanceCheckInController controller,
  ) async {
    if (state.isDirty) {
      final discard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!discard || !context.mounted) return;
    }
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

  Future<void> _openHistory(
    BuildContext context,
    WidgetRef ref,
    AttendanceCheckInState state,
    AttendanceCheckInController controller,
  ) async {
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
          _guardAndRun(context, state, () => controller.loadDate(date)),
    );
  }

  Future<void> _editSessionNote(
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

  Future<void> _editStudentNote(
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

  Future<void> _confirmUnlock(
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

  static ({int present, int late, int leave, int absent, int unmarked})
  _countDrafts(List<String> eligibleIds, Map<String, AttendanceStatus> drafts) {
    var present = 0, late = 0, leave = 0, absent = 0, unmarked = 0;
    for (final id in eligibleIds) {
      switch (drafts[id]) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.late:
          late++;
        case AttendanceStatus.leave:
          leave++;
        case AttendanceStatus.absent:
          absent++;
        case null:
          unmarked++;
      }
    }
    return (
      present: present,
      late: late,
      leave: leave,
      absent: absent,
      unmarked: unmarked,
    );
  }
}
