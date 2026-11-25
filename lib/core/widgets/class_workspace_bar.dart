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

/// Borderless Linear/Vercel-style underline tab bar sitting on a `1px` bottom
/// hairline border (`outlineVariant`) with a `2px` `primary` active underline.
///
/// On Desktop (`viewport >= 900px` and available width `>= 740px`), aligns an
/// optional [trailing] slot (such as the compact class selector dropdown) flush
/// right on the same row. On narrower screens, places [trailing] full-width
/// cleanly below the scrollable tab strip with zero overflow.
class ClassWorkspaceBar extends ConsumerWidget {
  const ClassWorkspaceBar({
    super.key,
    required this.subjectClassId,
    required this.activeTab,
    this.trailing,
    this.onSelectTab,
  });

  final String subjectClassId;
  final ClassWorkspaceTab activeTab;

  /// Optional compact widget aligned flush right beside the tabs on Desktop
  /// (stacks cleanly full-width below on narrow screens).
  final Widget? trailing;

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
    final viewportWidth = MediaQuery.sizeOf(context).width;

    final tabStrip = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < ClassWorkspaceTab.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _UnderlineTab(
              tab: ClassWorkspaceTab.values[i],
              isSelected: ClassWorkspaceTab.values[i] == activeTab,
              textTheme: textTheme,
              onTap: () =>
                  _handleSelect(context, ref, ClassWorkspaceTab.values[i]),
            ),
          ],
        ],
      ),
    );

    final bottomBorder = BoxDecoration(
      border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
    );

    if (trailing == null) {
      return DecoratedBox(
        decoration: bottomBorder,
        child: Align(alignment: Alignment.centerLeft, child: tabStrip),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isInlineTrailing =
            viewportWidth >= 900 && constraints.maxWidth >= 740;

        if (isInlineTrailing) {
          return DecoratedBox(
            decoration: bottomBorder,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: tabStrip),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 260,
                      maxWidth: 360,
                    ),
                    child: trailing!,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: bottomBorder,
              child: Align(alignment: Alignment.centerLeft, child: tabStrip),
            ),
            const SizedBox(height: 10),
            trailing!,
          ],
        );
      },
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  const _UnderlineTab({
    required this.tab,
    required this.isSelected,
    required this.textTheme,
    required this.onTap,
  });

  final ClassWorkspaceTab tab;
  final bool isSelected;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const topRadius = BorderRadius.vertical(top: Radius.circular(8));

    return Material(
      key: ValueKey<String>('class_workspace_tab_${tab.name}'),
      type: MaterialType.transparency,
      borderRadius: topRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: topRadius,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.05),
        focusColor: colorScheme.primary.withValues(alpha: 0.10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? tab.selectedIcon : tab.icon,
                size: 16,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
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
    );
  }
}
