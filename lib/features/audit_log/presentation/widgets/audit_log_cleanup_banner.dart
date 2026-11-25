import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/audit_log_providers.dart';

/// Non-intrusive warning banner shown on `TeacherDashboardPage` (and
/// `AuditLogPage`) ONLY when past academic years or near-1-year-expiry audit
/// logs exist, prompting teachers to Export CSV/JSON before yearly cleanup.
class AuditLogCleanupBanner extends ConsumerWidget {
  const AuditLogCleanupBanner({super.key, this.showNavigationAction = true});

  final bool showNavigationAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(auditLogCleanupAlertsProvider);
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final totalLogs = alerts.fold<int>(
      0,
      (sum, item) => sum + item.summary.totalLogsCount,
    );
    final yearLabels = alerts.map((a) => 'พ.ศ. ${a.summary.yearBe}').join(', ');

    return Material(
      color: semantic.warningContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: semantic.warning.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: semantic.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'แนะนำสำรองและล้างประวัติคะแนนประจำปี ($yearLabels)',
                        style: textTheme.titleSmall?.copyWith(
                          color: semantic.warning,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'พบประวัติการแก้ไข $totalLogs รายการของปีเก่าหรือใกล้ครบอายุ 1 ปี '
                        'แนะนำให้ Export CSV/JSON สำรองเก็บไว้ก่อนล้าง Log (คะแนนจริงไม่ถูกลบ)',
                        style: textTheme.bodySmall?.copyWith(
                          color: semantic.warning,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showNavigationAction)
              FilledButton.tonalIcon(
                onPressed: () =>
                    GoRouter.maybeOf(context)?.go(AppRoutes.teacherAuditLog),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('จัดการ / Export Log'),
              ),
          ],
        ),
      ),
    );
  }
}
