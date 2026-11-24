import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/dashboard_class_item.dart';
import 'dashboard_attendance_badge.dart';

/// Classroom card rendered on the Teacher Dashboard with quick pin toggle,
/// today-schedule badges, 4-state attendance summary, and 1-tap attendance CTA.
class DashboardClassCard extends StatelessWidget {
  const DashboardClassCard({
    super.key,
    required this.item,
    required this.todayIsoWeekday,
    required this.isBusy,
    required this.onTogglePin,
    required this.onOpenAttendance,
    required this.onOpenRoster,
  });

  final DashboardClassItem item;
  final int todayIsoWeekday;
  final bool isBusy;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenRoster;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final teachesToday = item.teachesOnWeekday(todayIsoWeekday);
    final summary = item.todayAttendance;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: teachesToday
              ? colorScheme.primary.withValues(alpha: 0.45)
              : colorScheme.outlineVariant,
          width: teachesToday ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Text(
                            item.subjectCode,
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (teachesToday)
                            DashboardTagPill(
                              label: 'มีสอนวันนี้',
                              background: colorScheme.primaryContainer,
                              foreground: colorScheme.onPrimaryContainer,
                            ),
                          if (item.isPinned)
                            DashboardTagPill(
                              label: 'ปักหมุด',
                              background: colorScheme.secondaryContainer,
                              foreground: colorScheme.onSecondaryContainer,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ห้อง ${item.roomName}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subjectName,
                        maxLines: 2,
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
                  onPressed: isBusy ? null : onTogglePin,
                  icon: Icon(
                    item.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 20,
                    color: item.isPinned
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _MetaText(
                  icon: Icons.people_outline_rounded,
                  label: '${item.activeStudentCount} คน',
                ),
                _MetaText(
                  icon: Icons.event_repeat_rounded,
                  label: _formatTeachingDays(item.teachingDays),
                ),
              ],
            ),
            const Divider(height: 22),
            if (summary != null)
              DashboardCheckedAttendanceSection(
                summary: summary,
                onOpenAttendance: onOpenAttendance,
              )
            else
              FilledButton.icon(
                onPressed: onOpenAttendance,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('เช็คชื่อวันนี้'),
              ),
            if (item.activeStudentCount == 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: semantic.warningContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: semantic.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ยังไม่มีนักเรียนในห้องนี้',
                        style: textTheme.bodySmall?.copyWith(
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
                      child: const Text('คลังรายชื่อ'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTeachingDays(List<int> days) {
    if (days.isEmpty) {
      return 'ยังไม่ระบุวันสอน';
    }
    return days
        .map((day) => ThaiDateFormatter.weekdayThaiName(day, short: true))
        .join(' ');
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.label});

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
