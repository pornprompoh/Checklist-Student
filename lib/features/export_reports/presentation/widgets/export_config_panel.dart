import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../domain/entities/export_options.dart';
import '../../domain/entities/export_orientation.dart';
import '../../domain/entities/export_section.dart';

/// Left-side configuration panel for `ExportReportsPage`: term & class picker,
/// 4 independent report sections, A4 orientation selector, and extra toggles.
class ExportConfigPanel extends StatelessWidget {
  const ExportConfigPanel({
    super.key,
    required this.academicYears,
    required this.terms,
    required this.selectedTermId,
    required this.classOptionsInTerm,
    required this.selectedClassId,
    required this.options,
    required this.orientationDecision,
    required this.onSelectTerm,
    required this.onSelectClass,
    required this.onToggleSection,
    required this.onSelectOrientationMode,
    required this.onToggleTransferredOut,
    required this.onToggleSignatureLines,
  });

  final List<AcademicYear> academicYears;
  final List<Term> terms;
  final String? selectedTermId;
  final List<CopyPlanSourceClassOption> classOptionsInTerm;
  final String? selectedClassId;
  final ExportOptions options;
  final OrientationDecision? orientationDecision;
  final ValueChanged<String> onSelectTerm;
  final ValueChanged<String> onSelectClass;
  final ValueChanged<ExportSection> onToggleSection;
  final ValueChanged<ExportOrientationMode> onSelectOrientationMode;
  final ValueChanged<bool> onToggleTransferredOut;
  final ValueChanged<bool> onToggleSignatureLines;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final yearBeById = <String, int>{
      for (final y in academicYears) y.id: y.yearBe,
    };

    final validTermId = terms.any((t) => t.id == selectedTermId)
        ? selectedTermId
        : null;
    final validClassId = classOptionsInTerm.any(
      (c) => c.subjectClassId == selectedClassId,
    )
        ? selectedClassId
        : null;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '1. เลือกห้องเรียนและหัวข้อรายงาน',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String?>('term_$validTermId'),
              initialValue: validTermId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'ภาคเรียน / ปีการศึกษา (พ.ศ.)',
                isDense: true,
              ),
              items: [
                for (final term in terms)
                  DropdownMenuItem<String>(
                    value: term.id,
                    child: Text(
                      'เทอม ${term.termLabel} / พ.ศ. ${yearBeById[term.academicYearId] ?? '-'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null && value != validTermId) {
                  onSelectTerm(value);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey<String?>('class_$validClassId'),
              initialValue: validClassId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'รายวิชาและห้องเรียน',
                isDense: true,
              ),
              items: [
                for (final opt in classOptionsInTerm)
                  DropdownMenuItem<String>(
                    value: opt.subjectClassId,
                    child: Text(
                      opt.displayLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null && value != validClassId) {
                  onSelectClass(value);
                }
              },
            ),
            const Divider(height: 24),
            Text(
              'เลือกหัวข้อที่ต้องการส่งออก (อย่างน้อย 1 หัวข้อ)',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final section in ExportSection.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  section.thaiTitle,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  section.shortDescription,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: options.hasSection(section),
                onChanged: (_) => onToggleSection(section),
              ),
            const Divider(height: 22),
            Text(
              'แนวกระดาษ A4',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ExportOrientationMode>(
              showSelectedIcon: false,
              segments: [
                for (final mode in ExportOrientationMode.values)
                  ButtonSegment<ExportOrientationMode>(
                    value: mode,
                    label: Text(
                      mode.thaiLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
              selected: <ExportOrientationMode>{options.orientationMode},
              onSelectionChanged: (sel) => onSelectOrientationMode(sel.first),
            ),
            if (orientationDecision != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      orientationDecision!.orientation ==
                              ExportPageOrientation.landscape
                          ? Icons.crop_landscape_rounded
                          : Icons.crop_portrait_rounded,
                      size: 18,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${orientationDecision!.orientation.dimensionThaiLabel} — '
                        '${orientationDecision!.reasonThai}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 22),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('รวมรายชื่อนักเรียนย้ายออก'),
              subtitle: Text(
                'ค่าเริ่มต้นซ่อนไว้เพื่อไม่ให้เลขที่ชนกับนักเรียนปัจจุบัน',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: options.includeTransferredOut,
              onChanged: onToggleTransferredOut,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('แสดงช่องลงนามท้ายเอกสาร'),
              subtitle: Text(
                'ครูผู้สอน · หัวหน้ากลุ่มสาระฯ · ผู้อำนวยการสถานศึกษา',
                style: textTheme.bodySmall?.copyWith(
                  color: semantic.success,
                ),
              ),
              value: options.includeSignatureLines,
              onChanged: onToggleSignatureLines,
            ),
          ],
        ),
      ),
    );
  }
}
