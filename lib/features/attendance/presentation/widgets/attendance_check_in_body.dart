import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/attendance_status.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_container.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../providers/attendance_check_in_controller.dart';
import '../providers/attendance_providers.dart';
import 'attendance_check_in_dialogs.dart';
import 'attendance_save_bar.dart';
import 'attendance_session_header.dart';
import 'attendance_status_summary_bar.dart';
import 'attendance_student_row.dart';
import 'transferred_out_attendance_section.dart';

/// Interactive body of the daily check-in screen guarded by [UnsavedChangesGuard].
///
/// Decluttered to 2 slim pinned rows on Desktop (`width >= 900 && height >= 520`)
/// — Header + Underline Tabs, then Flat Class/Date + Inline Counters + single
/// contextual CTA — scrolling only the student list independently. Hides the
/// bottom save bar whenever the session is locked to maximize list space.
class AttendanceCheckInBody extends ConsumerStatefulWidget {
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
  ConsumerState<AttendanceCheckInBody> createState() =>
      _AttendanceCheckInBodyState();
}

class _AttendanceCheckInBodyState extends ConsumerState<AttendanceCheckInBody> {
  final ScrollController _studentListController = ScrollController();

  @override
  void dispose() {
    _studentListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectClassId = widget.subjectClassId;
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

    final isReadyWithStudents =
        !enrollmentsAsync.isLoading &&
        !state.isLoading &&
        !enrollmentsAsync.hasError &&
        enrollments.isNotEmpty;

    final inlineSummary = isReadyWithStudents
        ? AttendanceStatusSummaryBar(
            presentCount: counts.present,
            lateCount: counts.late,
            leaveCount: counts.leave,
            absentCount: counts.absent,
            unmarkedCount: counts.unmarked,
            isLocked: state.isLocked,
            isBusy: state.isSaving,
            canMarkAllPresent: eligibleIds.isNotEmpty,
            onMarkAllPresent: () => controller.markAllPresent(eligibleIds),
            onUnlockSession: () =>
                AttendanceCheckInDialogs.confirmUnlock(context, controller),
          )
        : null;

    final sessionHeader = AttendanceSessionHeader(
      classOptions: widget.classOptions,
      selectedClassId: subjectClassId,
      selectedDate: state.selectedDate,
      hasSavedSession: state.hasSavedSession,
      isLocked: state.isLocked,
      isBusy: state.isLoading || state.isSaving,
      sessionNote: state.sessionNote,
      inlineStatusTrailing: inlineSummary,
      onSelectClass: (id) => AttendanceCheckInDialogs.guardAndRun(
        context,
        state,
        () => widget.onSwitchClass(id),
      ),
      onPreviousDay: () => AttendanceCheckInDialogs.guardAndRun(
        context,
        state,
        () => controller.loadDate(
          state.selectedDate.subtract(const Duration(days: 1)),
        ),
      ),
      onPickDate: () =>
          AttendanceCheckInDialogs.pickDate(context, state, controller),
      onNextDay: () => AttendanceCheckInDialogs.guardAndRun(
        context,
        state,
        () => controller.loadDate(
          state.selectedDate.add(const Duration(days: 1)),
        ),
      ),
      onOpenHistory: () => AttendanceCheckInDialogs.openHistory(
        context,
        ref,
        subjectClassId: subjectClassId,
        state: state,
        controller: controller,
      ),
      onOpenRules: () => AttendanceCheckInDialogs.guardAndRun(
        context,
        state,
        () => context.go(
          AppRoutes.teacherAttendanceRulesForClass(subjectClassId),
        ),
      ),
      onEditSessionNote: isReadyWithStudents
          ? () => AttendanceCheckInDialogs.editSessionNote(
              context,
              state,
              controller,
            )
          : null,
    );

    final errorBanner = state.errorMessage == null
        ? null
        : AppFeedbackBanner(
            type: AppFeedbackType.error,
            message: state.errorMessage!,
            retryLabel: state.isConflictError ? 'โหลดข้อมูลล่าสุด' : 'ลองใหม่',
            onRetry: controller.reloadCurrentDate,
          );

    final studentListSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeStudents.isNotEmpty)
          AppSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < activeStudents.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  AttendanceStudentRow(
                    embedded: true,
                    enrollment: activeStudents[i],
                    selectedDate: state.selectedDate,
                    selectedStatus: state.draftStatuses[activeStudents[i].id],
                    note: state.draftNotes[activeStudents[i].id] ?? '',
                    summary: summaries[activeStudents[i].id],
                    isLocked: state.isLocked,
                    onStatusSelected: (status) =>
                        controller.setStudentStatus(activeStudents[i].id, status),
                    onEditNote: () => AttendanceCheckInDialogs.editStudentNote(
                      context,
                      activeStudents[i],
                      state,
                      controller,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (transferredWithHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          TransferredOutAttendanceSection(
            students: transferredWithHistory,
            recordsByEnrollment: state.existingRecordsByEnrollment,
          ),
        ],
      ],
    );

