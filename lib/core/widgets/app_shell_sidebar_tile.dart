import 'package:flutter/material.dart';

import '../../features/sync_queue/presentation/providers/sync_queue_providers.dart';
import '../../features/sync_queue/presentation/widgets/sync_status_badge.dart';
import 'app_shell_nav_items.dart';

/// Desktop Sidebar destination with soft pill selection, hover/focus feedback,
/// and `SystemMouseCursors.click`.
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
    final counts = syncBadgeCounts;
    final hasBadge = counts != null && counts.hasAnyItems;
    final radius = BorderRadius.circular(10);

    final iconWidget = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 20,
      color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: collapsed ? item.label : '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.85)
                : Colors.transparent,
            borderRadius: radius,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: radius,
              mouseCursor: SystemMouseCursors.click,
              hoverColor: colorScheme.primary.withValues(alpha: 0.07),
              focusColor: colorScheme.primary.withValues(alpha: 0.12),
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
                            child: SyncStatusBadge(
                              counts: counts,
                              compact: true,
                            ),
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
                            color: selected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasBadge) ...[
                        const SizedBox(width: 8),
                        SyncStatusBadge(counts: counts),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
