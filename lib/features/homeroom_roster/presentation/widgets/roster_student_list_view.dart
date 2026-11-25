import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
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

/// Unified hairline-bordered student roster list supporting active/transferred-out
/// filter, Buddhist Era dates, edit, soft-delete, permanent delete, and optional
/// independent vertical scrolling inside Desktop Split-Pane layouts.
class RosterStudentListView extends StatefulWidget {
  const RosterStudentListView({
    super.key,
    required this.students,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleTransferStatus,
    this.onPermanentDelete,
    this.fillAvailableHeight = false,
    this.scrollController,
  });

  final List<RosterStudentRowData> students;
  final bool isBusy;
  final ValueChanged<RosterStudentRowData> onEdit;
  final ValueChanged<RosterStudentRowData> onToggleTransferStatus;
  final ValueChanged<RosterStudentRowData>? onPermanentDelete;
  final bool fillAvailableHeight;
  final ScrollController? scrollController;

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

    final summaryHeader = Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'กำลังเรียน $activeCount คน${outCount > 0 ? ' · ย้ายออก $outCount คน' : ''}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
        if (outCount > 0)
          FilterChip(
            label: const Text('แสดงนักเรียนที่ย้ายออก'),
            selected: _showTransferredOut,
            onSelected: (v) => setState(() => _showTransferredOut = v),
          ),
      ],
    );

    final Widget body;
    if (visible.isEmpty) {
      body = Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 28,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'ยังไม่มีรายชื่อนักเรียนในรายการนี้',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (widget.fillAvailableHeight) {
      body = Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: AppSubtleScrollbar(
          controller: widget.scrollController,
          child: ListView.separated(
            controller: widget.scrollController,
            primary: false,
            itemCount: visible.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant,
            ),
            itemBuilder: (_, i) => _StudentRowTile(
              item: visible[i],
              isBusy: widget.isBusy,
              semantic: semantic,
              onEdit: () => widget.onEdit(visible[i]),
              onToggleTransfer: () =>
                  widget.onToggleTransferStatus(visible[i]),
              onPermanentDelete: widget.onPermanentDelete == null
                  ? null
                  : () => widget.onPermanentDelete!(visible[i]),
            ),
          ),
        ),
      );
    } else {
      body = Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant,
                ),
              _StudentRowTile(
                item: visible[i],
                isBusy: widget.isBusy,
                semantic: semantic,
                onEdit: () => widget.onEdit(visible[i]),
                onToggleTransfer: () =>
                    widget.onToggleTransferStatus(visible[i]),
                onPermanentDelete: widget.onPermanentDelete == null
                    ? null
                    : () => widget.onPermanentDelete!(visible[i]),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        summaryHeader,
        const SizedBox(height: 12),
        if (widget.fillAvailableHeight) Expanded(child: body) else body,
      ],
    );
  }
}

class _StudentRowTile extends StatelessWidget {
  const _StudentRowTile({
    required this.item,
    required this.isBusy,
    required this.semantic,
    required this.onEdit,
    required this.onToggleTransfer,
    this.onPermanentDelete,
  });

  final RosterStudentRowData item;
  final bool isBusy;
  final AppSemanticColors semantic;
  final VoidCallback onEdit;
  final VoidCallback onToggleTransfer;
  final VoidCallback? onPermanentDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOut = item.isTransferredOut;

    return ColoredBox(
      color: isOut
          ? semantic.warningContainer.withValues(alpha: 0.25)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isOut
                    ? semantic.warningContainer
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.studentNumber}',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTheme.tabularFigures,
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
                      color: isOut
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
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
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      if (item.enrolledAt != null)
                        Text(
                          'เข้าเรียน ${ThaiDateFormatter.formatShortDate(item.enrolledAt!)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFeatures: AppTheme.tabularFigures,
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
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'จัดการรายชื่อนักเรียน',
              enabled: !isBusy,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'transfer') onToggleTransfer();
                if (value == 'delete' && onPermanentDelete != null) {
                  onPermanentDelete!();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined, size: 18),
                    title: Text('แก้ไขข้อมูลนักเรียน'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'transfer',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isOut
                          ? Icons.restore_rounded
                          : Icons.person_remove_outlined,
                      size: 18,
                      color: isOut ? semantic.success : semantic.warning,
                    ),
                    title: Text(
                      isOut
                          ? 'คืนสถานะกำลังเรียน'
                          : 'ย้ายออก (เก็บประวัติ ปพ.5)',
                    ),
                  ),
                ),
                if (onPermanentDelete != null)
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        size: 18,
                        color: semantic.danger,
                      ),
                      title: Text(
                        'ลบถาวร (กรณีเพิ่มผิด)',
                        style: TextStyle(color: semantic.danger),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
