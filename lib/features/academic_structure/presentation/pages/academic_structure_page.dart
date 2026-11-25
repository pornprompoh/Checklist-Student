import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/delete_impact_summary.dart';
import '../../domain/entities/term.dart';
import '../providers/academic_structure_controller.dart';
import '../providers/academic_structure_providers.dart';
import '../widgets/academic_year_form_dialog.dart';
import '../widgets/structural_delete_helper.dart';
import '../widgets/structure_empty_state_card.dart';
import '../widgets/subject_form_dialog.dart';
import '../widgets/term_form_dialog.dart';
import '../widgets/term_selector_header.dart';
import '../widgets/term_subjects_section.dart';

/// Teacher 4-level academic hierarchy management page (`/teacher/academic-structure`).
class AcademicStructurePage extends ConsumerWidget {
  const AcademicStructurePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final termsAsync = ref.watch(allTermsProvider);
    final isBusy = ref.watch(academicStructureControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(academicStructureControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    final years = yearsAsync.asData?.value ?? const <AcademicYear>[];
    final terms = termsAsync.asData?.value ?? const <Term>[];
    final selectedTerm = (years.isNotEmpty && terms.isNotEmpty)
        ? ref.watch(effectiveSelectedTermProvider)
        : null;
    final selectedYear = (selectedTerm != null && years.isNotEmpty)
        ? years.firstWhere(
            (y) => y.id == selectedTerm.academicYearId,
            orElse: () => years.first,
          )
        : null;

    final header = AppPageHeader(
      title: 'โครงสร้างปีการศึกษาและรายวิชา',
      actions: [
        if (selectedTerm != null && selectedYear != null) ...[
          FilledButton.icon(
            onPressed: isBusy
                ? null
                : () => _addSubject(context, ref, selectedTerm),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('เพิ่มรายวิชา'),
          ),
          _buildStructureOverflowMenu(
            context,
            ref: ref,
            academicYears: years,
            selectedYear: selectedYear,
            selectedTerm: selectedTerm,
            isBusy: isBusy,
          ),
        ],
      ],
    );

    return AppPageContainer.scrollable(
      header: header,
      child: yearsAsync.isLoading || termsAsync.isLoading
          ? const StructureSkeletonView()
          : yearsAsync.hasError || termsAsync.hasError
          ? AppFeedbackBanner(
              type: AppFeedbackType.error,
              message: ThaiErrorMapper.map(
                yearsAsync.error ?? termsAsync.error!,
              ),
              onRetry: () {
                ref.invalidate(academicYearsProvider);
                ref.invalidate(allTermsProvider);
              },
            )
          : _buildContent(
              context: context,
              ref: ref,
              academicYears: years,
              terms: terms,
              selectedTerm: selectedTerm,
              isBusy: isBusy,
            ),
    );
  }

  Widget _buildStructureOverflowMenu(
    BuildContext context, {
    required WidgetRef ref,
    required List<AcademicYear> academicYears,
    required AcademicYear selectedYear,
    required Term selectedTerm,
    required bool isBusy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    return PopupMenuButton<String>(
      tooltip: 'จัดการปีการศึกษาและเทอม',
      enabled: !isBusy,
      icon: Icon(Icons.more_horiz_rounded, color: colorScheme.onSurfaceVariant),
      onSelected: (value) {
        switch (value) {
          case 'add_year':
            _addYear(context, ref);
          case 'add_term':
            _addTerm(context, ref, academicYears, selectedYear.id);
          case 'edit_term':
            _editTerm(context, ref, academicYears, selectedTerm);
          case 'delete_term':
            _deleteTerm(context, ref, selectedTerm, selectedYear);
          case 'delete_year':
            _deleteYear(context, ref, selectedYear);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'add_year',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_month_outlined, size: 18),
            title: Text('เพิ่มปีการศึกษา'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'add_term',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.add_circle_outline_rounded, size: 18),
            title: Text('เพิ่มเทอม'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit_term',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined, size: 18),
            title: Text('แก้ไขเทอม'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete_term',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: semantic.danger,
            ),
            title: Text(
              'ลบเทอมนี้',
              style: TextStyle(color: semantic.danger),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete_year',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_forever_outlined,
              size: 18,
              color: semantic.danger,
            ),
            title: Text(
              'ลบปีการศึกษา ${selectedYear.yearBe}',
              style: TextStyle(color: semantic.danger),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required WidgetRef ref,
    required List<AcademicYear> academicYears,
    required List<Term> terms,
    required Term? selectedTerm,
    required bool isBusy,
  }) {
    if (academicYears.isEmpty) {
      return AppEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'เริ่มต้นสร้างปีการศึกษาแรก',
        description:
            'สร้างปีการศึกษา (พ.ศ.) เพื่อเริ่มต้นจัดการเทอม รายวิชา และห้องเรียน',
        actionLabel: 'เพิ่มปีการศึกษา',
        actionIcon: Icons.add_rounded,
        onAction: () => _addYear(context, ref),
      );
    }

    final activeTerm = ref.watch(activeTermProvider);

    if (terms.isEmpty || selectedTerm == null) {
      return AppEmptyState(
        icon: Icons.date_range_outlined,
        title: 'ยังไม่มีเทอมในปีการศึกษา ${academicYears.first.yearBe}',
        description:
            'เพิ่มเทอมพร้อมระบุวันเปิด-ปิดภาคเรียน เพื่อให้ระบบคำนวณเทอมปัจจุบันอัตโนมัติ',
        actionLabel: 'เพิ่มเทอมแรก',
        actionIcon: Icons.add_rounded,
        onAction: () =>
            _addTerm(context, ref, academicYears, academicYears.first.id),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TermSelectorHeader(
          academicYears: academicYears,
          terms: terms,
          selectedTerm: selectedTerm,
          activeTerm: activeTerm,
          isBusy: isBusy,
          onSelectTerm: (id) =>
              ref.read(selectedTermIdProvider.notifier).select(id),
          onTogglePinTerm: () => _togglePinTerm(context, ref, selectedTerm),
        ),
        const SizedBox(height: 20),
        TermSubjectsSection(term: selectedTerm, isBusy: isBusy),
      ],
    );
  }

  Future<void> _addSubject(
    BuildContext context,
    WidgetRef ref,
    Term term,
  ) async {
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

  Future<void> _addYear(BuildContext context, WidgetRef ref) async {
    final yearBe = await AcademicYearFormDialog.show(context);
    if (yearBe == null || !context.mounted) return;
    final created = await ref
        .read(academicStructureControllerProvider.notifier)
        .createAcademicYear(yearBe);
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เพิ่มปีการศึกษา ${created.yearBe} เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _addTerm(
    BuildContext context,
    WidgetRef ref,
    List<AcademicYear> years,
    String initialYearId,
  ) async {
    final result = await TermFormDialog.show(
      context,
      academicYears: years,
      initialYearId: initialYearId,
    );
    if (result == null || !context.mounted) return;
    final created = await ref
        .read(academicStructureControllerProvider.notifier)
        .createTerm(
          academicYearId: result.academicYearId,
          termLabel: result.termLabel,
          startDate: result.startDate,
          endDate: result.endDate,
        );
    if (created != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'เพิ่มเทอม ${created.termLabel} เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _editTerm(
    BuildContext context,
    WidgetRef ref,
    List<AcademicYear> years,
    Term term,
  ) async {
    final result = await TermFormDialog.show(
      context,
      academicYears: years,
      existingTerm: term,
    );
    if (result == null || !context.mounted) return;
    final updated = await ref
        .read(academicStructureControllerProvider.notifier)
        .updateTerm(
          termId: term.id,
          termLabel: result.termLabel,
          startDate: result.startDate,
          endDate: result.endDate,
        );
    if (updated != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'แก้ไขข้อมูลเทอมเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _togglePinTerm(
    BuildContext context,
    WidgetRef ref,
    Term term,
  ) async {
    final targetId = term.isPinnedActive ? null : term.id;
    final ok = await ref
        .read(academicStructureControllerProvider.notifier)
        .setPinnedActiveTerm(targetId);
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: targetId == null
            ? 'ปลดหมุดเทอมปัจจุบันแล้ว ระบบจะคำนวณตามช่วงวันที่อัตโนมัติ'
            : 'ปักหมุดเทอม ${term.termLabel} เป็นเทอมปัจจุบันเรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _deleteTerm(
    BuildContext context,
    WidgetRef ref,
    Term term,
    AcademicYear year,
  ) {
    final expected = 'เทอม ${term.termLabel}/${year.yearBe}';
    return confirmAndDeleteStructure(
      context: context,
      ref: ref,
      entityType: StructuralEntityType.term,
      entityId: term.id,
      title: 'ยืนยันการลบ$expected',
      description:
          'การลบเทอมจะลบรายวิชา ห้องเรียน คะแนน และคาบเช็คชื่อในเทอมนี้ทั้งหมดอย่างถาวร',
      expectedText: expected,
      onConfirmedDelete: () => ref
          .read(academicStructureControllerProvider.notifier)
          .deleteTerm(term.id),
    );
  }

  Future<void> _deleteYear(
    BuildContext context,
    WidgetRef ref,
    AcademicYear year,
  ) {
    return confirmAndDeleteStructure(
      context: context,
      ref: ref,
      entityType: StructuralEntityType.academicYear,
      entityId: year.id,
      title: 'ยืนยันการลบปีการศึกษา ${year.yearBe}',
      description:
          'การลบปีการศึกษาจะลบทุกเทอม รายวิชา ห้องเรียน และข้อมูลคะแนนทั้งหมดในปีนี้',
      expectedText: '${year.yearBe}',
      onConfirmedDelete: () => ref
          .read(academicStructureControllerProvider.notifier)
          .deleteAcademicYear(year.id),
    );
  }
}
