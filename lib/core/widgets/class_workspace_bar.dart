import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import 'unsaved_changes_guard.dart';
import 'unsaved_changes_provider.dart';

/// The four class-scoped workspaces a teacher switches between in 1 tap.
enum ClassWorkspaceTab {
  attendance('เช็คชื่อ', Icons.fact_check_outlined, Icons.fact_check_rounded),
  grading('ตารางคะแนน', Icons.table_chart_outlined, Icons.table_chart_rounded),
  plan('แผนเก็บงาน', Icons.assignment_outlined, Icons.assignment_rounded),
  export('ส่งออกรายงาน', Icons.file_download_outlined, Icons.file_download_rounded);

  const ClassWorkspaceTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Route for this workspace pre-selecting [subjectClassId].
  String routeFor(String subjectClassId) => switch (this) {
    ClassWorkspaceTab.attendance => AppRoutes.teacherAttendanceForClass(
      subjectClassId,
    ),
    ClassWorkspaceTab.grading => AppRoutes.teacherGradingForClass(
      subjectClassId,
    ),
    ClassWorkspaceTab.plan => AppRoutes.teacherGradingPlanForClass(
      subjectClassId,
    ),
    ClassWorkspaceTab.export => AppRoutes.teacherExportReportsForClass(
      subjectClassId,
    ),
  };
}

/// Compact segmented pill bar with exact concentric radii (`outer: 12`,
/// `padding: 4` → `inner: 8`), desktop hover/focus feedback, horizontal
/// scroll on `320px` screens, and [UnsavedChangesGuard] protection.
class ClassWorkspaceBar extends ConsumerWidget {
  const ClassWorkspaceBar({
    super.key,
    required this.subjectClassId,
    required this.activeTab,
    this.onSelectTab,
  });

  final String subjectClassId;
  final ClassWorkspaceTab activeTab;

  /// Overrides default `GoRouter` navigation when provided.
  final ValueChanged<ClassWorkspaceTab>? onSelectTab;

  Future<void> _handleSelect(
    BuildContext context,
    WidgetRef ref,
    ClassWorkspaceTab tab,
  ) async {
    if (tab == activeTab) return;
    if (onSelectTab != null) {
      onSelectTab!(tab);
      return;
    }
    if (ref.read(unsavedChangesStateProvider)) {
      final discard = await UnsavedChangesGuard.confirmDiscard(context);
      if (!discard || !context.mounted) return;
      ref.read(unsavedChangesStateProvider.notifier).clearAll();
    }
    if (!context.mounted) return;
    GoRouter.maybeOf(context)?.go(tab.routeFor(subjectClassId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final innerRadius = BorderRadius.circular(8);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < ClassWorkspaceTab.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _WorkspaceSegment(
                tab: ClassWorkspaceTab.values[i],
                isSelected: ClassWorkspaceTab.values[i] == activeTab,
                radius: innerRadius,
                textTheme: textTheme,
                onTap: () =>
                    _handleSelect(context, ref, ClassWorkspaceTab.values[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkspaceSegment extends StatelessWidget {
  const _WorkspaceSegment({
    required this.tab,
    required this.isSelected,
    required this.radius,
    required this.textTheme,
    required this.onTap,
  });

  final ClassWorkspaceTab tab;
  final bool isSelected;
  final BorderRadius radius;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      key: ValueKey<String>('class_workspace_tab_${tab.name}'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.surface : Colors.transparent,
        borderRadius: radius,
        border: isSelected
            ? Border.all(color: colorScheme.outlineVariant)
            : null,
        boxShadow: isSelected
            ? <BoxShadow>[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? tab.selectedIcon : tab.icon,
                  size: 18,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  tab.label,
                  style: textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
