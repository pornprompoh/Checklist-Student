import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/class_workspace_bar.dart';
import '../providers/grading_filter_provider.dart';
import '../providers/grading_providers.dart';
import '../providers/grading_table_state.dart';
import 'save_status_indicator.dart';

enum _TableOverflowAction {
  planPage,
  auditLog,
  exportReports,
  toggleTransferredOut,
}

/// Compact, uncluttered toolbar for [GradingTablePage]:
/// - Workspace bar (`เช็คชื่อ · ตารางคะแนน · แผนเก็บงาน · ส่งออกรายงาน`)
/// - Row 1: Class Switcher + Segmented `พรีวิว / แก้ไข` toggle + Save status + `⋯`
/// - Row 2: Search input + horizontally scrollable quick filter chips
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
    final validClassId =
        classOptions.any((opt) => opt.subjectClassId == selectedClassId)
        ? selectedClassId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPageHeader(
          title: 'ตารางคะแนนและเกรด',
          bottom: validClassId == null
              ? null
              : ClassWorkspaceBar(
                  subjectClassId: validClassId,
                  activeTab: ClassWorkspaceTab.grading,
                ),
        ),
        const SizedBox(height: 12),
        AppSurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String?>(validClassId),
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
                      _ModeSegmentedToggle(
                        isEditMode: isEditMode,
                        onToggle: onToggleEditMode,
                      ),
                      _buildOverflowMenu(context),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final searchField = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'ค้นหาชื่อ, รหัส หรือเลขที่...',
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  );

                  final filterStrip = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (
                          var i = 0;
                          i < GradingQuickFilter.values.length;
                          i++
                        ) ...[
                          if (i > 0) const SizedBox(width: 8),
                          FilterChip(
                            selected:
                                filterState.quickFilter ==
                                GradingQuickFilter.values[i],
                            label: Text(
                              '${GradingQuickFilter.values[i].thaiLabel} (${filterCounts[GradingQuickFilter.values[i]] ?? 0})',
                              style: const TextStyle(
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            onSelected: (_) =>
                                onSelectFilter(GradingQuickFilter.values[i]),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  );

                  if (constraints.maxWidth >= 720) {
                    return Row(
                      children: [
                        searchField,
                        const SizedBox(width: 12),
                        Expanded(child: filterStrip),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 8),
                      filterStrip,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverflowMenu(BuildContext context) {
    return PopupMenuButton<_TableOverflowAction>(
      tooltip: 'ตัวเลือกตารางคะแนน',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (action) {
        switch (action) {
          case _TableOverflowAction.planPage:
            onOpenPlanPage();
          case _TableOverflowAction.auditLog:
            onOpenAuditLog?.call();
          case _TableOverflowAction.exportReports:
            onOpenExportReports?.call();
          case _TableOverflowAction.toggleTransferredOut:
            onToggleShowTransferredOut(!filterState.showTransferredOut);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _TableOverflowAction.planPage,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.assignment_outlined),
            title: Text('ออกแบบแผนงาน / เกณฑ์'),
          ),
        ),
        if (onOpenAuditLog != null)
          const PopupMenuItem(
            value: _TableOverflowAction.auditLog,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history_rounded),
              title: Text('ประวัติคะแนน'),
            ),
          ),
        if (onOpenExportReports != null)
          const PopupMenuItem(
            value: _TableOverflowAction.exportReports,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.file_download_outlined),
              title: Text('ส่งออกรายงาน'),
            ),
          ),
        if (transferredOutCount > 0) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _TableOverflowAction.toggleTransferredOut,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                filterState.showTransferredOut
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              title: Text(
                filterState.showTransferredOut
                    ? 'ซ่อนผู้ย้ายออก ($transferredOutCount)'
                    : 'แสดงผู้ย้ายออก ($transferredOutCount)',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeSegmentedToggle extends StatelessWidget {
  const _ModeSegmentedToggle({
    required this.isEditMode,
    required this.onToggle,
  });

  final bool isEditMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    Widget buildPart({
      required bool active,
      required IconData icon,
      required String label,
      required Color activeBg,
      required Color activeFg,
    }) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? activeFg : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: active ? activeFg : colorScheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isEditMode
              ? semantic.warning.withValues(alpha: 0.6)
              : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildPart(
                active: !isEditMode,
                icon: Icons.visibility_outlined,
                label: 'พรีวิว',
                activeBg: colorScheme.surface,
                activeFg: colorScheme.onSurface,
              ),
              buildPart(
                active: isEditMode,
                icon: Icons.edit_rounded,
                label: 'แก้ไข',
                activeBg: semantic.warningContainer,
                activeFg: semantic.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
