import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_surface_card.dart';

/// Card for switching Light / Dark / System theme with tactile visual tiles and
/// displaying the read-only `can_use_ai` status from `public.teacher_feature_flags`.
class AppearanceSettingsCard extends ConsumerWidget {
  const AppearanceSettingsCard({super.key, required this.canUseAi});

  final bool canUseAi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semanticColors = AppSemanticColors.of(context);
    final currentMode = ref.watch(themeModeProvider);

    return AppSurfaceCard(
      title: 'การแสดงผลและสิทธิ์การใช้งาน',
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'โหมดสีของแอพ (Theme)',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = constraints.maxWidth >= 420
                  ? (constraints.maxWidth - 20) / 3
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ThemeModeOptionTile(
                    width: tileWidth,
                    label: 'ตามระบบ',
                    subtitle: 'ปรับตามอุปกรณ์',
                    icon: Icons.brightness_auto_outlined,
                    selected: currentMode == ThemeMode.system,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system),
                  ),
                  _ThemeModeOptionTile(
                    width: tileWidth,
                    label: 'สว่าง',
                    subtitle: 'สบายตาในห้องเรียน',
                    icon: Icons.light_mode_outlined,
                    selected: currentMode == ThemeMode.light,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light),
                  ),
                  _ThemeModeOptionTile(
                    width: tileWidth,
                    label: 'มืด',
                    subtitle: 'ลดแสงสะท้อนตอนค่ำ',
                    icon: Icons.dark_mode_outlined,
                    selected: currentMode == ThemeMode.dark,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'สิทธิ์นำเข้ารายชื่อด้วย AI:',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: canUseAi
                      ? semanticColors.successContainer
                      : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canUseAi
                          ? Icons.auto_awesome_rounded
                          : Icons.lock_outline_rounded,
                      size: 16,
                      color: canUseAi
                          ? semanticColors.success
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        canUseAi
                            ? 'เปิดใช้งานแล้ว'
                            : 'ปิดใช้งาน (อ่านอย่างเดียว)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: canUseAi
                              ? semanticColors.success
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'สิทธิ์การใช้งาน AI ถูกควบคุมโดยผู้ดูแลระบบเพื่อรักษาโควตา Free Tier และไม่สามารถแก้ไขได้จากหน้านี้',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeOptionTile extends StatelessWidget {
  const _ThemeModeOptionTile({
    required this.width,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
