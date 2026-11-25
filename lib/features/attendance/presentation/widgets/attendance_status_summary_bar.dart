import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card.dart';

/// Live per-session attendance counter bar (`มา / สาย / ลา / ขาด / ยังไม่เลือก`)
/// with tabular digits, prominent "มาทั้งหมด" / "ปลดล็อกเพื่อแก้ไข" action, and
/// optional session note toggle.
class AttendanceStatusSummaryBar extends StatelessWidget {
  const AttendanceStatusSummaryBar({
    super.key,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.unmarkedCount,
    required this.sessionNote,
    required this.isLocked,
    required this.isBusy,
    required this.canMarkAllPresent,
    required this.onMarkAllPresent,
    required this.onEditSessionNote,
    required this.onUnlockSession,
  });

  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final int unmarkedCount;
  final String sessionNote;
  final bool isLocked;
  final bool isBusy;
  final bool canMarkAllPresent;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onEditSessionNote;
  final VoidCallback onUnlockSession;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CounterPill(
                    label: '${AttendanceStatus.present.thaiLabel} $presentCount',
                    bg: semantic.presentContainer,
                    fg: semantic.present,
                  ),
                  _CounterPill(
                    label: '${AttendanceStatus.late.thaiLabel} $lateCount',
                    bg: semantic.lateContainer,
                    fg: semantic.late,
                  ),
                  _CounterPill(
                    label: '${AttendanceStatus.leave.thaiLabel} $leaveCount',
                    bg: semantic.leaveContainer,
                    fg: semantic.leave,
                  ),
                  _CounterPill(
                    label: '${AttendanceStatus.absent.thaiLabel} $absentCount',
                    bg: semantic.absentContainer,
                    fg: semantic.absent,
                  ),
                  if (unmarkedCount > 0)
                    _CounterPill(
                      label: 'ยังไม่เลือก $unmarkedCount',
                      bg: colorScheme.surfaceContainer,
                      fg: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isLocked)
                    FilledButton.icon(
                      onPressed: isBusy ? null : onUnlockSession,
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('ปลดล็อกเพื่อแก้ไข'),
                    )
                  else
                    FilledButton.tonalIcon(
                      onPressed: (isBusy || !canMarkAllPresent)
                          ? null
                          : onMarkAllPresent,
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('มาทั้งหมด'),
                    ),
                  OutlinedButton.icon(
                    onPressed: (isBusy || isLocked) ? null : onEditSessionNote,
                    icon: Icon(
                      sessionNote.isNotEmpty
                          ? Icons.sticky_note_2_rounded
                          : Icons.sticky_note_2_outlined,
                      size: 18,
                    ),
                    label: Text(
                      sessionNote.isNotEmpty
                          ? 'แก้ไขหมายเหตุคาบ'
                          : 'หมายเหตุคาบ',
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (sessionNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'หมายเหตุคาบ: $sessionNote',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontFeatures: AppTheme.tabularFigures,
        ),
      ),
    );
  }
}
