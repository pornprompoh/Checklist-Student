import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../providers/grading_filter_provider.dart';
import '../providers/grading_providers.dart';
import '../providers/grading_table_state.dart';
import 'save_status_indicator.dart';

/// Responsive toolbar for `GradingTablePage`: class switcher, Preview/Edit mode
/// toggle, auto-save status indicator, search field, and quick filter chips.
class GradingTableToolbar extends StatelessWidget {
  const GradingTableToolbar({
    super.key,
    required this.classOptions,
    required this.selectedClassId,
    required this.isEditMode,
    required this.saveStatus,
    required this.lastSavedAt,
    required this.filterState,
    required this.filterCounts,
    required this.transferredOutCount,
    required this.searchController,
    required this.onSelectClass,
    required this.onOpenPlanPage,
    this.onOpenAuditLog,
    this.onOpenExportReports,
    required this.onToggleEditMode,
    required this.onRetrySave,
    required this.onReloadLatest,
    required this.onSearchChanged,
    required this.onSelectFilter,
    required this.onToggleShowTransferredOut,
  });

  final List<CopyPlanSourceClassOption> classOptions;
  final String? selectedClassId;
  final bool isEditMode;
  final CellSaveStatus saveStatus;
  final DateTime? lastSavedAt;
  final GradingFilterState filterState;
  final Map<GradingQuickFilter, int> filterCounts;
  final int transferredOutCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSelectClass;
  final VoidCallback onOpenPlanPage;
  final VoidCallback? onOpenAuditLog;
  final VoidCallback? onOpenExportReports;
  final VoidCallback onToggleEditMode;
  final VoidCallback onRetrySave;
  final VoidCallback onReloadLatest;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<GradingQuickFilter> onSelectFilter;
  final ValueChanged<bool> onToggleShowTransferredOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final validClassId = classOptions.any(
      (opt) => opt.subjectClassId == selectedClassId,
    )
        ? selectedClassId
        : null;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340, minWidth: 200),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey<String?>(validClassId),
                    initialValue: validClassId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'ห้องเรียน',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      for (final option in classOptions)
                        DropdownMenuItem<String>(
                          value: option.subjectClassId,
                          child: Text(
                            '${option.displayLabel} (${option.termLabel}/${option.academicYearBe})',
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
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SaveStatusIndicator(
                      status: saveStatus,
                      lastSavedAt: lastSavedAt,
                      onRetry: onRetrySave,
                      onReloadLatest: onReloadLatest,
                    ),
                    if (isEditMode)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: semantic.warning,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        onPressed: onToggleEditMode,
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('โหมดแก้ไข (กดเพื่อพรีวิว)'),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: onToggleEditMode,
                        icon: const Icon(Icons.visibility_outlined, size: 17),
                        label: const Text('โหมดพรีวิว · กดเพื่อแก้ไข'),
                      ),
                    OutlinedButton.icon(
                      onPressed: onOpenPlanPage,
                      icon: const Icon(Icons.assignment_outlined, size: 17),
                      label: const Text('ออกแบบแผนงาน / เกณฑ์'),
                    ),
                    if (onOpenAuditLog != null)
                      OutlinedButton.icon(
                        onPressed: onOpenAuditLog,
                        icon: const Icon(Icons.history_rounded, size: 17),
                        label: const Text('ประวัติคะแนน'),
                      ),
                    if (onOpenExportReports != null)
                      OutlinedButton.icon(
                        onPressed: onOpenExportReports,
                        icon: const Icon(Icons.file_download_outlined, size: 17),
                        label: const Text('ส่งออกรายงาน'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280, minWidth: 180),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'ค้นหาชื่อ, รหัสนักเรียน หรือเลขที่...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: filterState.searchQuery.isEmpty
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
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                for (final chip in GradingQuickFilter.values)
                  FilterChip(
                    selected: filterState.quickFilter == chip,
                    label: Text(
                      '${chip.thaiLabel} (${filterCounts[chip] ?? 0})',
                    ),
                    onSelected: (_) => onSelectFilter(chip),
                    visualDensity: VisualDensity.compact,
                  ),
                if (transferredOutCount > 0)
                  FilterChip(
                    selected: filterState.showTransferredOut,
                    label: Text('แสดงผู้ย้ายออก ($transferredOutCount)'),
                    onSelected: onToggleShowTransferredOut,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
