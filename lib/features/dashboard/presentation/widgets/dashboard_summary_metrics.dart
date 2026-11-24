import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/dashboard_overview.dart';

/// Responsive 4-metric summary strip displaying today's schedule progress and
/// term totals cleanly from 390px mobile to desktop.
class DashboardSummaryMetrics extends StatelessWidget {
  const DashboardSummaryMetrics({super.key, required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    final checkedValue = overview.todayClassesCount > 0
        ? '${overview.checkedScheduledTodayCount} / ${overview.todayClassesCount} ห้อง'
        : '${overview.checkedTodayCount} ห้อง';

    final cards = <_MetricData>[
      _MetricData(
        icon: Icons.today_rounded,
        label: 'มีสอนวันนี้',
        value: '${overview.todayClassesCount} ห้อง',
        accent: colorScheme.primary,
        container: colorScheme.primaryContainer,
      ),
      _MetricData(
        icon: Icons.fact_check_outlined,
        label: 'เช็คชื่อแล้ววันนี้',
        value: checkedValue,
        accent: semantic.success,
        container: semantic.successContainer,
      ),
      _MetricData(
        icon: Icons.class_outlined,
        label: 'ห้องทั้งหมดในเทอม',
        value: '${overview.totalClassesCount} ห้อง',
        accent: colorScheme.secondary,
        container: colorScheme.secondaryContainer,
      ),
      _MetricData(
        icon: Icons.groups_outlined,
        label: 'นักเรียนกำลังเรียน',
        value: '${overview.totalActiveStudentsCount} คน',
        accent: semantic.leave,
        container: semantic.leaveContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
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
                child: _MetricCard(data: item),
              ),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.container,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color container;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: data.container,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, size: 18, color: data.accent),
            ),
            const SizedBox(height: 10),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
