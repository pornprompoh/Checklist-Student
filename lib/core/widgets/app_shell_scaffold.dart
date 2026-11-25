import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/sign_in_controller.dart';
import '../../features/sync_queue/presentation/providers/sync_queue_providers.dart';
import '../constants/app_routes.dart';
import '../network/connectivity_provider.dart';
import 'app_shell_banners.dart';
import 'app_shell_mobile_app_bar.dart';
import 'app_shell_nav_items.dart';
import 'app_shell_sidebar.dart';
import 'unsaved_changes_guard.dart';
import 'unsaved_changes_provider.dart';

/// Responsive Teacher App Shell switching between a collapsible, grouped
/// Desktop Sidebar (`width >= 900`) and a Mobile/Tablet layout with a clean
/// top AppBar + 5-slot Bottom NavigationBar (`< 900`).
///
/// Always guards navigation & sign-out with [UnsavedChangesGuard] and shows
/// the global Offline / Sync Conflict banners.
class AppShellScaffold extends ConsumerStatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  static const double desktopBreakpoint = 900;

  @override
  ConsumerState<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold> {
  bool _isSidebarCollapsed = false;

  Future<bool> _confirmLeaveIfDirty() async {
    if (!ref.read(unsavedChangesStateProvider)) {
      return true;
    }
    final shouldDiscard = await UnsavedChangesGuard.confirmDiscard(context);
    if (!shouldDiscard || !mounted) {
      return false;
    }
    ref.read(unsavedChangesStateProvider.notifier).clearAll();
    return true;
  }

  Future<void> _navigate(String route) async {
    if (widget.currentPath == route) {
      return;
    }
    if (!await _confirmLeaveIfDirty() || !mounted) {
      return;
    }
    context.go(route);
  }

  Future<void> _handleSignOut() async {
    if (!await _confirmLeaveIfDirty() || !mounted) {
      return;
    }
    await ref.read(signInControllerProvider.notifier).signOut();
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

    final body = Column(
      children: [
        AppShellBanners(
          isOffline: isOffline,
          showConflictBanner: showConflictBanner,
          conflictCount: syncCounts.conflictCount,
          onReviewConflicts: () => _navigate(AppRoutes.teacherSyncQueue),
        ),
        Expanded(child: widget.child),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              AppShellSidebar(
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
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    const items = AppShellNavigation.mobilePrimaryItems;
    return Scaffold(
      appBar: AppShellMobileAppBar(
        title: AppShellNavigation.titleFor(widget.currentPath),
        syncCounts: syncCounts,
        onOpenSyncQueue: () => _navigate(AppRoutes.teacherSyncQueue),
        onOpenAuditLog: () => _navigate(AppRoutes.teacherAuditLog),
        onSignOut: _handleSignOut,
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: AppShellNavigation.mobileIndexFor(widget.currentPath),
        onDestinationSelected: (index) => _navigate(items[index].route),
        destinations: [
          for (final item in items)
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
