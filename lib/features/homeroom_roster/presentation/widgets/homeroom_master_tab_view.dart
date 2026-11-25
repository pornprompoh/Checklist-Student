import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/typed_confirm_dialog.dart';
import '../../../academic_structure/domain/entities/subject.dart';
import '../../../academic_structure/domain/entities/subject_class.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/entities/homeroom_student.dart';
import '../../domain/entities/student_lifecycle_status.dart';
import '../../domain/services/roster_renumber_service.dart';
import '../../domain/services/unlinked_room_sync_service.dart';
import '../providers/homeroom_roster_controller.dart';
import '../providers/homeroom_roster_providers.dart';
import 'ai_roster_import_dialog.dart';
import 'homeroom_form_dialog.dart';
import 'homeroom_list_panel.dart';
import 'link_homeroom_classes_dialog.dart';
import 'renumber_confirm_dialog.dart';
import 'roster_import_dialog.dart';
import 'roster_student_list_view.dart';
import 'student_form_dialog.dart';

/// Tab 1: Term-level master homeroom roster (`homerooms` -> `homeroom_students`)
/// with Independent Split-Pane Scroll on Desktop (`_leftListController` and
/// `_rightListController` properly disposed).
class HomeroomMasterTabView extends ConsumerStatefulWidget {
  const HomeroomMasterTabView({
    super.key,
    required this.term,
    required this.isSplitPane,
    required this.isBusy,
  });

  final Term term;
  final bool isSplitPane;
  final bool isBusy;

  @override
  ConsumerState<HomeroomMasterTabView> createState() =>
      _HomeroomMasterTabViewState();
}

class _HomeroomMasterTabViewState extends ConsumerState<HomeroomMasterTabView> {
  final _leftListController = ScrollController();
  final _rightListController = ScrollController();

  @override
  void dispose() {
    _leftListController.dispose();
    _rightListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    final isSplitPane = widget.isSplitPane;
    final isBusy = widget.isBusy;
    final homeroomsAsync = ref.watch(homeroomsByTermProvider(term.id));
    final subjectsAsync = ref.watch(subjectsByTermProvider(term.id));
    final classesAsync = ref.watch(subjectClassesByTermProvider(term.id));

    if (homeroomsAsync.isLoading) {
      return const AppSurfaceCard(
        child: Column(
          children: [
            SkeletonBox(height: 44),
            SizedBox(height: 12),
            SkeletonBox(height: 44),
          ],
        ),
      );
    }

    if (homeroomsAsync.hasError) {
      return AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(homeroomsAsync.error!),
        onRetry: () => ref.invalidate(homeroomsByTermProvider(term.id)),
      );
    }

    final homerooms = homeroomsAsync.asData?.value ?? const <Homeroom>[];
    final subjects = subjectsAsync.asData?.value ?? const <Subject>[];
    final classes = classesAsync.asData?.value ?? const <SubjectClass>[];
    final linkedCounts = <String, int>{};
    for (final c in classes) {
      if (c.homeroomId != null) {
        linkedCounts[c.homeroomId!] = (linkedCounts[c.homeroomId!] ?? 0) + 1;
      }
    }

    final selectedId = ref.watch(selectedHomeroomIdProvider);
    final selectedHomeroom = homerooms.isEmpty
        ? null
        : homerooms.firstWhere(
            (h) => h.id == selectedId,
            orElse: () => homerooms.first,
          );

    final unlinkedGroups = UnlinkedRoomSyncService.findUnlinkedRooms(
      homerooms: homerooms,
      subjectClasses: classes,
    );

    final listPanel = HomeroomListPanel(
      homerooms: homerooms,
      selectedHomeroomId: selectedHomeroom?.id,
      linkedClassCounts: linkedCounts,
      isBusy: isBusy,
      fillAvailableHeight: isSplitPane,
      scrollController: isSplitPane ? _leftListController : null,
      onSelect: (id) =>
          ref.read(selectedHomeroomIdProvider.notifier).select(id),
      onCreate: () => _createHomeroom(context, ref),
      onRename: (room) => _renameHomeroom(context, ref, room),
      onDelete: (room) =>
          _deleteHomeroom(context, ref, room, linkedCounts[room.id] ?? 0),
      unlinkedRoomGroups: unlinkedGroups,
      onSyncUnlinkedGroup: (group) =>
          _syncUnlinkedRooms(context, ref, <UnlinkedRoomGroup>[group]),
      onSyncAllUnlinked: unlinkedGroups.isEmpty
          ? null
          : () => _syncUnlinkedRooms(context, ref, unlinkedGroups),
    );

    final detailCard = selectedHomeroom == null
        ? const SizedBox.shrink()
        : _HomeroomStudentsDetailCard(
            term: term,
            homeroom: selectedHomeroom,
            subjects: subjects,
            allClassesInTerm: classes,
            isBusy: isBusy,
            fillAvailableHeight: isSplitPane,
            scrollController: isSplitPane ? _rightListController : null,
          );

