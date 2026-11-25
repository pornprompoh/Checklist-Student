import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/services/sync_conflict_field_formatter.dart';

/// Responsive dialog comparing a conflicted offline mutation's local values
/// against the authoritative server snapshot, allowing explicit teacher choice
/// (`Keep Mine` vs `Use Server`) with zero silent overwrite.
class SyncConflictResolutionDialog extends StatefulWidget {
  const SyncConflictResolutionDialog({
    super.key,
    required this.item,
    required this.onKeepMine,
    required this.onUseServer,
    this.formatter = const SyncConflictFieldFormatter(),
  });

  final SyncQueueItem item;
  final Future<bool> Function() onKeepMine;
  final Future<bool> Function() onUseServer;
  final SyncConflictFieldFormatter formatter;

  @override
  State<SyncConflictResolutionDialog> createState() =>
      _SyncConflictResolutionDialogState();
}

class _SyncConflictResolutionDialogState
    extends State<SyncConflictResolutionDialog> {
  bool _submittingKeepMine = false;
  bool _submittingUseServer = false;

  bool get _isBusy => _submittingKeepMine || _submittingUseServer;

  Future<void> _handleAction({required bool keepMine}) async {
    if (_isBusy) return;
    setState(() {
      _submittingKeepMine = keepMine;
      _submittingUseServer = !keepMine;
    });
    try {
      final shouldClose = keepMine
          ? await widget.onKeepMine()
          : await widget.onUseServer();
      if (mounted && shouldClose) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingKeepMine = false;
          _submittingUseServer = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final diffs = widget.formatter.formatDiffs(widget.item);
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.compare_arrows_rounded, color: semantic.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เปรียบเทียบและแก้ปัญหาข้อมูลชนกัน',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.displayLabel,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ข้อมูลนี้ถูกแก้ไขจากอุปกรณ์อื่นระหว่างที่คุณทำงานออฟไลน์ กรุณาตรวจสอบและเลือกเวอร์ชันที่ต้องการเก็บไว้',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                if (isWide)
                  _SideBySideComparison(diffs: diffs)
                else
                  _StackedComparison(diffs: diffs),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isBusy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('ปิดไว้ก่อน'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isBusy
                          ? null
                          : () => _handleAction(keepMine: false),
                      icon: _submittingUseServer
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text('ใช้ค่าล่าสุดบนเซิร์ฟเวอร์'),
                    ),
                    FilledButton.icon(
                      onPressed: _isBusy
                          ? null
                          : () => _handleAction(keepMine: true),
                      icon: _submittingKeepMine
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('ใช้ค่าของฉัน (บันทึกทับเซิร์ฟเวอร์)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideBySideComparison extends StatelessWidget {
  const _SideBySideComparison({required this.diffs});

  final List<SyncConflictFieldDiff> diffs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('หัวข้อ', style: textTheme.labelMedium),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'ค่าของฉัน (เครื่องนี้)',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'ค่าล่าสุดบนเซิร์ฟเวอร์',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final diff in diffs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: diff.isDifferent ? semantic.warningContainer : null,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      diff.label,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      diff.localValue,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: diff.isDifferent
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      diff.serverValue,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: diff.isDifferent
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
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

class _StackedComparison extends StatelessWidget {
  const _StackedComparison({required this.diffs});

  final List<SyncConflictFieldDiff> diffs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final diff in diffs)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: diff.isDifferent
                  ? semantic.warningContainer
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: diff.isDifferent
                    ? semantic.warning
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diff.label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ของฉัน: ${diff.localValue}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: diff.isDifferent ? FontWeight.w700 : null,
                  ),
                ),
                Text(
                  'เซิร์ฟเวอร์: ${diff.serverValue}',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: diff.isDifferent ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
