import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/services/unlinked_room_sync_service.dart';

/// Master list panel displaying all term-level [Homeroom] rosters with linked
/// class count badges, unlinked rooms, optional room search, and independent
/// vertical scrolling when hosted inside a Desktop Split-Pane.
class HomeroomListPanel extends StatefulWidget {
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
    this.unlinkedRoomGroups = const <UnlinkedRoomGroup>[],
    this.onSyncUnlinkedGroup,
    this.onSyncAllUnlinked,
    this.fillAvailableHeight = false,
    this.scrollController,
  });

  final List<Homeroom> homerooms;
  final String? selectedHomeroomId;
  final Map<String, int> linkedClassCounts;
  final bool isBusy;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final ValueChanged<Homeroom> onRename;
  final ValueChanged<Homeroom> onDelete;
  final List<UnlinkedRoomGroup> unlinkedRoomGroups;
  final ValueChanged<UnlinkedRoomGroup>? onSyncUnlinkedGroup;
  final VoidCallback? onSyncAllUnlinked;
  final bool fillAvailableHeight;
  final ScrollController? scrollController;

  @override
  State<HomeroomListPanel> createState() => _HomeroomListPanelState();
}

class _HomeroomListPanelState extends State<HomeroomListPanel> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final q = _query.trim().toLowerCase();
    final visibleHomerooms = q.isEmpty
        ? widget.homerooms
        : widget.homerooms
              .where((r) => r.name.toLowerCase().contains(q))
              .toList(growable: false);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'คลังห้องเรียน (${widget.homerooms.length})',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: widget.isBusy ? null : widget.onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('สร้างห้อง'),
            ),
          ],
        ),
        if (widget.homerooms.length >= 6 || _query.isNotEmpty) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'ค้นหาห้องเรียน...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'ล้างคำค้นหา',
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded, size: 16),
                    ),
            ),
          ),
        ],
      ],
    );

    final listChildren = _buildListChildren(
      context,
      colorScheme: colorScheme,
      textTheme: textTheme,
      semantic: semantic,
      visibleHomerooms: visibleHomerooms,
    );

    if (widget.fillAvailableHeight) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            Expanded(
              child: AppSubtleScrollbar(
                controller: widget.scrollController,
                child: ListView(
                  controller: widget.scrollController,
                  primary: false,
                  padding: const EdgeInsets.only(right: 6),
                  children: listChildren,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, const SizedBox(height: 12), ...listChildren],
      ),
    );
  }

  List<Widget> _buildListChildren(
    BuildContext context, {
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required AppSemanticColors semantic,
    required List<Homeroom> visibleHomerooms,
  }) {
    return <Widget>[
      if (widget.homerooms.isEmpty && widget.unlinkedRoomGroups.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'ยังไม่มีคลังห้องเรียนในเทอมนี้ กด "สร้างห้อง" หรือสร้างห้องในหน้าโครงสร้างสอนเพื่อเริ่มต้น',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        )
      else if (visibleHomerooms.isEmpty && widget.homerooms.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'ไม่พบห้องเรียนตามคำค้นหา',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        )
      else ...[
        for (final room in visibleHomerooms) ...[
          _HomeroomTile(
            homeroom: room,
            selected: room.id == widget.selectedHomeroomId,
            linkedCount: widget.linkedClassCounts[room.id] ?? 0,
            isBusy: widget.isBusy,
            dangerColor: semantic.danger,
            onSelect: () => widget.onSelect(room.id),
            onRename: () => widget.onRename(room),
            onDelete: () => widget.onDelete(room),
          ),
          const SizedBox(height: 8),
        ],
      ],
      if (widget.unlinkedRoomGroups.isNotEmpty) ...[
        const Divider(height: 20),
        Text(
          'ห้องจากโครงสร้างสอน (${widget.unlinkedRoomGroups.length})',
          style: textTheme.labelLarge?.copyWith(
            color: semantic.warning,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'กดเลือกห้องเพื่อสร้าง/เชื่อมคลังรายชื่ออัตโนมัติโดยไม่ต้องพิมพ์ชื่อห้องซ้ำ',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.onSyncAllUnlinked != null) ...[
          OutlinedButton(
            onPressed: widget.isBusy ? null : widget.onSyncAllUnlinked,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_rounded, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'นำห้องจากโครงสร้างสอนเข้าคลังทั้งหมด',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        for (final group in widget.unlinkedRoomGroups) ...[
          Material(
            color: semantic.warningContainer.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: semantic.warning.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.isBusy || widget.onSyncUnlinkedGroup == null
                  ? null
                  : () => widget.onSyncUnlinkedGroup!(group),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.roomName,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'จากโครงสร้างสอน · ${group.classCount} วิชา',
                            style: textTheme.bodySmall?.copyWith(
                              color: semantic.warning,
                              fontWeight: FontWeight.w600,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.add_link_rounded,
                      size: 20,
                      color: semantic.warning,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    ];
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
          ? colorScheme.primaryContainer.withValues(alpha: 0.65)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'ผูกอยู่ $linkedCount รายวิชา',
                      style: textTheme.bodySmall?.copyWith(
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontFeatures: AppTheme.tabularFigures,
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
