import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../domain/entities/student_attendance_summary.dart';
import 'attendance_risk_badge.dart';

/// Fast, scannable student check-in row (`320px` mobile to desktop) with
/// tactile 4-state segmented pills (`มา / สาย / ลา / ขาด`), aligned baseline,
/// tabular student numbers, note icon, and read-only lifecycle states.
class AttendanceStudentRow extends StatelessWidget {
  const AttendanceStudentRow({
    super.key,
    required this.enrollment,
    required this.selectedDate,
    required this.selectedStatus,
    required this.note,
    required this.summary,
    required this.isLocked,
    required this.onStatusSelected,
    required this.onEditNote,
    this.embedded = false,
  });

  final ClassEnrollment enrollment;
  final DateTime selectedDate;
  final AttendanceStatus? selectedStatus;
  final String note;
  final StudentAttendanceSummary? summary;
  final bool isLocked;
  final ValueChanged<AttendanceStatus> onStatusSelected;
  final VoidCallback onEditNote;

  /// When `true`, renders borderless inside a parent [AppSurfaceCard] roster
  /// list to avoid 40 stacked card borders.
  final bool embedded;

  bool get _isNotYetEnrolled {
    final enrolled = _dateOnly(enrollment.enrolledAt);
    return _dateOnly(selectedDate).isBefore(enrolled);
  }

  bool get _isAlreadyTransferredOut {
    if (!enrollment.isTransferredOut) return false;
    final outDate = enrollment.transferredOutAt;
    if (outDate == null) return true;
    return _dateOnly(selectedDate).isAfter(_dateOnly(outDate));
  }

  bool get isEligibleForDate => !_isNotYetEnrolled && !_isAlreadyTransferredOut;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final hasNote = note.trim().isNotEmpty;

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 680;
          final studentInfo = _buildStudentHeader(
            context,
            colorScheme: colorScheme,
            textTheme: textTheme,
            hasNote: hasNote,
          );
          final controls = _buildStatusControl(context, semantic);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: studentInfo),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: controls),
                  ],
                )
              else ...[
                studentInfo,
                const SizedBox(height: 12),
                controls,
              ],
              if (hasNote && isEligibleForDate) ...[
                const SizedBox(height: 8),
                Text(
                  'หมายเหตุ: $note',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    if (embedded) {
      return body;
    }
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: body,
    );
  }

  Widget _buildStudentHeader(
    BuildContext context, {
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool hasNote,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${enrollment.studentNumber}',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                enrollment.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'รหัส ${enrollment.studentCode}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  AttendanceRiskBadge(summary: summary),
                ],
              ),
            ],
          ),
        ),
        if (isEligibleForDate)
          IconButton(
            tooltip: hasNote ? 'แก้ไขหมายเหตุ' : 'เพิ่มหมายเหตุ',
            visualDensity: VisualDensity.compact,
            onPressed: isLocked ? null : onEditNote,
            icon: Icon(
              hasNote ? Icons.comment_rounded : Icons.add_comment_outlined,
              size: 19,
              color: hasNote
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusControl(BuildContext context, AppSemanticColors semantic) {
    if (_isNotYetEnrolled) {
      return _ReadOnlyLifecycleBanner(
        icon: Icons.event_available_outlined,
        label:
            'เข้าเรียนเมื่อ ${ThaiDateFormatter.formatShortDate(enrollment.enrolledAt)} (ไม่ต้องเช็คชื่อวันนี้)',
      );
    }
    if (_isAlreadyTransferredOut) {
      return _ReadOnlyLifecycleBanner(
        icon: Icons.person_off_outlined,
        label: enrollment.transferredOutAt != null
            ? 'ย้ายออกเมื่อ ${ThaiDateFormatter.formatShortDate(enrollment.transferredOutAt!)}'
            : 'ย้ายออกแล้ว',
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (var i = 0; i < AttendanceStatus.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _StatusTapPill(
                status: AttendanceStatus.values[i],
                selected: selectedStatus == AttendanceStatus.values[i],
                disabled: isLocked,
                semantic: semantic,
                onTap: () => onStatusSelected(AttendanceStatus.values[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusTapPill extends StatelessWidget {
  const _StatusTapPill({
    required this.status,
    required this.selected,
    required this.disabled,
    required this.semantic,
    required this.onTap,
  });

  final AttendanceStatus status;
  final bool selected;
  final bool disabled;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color fg, Color bg) = switch (status) {
      AttendanceStatus.present => (semantic.present, semantic.presentContainer),
      AttendanceStatus.late => (semantic.late, semantic.lateContainer),
      AttendanceStatus.leave => (semantic.leave, semantic.leaveContainer),
      AttendanceStatus.absent => (semantic.absent, semantic.absentContainer),
    };
    final radius = BorderRadius.circular(8);

    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? bg : Colors.transparent,
          borderRadius: radius,
          border: selected ? Border.all(color: fg, width: 1.2) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            mouseCursor: disabled
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            hoverColor: fg.withValues(alpha: 0.09),
            onTap: disabled ? null : onTap,
            child: SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  status.thaiLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? fg : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyLifecycleBanner extends StatelessWidget {
  const _ReadOnlyLifecycleBanner({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
