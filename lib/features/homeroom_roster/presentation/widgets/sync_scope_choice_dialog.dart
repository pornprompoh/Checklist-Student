import 'package:flutter/material.dart';

/// Teacher's choice when editing or changing status of a student linked to
/// a master homeroom roster.
enum RosterSyncScope { classOnly, homeroomAndAllClasses }

/// Thai confirmation dialog asking whether edits made inside a subject class
/// apply only to this class or also sync back to the master homeroom and all
/// linked classes in the same term via `sync_homeroom_student_update`.
class SyncScopeChoiceDialog extends StatelessWidget {
  const SyncScopeChoiceDialog({
    super.key,
    required this.studentName,
    this.actionTitle = 'เลือกขอบเขตการอัปเดตข้อมูลนักเรียน',
  });

  final String studentName;
  final String actionTitle;

  static Future<RosterSyncScope?> show(
    BuildContext context, {
    required String studentName,
    String actionTitle = 'เลือกขอบเขตการอัปเดตข้อมูลนักเรียน',
  }) {
    return showDialog<RosterSyncScope>(
      context: context,
      builder: (dialogContext) => SyncScopeChoiceDialog(
        studentName: studentName,
        actionTitle: actionTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      title: Text(actionTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'นักเรียน "$studentName" ผูกอยู่กับคลังห้องเรียนกลาง ต้องการอัปเดตแบบใด?',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(RosterSyncScope.classOnly),
              icon: const Icon(Icons.class_outlined),
              label: const Text('อัปเดตเฉพาะวิชานี้'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: () => Navigator.of(
                context,
              ).pop(RosterSyncScope.homeroomAndAllClasses),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('อัปเดตกลับคลังหลักและซิงค์ทุกวิชาที่ผูกในเทอมนี้'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
