import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/term.dart';

/// Top header card for switching terms (current / historical), showing active
/// status badges, pinning active term, and triggering structural actions.
class TermSelectorHeader extends StatelessWidget {
  const TermSelectorHeader({
    super.key,
    required this.academicYears,
    required this.terms,
    required this.selectedTerm,
    required this.activeTerm,
    required this.isBusy,
    required this.onSelectTerm,
    required this.onAddYear,
    required this.onAddTerm,
    required this.onTogglePinTerm,
    required this.onEditTerm,
    required this.onDeleteTerm,
    required this.onDeleteYear,
  });

  final List<AcademicYear> academicYears;
  final List<Term> terms;
  final Term selectedTerm;
  final Term? activeTerm;
  final bool isBusy;
  final ValueChanged<String> onSelectTerm;
  final VoidCallback onAddYear;
  final VoidCallback onAddTerm;
  final VoidCallback onTogglePinTerm;
  final VoidCallback onEditTerm;
  final VoidCallback onDeleteTerm;
  final VoidCallback onDeleteYear;

  Map<String, AcademicYear> get _yearById => <String, AcademicYear>{
    for (final year in academicYears) year.id: year,
  };

  String _termDisplayLabel(Term term, Map<String, AcademicYear> years) {
    final yearBe = years[term.academicYearId]?.yearBe;
    final range = ThaiDateFormatter.formatDateRange(
      term.startDate,
      term.endDate,
    );
    final prefix = yearBe != null ? 'ปีการศึกษา $yearBe — ' : '';
    return '$prefixเทอม ${term.termLabel} ($range)';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final years = _yearById;
    final selectedYear = years[selectedTerm.academicYearId];

    final bool isPinned = selectedTerm.isPinnedActive;
    final bool isActiveByDate = !isPinned && activeTerm?.id == selectedTerm.id;
    final (String badgeText, Color badgeBg, Color badgeFg, IconData badgeIcon) =
        isPinned
        ? (
            'เทอมปัจจุบัน (ปักหมุด)',
            semantic.successContainer,
            semantic.success,
            Icons.push_pin_rounded,
          )
        : isActiveByDate
        ? (
            'เทอมปัจจุบัน (ตามช่วงวันที่)',
            colorScheme.primaryContainer,
            colorScheme.onPrimaryContainer,
            Icons.event_available_rounded,
          )
        : (
            'เทอมย้อนหลัง (ยังแก้ไขได้)',
            semantic.warningContainer,
            semantic.warning,
            Icons.history_rounded,
          );

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey<String>(selectedTerm.id),
            initialValue: selectedTerm.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'เลือกปีการศึกษาและเทอม',
              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            items: [
              for (final term in terms)
                DropdownMenuItem<String>(
                  value: term.id,
                  child: Text(
                    _termDisplayLabel(term, years),
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
            ],
            onChanged: isBusy
                ? null
                : (value) {
                    if (value != null) onSelectTerm(value);
                  },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 15, color: badgeFg),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        badgeText,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color: badgeFg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onTogglePinTerm,
                icon: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 18,
                ),
                label: Text(
                  isPinned
                      ? 'ปลดหมุด (ใช้วันที่อัตโนมัติ)'
                      : 'ปักหมุดเป็นเทอมปัจจุบัน',
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onAddYear,
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('เพิ่มปีการศึกษา'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onAddTerm,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('เพิ่มเทอม'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onEditTerm,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('แก้ไขเทอม'),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'ลบเทอมหรือปีการศึกษา',
                enabled: !isBusy,
                onSelected: (value) {
                  if (value == 'delete_term') onDeleteTerm();
                  if (value == 'delete_year') onDeleteYear();
                },
                itemBuilder: (context) => [
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
                  if (selectedYear != null)
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'จัดการลบ',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
