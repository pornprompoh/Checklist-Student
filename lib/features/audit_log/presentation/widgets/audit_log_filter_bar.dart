import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../domain/entities/audit_log_filter.dart';
import '../../domain/entities/audit_log_target_type.dart';

/// Responsive filter & export bar for `AuditLogPage`.
class AuditLogFilterBar extends StatelessWidget {
  const AuditLogFilterBar({
    super.key,
    required this.filter,
    required this.academicYears,
    required this.classOptions,
    required this.searchController,
    required this.filteredCount,
    required this.isBusy,
    required this.onYearChanged,
    required this.onClassChanged,
    required this.onClearEnrollmentFilter,
    required this.onTargetTypeChanged,
    required this.onSearchChanged,
    required this.onExportCsv,
    required this.onExportJson,
  });

  final AuditLogFilter filter;
  final List<AcademicYear> academicYears;
  final List<CopyPlanSourceClassOption> classOptions;
  final TextEditingController searchController;
  final int filteredCount;
  final bool isBusy;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onClassChanged;
  final VoidCallback onClearEnrollmentFilter;
  final ValueChanged<AuditLogTargetType?> onTargetTypeChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onExportCsv;
  final VoidCallback onExportJson;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final validYearId = academicYears.any((y) => y.id == filter.academicYearId)
        ? filter.academicYearId
        : null;
    final validClassId =
        classOptions.any((c) => c.subjectClassId == filter.subjectClassId)
        ? filter.subjectClassId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180, minWidth: 0),
              child: DropdownButtonFormField<String?>(
                key: ValueKey<String?>('year_$validYearId'),
                initialValue: validYearId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ปีการศึกษา (พ.ศ.)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ทุกปีการศึกษา'),
                  ),
                  for (final year in academicYears)
                    DropdownMenuItem<String?>(
                      value: year.id,
                      child: Text(
                        'พ.ศ. ${year.yearBe}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                ],
                onChanged: onYearChanged,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260, minWidth: 0),
              child: DropdownButtonFormField<String?>(
                key: ValueKey<String?>('class_$validClassId'),
                initialValue: validClassId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ห้องเรียน',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ทุกห้องเรียน'),
                  ),
                  for (final opt in classOptions)
                    DropdownMenuItem<String?>(
                      value: opt.subjectClassId,
                      child: Text(
                        '${opt.displayLabel} (${opt.termLabel}/${opt.academicYearBe})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: onClassChanged,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240, minWidth: 0),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'ค้นหาชื่อ, รหัส, เลขที่, งาน...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: filter.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างคำค้นหา',
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                FilterChip(
                  selected: filter.targetType == null,
                  label: const Text('ทั้งหมด'),
                  onSelected: (_) => onTargetTypeChanged(null),
                  visualDensity: VisualDensity.compact,
                ),
                for (final type in AuditLogTargetType.values)
                  FilterChip(
                    selected: filter.targetType == type,
                    label: Text(type.thaiLabel),
                    onSelected: (_) => onTargetTypeChanged(type),
                    visualDensity: VisualDensity.compact,
                  ),
                if (filter.enrollmentId != null)
                  InputChip(
                    label: const Text('กรองเฉพาะนักเรียนที่เลือก'),
                    onDeleted: onClearEnrollmentFilter,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy || filteredCount == 0 ? null : onExportCsv,
                  icon: const Icon(Icons.table_view_outlined, size: 17),
                  label: Text(
                    'Export CSV ($filteredCount)',
                    style: const TextStyle(
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy || filteredCount == 0 ? null : onExportJson,
                  icon: const Icon(Icons.data_object_rounded, size: 17),
                  label: const Text('Export JSON'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
