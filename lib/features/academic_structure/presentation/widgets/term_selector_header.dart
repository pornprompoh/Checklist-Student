import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/term.dart';
import '../../domain/services/term_label_formatter.dart';

/// Clean 1-row inline term switcher + unified pin-status toggle control.
///
/// Expands the term dropdown up to `500px` on Desktop so full Buddhist Era
/// date ranges never truncate prematurely, and merges the active-pin badge and
/// pin/unpin button into a single cohesive toggle directly beside the dropdown.
class TermSelectorHeader extends StatelessWidget {
  const TermSelectorHeader({
    super.key,
    required this.academicYears,
    required this.terms,
    required this.selectedTerm,
    required this.activeTerm,
    required this.isBusy,
    required this.onSelectTerm,
    required this.onTogglePinTerm,
  });

  final List<AcademicYear> academicYears;
  final List<Term> terms;
  final Term selectedTerm;
  final Term? activeTerm;
  final bool isBusy;
  final ValueChanged<String> onSelectTerm;
  final VoidCallback onTogglePinTerm;

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

    final bool isPinned = selectedTerm.isPinnedActive;
    final bool isActiveAuto = !isPinned && activeTerm?.id == selectedTerm.id;
    final bool isPast = !isPinned && !isActiveAuto && selectedTerm.isPastTerm();

    final termDropdown = DropdownButtonFormField<String>(
      key: ValueKey<String>(selectedTerm.id),
      initialValue: selectedTerm.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'ปีการศึกษาและเทอม',
        prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        for (final term in terms)
          DropdownMenuItem<String>(
            value: term.id,
            child: Text(
              _termDisplayLabel(term, years),
              maxLines: 1,
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
    );

    final Widget pinToggleControl = isPinned
        ? Tooltip(
            message: 'คลิกเพื่อปลดหมุดและใช้วันที่อัตโนมัติ',
            child: Material(
              color: semantic.successContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: semantic.success.withValues(alpha: 0.35),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isBusy ? null : onTogglePinTerm,
                mouseCursor: isBusy
                    ? MouseCursor.defer
                    : SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: semantic.success,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'เทอมปัจจุบัน (ปักหมุด)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: semantic.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: semantic.success,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: isBusy ? null : onTogglePinTerm,
                icon: const Icon(Icons.push_pin_outlined, size: 16),
                label: const Text('ปักหมุดเป็นเทอมปัจจุบัน'),
              ),
              if (isActiveAuto)
                _StatusMetaTag(
                  icon: Icons.event_available_rounded,
                  label: selectedTerm.hasDateRange
                      ? 'เทอมปัจจุบัน (ตามช่วงวันที่)'
                      : 'เทอมปัจจุบัน (อัตโนมัติ)',
                  background: colorScheme.primaryContainer,
                  foreground: colorScheme.onPrimaryContainer,
                )
              else if (isPast)
                _StatusMetaTag(
                  icon: Icons.history_rounded,
                  label: 'เทอมย้อนหลัง',
                  background: semantic.warningContainer,
                  foreground: semantic.warning,
                ),
            ],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 680) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320,
                    maxWidth: 500,
                  ),
                  child: termDropdown,
                ),
              ),
              const SizedBox(width: 12),
              pinToggleControl,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            termDropdown,
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: pinToggleControl),
          ],
        );
      },
    );
  }
}

class _StatusMetaTag extends StatelessWidget {
  const _StatusMetaTag({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
