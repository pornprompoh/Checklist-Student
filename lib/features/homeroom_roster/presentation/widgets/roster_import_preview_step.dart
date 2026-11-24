import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/roster_import_row_preview.dart';

/// Step 3 of the Excel/CSV import wizard: Preview parsed Thai names,
/// highlight duplicate/invalid rows, and choose Skip vs Overwrite.
class RosterImportPreviewStep extends StatelessWidget {
  const RosterImportPreviewStep({
    super.key,
    required this.rows,
    required this.hasLinkedClasses,
    required this.syncOverwrittenToLinkedClasses,
    required this.onToggleSyncOverwritten,
    required this.onApplyAllDuplicateAction,
    required this.onRowDuplicateActionChanged,
  });

  final List<RosterImportRowPreview> rows;
  final bool hasLinkedClasses;
  final bool syncOverwrittenToLinkedClasses;
  final ValueChanged<bool> onToggleSyncOverwritten;
  final ValueChanged<DuplicateResolutionAction> onApplyAllDuplicateAction;
  final void Function(int index, DuplicateResolutionAction action)
  onRowDuplicateActionChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final newCount = rows
        .where((r) => r.status == RosterImportRowStatus.readyNew)
        .length;
    final dupCount = rows
        .where((r) => r.status == RosterImportRowStatus.duplicateExisting)
        .length;
    final overwriteCount = rows
        .where(
          (r) =>
              r.status == RosterImportRowStatus.duplicateExisting &&
              r.duplicateAction == DuplicateResolutionAction.overwrite,
        )
        .length;
    final problemCount = rows
        .where(
          (r) =>
              r.status == RosterImportRowStatus.invalid ||
              r.status == RosterImportRowStatus.duplicateInFile,
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _SummaryPill(
              label: 'นำเข้าใหม่ $newCount คน',
              background: semantic.successContainer,
              foreground: semantic.success,
            ),
            if (dupCount > 0)
              _SummaryPill(
                label: 'รหัสซ้ำในคลัง $dupCount คน',
                background: semantic.warningContainer,
                foreground: semantic.warning,
              ),
            if (problemCount > 0)
              _SummaryPill(
                label: 'ข้อมูลไม่สมบูรณ์/ซ้ำในไฟล์ $problemCount แถว',
                background: semantic.dangerContainer,
                foreground: semantic.danger,
              ),
          ],
        ),
        if (dupCount > 0) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton(
                onPressed: () =>
                    onApplyAllDuplicateAction(DuplicateResolutionAction.skip),
                child: const Text('ข้ามรหัสซ้ำทั้งหมด'),
              ),
              FilledButton.tonal(
                onPressed: () => onApplyAllDuplicateAction(
                  DuplicateResolutionAction.overwrite,
                ),
                child: const Text('อัปเดตทับรหัสซ้ำทั้งหมด'),
              ),
            ],
          ),
        ],
        if (hasLinkedClasses && overwriteCount > 0) ...[
          const SizedBox(height: 6),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: syncOverwrittenToLinkedClasses,
            onChanged: (v) => onToggleSyncOverwritten(v ?? false),
            title: const Text(
              'ซิงค์รายการที่อัปเดตทับไปยังรายวิชาที่ผูกกับคลังนี้ในเทอมเดียวกัน',
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'ไม่พบแถวข้อมูลนักเรียนใต้แถวหัวตารางที่เลือก',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < rows.length; i++) ...[
            _PreviewRowTile(
              row: rows[i],
              semantic: semantic,
              onDuplicateActionChanged: (action) =>
                  onRowDuplicateActionChanged(i, action),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreviewRowTile extends StatelessWidget {
  const _PreviewRowTile({
    required this.row,
    required this.semantic,
    required this.onDuplicateActionChanged,
  });

  final RosterImportRowPreview row;
  final AppSemanticColors semantic;
  final ValueChanged<DuplicateResolutionAction> onDuplicateActionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (Color bg, Color border) = switch (row.status) {
      RosterImportRowStatus.readyNew => (
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        colorScheme.outlineVariant,
      ),
      RosterImportRowStatus.duplicateExisting => (
        semantic.warningContainer.withValues(alpha: 0.5),
        semantic.warning,
      ),
      RosterImportRowStatus.duplicateInFile ||
      RosterImportRowStatus.invalid => (
        semantic.dangerContainer.withValues(alpha: 0.5),
        semantic.danger,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'แถว ${row.sourceRowNumber} · เลขที่ ${row.studentNumber}',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'รหัส: ${row.studentCode.isEmpty ? "-" : row.studentCode}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'คำนำหน้า: "${row.prefix}" · ชื่อ: "${row.firstName}" · นามสกุล: "${row.lastName}"',
            style: textTheme.bodySmall,
          ),
          if (row.status == RosterImportRowStatus.duplicateExisting &&
              row.existingStudent != null) ...[
            const SizedBox(height: 6),
            Text(
              'เดิมในคลัง: เลขที่ ${row.existingStudent!.studentNumber} ${row.existingStudent!.fullName}',
              style: textTheme.bodySmall?.copyWith(
                color: semantic.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<DuplicateResolutionAction>(
              segments: const [
                ButtonSegment<DuplicateResolutionAction>(
                  value: DuplicateResolutionAction.skip,
                  label: Text('ข้าม'),
                ),
                ButtonSegment<DuplicateResolutionAction>(
                  value: DuplicateResolutionAction.overwrite,
                  label: Text('อัปเดตทับ'),
                ),
              ],
              selected: <DuplicateResolutionAction>{row.duplicateAction},
              onSelectionChanged: (sel) {
                if (sel.isNotEmpty) onDuplicateActionChanged(sel.first);
              },
            ),
          ] else if (row.errorReason != null) ...[
            const SizedBox(height: 4),
            Text(
              row.errorReason!,
              style: textTheme.bodySmall?.copyWith(
                color: semantic.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
