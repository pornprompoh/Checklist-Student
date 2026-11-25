import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/providers/sign_in_controller.dart';
import '../theme/app_color_scheme.dart';
import '../theme/theme_mode_provider.dart';

/// Sidebar footer: borderless tonal teacher profile strip with online/offline
/// status dot, theme switcher, and sign-out action (zero card-in-card clutter).
class AppShellSidebarFooter extends ConsumerWidget {
  const AppShellSidebarFooter({
    super.key,
    required this.collapsed,
    required this.isOnline,
    required this.onSignOut,
  });

  final bool collapsed;
  final bool isOnline;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSigningOut = ref.watch(signInControllerProvider).isLoading;
    final profile = ref.watch(authStateProvider).profile;
    final statusLabel = isOnline ? 'ออนไลน์' : 'ออฟไลน์';
    final statusColor = isOnline ? semantic.success : semantic.danger;

    final avatar = Tooltip(
      message: statusLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );

    final themeButton = IconButton(
      tooltip: isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด',
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .toggleTheme(platformBrightness: Theme.of(context).brightness),
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 20,
      ),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 8),
            themeButton,
            IconButton(
              tooltip: 'ออกจากระบบ',
              onPressed: isSigningOut ? null : onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 20),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile?.effectiveDisplayName ?? 'ครูผู้สอน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                      Text(
                        profile != null
                            ? '${profile.teacherCode} · $statusLabel'
                            : statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              themeButton,
              const SizedBox(width: 4),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: isSigningOut ? null : onSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'ออกจากระบบ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
