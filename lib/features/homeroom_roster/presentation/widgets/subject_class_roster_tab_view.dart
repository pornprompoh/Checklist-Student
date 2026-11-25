import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/typed_confirm_dialog.dart';
import '../../../academic_structure/domain/entities/subject.dart';
import '../../../academic_structure/domain/entities/subject_class.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/entities/student_lifecycle_status.dart';
import '../../domain/services/roster_renumber_service.dart';
import '../providers/homeroom_roster_controller.dart';
import '../providers/homeroom_roster_providers.dart';
import 'renumber_confirm_dialog.dart';
import 'roster_student_list_view.dart';
import 'student_form_dialog.dart';
import 'sync_scope_choice_dialog.dart';

/// Tab 2: Subject-class roster view (`subject_classes` -> `class_enrollments`)
/// supporting Independent Split-Pane Scroll on Desktop (`_leftClassController`
/// and `_rightEnrollmentController`), mid-term additions, soft delete, and sync.
class SubjectClassRosterTabView extends ConsumerStatefulWidget {
  const SubjectClassRosterTabView({
    super.key,
    required this.term,
    required this.isSplitPane,
    required this.isBusy,
  });

  final Term term;
  final bool isSplitPane;
  final bool isBusy;

  @override
  ConsumerState<SubjectClassRosterTabView> createState() =>
      _SubjectClassRosterTabViewState();
}

