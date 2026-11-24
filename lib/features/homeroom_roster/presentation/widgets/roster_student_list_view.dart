import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/student_lifecycle_status.dart';

/// Shared display model rendered by [RosterStudentListView] for both
/// `HomeroomStudent` and `ClassEnrollment` lists.
class RosterStudentRowData {
  const RosterStudentRowData({
    required this.id,
    required this.studentNumber,
    required this.studentCode,
    required this.fullName,
    required this.status,
    this.enrolledAt,
    this.transferredOutAt,
  });

  final String id;
  final int studentNumber;
  final String studentCode;
  final String fullName;
  final StudentLifecycleStatus status;
  final DateTime? enrolledAt;
  final DateTime? transferredOutAt;

  bool get isTransferredOut => status == StudentLifecycleStatus.transferredOut;
}

/// Reusable student roster list supporting active/transferred-out filter,
/// Buddhist Era dates, edit, soft-delete (transfer out), and restore actions.
class RosterStudentListView extends StatefulWidget {
  const RosterStudentListView({
    super.key,
    required this.students,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleTransferStatus,
  });

  final List<RosterStudentRowData> students;
  final bool isBusy;
  final ValueChanged<RosterStudentRowData> onEdit;
  final ValueChanged<RosterStudentRowData> onToggleTransferStatus;

  @override
  State<RosterStudentListView> createState() => _RosterStudentListViewState();
}

class _RosterStudentListViewState extends State<RosterStudentListView> {
  bool _showTransferredOut = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    final activeCount = widget.students.where((s) => !s.isTransferredOut).length;
    final outCount = widget.students.length - activeCount;
    final visible = _showTransferredOut
        ? widget.students
        : widget.students.where((s) => !s.isTransferredOut).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'กำลังเรียน $activeCount คน${outCount > 0 ? ' · ย้ายออก $outCount คน' : ''}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (outCount > 0)
              FilterChip(
                label: const Text('แสดงนักเรียนที่ย้ายออก'),
                selected: _showTransferredOut,
                onSelected: (v) => setState(() => _showTransferredOut = v),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'ยังไม่มีรายชื่อนักเรียนในรายการนี้',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (final item in visible) ...[
            _StudentRowCard(
              item: item,
              isBusy: widget.isBusy,
              semantic: semantic,
              onEdit: () => widget.onEdit(item),
              onToggleTransfer: () => widget.onToggleTransferStatus(item),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _StudentRowCard extends StatelessWidget {
  const _StudentRowCard({
    required this.item,
    required this.isBusy,
    required this.semantic,
    required this.onEdit,
    required this.onToggleTransfer,
  });

  final RosterStudentRowData item;
  final bool isBusy;
  final AppSemanticColors semantic;
  final VoidCallback onEdit;
  final VoidCallback onToggleTransfer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOut = item.isTransferredOut;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOut
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: isOut
            ? Border.all(color: semantic.warning.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isOut
                  ? semantic.warningContainer
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.studentNumber}',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isOut
                    ? semantic.warning
                    : colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fullName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isOut ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'รหัส ${item.studentCode}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.enrolledAt != null)
                      Text(
                        'เข้าเรียน ${ThaiDateFormatter.formatShortDate(item.enrolledAt!)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (isOut)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: semantic.warningContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.transferredOutAt != null
                              ? 'ย้ายออก (${ThaiDateFormatter.formatShortDate(item.transferredOutAt!)})'
                              : 'ย้ายออก',
                          style: textTheme.labelSmall?.copyWith(
                            color: semantic.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'แก้ไขข้อมูลนักเรียน',
            onPressed: isBusy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: isOut ? 'คืนสถานะกำลังเรียน' : 'บันทึกย้ายออก (คงเลขที่เดิม)',
            onPressed: isBusy ? null : onToggleTransfer,
            icon: Icon(
              isOut ? Icons.restore_rounded : Icons.person_remove_outlined,
              size: 18,
              color: isOut ? semantic.success : semantic.warning,
            ),
          ),
        ],
      ),
    );
  }
}
