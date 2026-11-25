import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';
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
import 'subject_block_card.dart';
import 'subject_class_form_dialog.dart';
import 'subject_detail_view.dart';
import 'subject_form_dialog.dart';

/// Displays all [Subject] records as equal-height Subject Blocks in a Grid and
/// supports in-page drill-down into a selected subject's [SubjectClass] list.
class TermSubjectsSection extends ConsumerStatefulWidget {
  const TermSubjectsSection({
    super.key,
    required this.term,
    required this.isBusy,
  });

  final Term term;
  final bool isBusy;

  @override
  ConsumerState<TermSubjectsSection> createState() =>
      _TermSubjectsSectionState();
}

class _TermSubjectsSectionState extends ConsumerState<TermSubjectsSection> {
  final _searchCtrl = TextEditingController();
  String? _selectedSubjectId;
  String _searchQuery = '';

  @override
  void didUpdateWidget(covariant TermSubjectsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id) {
      _selectedSubjectId = null;
      _searchQuery = '';
      _searchCtrl.clear();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    final isBusy = widget.isBusy;
    final subjectsAsync = ref.watch(subjectsByTermProvider(term.id));
    final classesAsync = ref.watch(subjectClassesByTermProvider(term.id));
    final homeroomsAsync = ref.watch(homeroomsByTermProvider(term.id));

    if (subjectsAsync.isLoading || classesAsync.isLoading) {
      return const AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox.line(width: 140, height: 16),
            SizedBox(height: 12),
            SkeletonBox(height: 52),
          ],
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

    final selectedSubject = _selectedSubjectId == null
        ? null
        : subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;

    if (selectedSubject != null) {
      return SubjectDetailView(
        subject: selectedSubject,
        classes: classesBySubject[selectedSubject.id] ?? const <SubjectClass>[],
        isBusy: isBusy,
        onBack: () => setState(() => _selectedSubjectId = null),
        onEditSubject: () => _editSubject(context, selectedSubject),
        onDeleteSubject: () => _deleteSubject(context, selectedSubject),
        onAddClass: () =>
            _addClass(context, selectedSubject, suggestedRoomNames),
        onTogglePinClass: (sc) => ref
            .read(academicStructureControllerProvider.notifier)
            .togglePinSubjectClass(termId: term.id, subjectClass: sc),
        onEditClass: (sc) => _editClass(context, selectedSubject, sc),
        onDeleteClass: (sc) => _deleteClass(context, sc),
        onOpenAttendance: (sc) => GoRouter.maybeOf(
          context,
        )?.go(AppRoutes.teacherAttendanceForClass(sc.id)),
        onOpenGrading: (sc) => GoRouter.maybeOf(
          context,
        )?.go(AppRoutes.teacherGradingForClass(sc.id)),
        onOpenGradingPlan: (sc) => GoRouter.maybeOf(
          context,
        )?.go(AppRoutes.teacherGradingPlanForClass(sc.id)),
      );
    }

    final q = _searchQuery.trim().toLowerCase();
    final filteredSubjects = q.isEmpty
        ? subjects
        : subjects
              .where(
                (s) =>
                    s.subjectCode.toLowerCase().contains(q) ||
                    s.subjectName.toLowerCase().contains(q) ||
                    (classesBySubject[s.id] ?? const <SubjectClass>[]).any(
                      (c) => c.roomName.toLowerCase().contains(q),
                    ),
              )
              .toList(growable: false);

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
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
            if (subjects.length >= 4 || _searchQuery.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'ค้นหารหัสวิชา ชื่อวิชา หรือห้อง...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'ล้างคำค้นหา',
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                          ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          AppEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'ยังไม่มีรายวิชาในเทอม ${term.termLabel}',
            description:
                'เพิ่มรายวิชาแรกแล้วสร้างห้องเรียนพร้อมกำหนดวันสอนได้ทันที',
            actionLabel: 'เพิ่มรายวิชาแรก',
            actionIcon: Icons.add_rounded,
            onAction: () => _addSubject(context),
          )
        else if (filteredSubjects.isEmpty)
          AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'ไม่พบรายวิชาที่ตรงกับคำค้นหา',
            description: 'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรองเพื่อดูรายวิชาทั้งหมด',
            actionLabel: 'ล้างคำค้นหา',
            actionIcon: Icons.refresh_rounded,
            onAction: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          )
        else
          _buildSubjectGrid(
            context,
            subjects: filteredSubjects,
            classesBySubject: classesBySubject,
            suggestedRoomNames: suggestedRoomNames,
          ),
      ],
    );
  }

  Widget _buildSubjectGrid(
    BuildContext context, {
    required List<Subject> subjects,
    required Map<String, List<SubjectClass>> classesBySubject,
    required List<String> suggestedRoomNames,
  }) {
    Widget buildBlock(Subject subject) => SubjectBlockCard(
      subject: subject,
      classes: classesBySubject[subject.id] ?? const <SubjectClass>[],
      isBusy: widget.isBusy,
      onOpenDetail: () => setState(() => _selectedSubjectId = subject.id),
      onAddClass: () => _addClass(context, subject, suggestedRoomNames),
      onEditSubject: () => _editSubject(context, subject),
      onDeleteSubject: () => _deleteSubject(context, subject),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : (constraints.maxWidth >= 600 ? 2 : 1);

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < subjects.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                buildBlock(subjects[i]),
              ],
            ],
          );
        }

        final rowCount = (subjects.length / columns).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < rowCount; row++) ...[
              if (row > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < columns; col++) ...[
                      if (col > 0) const SizedBox(width: 12),
                      Expanded(
                        child: (row * columns + col) < subjects.length
                            ? buildBlock(subjects[row * columns + col])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    final result = await SubjectFormDialog.show(context);
    if (result == null || !context.mounted) return;
    final created = await ref
        .read(academicStructureControllerProvider.notifier)
        .createSubject(
          termId: widget.term.id,
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

  Future<void> _editSubject(BuildContext context, Subject subject) async {
    final result = await SubjectFormDialog.show(
      context,
      existingSubject: subject,
    );
    if (result == null || !context.mounted) return;
    final updated = await ref
        .read(academicStructureControllerProvider.notifier)
        .updateSubject(
          termId: widget.term.id,
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

  Future<void> _deleteSubject(BuildContext context, Subject subject) {
    return confirmAndDeleteStructure(
      context: context,
      ref: ref,
      entityType: StructuralEntityType.subject,
      entityId: subject.id,
      title: 'ยืนยันการลบรายวิชา ${subject.subjectCode}',
      description:
          'การลบรายวิชาจะลบห้องเรียน ข้อมูลเช็คชื่อ และคะแนนทั้งหมดของวิชานี้',
      expectedText: subject.subjectCode,
      onConfirmedDelete: () async {
        final deleted = await ref
            .read(academicStructureControllerProvider.notifier)
            .deleteSubject(termId: widget.term.id, subjectId: subject.id);
        if (deleted && mounted && _selectedSubjectId == subject.id) {
          setState(() => _selectedSubjectId = null);
        }
        return deleted;
      },
    );
  }

  Future<void> _addClass(
    BuildContext context,
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
          termId: widget.term.id,
          subjectId: subject.id,
          roomName: result.roomName,
          teachingDays: result.teachingDays,
          isPinned: result.isPinned,
          autoLinkHomeroom: result.autoLinkHomeroom,
          defaultEnrolledAt: widget.term.startDate,
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
          termId: widget.term.id,
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

  Future<void> _deleteClass(BuildContext context, SubjectClass subjectClass) {
    return confirmAndDeleteStructure(
      context: context,
      ref: ref,
      entityType: StructuralEntityType.subjectClass,
      entityId: subjectClass.id,
      title: 'ยืนยันการลบห้องเรียน ${subjectClass.roomName}',
      description:
          'การลบห้องเรียนจะลบรายชื่อในวิชานี้ คาบเช็คชื่อ และคะแนนทั้งหมดของห้องนี้',
      expectedText: subjectClass.roomName,
      onConfirmedDelete: () => ref
          .read(academicStructureControllerProvider.notifier)
          .deleteSubjectClass(
            termId: widget.term.id,
            subjectClassId: subjectClass.id,
          ),
    );
  }
}
