import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';

/// Clean top header for [TeacherDashboardPage] built on [AppPageHeader]:
/// greeting, Thai Buddhist Era date, compact pill term switcher, quick
/// "+ เพิ่มวิชา/ห้อง" CTA and refresh action.
class DashboardHeaderBar extends StatelessWidget {
  const DashboardHeaderBar({
    super.key,
    required this.teacherDisplayName,
    required this.today,
    required this.academicYears,
    required this.terms,
    required this.selectedTerm,
    required this.activeTermId,
    required this.isBusy,
    required this.onSelectTerm,
    required this.onRefresh,
    this.onAddClass,
  });

  final String teacherDisplayName;
  final DateTime today;
  final List<AcademicYear> academicYears;
  final List<Term> terms;
  final Term? selectedTerm;
  final String? activeTermId;
  final bool isBusy;
  final ValueChanged<String> onSelectTerm;
  final VoidCallback onRefresh;
  final VoidCallback? onAddClass;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final yearById = {for (final y in academicYears) y.id: y};
    final isViewingActiveTerm =
        selectedTerm != null && selectedTerm!.id == activeTermId;
    final todayThaiLabel =
        'วัน${ThaiDateFormatter.weekdayThaiName(today.weekday)}ที่ '
        '${ThaiDateFormatter.formatShortDate(today)}';

    return AppPageHeader(
      title: 'สวัสดี, $teacherDisplayName',
      subtitle: todayThaiLabel,
      actions: [
        if (terms.isNotEmpty && selectedTerm != null)
          _TermPickerPill(
            selectedTerm: selectedTerm!,
            terms: terms,
            yearById: yearById,
            activeTermId: activeTermId,
            isViewingActiveTerm: isViewingActiveTerm,
            enabled: !isBusy,
            onSelectTerm: onSelectTerm,
          ),
        if (onAddClass != null)
          FilledButton.tonalIcon(
            onPressed: onAddClass,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'เพิ่มวิชา/ห้อง',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        IconButton(
          tooltip: 'รีเฟรชข้อมูลหน้าหลัก',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surface,
            side: BorderSide(color: colorScheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isBusy ? null : onRefresh,
          icon: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: isBusy ? colorScheme.onSurfaceVariant : semantic.leave,
          ),
        ),
      ],
    );
  }
}

class _TermPickerPill extends StatelessWidget {
  const _TermPickerPill({
    required this.selectedTerm,
    required this.terms,
    required this.yearById,
    required this.activeTermId,
    required this.isViewingActiveTerm,
    required this.enabled,
    required this.onSelectTerm,
  });

  final Term selectedTerm;
  final List<Term> terms;
  final Map<String, AcademicYear> yearById;
  final String? activeTermId;
  final bool isViewingActiveTerm;
  final bool enabled;
  final ValueChanged<String> onSelectTerm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final yearBe = yearById[selectedTerm.academicYearId]?.yearBe;
    final compactLabel = yearBe != null
        ? 'เทอม ${selectedTerm.termLabel}/$yearBe'
        : 'เทอม ${selectedTerm.termLabel}';

    return PopupMenuButton<String>(
      enabled: enabled,
      tooltip: 'สลับภาคเรียน',
      onSelected: onSelectTerm,
      itemBuilder: (context) => [
        for (final term in terms)
          PopupMenuItem<String>(
            value: term.id,
            child: Row(
              children: [
                Icon(
                  term.id == selectedTerm.id
                      ? Icons.check_rounded
                      : Icons.school_outlined,
                  size: 18,
                  color: term.id == selectedTerm.id
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTermHeadline(term),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                      Text(
                        ThaiDateFormatter.formatDateRange(
                          term.startDate,
                          term.endDate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isViewingActiveTerm
                      ? semantic.success
                      : colorScheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isViewingActiveTerm
                      ? '$compactLabel (ปัจจุบัน)'
                      : '$compactLabel (ย้อนหลัง)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTermHeadline(Term term) {
    final yearBe = yearById[term.academicYearId]?.yearBe;
    final yearPart = yearBe != null ? 'ปีการศึกษา $yearBe ' : '';
    final activeTag = term.id == activeTermId ? ' (ปัจจุบัน)' : '';
    return '$yearPartเทอม ${term.termLabel}$activeTag';
  }
}
