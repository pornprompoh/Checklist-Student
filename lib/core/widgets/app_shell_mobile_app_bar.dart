import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/sign_in_controller.dart';
import '../../features/sync_queue/presentation/providers/sync_queue_providers.dart';
import '../../features/sync_queue/presentation/widgets/sync_status_badge.dart';
import '../theme/app_color_scheme.dart';
import '../theme/theme_mode_provider.dart';

enum _MobileMenuAction { auditLog, syncQueue, toggleTheme, signOut }

/// Clean Mobile/Tablet (`< 900px`) top AppBar with generous breathing room
/// for page titles even at `320px`: sync queue icon + compact [SyncStatusBadge]
/// and an overflow menu (`ประวัติคะแนน`, `สถานะซิงค์`, สลับธีม, `ออกจากระบบ`).
class AppShellMobileAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const AppShellMobileAppBar({
    super.key,
    required this.title,
    required this.syncCounts,
    required this.onOpenSyncQueue,
    required this.onOpenAuditLog,
    required this.onSignOut,
  });

  final String title;
  final SyncQueueStatusCounts syncCounts;
  final VoidCallback onOpenSyncQueue;
  final VoidCallback onOpenAuditLog;
  final VoidCallback onSignOut;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSigningOut = ref.watch(signInControllerProvider).isLoading;
    final semantic = AppSemanticColors.of(context);

    return AppBar(
      titleSpacing: 16,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: 'สถานะการซิงค์ข้อมูลออฟไลน์',
          visualDensity: VisualDensity.compact,
          onPressed: onOpenSyncQueue,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                syncCounts.hasConflicts
                    ? Icons.sync_problem_rounded
                    : Icons.sync_rounded,
                size: 21,
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
        PopupMenuButton<_MobileMenuAction>(
          tooltip: 'เมนูเพิ่มเติม',
          icon: const Icon(Icons.more_vert_rounded, size: 21),
          onSelected: (action) {
            switch (action) {
              case _MobileMenuAction.auditLog:
                onOpenAuditLog();
              case _MobileMenuAction.syncQueue:
                onOpenSyncQueue();
              case _MobileMenuAction.toggleTheme:
                ref
                    .read(themeModeProvider.notifier)
                    .toggleTheme(
                      platformBrightness: Theme.of(context).brightness,
                    );
              case _MobileMenuAction.signOut:
                if (!isSigningOut) onSignOut();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _MobileMenuAction.auditLog,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.history_rounded),
                title: Text('ประวัติคะแนน'),
              ),
            ),
            const PopupMenuItem(
              value: _MobileMenuAction.syncQueue,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.sync_rounded),
                title: Text('สถานะซิงค์'),
              ),
            ),
            PopupMenuItem(
              value: _MobileMenuAction.toggleTheme,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                title: Text(isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _MobileMenuAction.signOut,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded),
                title: Text('ออกจากระบบ'),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
