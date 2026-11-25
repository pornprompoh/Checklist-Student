import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../audit_log/presentation/providers/audit_log_providers.dart';
import '../../../audit_log/presentation/widgets/audit_log_cleanup_banner.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/dashboard_class_item.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../providers/dashboard_controller.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_class_grid_section.dart';
import '../widgets/dashboard_filter_bar.dart';
import '../widgets/dashboard_header_bar.dart';
import '../widgets/dashboard_skeleton_view.dart';
import '../widgets/dashboard_summary_metrics.dart';

/// Main Teacher Dashboard (`/teacher/dashboard`) with clear visual hierarchy:
/// compact header & term pill, 4-metric KPI strip, conditional alert slot,
/// prominent "คาบสอนวันนี้" section, and full term class grid.
class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final termsAsync = ref.watch(allTermsProvider);
    final activeTerm = ref.watch(activeTermProvider);
    final selectedTerm = ref.watch(effectiveSelectedTermProvider);
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final filterState = ref.watch(dashboardFilterProvider);
    final isBusy = ref.watch(dashboardControllerProvider).isLoading;
    final hasCleanupAlerts = ref.watch(auditLogCleanupAlertsProvider).isNotEmpty;

    ref.listen<AsyncValue<void>>(dashboardControllerProvider, (prev, next) {
      if (next.hasError && prev?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final teacherName = authState.profile?.effectiveDisplayName ?? 'ครูผู้สอน';
    final years = yearsAsync.asData?.value ?? const <AcademicYear>[];
    final terms = termsAsync.asData?.value ?? const <Term>[];

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeaderBar(
                teacherDisplayName: teacherName,
                today: today,
                academicYears: years,
                terms: terms,
                selectedTerm: selectedTerm,
                activeTermId: activeTerm?.id,
                isBusy: isBusy,
                onSelectTerm: (termId) =>
                    ref.read(selectedTermIdProvider.notifier).select(termId),
                onRefresh: () =>
                    ref.read(dashboardControllerProvider.notifier).refresh(),
                onAddClass: () =>
                    context.go(AppRoutes.teacherAcademicStructure),
              ),
              if (hasCleanupAlerts) ...[
                const SizedBox(height: 16),
                const AuditLogCleanupBanner(),
              ],
              const SizedBox(height: 16),
              if (yearsAsync.isLoading || termsAsync.isLoading)
                const DashboardSkeletonView()
              else if (yearsAsync.hasError || termsAsync.hasError)
                AppFeedbackBanner(
                  type: AppFeedbackType.error,
                  message: ThaiErrorMapper.map(
                    yearsAsync.error ?? termsAsync.error!,
                  ),
                  onRetry: () =>
                      ref.read(dashboardControllerProvider.notifier).refresh(),
                )
              else if (selectedTerm == null)
                AppEmptyState(
                  icon: Icons.school_outlined,
                  title: 'ยังไม่มีภาคเรียนในระบบ',
                  description:
                      'เริ่มต้นสร้างปีการศึกษา เทอม รายวิชา และห้องเรียนที่หน้าโครงสร้างสอน',
                  actionLabel: 'ไปหน้าโครงสร้างสอน',
                  onAction: () =>
                      context.go(AppRoutes.teacherAcademicStructure),
                )
              else
                overviewAsync.when(
                  loading: () => const DashboardSkeletonView(),
                  error: (error, _) => AppFeedbackBanner(
                    type: AppFeedbackType.error,
                    message: ThaiErrorMapper.map(error),
                    onRetry: () => ref.invalidate(dashboardOverviewProvider),
                  ),
                  data: (overview) {
                    if (overview == null || overview.classes.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.class_outlined,
                        title:
                            'ยังไม่มีห้องเรียนในเทอม ${selectedTerm.termLabel}',
                        description:
                            'เพิ่มรายวิชาและห้องเรียนพร้อมกำหนดวันสอน เพื่อเริ่มเช็คชื่อและเก็บคะแนนได้ทันที',
                        actionLabel: 'เพิ่มรายวิชาและห้องเรียน',
                        actionIcon: Icons.add_rounded,
                        onAction: () =>
                            context.go(AppRoutes.teacherAcademicStructure),
                      );
                    }
                    return _buildLoadedDashboard(
                      context,
                      overview: overview,
                      filterState: filterState,
                      isBusy: isBusy,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedDashboard(
    BuildContext context, {
    required DashboardOverview overview,
    required DashboardFilterState filterState,
    required bool isBusy,
  }) {
    final sorter = ref.watch(dashboardClassSorterServiceProvider);
    final weekday = overview.referenceDate.weekday;
    final filtered = sorter.filterClasses(
      overview.classes,
      todayIsoWeekday: weekday,
      onlyToday: filterState.mode == DashboardFilterMode.today,
      onlyPinned: filterState.mode == DashboardFilterMode.pinned,
      query: filterState.query,
    );

    final showSplitSections =
        filterState.mode == DashboardFilterMode.all &&
        filterState.query.trim().isEmpty;
    final todayClasses = filtered
        .where((c) => c.teachesOnWeekday(weekday))
        .toList(growable: false);
    final otherClasses = filtered
        .where((c) => !c.teachesOnWeekday(weekday))
        .toList(growable: false);

    void handleTogglePin(DashboardClassItem item) {
      ref
          .read(dashboardControllerProvider.notifier)
          .togglePin(
            termId: overview.termId,
            subjectClassId: item.subjectClassId,
            isPinned: !item.isPinned,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSummaryMetrics(overview: overview),
        const SizedBox(height: 20),
        DashboardFilterBar(
          totalClassesCount: overview.totalClassesCount,
          todayClassesCount: overview.todayClassesCount,
          filterState: filterState,
          searchController: _searchController,
          onModeChanged: (mode) =>
              ref.read(dashboardFilterProvider.notifier).setMode(mode),
          onQueryChanged: (query) =>
              ref.read(dashboardFilterProvider.notifier).setQuery(query),
          onClearQuery: () {
            _searchController.clear();
            ref.read(dashboardFilterProvider.notifier).setQuery('');
          },
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          AppEmptyState(
            icon: Icons.filter_list_off_rounded,
            title: 'ไม่พบห้องเรียนตามตัวกรองที่เลือก',
            description: 'ลองเปลี่ยนตัวกรองเป็น "ทั้งหมด" หรือล้างคำค้นหา',
            actionLabel: 'แสดงห้องเรียนทั้งหมด',
            actionIcon: Icons.refresh_rounded,
            onAction: () {
              _searchController.clear();
              ref.read(dashboardFilterProvider.notifier).clear();
            },
          )
        else if (showSplitSections && todayClasses.isNotEmpty) ...[
          DashboardClassGridSection(
            heading: 'คาบสอนวันนี้ (${todayClasses.length} ห้อง)',
            headingAccent: AppSemanticColors.of(context).success,
            items: todayClasses,
            overview: overview,
            isBusy: isBusy,
            onTogglePin: handleTogglePin,
          ),
          if (otherClasses.isNotEmpty) ...[
            const SizedBox(height: 24),
            DashboardClassGridSection(
              heading: 'ห้องเรียนทั้งหมดในเทอมนี้ (${otherClasses.length} ห้อง)',
              headingAccent: Theme.of(context).colorScheme.onSurfaceVariant,
              items: otherClasses,
              overview: overview,
              isBusy: isBusy,
              onTogglePin: handleTogglePin,
            ),
          ],
        ] else
          DashboardClassGridSection(
            items: filtered,
            overview: overview,
            isBusy: isBusy,
            onTogglePin: handleTogglePin,
          ),
      ],
    );
  }
}
