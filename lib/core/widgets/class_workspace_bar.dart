import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import 'unsaved_changes_guard.dart';
import 'unsaved_changes_provider.dart';

/// The four class-scoped workspaces a teacher jumps between.
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

/// Compact segmented pill bar to switch between `เช็คชื่อ · ตารางคะแนน ·
/// แผนเก็บงาน · ส่งออกรายงาน` of the same class in one tap. Scrolls
/// horizontally on `320px` screens and respects [UnsavedChangesGuard].
class ClassWorkspaceBar extends ConsumerWidget {
  const ClassWorkspaceBar({
    super.key,
    required this.subjectClassId,
    required this.activeTab,
    this.onSelectTab,
  });

  final String subjectClassId;
  final ClassWorkspaceTab activeTab;

  /// Overrides the default `GoRouter` navigation when provided.
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
            for (final tab in ClassWorkspaceTab.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  key: ValueKey<String>('class_workspace_tab_${tab.name}'),
                  color: tab == activeTab
                      ? colorScheme.surface
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                    side: tab == activeTab
                        ? BorderSide(color: colorScheme.outlineVariant)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => _handleSelect(context, ref, tab),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab == activeTab ? tab.selectedIcon : tab.icon,
                            size: 18,
                            color: tab == activeTab
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab.label,
                            style: textTheme.labelLarge?.copyWith(
                              color: tab == activeTab
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: tab == activeTab
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
