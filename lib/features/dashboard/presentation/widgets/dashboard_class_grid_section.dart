import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_class_item.dart';
import '../../domain/entities/dashboard_overview.dart';
import 'dashboard_class_card.dart';

/// Responsive 1/2/3-column classroom card grid where cards in the same
/// multi-column row share identical height via [IntrinsicHeight] and aligned
/// footer actions.
class DashboardClassGridSection extends StatelessWidget {
  const DashboardClassGridSection({
    super.key,
    this.heading,
    this.headingAccent,
    required this.items,
    required this.overview,
    required this.isBusy,
    required this.onTogglePin,
  });

  final String? heading;
  final Color? headingAccent;
  final List<DashboardClassItem> items;
  final DashboardOverview overview;
  final bool isBusy;
  final ValueChanged<DashboardClassItem> onTogglePin;

  @override
  Widget build(BuildContext context) {
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1020
            ? 3
            : (constraints.maxWidth >= 660 ? 2 : 1);

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildCard(context, items[i]),
              ],
            ],
          );
        }

        final rowCount = (items.length / columns).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < rowCount; row++) ...[
              if (row > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < columns; col++) ...[
                      if (col > 0) const SizedBox(width: 12),
                      Expanded(
                        child: (row * columns + col) < items.length
                            ? _buildCard(context, items[row * columns + col])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );

    if (heading == null) {
      return grid;
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: headingAccent ?? colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                heading!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        grid,
      ],
    );
  }

  Widget _buildCard(BuildContext context, DashboardClassItem item) {
    return DashboardClassCard(
      item: item,
      todayIsoWeekday: overview.referenceDate.weekday,
      isBusy: isBusy,
      onTogglePin: () => onTogglePin(item),
      onOpenAttendance: () => context.go(
        AppRoutes.teacherAttendanceForClass(item.subjectClassId),
      ),
      onOpenGradingTable: () => context.go(
        AppRoutes.teacherGradingForClass(item.subjectClassId),
      ),
      onOpenGradingPlan: () => context.go(
        AppRoutes.teacherGradingPlanForClass(item.subjectClassId),
      ),
      onOpenAttendanceRules: () => context.go(
        AppRoutes.teacherAttendanceRulesForClass(item.subjectClassId),
      ),
      onOpenExportReports: () => context.go(
        AppRoutes.teacherExportReportsForClass(item.subjectClassId),
      ),
      onOpenAuditLog: () => context.go(
        AppRoutes.teacherAuditLogForClass(item.subjectClassId),
      ),
      onOpenRoster: () => context.go(AppRoutes.teacherHomeroomRoster),
    );
  }
}
