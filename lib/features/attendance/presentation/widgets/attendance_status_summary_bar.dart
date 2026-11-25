import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';

/// Compact flat inline attendance summary counters (`มา / สาย / ลา / ขาด`) +
/// single contextual action (`ปลดล็อก` when locked, `มาทั้งหมด` when unlocked).
///
/// Renders with zero outer card framing so it sits seamlessly on the same
/// flat control row as the class/date picker.
class AttendanceStatusSummaryBar extends StatelessWidget {
  const AttendanceStatusSummaryBar({
    super.key,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.unmarkedCount,
    required this.isLocked,
    required this.isBusy,
    required this.canMarkAllPresent,
    required this.onMarkAllPresent,
    required this.onUnlockSession,
  });

  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final int unmarkedCount;
  final bool isLocked;
  final bool isBusy;
  final bool canMarkAllPresent;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onUnlockSession;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        if (isLocked)
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: semantic.warningContainer,
              foregroundColor: semantic.warning,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: isBusy ? null : onUnlockSession,
            icon: const Icon(Icons.lock_open_rounded, size: 16),
            label: const Text('ปลดล็อก'),
          )
        else
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: (isBusy || !canMarkAllPresent)
                ? null
                : onMarkAllPresent,
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('มาทั้งหมด'),
          ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
