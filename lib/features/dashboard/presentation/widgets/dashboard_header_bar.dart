import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';

/// Top header bar on the Teacher Dashboard displaying greeting, today's Thai
/// Buddhist Era date, active/past term badge, term switcher, and refresh button.
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final yearById = {for (final y in academicYears) y.id: y};
    final isViewingActiveTerm =
        selectedTerm != null && selectedTerm!.id == activeTermId;

    final todayThaiLabel =
        'วัน${ThaiDateFormatter.weekdayThaiName(today.weekday)}ที่ '
        '${ThaiDateFormatter.formatShortDate(today)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สวัสดี, $teacherDisplayName',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                todayThaiLabel,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (selectedTerm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isViewingActiveTerm
                                    ? semantic.successContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                isViewingActiveTerm
                                    ? 'เทอมปัจจุบัน'
                                    : 'เทอมย้อนหลัง',
                                style: textTheme.labelSmall?.copyWith(
                                  color: isViewingActiveTerm
                                      ? semantic.success
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'รีเฟรชข้อมูลหน้าหลัก',
                  onPressed: isBusy ? null : onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
            if (terms.isNotEmpty && selectedTerm != null) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(selectedTerm!.id),
                initialValue: selectedTerm!.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ภาคเรียนที่กำลังแสดง',
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                ),
                items: [
                  for (final term in terms)
                    DropdownMenuItem<String>(
                      value: term.id,
                      child: Text(
                        _formatTermOption(term, yearById, activeTermId),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: isBusy
                    ? null
                    : (id) {
                        if (id != null) {
                          onSelectTerm(id);
                        }
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTermOption(
    Term term,
    Map<String, AcademicYear> yearById,
    String? activeTermId,
  ) {
    final yearBe = yearById[term.academicYearId]?.yearBe;
    final yearPart = yearBe != null ? 'ปีการศึกษา $yearBe ' : '';
    final activeTag = term.id == activeTermId ? ' (ปัจจุบัน)' : '';
    return '${yearPart}เทอม ${term.termLabel}$activeTag · '
        '${ThaiDateFormatter.formatDateRange(term.startDate, term.endDate)}';
  }
}