class _SubjectClassRosterTabViewState
    extends ConsumerState<SubjectClassRosterTabView> {
  final _leftClassController = ScrollController();
  final _rightEnrollmentController = ScrollController();

  Term get term => widget.term;

  @override
  void dispose() {
    _leftClassController.dispose();
    _rightEnrollmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSplitPane = widget.isSplitPane;
    final isBusy = widget.isBusy;
    final subjectsAsync = ref.watch(subjectsByTermProvider(term.id));
    final classesAsync = ref.watch(subjectClassesByTermProvider(term.id));
    final homeroomsAsync = ref.watch(homeroomsByTermProvider(term.id));

    if (subjectsAsync.isLoading || classesAsync.isLoading) {
      return const AppSurfaceCard(child: SkeletonBox(height: 52));
    }

    if (subjectsAsync.hasError || classesAsync.hasError) {
      return AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(subjectsAsync.error ?? classesAsync.error!),
        onRetry: () {
          ref.invalidate(subjectsByTermProvider(term.id));
          ref.invalidate(subjectClassesByTermProvider(term.id));
        },
      );
    }

    final subjects = subjectsAsync.asData?.value ?? const <Subject>[];
    final classes = classesAsync.asData?.value ?? const <SubjectClass>[];
    final homerooms = homeroomsAsync.asData?.value ?? const <Homeroom>[];

    if (classes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.class_outlined,
        title: 'ยังไม่มีห้องเรียนรายวิชาในเทอมนี้',
        description: 'กรุณาสร้างรายวิชาและห้องเรียนที่หน้า "โครงสร้างสอน" ก่อน',
      );
    }

    final subjectById = {for (final s in subjects) s.id: s};
    final homeroomById = {for (final h in homerooms) h.id: h};
    final selectedId = ref.watch(selectedSubjectClassIdProvider);
    final selectedClass = classes.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => classes.first,
    );
    final linkedHomeroom = selectedClass.homeroomId == null
        ? null
        : homeroomById[selectedClass.homeroomId!];
    final siblingClassIds = selectedClass.homeroomId == null
        ? const <String>[]
        : classes
              .where((c) => c.homeroomId == selectedClass.homeroomId)
              .map((c) => c.id)
              .toList(growable: false);

    final enrollmentsAsync = ref.watch(
      classEnrollmentsProvider(selectedClass.id),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final selectedSubject = subjectById[selectedClass.subjectId];
    final selectedClassTitle =
        '${selectedSubject?.subjectCode ?? ''} '
        '${selectedSubject?.subjectName ?? ''} — ${selectedClass.roomName}';

    final actionBar = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: linkedHomeroom != null
                ? semantic.successContainer
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                linkedHomeroom != null
                    ? Icons.link_rounded
                    : Icons.link_off_rounded,
                size: 15,
                color: linkedHomeroom != null
                    ? semantic.success
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  linkedHomeroom != null
                      ? 'ผูกกับคลังกลาง: ${linkedHomeroom.name}'
                      : 'ยังไม่ได้ผูกกับคลังกลาง',
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: linkedHomeroom != null
                        ? semantic.success
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (linkedHomeroom != null)
              OutlinedButton.icon(
                onPressed: isBusy
                    ? null
                    : () => _syncMissingFromHomeroom(
                        context,
                        ref,
                        linkedHomeroom,
                        selectedClass,
                      ),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('ดึงนักเรียนใหม่จากคลัง'),
              ),
            OutlinedButton.icon(
              onPressed: isBusy || enrollmentsAsync.asData == null
                  ? null
                  : () => _renumber(
                      context,
                      ref,
                      selectedClass,
                      enrollmentsAsync.asData!.value,
                    ),
              icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
              label: const Text('เรียงเลขที่ใหม่'),
            ),
            FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () => _addMidTerm(
                      context,
                      ref,
                      selectedClass,
                      linkedHomeroom,
                      enrollmentsAsync.asData?.value ?? const [],
                    ),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('ย้ายเข้ากลางเทอม'),
            ),
          ],
        ),
      ],
    );

    final enrollmentBody = enrollmentsAsync.when(
      loading: () => const Column(
        children: [
          SkeletonBox(height: 52),
          SizedBox(height: 8),
          SkeletonBox(height: 52),
        ],
      ),
      error: (error, _) => AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(error),
        onRetry: () =>
            ref.invalidate(classEnrollmentsProvider(selectedClass.id)),
      ),
      data: (enrollments) {
        final byId = {for (final e in enrollments) e.id: e};
        return RosterStudentListView(
          isBusy: isBusy,
          fillAvailableHeight: isSplitPane,
          scrollController: isSplitPane ? _rightEnrollmentController : null,
          students: [
            for (final e in enrollments)
              RosterStudentRowData(
                id: e.id,
                studentNumber: e.studentNumber,
                studentCode: e.studentCode,
                fullName: e.fullName,
                status: e.status,
                enrolledAt: e.enrolledAt,
                transferredOutAt: e.transferredOutAt,
              ),
          ],
          onEdit: (row) => _editEnrollment(
            context,
            ref,
            byId[row.id]!,
            linkedHomeroom?.id,
            siblingClassIds,
          ),
          onToggleTransferStatus: (row) => _toggleStatus(
            context,
            ref,
            byId[row.id]!,
            linkedHomeroom?.id,
            siblingClassIds,
          ),
          onPermanentDelete: (row) => _permanentDeleteEnrollment(
            context,
            ref,
            byId[row.id]!,
            linkedHomeroom?.id,
            siblingClassIds,
          ),
        );
      },
    );

    if (isSplitPane) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 296,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'รายวิชาและห้องเรียน (${classes.length})',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AppSubtleScrollbar(
                      controller: _leftClassController,
                      child: ListView.separated(
                        controller: _leftClassController,
                        primary: false,
                        padding: const EdgeInsets.only(right: 6),
                        itemCount: classes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, idx) {
                          final sc = classes[idx];
                          final sub = subjectById[sc.subjectId];
                          final isSelected = sc.id == selectedClass.id;
                          return Material(
                            color: isSelected
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.65,
                                  )
                                : colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? colorScheme.primary.withValues(alpha: 0.5)
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: isBusy
                                  ? null
                                  : () => ref
                                        .read(
                                          selectedSubjectClassIdProvider
                                              .notifier,
                                        )
                                        .select(sc.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${sub?.subjectCode ?? ''} · ${sc.roomName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                    ),
                                    if (sub != null)
                                      Text(
                                        sub.subjectName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selectedClassTitle.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  actionBar,
                  const Divider(height: 24),
                  Expanded(child: enrollmentBody),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey<String>(selectedClass.id),
            initialValue: selectedClass.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'เลือกรายวิชาและห้องเรียน',
              prefixIcon: Icon(Icons.class_outlined, size: 18),
            ),
            items: [
              for (final sc in classes)
                DropdownMenuItem<String>(
                  value: sc.id,
                  child: Text(
                    '${subjectById[sc.subjectId]?.subjectCode ?? ''} '
                    '${subjectById[sc.subjectId]?.subjectName ?? ''} — ${sc.roomName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: isBusy
                ? null
                : (id) {
                    if (id != null) {
                      ref
                          .read(selectedSubjectClassIdProvider.notifier)
                          .select(id);
                    }
                  },
          ),
          const SizedBox(height: 12),
          actionBar,
          const Divider(height: 24),
          enrollmentBody,
        ],
      ),
    );
  }

  Future<void> _syncMissingFromHomeroom(
    BuildContext context,
    WidgetRef ref,
    Homeroom homeroom,
    SubjectClass subjectClass,
  ) async {
    final added = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .linkHomeroomToSubjectClasses(
          termId: term.id,
          homeroomId: homeroom.id,
          subjectClassIds: <String>[subjectClass.id],
          enrolledAt: DateTime.now(),
        );
    if (added != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: added > 0
            ? 'ดึงนักเรียนใหม่จากคลังเพิ่ม $added คนเรียบร้อยแล้ว'
            : 'รายชื่อตรงกับคลังกลางครบแล้ว ไม่มีนักเรียนใหม่เพิ่มเติม',
      );
    }
  }

  Future<void> _addMidTerm(
    BuildContext context,
    WidgetRef ref,
    SubjectClass subjectClass,
    Homeroom? linkedHomeroom,
    List<ClassEnrollment> existing,
  ) async {
    final nextNum = RosterRenumberService.nextStudentNumber(
      existing.map((e) => e.studentNumber),
    );
    final result = await StudentFormDialog.show(
      context,
      title: 'เพิ่มนักเรียนย้ายเข้ากลางเทอม (${subjectClass.roomName})',
      initialStudentNumber: nextNum,
      showEnrolledAt: true,
      showAddToHomeroomOption: linkedHomeroom != null,
    );
    if (result == null || !context.mounted) return;
    final created = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .addClassEnrollmentMidTerm(
          subjectClassId: subjectClass.id,
          addToHomeroomId: result.alsoAddToHomeroom ? linkedHomeroom?.id : null,
          studentCode: result.studentCode,
          studentNumber: result.studentNumber,
          prefix: result.prefix,
          firstName: result.firstName,
          lastName: result.lastName,
          enrolledAt: result.enrolledAt,
        );
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เพิ่ม ${created.fullName} เข้ารายวิชาเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _editEnrollment(
    BuildContext context,
    WidgetRef ref,
    ClassEnrollment enrollment,
    String? linkedHomeroomId,
    List<String> siblingClassIds,
  ) async {
    final form = await StudentFormDialog.show(
      context,
      title: 'แก้ไขข้อมูลนักเรียนในรายวิชา',
      initialStudentNumber: enrollment.studentNumber,
      initialStudentCode: enrollment.studentCode,
      initialPrefix: enrollment.prefix,
      initialFirstName: enrollment.firstName,
      initialLastName: enrollment.lastName,
      initialEnrolledAt: enrollment.enrolledAt,
      showEnrolledAt: true,
    );
    if (form == null || !context.mounted) return;

    var syncAll = false;
    if (enrollment.isLinkedToHomeroom) {
      final choice = await SyncScopeChoiceDialog.show(
        context,
        studentName: enrollment.fullName,
      );
      if (choice == null || !context.mounted) return;
      syncAll = choice == RosterSyncScope.homeroomAndAllClasses;
    }

    final updated = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .updateClassEnrollment(
          existing: enrollment,
          studentCode: form.studentCode,
          studentNumber: form.studentNumber,
          prefix: form.prefix,
          firstName: form.firstName,
          lastName: form.lastName,
          enrolledAt: form.enrolledAt,
          syncToHomeroomAndAllClasses: syncAll,
          linkedHomeroomId: linkedHomeroomId,
          siblingClassIds: siblingClassIds,
        );
    if (updated != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: syncAll
            ? 'อัปเดตคลังหลักและซิงค์ทุกวิชาที่ผูกแล้ว ($updated รายการ)'
            : 'อัปเดตข้อมูลเฉพาะวิชานี้เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    ClassEnrollment enrollment,
    String? linkedHomeroomId,
    List<String> siblingClassIds,
  ) async {
    final nextStatus = enrollment.isTransferredOut
        ? StudentLifecycleStatus.active
        : StudentLifecycleStatus.transferredOut;
    var syncAll = false;
    if (enrollment.isLinkedToHomeroom) {
      final choice = await SyncScopeChoiceDialog.show(
        context,
        studentName: enrollment.fullName,
        actionTitle: nextStatus == StudentLifecycleStatus.transferredOut
            ? 'เลือกขอบเขตการบันทึกย้ายออก'
            : 'เลือกขอบเขตการคืนสถานะนักเรียน',
      );
      if (choice == null || !context.mounted) return;
      syncAll = choice == RosterSyncScope.homeroomAndAllClasses;
    }

    final updated = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .setClassEnrollmentStatus(
          existing: enrollment,
          status: nextStatus,
          transferredOutAt: DateTime.now(),
          syncToHomeroomAndAllClasses: syncAll,
          linkedHomeroomId: linkedHomeroomId,
          siblingClassIds: siblingClassIds,
        );
    if (updated != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: nextStatus == StudentLifecycleStatus.transferredOut
            ? 'บันทึกย้ายออกแล้ว (คงเลขที่เดิม ${enrollment.studentNumber} ไว้)'
            : 'คืนสถานะกำลังเรียนเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _permanentDeleteEnrollment(
    BuildContext context,
    WidgetRef ref,
    ClassEnrollment enrollment,
    String? linkedHomeroomId,
    List<String> siblingClassIds,
  ) async {
    var alsoDeleteFromHomeroom = false;
    if (enrollment.isLinkedToHomeroom) {
      final choice = await SyncScopeChoiceDialog.show(
        context,
        studentName: enrollment.fullName,
        actionTitle: 'เลือกขอบเขตการลบถาวร (กรณีเพิ่มผิด)',
      );
      if (choice == null || !context.mounted) return;
      alsoDeleteFromHomeroom = choice == RosterSyncScope.homeroomAndAllClasses;
    }

    final confirmed = await TypedConfirmDialog.show(
      context,
      title: 'ยืนยันการลบถาวร ${enrollment.fullName}',
      description: alsoDeleteFromHomeroom
          ? 'ระบบจะลบรายชื่อนี้รวมถึงประวัติเช็คชื่อและคะแนนออกจากคลังกลางและทุกวิชาที่ผูกไว้ในเทอมนี้แบบถาวร (กู้คืนไม่ได้)'
          : 'ระบบจะลบรายชื่อนี้รวมถึงประวัติเช็คชื่อและคะแนนออกจากรายวิชานี้แบบถาวร (กู้คืนไม่ได้)',
      expectedText: enrollment.studentCode,
      confirmLabel: 'ลบถาวร',
      impactSummary: <DeleteImpactItem>[
        DeleteImpactItem(
          label: alsoDeleteFromHomeroom
              ? 'รายวิชาที่ผูกกับคลังห้องนี้ที่จะถูกลบ'
              : 'รายวิชาที่จะถูกลบ',
          count: alsoDeleteFromHomeroom
              ? (siblingClassIds.isEmpty ? 1 : siblingClassIds.length)
              : 1,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .permanentlyDeleteClassEnrollment(
          existing: enrollment,
          alsoDeleteFromHomeroom: alsoDeleteFromHomeroom,
          linkedHomeroomId: linkedHomeroomId,
          siblingClassIds: siblingClassIds,
        );
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: alsoDeleteFromHomeroom
            ? 'ลบถาวร ${enrollment.fullName} ออกจากคลังกลางและทุกวิชาที่ผูกเรียบร้อยแล้ว'
            : 'ลบถาวร ${enrollment.fullName} ออกจากรายวิชานี้เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _renumber(
    BuildContext context,
    WidgetRef ref,
    SubjectClass subjectClass,
    List<ClassEnrollment> enrollments,
  ) async {
    final assignments = RosterRenumberService.computeClassEnrollmentRenumber(
      enrollments,
    );
    if (assignments.isEmpty) {
      AppFeedbackBanner.showSnackBar(
        context,
        message: 'เลขที่ของนักเรียนที่กำลังเรียนเรียงต่อเนื่อง 1..N อยู่แล้ว',
      );
      return;
    }
    final confirm = await RenumberConfirmDialog.show(
      context,
      assignments: assignments,
      showSyncLinkedOption: false,
    );
    if (confirm == null || !context.mounted) return;
    final ok = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .renumberClassEnrollments(
          subjectClassId: subjectClass.id,
          currentEnrollments: enrollments,
          assignments: assignments,
        );
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เรียงเลขที่ใหม่ในห้องนี้เรียบร้อยแล้ว',
      );
    }
  }
}
