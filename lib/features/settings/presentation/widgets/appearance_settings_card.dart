import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/theme_mode_provider.dart';

/// Card for switching Light / Dark / System theme and displaying the
/// read-only `can_use_ai` status from `public.teacher_feature_flags`.
class AppearanceSettingsCard extends ConsumerWidget {
  const AppearanceSettingsCard({
    super.key,
    required this.canUseAi,
  });

  final bool canUseAi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semanticColors = AppSemanticColors.of(context);
    final currentMode = ref.watch(themeModeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'การแสดงผลและสิทธิ์การใช้งาน',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'โหมดสีของแอพ (Theme)',
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined, size: 18),
                    label: Text('ตามระบบ'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined, size: 18),
                    label: Text('สว่าง'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text('มืด'),
                  ),
                ],
                selected: <ThemeMode>{currentMode},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selection.first);
                  }
                },
              ),
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'สิทธิ์นำเข้ารายชื่อด้วย AI:',
                  style: textTheme.labelLarge,
                ),
                Chip(
                  avatar: Icon(
                    canUseAi
                        ? Icons.auto_awesome_rounded
                        : Icons.lock_outline_rounded,
                    size: 16,
                    color: canUseAi
                        ? semanticColors.success
                        : colorScheme.onSurfaceVariant,
                  ),
                  backgroundColor: canUseAi
                      ? semanticColors.successContainer
                      : colorScheme.surfaceContainerHighest,
                  label: Text(
                    canUseAi ? 'เปิดใช้งานแล้ว' : 'ปิดใช้งาน (อ่านอย่างเดียว)',
                    style: textTheme.labelMedium?.copyWith(
                      color: canUseAi
                          ? semanticColors.success
                          : colorScheme.onSurfaceVariant,
                    ),
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
      ),
    );
  }
}
