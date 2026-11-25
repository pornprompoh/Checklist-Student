import 'package:flutter/material.dart';

import '../../features/sync_queue/presentation/providers/sync_queue_providers.dart';
import '../../features/sync_queue/presentation/widgets/sync_status_badge.dart';
import 'app_shell_nav_items.dart';

/// Desktop Sidebar destination rendered as a soft tinted pill when selected.
class AppShellSidebarTile extends StatelessWidget {
  const AppShellSidebarTile({
    super.key,
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    this.syncBadgeCounts,
  });

  final AppShellNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;
  final SyncQueueStatusCounts? syncBadgeCounts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final counts = syncBadgeCounts;
    final hasBadge = counts != null && counts.hasAnyItems;
    final radius = BorderRadius.circular(12);

    final iconWidget = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 21,
      color: selected ? colorScheme.primary : foreground,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: collapsed ? item.label : '',
        child: Material(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : 12,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (collapsed && hasBadge)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        iconWidget,
                        Positioned(
                          right: -8,
                          top: -6,
                          child: SyncStatusBadge(counts: counts, compact: true),
                        ),
                      ],
                    )
                  else
                    iconWidget,
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (hasBadge) ...[
                      const SizedBox(width: 6),
                      SyncStatusBadge(counts: counts),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
