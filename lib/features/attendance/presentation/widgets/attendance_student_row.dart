import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../domain/entities/student_attendance_summary.dart';
import 'attendance_risk_badge.dart';

/// Responsive row for checking in one student (mobile `390px` through desktop).
///
/// Renders 1-tap 4-state buttons (`มา / สาย / ลา / ขาด`), note button, `มส`
/// risk badge, and read-only states for locked sessions, mid-term future
/// enrollments, or transferred-out students.
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
  });

  final ClassEnrollment enrollment;
  final DateTime selectedDate;
  final AttendanceStatus? selectedStatus;
  final String note;
  final StudentAttendanceSummary? summary;
  final bool isLocked;
  final ValueChanged<AttendanceStatus> onStatusSelected;
  final VoidCallback onEditNote;

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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${enrollment.studentNumber}',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.fullName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'รหัส ${enrollment.studentCode}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
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
                    onPressed: isLocked ? null : onEditNote,
                    icon: Icon(
                      hasNote
                          ? Icons.comment_rounded
                          : Icons.add_comment_outlined,
                      size: 20,
                      color: hasNote
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isNotYetEnrolled)
              _ReadOnlyLifecycleBanner(
                icon: Icons.event_available_outlined,
                label:
                    'เข้าเรียนเมื่อ ${ThaiDateFormatter.formatShortDate(enrollment.enrolledAt)} (ไม่ต้องเช็คชื่อวันนี้)',
              )
            else if (_isAlreadyTransferredOut)
              _ReadOnlyLifecycleBanner(
                icon: Icons.person_off_outlined,
                label: enrollment.transferredOutAt != null
                    ? 'ย้ายออกเมื่อ ${ThaiDateFormatter.formatShortDate(enrollment.transferredOutAt!)}'
                    : 'ย้ายออกแล้ว',
              )
            else
              Row(
                children: [
                  for (var i = 0; i < AttendanceStatus.values.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _StatusTapButton(
                        status: AttendanceStatus.values[i],
                        selected: selectedStatus == AttendanceStatus.values[i],
                        disabled: isLocked,
                        semantic: semantic,
                        onTap: () =>
                            onStatusSelected(AttendanceStatus.values[i]),
                      ),
                    ),
                  ],
                ],
              ),
            if (hasNote && isEligibleForDate) ...[
              const SizedBox(height: 6),
              Text(
                'หมายเหตุ: $note',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusTapButton extends StatelessWidget {
  const _StatusTapButton({
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

    final effectiveBg = selected
        ? bg
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final effectiveFg = selected ? fg : colorScheme.onSurfaceVariant;
    final borderColor = selected
        ? fg
        : colorScheme.outlineVariant.withValues(alpha: 0.8);

    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Material(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: disabled ? null : onTap,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              status.thaiLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: effectiveFg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
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
