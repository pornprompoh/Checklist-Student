import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/dashboard_class_item.dart';
import 'dashboard_attendance_badge.dart';
import 'dashboard_class_card_menu.dart';

/// Scannable classroom card for [TeacherDashboardPage]:
/// - Top row: subject code pill + bold room name + "สอนวันนี้" pill + pin + `⋯`
/// - Middle: subject name + student/schedule meta + today's attendance status
/// - Bottom: clear 2-button hierarchy (`เช็คชื่อวันนี้`/`ดูเช็คชื่อ` + `ตารางคะแนน`)
class DashboardClassCard extends StatelessWidget {
  const DashboardClassCard({
    super.key,
    required this.item,
    required this.todayIsoWeekday,
    required this.isBusy,
    required this.onTogglePin,
    required this.onOpenAttendance,
    required this.onOpenGradingTable,
    required this.onOpenGradingPlan,
    required this.onOpenAttendanceRules,
    required this.onOpenExportReports,
    required this.onOpenAuditLog,
    required this.onOpenRoster,
  });

  final DashboardClassItem item;
  final int todayIsoWeekday;
  final bool isBusy;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenGradingTable;
  final VoidCallback onOpenGradingPlan;
  final VoidCallback onOpenAttendanceRules;
  final VoidCallback onOpenExportReports;
  final VoidCallback onOpenAuditLog;
  final VoidCallback onOpenRoster;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final teachesToday = item.teachesOnWeekday(todayIsoWeekday);
    final isChecked = item.todayAttendance != null;

    return AppSurfaceCard(
      borderColor: teachesToday
          ? colorScheme.primary.withValues(alpha: 0.45)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DashboardTagPill(
                          label: item.subjectCode,
                          background: colorScheme.primaryContainer,
                          foreground: colorScheme.onPrimaryContainer,
                        ),
                        if (teachesToday)
                          DashboardTagPill(
                            label: 'สอนวันนี้',
                            icon: Icons.circle,
                            background: semantic.successContainer,
                            foreground: semantic.success,
                          ),
                        if (item.isPinned)
                          DashboardTagPill(
                            label: 'ปักหมุด',
                            background: colorScheme.secondaryContainer,
                            foreground: colorScheme.onSecondaryContainer,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ห้อง ${item.roomName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: item.isPinned ? 'ยกเลิกปักหมุด' : 'ปักหมุดห้องนี้',
                visualDensity: VisualDensity.compact,
                onPressed: isBusy ? null : onTogglePin,
                icon: Icon(
                  item.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 19,
                  color: item.isPinned
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              DashboardClassCardMenu(
                isPinned: item.isPinned,
                isBusy: isBusy,
                onTogglePin: onTogglePin,
                onOpenGradingPlan: onOpenGradingPlan,
                onOpenAttendanceRules: onOpenAttendanceRules,
                onOpenExportReports: onOpenExportReports,
                onOpenAuditLog: onOpenAuditLog,
                onOpenRoster: onOpenRoster,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _MetaChip(
                icon: Icons.people_outline_rounded,
                label: '${item.activeStudentCount} คน',
              ),
              _MetaChip(
                icon: Icons.event_repeat_rounded,
                label: _formatTeachingDays(item.teachingDays),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DashboardTodayStatusStrip(
            summary: item.todayAttendance,
            teachesToday: teachesToday,
          ),
          if (item.activeStudentCount == 0) ...[
            const SizedBox(height: 8),
            _EmptyRosterHint(onOpenRoster: onOpenRoster),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: isChecked
                    ? FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: onOpenAttendance,
                        icon: const Icon(Icons.fact_check_outlined, size: 17),
                        label: const Text(
                          'ดูเช็คชื่อ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: onOpenAttendance,
                        icon: const Icon(Icons.fact_check_outlined, size: 17),
                        label: const Text(
                          'เช็คชื่อวันนี้',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: onOpenGradingTable,
                  icon: const Icon(Icons.table_chart_outlined, size: 17),
                  label: const Text(
                    'ตารางคะแนน',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTeachingDays(List<int> days) {
    if (days.isEmpty) return 'ยังไม่ระบุวันสอน';
    return days
        .map((day) => ThaiDateFormatter.weekdayThaiName(day, short: true))
        .join(' ');
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRosterHint extends StatelessWidget {
  const _EmptyRosterHint({required this.onOpenRoster});

  final VoidCallback onOpenRoster;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 15, color: semantic.warning),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'ยังไม่มีรายชื่อนักเรียน',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: semantic.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onOpenRoster,
          child: const Text('เพิ่มรายชื่อ'),
        ),
      ],
    );
  }
}
