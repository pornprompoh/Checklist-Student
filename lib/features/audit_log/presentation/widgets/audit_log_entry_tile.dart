import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/audit_log_target_type.dart';
import '../../domain/entities/score_audit_log_entry.dart';

/// Activity-ledger card rendering one `public.score_audit_logs` entry with
/// crisp `ค่าเดิม → ค่าใหม่` diff pill, Buddhist Era timestamp, and lock badge.
class AuditLogEntryTile extends StatelessWidget {
  const AuditLogEntryTile({super.key, required this.entry});

  final ScoreAuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isGradeStatus = entry.targetType == AuditLogTargetType.gradeStatus;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TagChip(
                    label: entry.targetType.thaiLabel,
                    bg: isGradeStatus
                        ? semantic.warningContainer
                        : colorScheme.primaryContainer,
                    fg: isGradeStatus
                        ? semantic.warning
                        : colorScheme.onPrimaryContainer,
                  ),
                  if (entry.isInitialEntry)
                    _TagChip(
                      icon: Icons.lock_outline_rounded,
                      label: 'รายการแรก (ล็อกไว้)',
                      bg: semantic.successContainer,
                      fg: semantic.success,
                    ),
                ],
              ),
              Text(
                ThaiDateFormatter.formatDateTime(entry.changedAt),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'เลขที่ ${entry.studentNumber} ${entry.studentFullName} (${entry.studentCode})',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.subjectCode} ${entry.subjectName} · ห้อง ${entry.roomName} '
            '· ${entry.displayTargetLabel} (ปี พ.ศ. ${entry.yearBe})',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  entry.displayOldValue,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                Text(
                  entry.displayNewValue,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isGradeStatus
                        ? semantic.danger
                        : colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData? icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
