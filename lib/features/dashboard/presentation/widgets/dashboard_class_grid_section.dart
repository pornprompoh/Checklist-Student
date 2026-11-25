import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../domain/entities/dashboard_class_item.dart';
import '../../domain/entities/dashboard_overview.dart';
import 'dashboard_class_card.dart';

/// Responsive 1/2/3-column classroom card grid with an optional section heading
/// (used for "คาบสอนวันนี้" and "ห้องเรียนทั้งหมดในเทอมนี้").
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
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: DashboardClassCard(
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
                    AppRoutes.teacherAttendanceRulesForClass(
                      item.subjectClassId,
                    ),
                  ),
                  onOpenExportReports: () => context.go(
                    AppRoutes.teacherExportReportsForClass(item.subjectClassId),
                  ),
                  onOpenAuditLog: () => context.go(
                    AppRoutes.teacherAuditLogForClass(item.subjectClassId),
                  ),
                  onOpenRoster: () =>
                      context.go(AppRoutes.teacherHomeroomRoster),
                ),
              ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        grid,
      ],
    );
  }
}
