import 'package:flutter/material.dart';

import '../providers/dashboard_providers.dart';

/// Quick filter chips (`ทั้งหมด`, `มีสอนวันนี้`, `ปักหมุด`) and compact search
/// input rendered above the Teacher Dashboard classroom grid.
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
      spacing: 8,
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
              label: Text('มีสอนวันนี้ ($todayClassesCount)'),
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

/// Friendly Thai empty-state card used when no terms, no classes, or no
/// filtered results exist on the Teacher Dashboard.
class DashboardEmptyStateCard extends StatelessWidget {
  const DashboardEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 42, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
