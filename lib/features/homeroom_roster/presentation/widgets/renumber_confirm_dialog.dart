import 'package:flutter/material.dart';

import '../../domain/services/roster_renumber_service.dart';

/// Confirmation result from [RenumberConfirmDialog].
class RenumberConfirmResult {
  const RenumberConfirmResult({required this.syncLinkedClasses});

  final bool syncLinkedClasses;
}

/// Preview and confirmation dialog for sequential `1..N` active student
/// renumbering (preserving transferred-out numbers untouched).
class RenumberConfirmDialog extends StatefulWidget {
  const RenumberConfirmDialog({
    super.key,
    required this.assignments,
    required this.showSyncLinkedOption,
  });

  final List<RenumberAssignment> assignments;
  final bool showSyncLinkedOption;

  static Future<RenumberConfirmResult?> show(
    BuildContext context, {
    required List<RenumberAssignment> assignments,
    required bool showSyncLinkedOption,
  }) {
    return showDialog<RenumberConfirmResult>(
      context: context,
      builder: (dialogContext) => RenumberConfirmDialog(
        assignments: assignments,
        showSyncLinkedOption: showSyncLinkedOption,
      ),
    );
  }

  @override
  State<RenumberConfirmDialog> createState() => _RenumberConfirmDialogState();
}

class _RenumberConfirmDialogState extends State<RenumberConfirmDialog> {
  bool _syncLinkedClasses = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      title: const Text('ยืนยันการเรียงเลขที่ใหม่'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบบจะเรียงเลขที่ 1..N เฉพาะนักเรียนที่กำลังเรียนอยู่ (${widget.assignments.length} คนที่จะเปลี่ยนเลขที่) '
              'และคงเลขที่เดิมของนักเรียนที่ย้ายออกไว้ทั้งหมด',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in widget.assignments.take(15))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.oldNumber} → ${item.newNumber}',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.assignments.length > 15)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'และอีก ${widget.assignments.length - 15} คน...',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.showSyncLinkedOption) ...[
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _syncLinkedClasses,
                onChanged: (v) =>
                    setState(() => _syncLinkedClasses = v ?? false),
                title: const Text('ซิงค์เลขที่ใหม่ไปยังทุกวิชาที่ผูกกับคลังนี้ด้วย'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            RenumberConfirmResult(
              syncLinkedClasses:
                  widget.showSyncLinkedOption && _syncLinkedClasses,
            ),
          ),
          child: const Text('ยืนยันเรียงเลขที่ใหม่'),
        ),
      ],
    );
  }
}
