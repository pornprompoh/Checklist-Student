import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../homeroom_roster/domain/entities/homeroom.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../domain/entities/delete_impact_summary.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import '../../domain/entities/term.dart';
import '../providers/academic_structure_controller.dart';
import '../providers/academic_structure_providers.dart';
import 'structural_delete_helper.dart';
import 'structure_empty_state_card.dart';
import 'subject_card.dart';
import 'subject_class_form_dialog.dart';
import 'subject_form_dialog.dart';

/// Displays and manages all [Subject] and [SubjectClass] records for [term].
class TermSubjectsSection extends ConsumerWidget {
  const TermSubjectsSection({
    super.key,
    required this.term,
    required this.isBusy,
  });

  final Term term;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsByTermProvider(term.id));
    final classesAsync = ref.watch(subjectClassesByTermProvider(term.id));
    final homeroomsAsync = ref.watch(homeroomsByTermProvider(term.id));

    if (subjectsAsync.isLoading || classesAsync.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox.line(width: 140, height: 16),
              SizedBox(height: 10),
              SkeletonBox(height: 52),
            ],
          ),
        ),
      );
    }

    if (subjectsAsync.hasError || classesAsync.hasError) {
      return AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(
          subjectsAsync.error ?? classesAsync.error!,
        ),
        onRetry: () {
          ref.invalidate(subjectsByTermProvider(term.id));
          ref.invalidate(subjectClassesByTermProvider(term.id));
        },
      );
    }

    final subjects = subjectsAsync.asData?.value ?? const <Subject>[];
    final classes = classesAsync.asData?.value ?? const <SubjectClass>[];
    final homerooms = homeroomsAsync.asData?.value ?? const <Homeroom>[];
    final suggestedRoomNames = <String>{
      for (final h in homerooms) h.name.trim(),
      for (final c in classes) c.roomName.trim(),
    }.where((name) => name.isNotEmpty).toList()
      ..sort();
    final classesBySubject = <String, List<SubjectClass>>{};
    for (final c in classes) {
      classesBySubject.putIfAbsent(c.subjectId, () => <SubjectClass>[]).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'รายวิชาและห้องเรียน (${subjects.length} วิชา)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            FilledButton.icon(
              onPressed: isBusy ? null : () => _addSubject(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('เพิ่มรายวิชา'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          StructureEmptyStateCard(
            icon: Icons.menu_book_outlined,
            title: 'ยังไม่มีรายวิชาในเทอม ${term.termLabel}',
            subtitle: 'เพิ่มรายวิชาแรกแล้วสร้างห้องเรียนพร้อมกำหนดวันสอนได้ทันที',
            actionLabel: 'เพิ่มรายวิชาแรก',
            onAction: () => _addSubject(context, ref),
          )
        else
          for (final subject in subjects) ...[
            SubjectCard(
              subject: subject,
              classes: classesBySubject[subject.id] ?? const <SubjectClass>[],
              isBusy: isBusy,
              onEditSubject: () => _editSubject(context, ref, subject),
              onDeleteSubject: () => _deleteSubject(context, ref, subject),
              onAddClass: () =>
                  _addClass(context, ref, subject, suggestedRoomNames),
              onTogglePinClass: (sc) => ref
                  .read(academicStructureControllerProvider.notifier)
                  .togglePinSubjectClass(termId: term.id, subjectClass: sc),
              onEditClass: (sc) => _editClass(context, ref, subject, sc),
              onDeleteClass: (sc) => _deleteClass(context, ref, sc),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Future<void> _addSubject(BuildContext context, WidgetRef ref) async {
    final result = await SubjectFormDialog.show(context);
    if (result == null || !context.mounted) return;
    final created = await ref
        .read(academicStructureControllerProvider.notifier)
        .createSubject(
          termId: term.id,
          subjectCode: result.subjectCode,
          subjectName: result.subjectName,
        );
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เพิ่มรายวิชา ${created.subjectCode} เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _editSubject(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final result = await SubjectFormDialog.show(
      context,
      existingSubject: subject,
    );
    if (result == null || !context.mounted) return;
    final updated = await ref
        .read(academicStructureControllerProvider.notifier)
        .updateSubject(
          termId: term.id,
          subjectId: subject.id,
          subjectCode: result.subjectCode,
          subjectName: result.subjectName,
        );
    if (updated != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'แก้ไขรายวิชาเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _deleteSubject(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) {
    return confirmAndDeleteStructure(
      context: context,
      ref: ref,
      entityType: StructuralEntityType.subject,
      entityId: subject.id,
      title: 'ยืนยันการลบรายวิชา ${subject.subjectCode}',
      description: 'การลบรายวิชาจะลบห้องเรียน ข้อมูลเช็คชื่อ และคะแนนทั้งหมดของวิชานี้',
      expectedText: subject.subjectCode,
      onConfirmedDelete: () => ref
          .read(academicStructureControllerProvider.notifier)
          .deleteSubject(termId: term.id, subjectId: subject.id),
    );
  }

  Future<void> _addClass(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
    List<String> suggestedRoomNames,
  ) async {
    final result = await SubjectClassFormDialog.show(
      context,
      subjectLabel: '${subject.subjectCode} ${subject.subjectName}',
      suggestedRoomNames: suggestedRoomNames,
    );
    if (result == null || !context.mounted) return;
    final created = await ref
        .read(academicStructureControllerProvider.notifier)
        .createSubjectClass(
          termId: term.id,
          subjectId: subject.id,
          roomName: result.roomName,
          teachingDays: result.teachingDays,
          isPinned: result.isPinned,
          autoLinkHomeroom: result.autoLinkHomeroom,
          defaultEnrolledAt: term.startDate,
        );
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: result.autoLinkHomeroom
            ? 'เพิ่มห้องเรียน ${created.roomName} และผูกคลังรายชื่อกลางเรียบร้อยแล้ว'
            : 'เพิ่มห้องเรียน ${created.roomName} เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _editClass(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
    SubjectClass existing,
  ) async {
    final result = await SubjectClassFormDialog.show(
      context,
      subjectLabel: '${subject.subjectCode} ${subject.subjectName}',
      existingClass: existing,
    );
    if (result == null || !context.mounted) return;
    final updated = await ref
        .read(academicStructureControllerProvider.notifier)
        .updateSubjectClass(
          termId: term.id,
          existing: existing,
          roomName: result.roomName,
          teachingDays: result.teachingDays,
          isPinned: result.isPinned,
        );
    if (updated != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'แก้ไขห้องเรียนเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _deleteClass(
    BuildContext context,
    WidgetRef ref,
    SubjectClass subjectClass,
  ) {
    return confirmAndDeleteStructure(
      context: context,
      ref: ref,
      entityType: StructuralEntityType.subjectClass,
      entityId: subjectClass.id,
      title: 'ยืนยันการลบห้องเรียน ${subjectClass.roomName}',
      description: 'การลบห้องเรียนจะลบรายชื่อในวิชานี้ คาบเช็คชื่อ และคะแนนทั้งหมดของห้องนี้',
      expectedText: subjectClass.roomName,
      onConfirmedDelete: () => ref
          .read(academicStructureControllerProvider.notifier)
          .deleteSubjectClass(termId: term.id, subjectClassId: subjectClass.id),
    );
  }
}