    if (isSplitPane) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 296, child: listPanel),
          const SizedBox(width: 16),
          Expanded(child: detailCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        listPanel,
        if (selectedHomeroom != null) ...[
          const SizedBox(height: 16),
          detailCard,
        ],
      ],
    );
  }

  Term get term => widget.term;

  Future<void> _syncUnlinkedRooms(
    BuildContext context,
    WidgetRef ref,
    List<UnlinkedRoomGroup> groups,
  ) async {
    final first = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .syncUnlinkedRoomGroups(
          termId: term.id,
          groups: groups,
          enrolledAt: term.startDate ?? DateTime.now(),
        );
    if (first != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: groups.length == 1
            ? 'เชื่อมห้อง "${first.name}" เข้าคลังรายชื่อเรียบร้อยแล้ว พร้อมเพิ่มนักเรียนได้ทันที'
            : 'นำเข้าและเชื่อม ${groups.length} ห้องจากโครงสร้างสอนเข้าคลังรายชื่อเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _createHomeroom(BuildContext context, WidgetRef ref) async {
    final name = await HomeroomFormDialog.show(context);
    if (name == null || !context.mounted) return;
    final created = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .createHomeroom(termId: term.id, name: name);
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'สร้างคลังห้องเรียน "${created.name}" เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _renameHomeroom(
    BuildContext context,
    WidgetRef ref,
    Homeroom room,
  ) async {
    final name = await HomeroomFormDialog.show(context, initialName: room.name);
    if (name == null || name == room.name || !context.mounted) return;
    final updated = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .renameHomeroom(termId: term.id, homeroomId: room.id, name: name);
    if (updated != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เปลี่ยนชื่อคลังห้องเป็น "${updated.name}" เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _deleteHomeroom(
    BuildContext context,
    WidgetRef ref,
    Homeroom room,
    int linkedClassCount,
  ) async {
    final confirmed = await TypedConfirmDialog.show(
      context,
      title: 'ยืนยันการลบคลังห้องเรียน ${room.name}',
      description:
          'การลบคลังห้องจะลบรายชื่อกลางในคลังนี้ (รายชื่อที่คัดลอกไปในแต่ละวิชาจะยังคงอยู่แต่ถูกปลดการผูก)',
      expectedText: room.name,
      impactSummary: <DeleteImpactItem>[
        DeleteImpactItem(label: 'รายวิชาที่ผูกกับคลังนี้', count: linkedClassCount),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .deleteHomeroom(termId: term.id, homeroomId: room.id);
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'ลบคลังห้องเรียบร้อยแล้ว',
      );
    }
  }
}

class _HomeroomStudentsDetailCard extends ConsumerWidget {
  const _HomeroomStudentsDetailCard({
    required this.term,
    required this.homeroom,
    required this.subjects,
    required this.allClassesInTerm,
    required this.isBusy,
    required this.fillAvailableHeight,
    this.scrollController,
  });

  final Term term;
  final Homeroom homeroom;
  final List<Subject> subjects;
  final List<SubjectClass> allClassesInTerm;
  final bool isBusy;
  final bool fillAvailableHeight;
  final ScrollController? scrollController;

  List<String> get _linkedClassIds => allClassesInTerm
      .where((c) => c.homeroomId == homeroom.id)
      .map((c) => c.id)
      .toList(growable: false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(homeroomStudentsProvider(homeroom.id));
    final canUseAi = ref.watch(
      authStateProvider.select((state) => state.canUseAi),
    );
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final headerContent = <Widget>[
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'รายชื่อกลางห้อง ${homeroom.name}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ผูกอยู่ ${_linkedClassIds.length} รายวิชาในเทอมนี้',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: isBusy
                ? null
                : () => _addStudent(
                    context,
                    ref,
                    studentsAsync.asData?.value ?? const [],
                  ),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('เพิ่มนักเรียน'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (canUseAi)
            FilledButton.tonalIcon(
              onPressed: isBusy
                  ? null
                  : () => _importWithAi(
                      context,
                      ref,
                      studentsAsync.asData?.value ?? const [],
                    ),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: const Text('นำเข้าด้วย AI (รูป/PDF)'),
            ),
          FilledButton.tonalIcon(
            onPressed: isBusy
                ? null
                : () => _importSpreadsheet(
                    context,
                    ref,
                    studentsAsync.asData?.value ?? const [],
                  ),
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('นำเข้า Excel/CSV'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : () => _linkClasses(context, ref),
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('ผูกกับรายวิชา'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy || studentsAsync.asData == null
                ? null
                : () => _renumber(
                    context,
                    ref,
                    studentsAsync.asData!.value,
                  ),
            icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
            label: const Text('เรียงเลขที่ใหม่'),
          ),
        ],
      ),
      const Divider(height: 24),
    ];

    final studentBody = studentsAsync.when(
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
        onRetry: () => ref.invalidate(homeroomStudentsProvider(homeroom.id)),
      ),
      data: (students) {
        final byId = {for (final s in students) s.id: s};
        return RosterStudentListView(
          isBusy: isBusy,
          fillAvailableHeight: fillAvailableHeight,
          scrollController: scrollController,
          students: [
            for (final s in students)
              RosterStudentRowData(
                id: s.id,
                studentNumber: s.studentNumber,
                studentCode: s.studentCode,
                fullName: s.fullName,
                status: s.status,
                transferredOutAt: s.transferredOutAt,
              ),
          ],
          onEdit: (row) => _editStudent(context, ref, byId[row.id]!),
          onToggleTransferStatus: (row) =>
              _toggleStatus(context, ref, byId[row.id]!),
          onPermanentDelete: (row) =>
              _permanentDeleteStudent(context, ref, byId[row.id]!),
        );
      },
    );

    if (fillAvailableHeight) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...headerContent, Expanded(child: studentBody)],
        ),
      );
    }

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...headerContent, studentBody],
      ),
    );
  }

  Future<void> _importWithAi(
    BuildContext context,
    WidgetRef ref,
    List<HomeroomStudent> existing,
  ) async {
    final result = await AiRosterImportDialog.show(
      context,
      academicYearId: term.academicYearId,
      homeroomId: homeroom.id,
      homeroomName: homeroom.name,
      existingStudents: existing,
      linkedClassIds: _linkedClassIds,
      defaultEnrolledAt: term.startDate,
    );
    if (result == null || !context.mounted) return;
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message:
          'นำเข้าด้วย AI สำเร็จ: เพิ่มใหม่ ${result.insertedCount} คน'
          '${result.autoEnrolledClassesCount > 0 ? ' · ซิงค์เข้า ${result.autoEnrolledClassesCount} รายวิชาแล้ว' : ''}'
          '${result.updatedCount > 0 ? ' · อัปเดตทับ ${result.updatedCount} คน' : ''}'
          '${result.skippedCount > 0 ? ' · ข้าม ${result.skippedCount} แถว' : ''}',
    );
  }

  Future<void> _importSpreadsheet(
    BuildContext context,
    WidgetRef ref,
    List<HomeroomStudent> existing,
  ) async {
    final result = await RosterImportDialog.show(
      context,
      homeroomId: homeroom.id,
      homeroomName: homeroom.name,
      existingStudents: existing,
      linkedClassIds: _linkedClassIds,
      defaultEnrolledAt: term.startDate,
    );
    if (result == null || !context.mounted) return;
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message:
          'นำเข้าสำเร็จ: เพิ่มใหม่ ${result.insertedCount} คน'
          '${result.autoEnrolledClassesCount > 0 ? ' · ซิงค์เข้า ${result.autoEnrolledClassesCount} รายวิชาแล้ว' : ''}'
          '${result.updatedCount > 0 ? ' · อัปเดตทับ ${result.updatedCount} คน' : ''}'
          '${result.skippedCount > 0 ? ' · ข้าม ${result.skippedCount} แถว' : ''}',
    );
  }

  Future<void> _linkClasses(BuildContext context, WidgetRef ref) async {
    final result = await LinkHomeroomClassesDialog.show(
      context,
      homeroomId: homeroom.id,
      homeroomName: homeroom.name,
      subjects: subjects,
      subjectClasses: allClassesInTerm,
      defaultEnrolledAt: term.startDate,
    );
    if (result == null || !context.mounted) return;
    final inserted = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .linkHomeroomToSubjectClasses(
          termId: term.id,
          homeroomId: homeroom.id,
          subjectClassIds: result.subjectClassIds,
          enrolledAt: result.enrolledAt,
        );
    if (inserted != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'ผูกกับรายวิชาแล้ว เพิ่มนักเรียนใหม่เข้าห้องสอน $inserted รายการ',
      );
    }
  }

  Future<void> _addStudent(
    BuildContext context,
    WidgetRef ref,
    List<HomeroomStudent> existing,
  ) async {
    final nextNum = RosterRenumberService.nextStudentNumber(
      existing.map((e) => e.studentNumber),
    );
    final result = await StudentFormDialog.show(
      context,
      title: 'เพิ่มนักเรียนเข้าคลัง ${homeroom.name}',
      initialStudentNumber: nextNum,
      showSyncToLinkedClassesOption: _linkedClassIds.isNotEmpty,
      linkedClassCount: _linkedClassIds.length,
    );
    if (result == null || !context.mounted) return;
    final created = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .addHomeroomStudent(
          homeroomId: homeroom.id,
          studentCode: result.studentCode,
          studentNumber: result.studentNumber,
          prefix: result.prefix,
          firstName: result.firstName,
          lastName: result.lastName,
          autoEnrollLinkedClasses: result.syncToLinkedClasses,
          enrolledAt: term.startDate,
          linkedClassIds: _linkedClassIds,
        );
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: result.syncToLinkedClasses && _linkedClassIds.isNotEmpty
            ? 'เพิ่ม ${created.fullName} เข้าคลังและซิงค์เข้า ${_linkedClassIds.length} รายวิชาที่ผูกไว้เรียบร้อยแล้ว'
            : 'เพิ่ม ${created.fullName} เข้าคลังเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _editStudent(
    BuildContext context,
    WidgetRef ref,
    HomeroomStudent student,
  ) async {
    final result = await StudentFormDialog.show(
      context,
      title: 'แก้ไขข้อมูลนักเรียน (คลังกลาง)',
      initialStudentNumber: student.studentNumber,
      initialStudentCode: student.studentCode,
      initialPrefix: student.prefix,
      initialFirstName: student.firstName,
      initialLastName: student.lastName,
    );
    if (result == null || !context.mounted) return;
    final synced = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .updateHomeroomStudent(
          homeroomId: homeroom.id,
          homeroomStudentId: student.id,
          studentCode: result.studentCode,
          studentNumber: result.studentNumber,
          prefix: result.prefix,
          firstName: result.firstName,
          lastName: result.lastName,
          syncLinkedClasses: _linkedClassIds.isNotEmpty,
          linkedClassIds: _linkedClassIds,
        );
    if (synced != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: synced > 0
            ? 'บันทึกและซิงค์ข้อมูลไปยัง $synced ห้องเรียนเรียบร้อยแล้ว'
            : 'บันทึกข้อมูลเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    HomeroomStudent student,
  ) async {
    final nextStatus = student.isTransferredOut
        ? StudentLifecycleStatus.active
        : StudentLifecycleStatus.transferredOut;
    final synced = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .setHomeroomStudentStatus(
          homeroomId: homeroom.id,
          homeroomStudentId: student.id,
          status: nextStatus,
          transferredOutAt: DateTime.now(),
          syncLinkedClasses: _linkedClassIds.isNotEmpty,
          linkedClassIds: _linkedClassIds,
        );
    if (synced != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: nextStatus == StudentLifecycleStatus.transferredOut
            ? 'บันทึกย้ายออกแล้ว (คงเลขที่เดิม ${student.studentNumber} ไว้)'
            : 'คืนสถานะกำลังเรียนเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _permanentDeleteStudent(
    BuildContext context,
    WidgetRef ref,
    HomeroomStudent student,
  ) async {
    final confirmed = await TypedConfirmDialog.show(
      context,
      title: 'ยืนยันการลบถาวร ${student.fullName}',
      description:
          'การลบถาวรเหมาะสำหรับรายชื่อที่เพิ่มหรือนำเข้าผิดพลาด ระบบจะลบรายชื่อนี้รวมถึงประวัติเช็คชื่อและคะแนนทั้งหมดออกจากคลังกลางและทุกวิชาที่ผูกไว้ในเทอมนี้แบบถาวร (ไม่สามารถกู้คืนได้)',
      expectedText: student.studentCode,
      confirmLabel: 'ลบถาวร',
      impactSummary: <DeleteImpactItem>[
        DeleteImpactItem(
          label: 'รายวิชาที่ผูกกับคลังห้องนี้ที่จะถูกลบไปด้วย',
          count: _linkedClassIds.length,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final deletedClasses = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .permanentlyDeleteHomeroomStudent(
          homeroomId: homeroom.id,
          homeroomStudentId: student.id,
          deleteFromLinkedClasses: true,
          linkedClassIds: _linkedClassIds,
        );
    if (deletedClasses != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: deletedClasses > 0
            ? 'ลบถาวร ${student.fullName} ออกจากคลังกลางและ $deletedClasses รายวิชาเรียบร้อยแล้ว'
            : 'ลบถาวร ${student.fullName} ออกจากคลังกลางเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _renumber(
    BuildContext context,
    WidgetRef ref,
    List<HomeroomStudent> students,
  ) async {
    final assignments = RosterRenumberService.computeHomeroomRenumber(students);
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
      showSyncLinkedOption: _linkedClassIds.isNotEmpty,
    );
    if (confirm == null || !context.mounted) return;
    final synced = await ref
        .read(homeroomRosterControllerProvider.notifier)
        .renumberHomeroomStudents(
          homeroomId: homeroom.id,
          assignments: assignments,
          syncLinkedClasses: confirm.syncLinkedClasses,
          linkedClassIds: _linkedClassIds,
        );
    if (synced != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เรียงเลขที่ใหม่เรียบร้อยแล้ว',
      );
    }
  }
}
