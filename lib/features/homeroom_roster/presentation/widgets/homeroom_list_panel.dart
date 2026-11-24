import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../domain/entities/homeroom.dart';

/// Master list panel displaying all term-level [Homeroom] rosters with linked
/// class count badges and create/rename/delete actions.
class HomeroomListPanel extends StatelessWidget {
  const HomeroomListPanel({
    super.key,
    required this.homerooms,
    required this.selectedHomeroomId,
    required this.linkedClassCounts,
    required this.isBusy,
    required this.onSelect,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  final List<Homeroom> homerooms;
  final String? selectedHomeroomId;
  final Map<String, int> linkedClassCounts;
  final bool isBusy;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final ValueChanged<Homeroom> onRename;
  final ValueChanged<Homeroom> onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'คลังห้องเรียน (${homerooms.length})',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onCreate,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('สร้างห้อง'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (homerooms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'ยังไม่มีคลังห้องเรียนในเทอมนี้ กด "สร้างห้อง" เพื่อเริ่มต้น',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final room in homerooms) ...[
                _HomeroomTile(
                  homeroom: room,
                  selected: room.id == selectedHomeroomId,
                  linkedCount: linkedClassCounts[room.id] ?? 0,
                  isBusy: isBusy,
                  dangerColor: semantic.danger,
                  onSelect: () => onSelect(room.id),
                  onRename: () => onRename(room),
                  onDelete: () => onDelete(room),
                ),
                const SizedBox(height: 6),
              ],
          ],
        ),
      ),
    );
  }
}

class _HomeroomTile extends StatelessWidget {
  const _HomeroomTile({
    required this.homeroom,
    required this.selected,
    required this.linkedCount,
    required this.isBusy,
    required this.dangerColor,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  final Homeroom homeroom;
  final bool selected;
  final int linkedCount;
  final bool isBusy;
  final Color dangerColor;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeroom.name,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'ผูกอยู่ $linkedCount รายวิชา',
                      style: textTheme.bodySmall?.copyWith(
                        color: selected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'จัดการคลังห้อง',
                enabled: !isBusy,
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'rename',
                    child: Text('เปลี่ยนชื่อห้อง'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'ลบคลังห้อง',
                      style: TextStyle(color: dangerColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
