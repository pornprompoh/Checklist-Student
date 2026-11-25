import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/term.dart';
import '../../domain/services/term_label_formatter.dart';

/// Flat 1-row control bar for switching terms, showing active status, pinning
/// the active term, and accessing structural actions (`⋯` menu).
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
    return TermLabelFormatter.formatFullLabel(
      term,
      academicYearBe: years[term.academicYearId]?.yearBe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final years = _yearById;
    final selectedYear = years[selectedTerm.academicYearId];

    final bool isPinned = selectedTerm.isPinnedActive;
    final bool isActiveAuto = !isPinned && activeTerm?.id == selectedTerm.id;
    final bool isPast = selectedTerm.isPastTerm();
    final (String badgeText, Color badgeBg, Color badgeFg, IconData badgeIcon) =
        isPinned
        ? (
            'เทอมปัจจุบัน (ปักหมุด)',
            semantic.successContainer,
            semantic.success,
            Icons.push_pin_rounded,
          )
        : isActiveAuto
        ? (
            selectedTerm.hasDateRange
                ? 'เทอมปัจจุบัน (ตามช่วงวันที่)'
                : 'เทอมปัจจุบัน (อัตโนมัติ)',
            colorScheme.primaryContainer,
            colorScheme.onPrimaryContainer,
            Icons.event_available_rounded,
          )
        : isPast
        ? (
            'เทอมย้อนหลัง (ยังแก้ไขได้)',
            semantic.warningContainer,
            semantic.warning,
            Icons.history_rounded,
          )
        : (
            'เทอมอื่น (ยังแก้ไขได้)',
            colorScheme.surfaceContainer,
            colorScheme.onSurfaceVariant,
            Icons.calendar_today_outlined,
          );

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: DropdownButtonFormField<String>(
                key: ValueKey<String>(selectedTerm.id),
                initialValue: selectedTerm.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ปีการศึกษาและเทอม',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: isBusy ? null : onTogglePinTerm,
              icon: Icon(
                isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                size: 16,
              ),
              label: Text(
                isPinned ? 'ปลดหมุด' : 'ปักหมุดเป็นเทอมปัจจุบัน',
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'จัดการปีการศึกษาและเทอม',
              enabled: !isBusy,
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'add_year':
                    onAddYear();
                  case 'add_term':
                    onAddTerm();
                  case 'edit_term':
                    onEditTerm();
                  case 'delete_term':
                    onDeleteTerm();
                  case 'delete_year':
                    onDeleteYear();
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
            ),
          ],
        ),
      ],
    );
  }
}
