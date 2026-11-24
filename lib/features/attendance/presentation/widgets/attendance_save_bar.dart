import 'package:flutter/material.dart';

/// Sticky bottom action bar on the Attendance Check-In page providing the
/// post-save lock toggle and anti-double-tap save button.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: lockAfterSave,
                    onChanged: (isLocked || isSaving)
                        ? null
                        : (v) => onToggleLockAfterSave(v ?? true),
                  ),
                  Flexible(
                    child: Text(
                      'ล็อกหลังบันทึก (กันมือลั่นแก้ทับ)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
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
