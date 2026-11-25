import 'package:flutter/material.dart';

import '../providers/dashboard_providers.dart';

/// Quick filter chips (`ทั้งหมด`, `สอนวันนี้`, `ปักหมุด`) and compact search
/// box rendered above the Teacher Dashboard classroom sections.
class DashboardFilterBar extends StatelessWidget {
  const DashboardFilterBar({
    super.key,
    required this.totalClassesCount,
    required this.todayClassesCount,
    required this.filterState,
    required this.searchController,
    required this.onModeChanged,
    required this.onQueryChanged,
    required this.onClearQuery,
  });

  final int totalClassesCount;
  final int todayClassesCount;
  final DashboardFilterState filterState;
  final TextEditingController searchController;
  final ValueChanged<DashboardFilterMode> onModeChanged;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: Text('ทั้งหมด ($totalClassesCount)'),
              selected: filterState.mode == DashboardFilterMode.all,
              onSelected: (_) => onModeChanged(DashboardFilterMode.all),
            ),
            ChoiceChip(
              label: Text('สอนวันนี้ ($todayClassesCount)'),
              selected: filterState.mode == DashboardFilterMode.today,
              onSelected: (_) => onModeChanged(DashboardFilterMode.today),
            ),
            ChoiceChip(
              label: const Text('ปักหมุด'),
              selected: filterState.mode == DashboardFilterMode.pinned,
              onSelected: (_) => onModeChanged(DashboardFilterMode.pinned),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'ค้นหารหัสวิชา ชื่อวิชา หรือห้อง...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: filterState.query.isNotEmpty
                  ? IconButton(
                      tooltip: 'ล้างคำค้นหา',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onClearQuery,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
