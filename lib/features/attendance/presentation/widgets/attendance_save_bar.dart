import 'package:flutter/material.dart';

/// Sticky bottom action bar on the Attendance Check-In page providing the
/// post-save lock toggle and anti-double-tap save button cleanly from `320px`.
class AttendanceSaveBar extends StatelessWidget {
  const AttendanceSaveBar({
    super.key,
    required this.lockAfterSave,
    required this.isLocked,
    required this.isSaving,
    required this.canSave,
    required this.onToggleLockAfterSave,
    required this.onSave,
  });

  final bool lockAfterSave;
  final bool isLocked;
  final bool isSaving;
  final bool canSave;
  final ValueChanged<bool> onToggleLockAfterSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: (isLocked || isSaving)
                    ? null
                    : () => onToggleLockAfterSave(!lockAfterSave),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: lockAfterSave,
                          onChanged: (isLocked || isSaving)
                              ? null
                              : (v) => onToggleLockAfterSave(v ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'ล็อกหลังบันทึก (กันมือลั่นแก้ทับ)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: (isLocked || isSaving || !canSave) ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  isSaving
                      ? 'กำลังบันทึก...'
                      : isLocked
                      ? 'คาบถูกล็อกอยู่'
                      : 'บันทึกการเช็คชื่อ',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