    return UnsavedChangesGuard(
      hasUnsavedChanges: state.isDirty,
      child: LayoutBuilder(
        builder: (context, outerConstraints) {
          final isPinnedLayout =
              outerConstraints.maxWidth >= 900 &&
              outerConstraints.maxHeight >= 520 &&
              isReadyWithStudents;

          return Column(
            children: [
              Expanded(
                child: isPinnedLayout
                    ? AppPageContainer.viewport(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            sessionHeader,
                            if (errorBanner != null) ...[
                              const SizedBox(height: 12),
                              errorBanner,
                            ],
                            const SizedBox(height: 12),
                            Expanded(
                              child: AppSubtleScrollbar(
                                controller: _studentListController,
                                child: SingleChildScrollView(
                                  controller: _studentListController,
                                  primary: false,
                                  padding: const EdgeInsets.only(
                                    right: 6,
                                    bottom: 8,
                                  ),
                                  child: studentListSection,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : AppPageContainer.scrollable(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            sessionHeader,
                            if (errorBanner != null) ...[
                              const SizedBox(height: 12),
                              errorBanner,
                            ],
                            const SizedBox(height: 12),
                            if (enrollmentsAsync.isLoading || state.isLoading)
                              const Column(
                                children: [
                                  SkeletonBox(height: 68),
                                  SizedBox(height: 12),
                                  SkeletonBox(height: 80),
                                  SizedBox(height: 12),
                                  SkeletonBox(height: 80),
                                ],
                              )
                            else if (enrollmentsAsync.hasError)
                              AppFeedbackBanner(
                                type: AppFeedbackType.error,
                                message: ThaiErrorMapper.map(
                                  enrollmentsAsync.error!,
                                ),
                                onRetry: () => ref.invalidate(
                                  classEnrollmentsProvider(subjectClassId),
                                ),
                              )
                            else if (enrollments.isEmpty)
                              AppEmptyState(
                                icon: Icons.groups_outlined,
                                title: 'ยังไม่มีรายชื่อนักเรียนในห้องเรียนนี้',
                                description:
                                    'เพิ่มรายชื่อนักเรียนในคลังรายชื่อก่อนเริ่มเช็คชื่อประจำคาบ',
                                actionLabel: 'ไปเพิ่มรายชื่อที่คลังรายชื่อ',
                                onAction: () =>
                                    context.go(AppRoutes.teacherHomeroomRoster),
                              )
                            else
                              studentListSection,
                          ],
                        ),
                      ),
              ),
              if (activeStudents.isNotEmpty && !state.isLocked)
                AttendanceSaveBar(
                  lockAfterSave: widget.lockAfterSave,
                  isLocked: state.isLocked,
                  isSaving: state.isSaving,
                  canSave: hasAnyEligibleDraft,
                  onToggleLockAfterSave: widget.onToggleLockAfterSave,
                  onSave: () async {
                    final ok = await controller.saveAttendance(
                      lockAfterSave: widget.lockAfterSave,
                      eligibleEnrollmentIds: eligibleIdSet,
                    );
                    if (ok && context.mounted) {
                      AppFeedbackBanner.showSnackBar(
                        context,
                        type: AppFeedbackType.success,
                        message: widget.lockAfterSave
                            ? 'บันทึกและล็อกคาบเช็คชื่อเรียบร้อยแล้ว'
                            : 'บันทึกการเช็คชื่อเรียบร้อยแล้ว',
                      );
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
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
