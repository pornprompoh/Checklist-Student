import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/providers/sign_in_controller.dart';
import '../../features/sync_queue/presentation/providers/sync_queue_providers.dart';
import '../../features/sync_queue/presentation/widgets/sync_status_badge.dart';
import '../constants/app_routes.dart';
import '../network/connectivity_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/theme_mode_provider.dart';
import 'app_feedback_banner.dart';
import 'unsaved_changes_guard.dart';
import 'unsaved_changes_provider.dart';

class _NavItem {
  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Responsive Teacher App Shell switching between a collapsible Desktop
/// Sidebar (`width >= 900`) and a Mobile/Tablet Bottom NavigationBar (`< 900`).
class AppShellScaffold extends ConsumerStatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  static const double desktopBreakpoint = 900;

  static const List<_NavItem> _primaryItems = <_NavItem>[
    _NavItem(
      route: AppRoutes.teacherDashboard,
      label: 'หน้าหลัก',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _NavItem(
      route: AppRoutes.teacherAcademicStructure,
      label: 'โครงสร้างสอน',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree_rounded,
    ),
    _NavItem(
      route: AppRoutes.teacherHomeroomRoster,
      label: 'คลังรายชื่อ',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
    ),
    _NavItem(
      route: AppRoutes.teacherExportReports,
      label: 'ส่งออกรายงาน',
      icon: Icons.file_download_outlined,
      selectedIcon: Icons.file_download_rounded,
    ),
    _NavItem(
      route: AppRoutes.teacherSettings,
      label: 'ตั้งค่า',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  static const _NavItem _syncQueueItem = _NavItem(
    route: AppRoutes.teacherSyncQueue,
    label: 'สถานะซิงค์',
    icon: Icons.sync_outlined,
    selectedIcon: Icons.sync_rounded,
  );

  @override
  ConsumerState<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold> {
  bool _isSidebarCollapsed = false;

  int get _selectedPrimaryIndex {
    final idx = AppShellScaffold._primaryItems.indexWhere(
      (item) => widget.currentPath.startsWith(item.route),
    );
    return idx >= 0 ? idx : 0;
  }

  String get _currentTitle {
    if (widget.currentPath.startsWith(AppShellScaffold._syncQueueItem.route)) {
      return AppShellScaffold._syncQueueItem.label;
    }
    return AppShellScaffold._primaryItems[_selectedPrimaryIndex].label;
  }

  Future<void> _navigate(String route) async {
    if (widget.currentPath == route) {
      return;
    }
    if (ref.read(unsavedChangesStateProvider)) {
      final shouldDiscard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!shouldDiscard || !mounted) {
        return;
      }
      ref.read(unsavedChangesStateProvider.notifier).clearAll();
    }
    if (mounted) {
      context.go(route);
    }
  }

  Future<void> _handleSignOut() async {
    if (ref.read(unsavedChangesStateProvider)) {
      final shouldDiscard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!shouldDiscard || !mounted) {
        return;
      }
      ref.read(unsavedChangesStateProvider.notifier).clearAll();
    }
    if (mounted) {
      await ref.read(signInControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppShellScaffold.desktopBreakpoint;
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOffline = connectivity.asData?.value == false;
    final syncCounts = ref.watch(syncQueueStatusCountsProvider);
    final showConflictBanner =
        syncCounts.hasConflicts &&
        !widget.currentPath.startsWith(AppRoutes.teacherSyncQueue);

    final bodyWithBanner = Column(
      children: [
        if (isOffline)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppFeedbackBanner(
              type: AppFeedbackType.warning,
              message:
                  'ขณะนี้อยู่ในโหมดออฟไลน์ การเชื่อมต่ออินเทอร์เน็ตขาดหายชั่วคราว',
            ),
          ),
        if (showConflictBanner)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: AppFeedbackBanner(
              type: AppFeedbackType.error,
              message:
                  'พบข้อมูลชนกัน ${syncCounts.conflictCount} รายการจากการทำงานออฟไลน์',
              retryLabel: 'ตรวจสอบ',
              onRetry: () => _navigate(AppRoutes.teacherSyncQueue),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _DesktopSidebar(
                collapsed: _isSidebarCollapsed,
                currentPath: widget.currentPath,
                isOnline: !isOffline,
                syncCounts: syncCounts,
                onToggleCollapse: () => setState(
                  () => _isSidebarCollapsed = !_isSidebarCollapsed,
                ),
                onSelectRoute: _navigate,
                onSignOut: _handleSignOut,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: bodyWithBanner),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSigningOut = ref.watch(signInControllerProvider).isLoading;
    final semantic = AppSemanticColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTitle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          IconButton(
            tooltip: 'สถานะการซิงค์ข้อมูลออฟไลน์',
            onPressed: () => _navigate(AppRoutes.teacherSyncQueue),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  syncCounts.hasConflicts
                      ? Icons.sync_problem_rounded
                      : Icons.sync_rounded,
                  color: syncCounts.hasConflicts ? semantic.danger : null,
                ),
                if (syncCounts.hasAnyItems)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: SyncStatusBadge(counts: syncCounts, compact: true),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด',
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .toggleTheme(platformBrightness: Theme.of(context).brightness),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: isSigningOut ? null : _handleSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(child: bodyWithBanner),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPrimaryIndex,
        onDestinationSelected: (index) =>
            _navigate(AppShellScaffold._primaryItems[index].route),
        destinations: [
          for (final item in AppShellScaffold._primaryItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.collapsed,
    required this.currentPath,
    required this.isOnline,
    required this.syncCounts,
    required this.onToggleCollapse,
    required this.onSelectRoute,
    required this.onSignOut,
  });

  final bool collapsed;
  final String currentPath;
  final bool isOnline;
  final SyncQueueStatusCounts syncCounts;
  final VoidCallback onToggleCollapse;
  final ValueChanged<String> onSelectRoute;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final isSigningOut = ref.watch(signInControllerProvider).isLoading;
    final profile = authState.profile;
    final allItems = <_NavItem>[
      ...AppShellScaffold._primaryItems,
      AppShellScaffold._syncQueueItem,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: collapsed ? 76 : 248,
      color: colorScheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = collapsed || constraints.maxWidth < 180;
          final isShortHeight = constraints.maxHeight < 340;

          final header = Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: Row(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCompact)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.fact_check_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Checklist-Student',
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  tooltip: collapsed ? 'ขยายแถบด้านข้าง' : 'พับแถบด้านข้าง',
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    collapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                  ),
                ),
              ],
            ),
          );

          final profileBox = (!isCompact && profile != null)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.effectiveDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'รหัสครู: ${profile.teacherCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null;

          final navTiles = <Widget>[
            for (final item in allItems)
              _SidebarTile(
                item: item,
                selected: currentPath.startsWith(item.route),
                collapsed: isCompact,
                syncBadgeCounts: item.route == AppRoutes.teacherSyncQueue
                    ? syncCounts
                    : null,
                onTap: () => onSelectRoute(item.route),
              ),
          ];

          final footer = Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                  child: Row(
                    mainAxisAlignment: isCompact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(
                        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        size: 18,
                        color: isOnline ? semantic.success : semantic.danger,
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: isOnline
                                  ? semantic.success
                                  : semantic.danger,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: isCompact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: isDark
                          ? 'สลับเป็นโหมดสว่าง'
                          : 'สลับเป็นโหมดมืด',
                      onPressed: () => ref
                          .read(themeModeProvider.notifier)
                          .toggleTheme(
                            platformBrightness: Theme.of(context).brightness,
                          ),
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                    ),
                    if (!isCompact)
                      Flexible(
                        child: TextButton(
                          onPressed: isSigningOut ? null : onSignOut,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded, size: 18),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'ออกจากระบบ',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (isCompact)
                  IconButton(
                    tooltip: 'ออกจากระบบ',
                    onPressed: isSigningOut ? null : onSignOut,
                    icon: const Icon(Icons.logout_rounded),
                  ),
              ],
            ),
          );

          if (isShortHeight) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  ?profileBox,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: navTiles),
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
              ?profileBox,
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  children: navTiles,
                ),
              ),
              const Divider(height: 1),
              footer,
            ],
          );
        },
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    this.syncBadgeCounts,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool collapsed;
  final SyncQueueStatusCounts? syncBadgeCounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    final counts = syncBadgeCounts;
    final iconWidget = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 22,
      color: foreground,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: collapsed ? item.label : '',
        child: Material(
          color: selected ? colorScheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
                  if (collapsed && counts != null && counts.hasAnyItems)
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
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (counts != null && counts.hasAnyItems) ...[
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
