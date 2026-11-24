import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/term.dart';

/// Top header bar for switching terms (current / historical), showing active
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
    final (String badgeText, Color badgeBg, Color badgeFg) = isPinned
        ? ('เทอมปัจจุบัน (ปักหมุด)', semantic.successContainer, semantic.success)
        : isActiveByDate
        ? (
            'เทอมปัจจุบัน (ตามช่วงวันที่)',
            colorScheme.primaryContainer,
            colorScheme.onPrimaryContainer,
          )
        : (
            'เทอมย้อนหลัง (ยังแก้ไขได้)',
            semantic.warningContainer,
            semantic.warning,
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey<String>(selectedTerm.id),
              initialValue: selectedTerm.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'เลือกปีการศึกษาและเทอม',
              ),
              items: [
                for (final term in terms)
                  DropdownMenuItem<String>(
                    value: term.id,
                    child: Text(
                      _termDisplayLabel(term, years),
                      overflow: TextOverflow.ellipsis,
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
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: textTheme.labelMedium?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w600,
                    ),
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
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onAddYear,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('เพิ่มปีการศึกษา'),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onAddTerm,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('เพิ่มเทอม'),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onEditTerm,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('แก้ไขเทอม'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: semantic.danger,
                  ),
                  onPressed: isBusy ? null : onDeleteTerm,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('ลบเทอม'),
                ),
                if (selectedYear != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: semantic.danger,
                    ),
                    onPressed: isBusy ? null : onDeleteYear,
                    icon: const Icon(Icons.delete_forever_outlined, size: 18),
                    label: Text('ลบปี ${selectedYear.yearBe}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
