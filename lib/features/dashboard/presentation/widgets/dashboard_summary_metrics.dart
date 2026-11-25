import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/dashboard_overview.dart';

/// Compact 4-KPI summary strip (4 columns on desktop, 2×2 on mobile using
/// `LayoutBuilder` + intrinsic height — never fixed `childAspectRatio`).
class DashboardSummaryMetrics extends StatelessWidget {
  const DashboardSummaryMetrics({super.key, required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    final checkedValue = overview.todayClassesCount > 0
        ? '${overview.checkedScheduledTodayCount}/${overview.todayClassesCount}'
        : '${overview.checkedTodayCount}';

    final cards = <_KpiItem>[
      _KpiItem(
        icon: Icons.class_outlined,
        label: 'ห้องที่สอน',
        value: '${overview.totalClassesCount}',
        unit: 'ห้อง',
        accent: colorScheme.primary,
        container: colorScheme.primaryContainer,
      ),
      _KpiItem(
        icon: Icons.today_rounded,
        label: 'สอนวันนี้',
        value: '${overview.todayClassesCount}',
        unit: 'ห้อง',
        accent: semantic.leave,
        container: semantic.leaveContainer,
      ),
      _KpiItem(
        icon: Icons.fact_check_outlined,
        label: 'เช็คชื่อวันนี้แล้ว',
        value: checkedValue,
        unit: 'ห้อง',
        accent: semantic.success,
        container: semantic.successContainer,
      ),
      _KpiItem(
        icon: Icons.groups_outlined,
        label: 'นักเรียนทั้งหมด',
        value: '${overview.totalActiveStudentsCount}',
        unit: 'คน',
        accent: colorScheme.secondary,
        container: colorScheme.secondaryContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in cards)
              SizedBox(
                width: itemWidth,
                child: _KpiTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _KpiItem {
  const _KpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
    required this.container,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accent;
  final Color container;
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.container,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 19, color: item.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.unit,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
