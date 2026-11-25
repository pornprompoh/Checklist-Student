import 'package:flutter/material.dart';

import '../../features/sync_queue/presentation/providers/sync_queue_providers.dart';
import 'app_shell_nav_items.dart';
import 'app_shell_sidebar_footer.dart';
import 'app_shell_sidebar_tile.dart';

/// Collapsible Desktop Sidebar (`>= 900px`) with grouped destinations
/// (`การสอนประจำวัน` / `รายงานและระบบ`), brand header and profile footer.
class AppShellSidebar extends StatelessWidget {
  const AppShellSidebar({
    super.key,
    required this.collapsed,
    required this.currentPath,
    required this.isOnline,
    required this.syncCounts,
    required this.onToggleCollapse,
    required this.onSelectRoute,
    required this.onSignOut,
  });

  static const double expandedWidth = 260;
  static const double collapsedWidth = 76;

  final bool collapsed;
  final String currentPath;
  final bool isOnline;
  final SyncQueueStatusCounts syncCounts;
  final VoidCallback onToggleCollapse;
  final ValueChanged<String> onSelectRoute;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: collapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = collapsed || constraints.maxWidth < 200;
          final isShortHeight = constraints.maxHeight < 360;

          final navChildren = <Widget>[
            for (var g = 0; g < AppShellNavigation.sidebarGroups.length; g++)
              ..._buildGroup(
                context,
                AppShellNavigation.sidebarGroups[g],
                isCompact: isCompact,
                isFirst: g == 0,
              ),
          ];
          final header = _buildHeader(context, isCompact);
          final footer = AppShellSidebarFooter(
            collapsed: isCompact,
            isOnline: isOnline,
            onSignOut: onSignOut,
          );
          const navPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);

          if (isShortHeight) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  Padding(
                    padding: navPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: navChildren,
                    ),
                  ),
                  const Divider(height: 1),
                  footer,
                ],
              ),
            );
          }

          return Column(
            children: [
              header,
              Expanded(
                child: ListView(padding: navPadding, children: navChildren),
              ),
              const Divider(height: 1),
              footer,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final toggleButton = IconButton(
      tooltip: collapsed ? 'ขยายแถบด้านข้าง' : 'พับแถบด้านข้าง',
      onPressed: onToggleCollapse,
      icon: Icon(
        collapsed
            ? Icons.keyboard_double_arrow_right_rounded
            : Icons.keyboard_double_arrow_left_rounded,
        size: 20,
      ),
    );

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Center(child: toggleButton),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fact_check_rounded,
              size: 20,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Checklist-Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'พื้นที่ทำงานของครู',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          toggleButton,
        ],
      ),
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    AppShellNavGroup group, {
    required bool isCompact,
    required bool isFirst,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return <Widget>[
      if (isCompact)
        Padding(
          padding: EdgeInsets.symmetric(vertical: isFirst ? 4 : 8),
          child: isFirst
              ? const SizedBox.shrink()
              : const Divider(height: 1, indent: 14, endIndent: 14),
        )
      else
        Padding(
          padding: EdgeInsets.fromLTRB(12, isFirst ? 8 : 18, 12, 6),
          child: Text(
            group.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final item in group.items)
        AppShellSidebarTile(
          item: item,
          selected: currentPath.startsWith(item.route),
          collapsed: isCompact,
          syncBadgeCounts: item.route == AppShellNavigation.syncQueue.route
              ? syncCounts
              : null,
          onTap: () => onSelectRoute(item.route),
        ),
    ];
  }
}
