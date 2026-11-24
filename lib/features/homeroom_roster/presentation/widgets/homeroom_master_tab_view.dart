import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
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

/// Tab 1: Term-level master homeroom roster (`homerooms` -> `homeroom_students`).
class HomeroomMasterTabView extends ConsumerWidget {
  const HomeroomMasterTabView({
    super.key,
    required this.term,
    required this.isDesktop,
    required this.isBusy,
  });

  final Term term;
  final bool isDesktop;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeroomsAsync = ref.watch(homeroomsByTermProvider(term.id));
    final subjectsAsync = ref.watch(subjectsByTermProvider(term.id));
    final classesAsync = ref.watch(subjectClassesByTermProvider(term.id));

    if (homeroomsAsync.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonBox(height: 44),
              SizedBox(height: 10),
              SkeletonBox(height: 44),
            ],
          ),
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

    final listPanel = HomeroomListPanel(
      homerooms: homerooms,
      selectedHomeroomId: selectedHomeroom?.id,
      linkedClassCounts: linkedCounts,
      isBusy: isBusy,
      onSelect: (id) =>
          ref.read(selectedHomeroomIdProvider.notifier).select(id),
      onCreate: () => _createHomeroom(context, ref),
      onRename: (room) => _renameHomeroom(context, ref, room),
      onDelete: (room) =>
          _deleteHomeroom(context, ref, room, linkedCounts[room.id] ?? 0),
    );

    final detailCard = selectedHomeroom == null
        ? const SizedBox.shrink()
        : _HomeroomStudentsDetailCard(
            term: term,
            homeroom: selectedHomeroom,
            subjects: subjects,
            allClassesInTerm: classes,
            isBusy: isBusy,
          );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 280, child: listPanel),
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
  });

  final Term term;
  final Homeroom homeroom;
  final List<Subject> subjects;
  final List<SubjectClass> allClassesInTerm;
  final bool isBusy;

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'รายชื่อกลางห้อง ${homeroom.name}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                    FilledButton.tonalIcon(
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
              ],
            ),
            const Divider(height: 24),
            studentsAsync.when(
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
                    ref.invalidate(homeroomStudentsProvider(homeroom.id)),
              ),
              data: (students) {
                final byId = {for (final s in students) s.id: s};
                return RosterStudentListView(
                  isBusy: isBusy,
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
                );
              },
            ),
          ],
        ),
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
    );
    if (result == null || !context.mounted) return;
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message:
          'นำเข้าด้วย AI สำเร็จ: เพิ่มใหม่ ${result.insertedCount} คน'
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
    );
    if (result == null || !context.mounted) return;
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message:
          'นำเข้าสำเร็จ: เพิ่มใหม่ ${result.insertedCount} คน'
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
        );
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เพิ่ม ${created.fullName} เข้าคลังเรียบร้อยแล้ว',
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
