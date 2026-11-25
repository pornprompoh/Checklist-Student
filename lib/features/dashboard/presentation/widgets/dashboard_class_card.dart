import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/dashboard_class_item.dart';
import 'dashboard_attendance_badge.dart';
import 'dashboard_class_card_menu.dart';

/// Scannable classroom card for [TeacherDashboardPage] designed to stretch
/// cleanly inside [IntrinsicHeight] rows so sibling cards share identical
/// height and bottom-aligned primary/secondary action buttons.
class DashboardClassCard extends StatefulWidget {
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
  State<DashboardClassCard> createState() => _DashboardClassCardState();
}

class _DashboardClassCardState extends State<DashboardClassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final item = widget.item;
    final teachesToday = item.teachesOnWeekday(widget.todayIsoWeekday);
    final isChecked = item.todayAttendance != null;

    final baseBorder = teachesToday
        ? colorScheme.primary.withValues(alpha: 0.4)
        : colorScheme.outlineVariant;
    final effectiveBorder = _isHovered
        ? colorScheme.primary.withValues(alpha: 0.55)
        : baseBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: effectiveBorder),
          boxShadow: _isHovered
              ? <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                            spacing: 8,
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
                                  showDot: true,
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                    DashboardClassCardMenu(
                      isPinned: item.isPinned,
                      isBusy: widget.isBusy,
                      onTogglePin: widget.onTogglePin,
                      onOpenGradingPlan: widget.onOpenGradingPlan,
                      onOpenAttendanceRules: widget.onOpenAttendanceRules,
                      onOpenExportReports: widget.onOpenExportReports,
                      onOpenAuditLog: widget.onOpenAuditLog,
                      onOpenRoster: widget.onOpenRoster,
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
                  _EmptyRosterHint(onOpenRoster: widget.onOpenRoster),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: isChecked
                        ? FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onPressed: widget.onOpenAttendance,
                            icon: const Icon(
                              Icons.fact_check_outlined,
                              size: 17,
                            ),
                            label: const Text(
                              'ดูเช็คชื่อ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onPressed: widget.onOpenAttendance,
                            icon: const Icon(
                              Icons.fact_check_outlined,
                              size: 17,
                            ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: widget.onOpenGradingTable,
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
            ),
          ],
        ),
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
              fontFeatures: AppTheme.tabularFigures,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: semantic.warningContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: semantic.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: semantic.warning),
          const SizedBox(width: 8),
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
      ),
    );
  }
}
