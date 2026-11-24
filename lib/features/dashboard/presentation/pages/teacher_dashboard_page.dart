import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../providers/dashboard_controller.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_class_card.dart';
import '../widgets/dashboard_header_bar.dart';
import '../widgets/dashboard_skeleton_view.dart';
import '../widgets/dashboard_summary_metrics.dart';

/// Main Teacher Dashboard page (`/teacher/dashboard`) showing the active term,
/// smartly sorted classroom cards (today's schedule + pinned first), and
/// one-tap attendance shortcuts with today's 4-state summary.
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

    ref.listen<AsyncValue<void>>(dashboardControllerProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final teacherName =
        authState.profile?.effectiveDisplayName ?? 'ครูผู้สอน';
    final academicYears =
        yearsAsync.asData?.value ?? const <AcademicYear>[];
    final terms = termsAsync.asData?.value ?? const <Term>[];

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeaderBar(
                teacherDisplayName: teacherName,
                today: today,
                academicYears: academicYears,
                terms: terms,
                selectedTerm: selectedTerm,
                activeTermId: activeTerm?.id,
                isBusy: isBusy,
                onSelectTerm: (termId) =>
                    ref.read(selectedTermIdProvider.notifier).select(termId),
                onRefresh: () =>
                    ref.read(dashboardControllerProvider.notifier).refresh(),
              ),
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
                _EmptyDashboardCard(
                  icon: Icons.school_outlined,
                  title: 'ยังไม่มีภาคเรียนในระบบ',
                  subtitle:
                      'เริ่มต้นสร้างปีการศึกษา เทอม รายวิชา และห้องเรียนที่หน้าโครงสร้างการสอน',
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
                      return _EmptyDashboardCard(
                        icon: Icons.class_outlined,
                        title: 'ยังไม่มีห้องเรียนในเทอม ${selectedTerm.termLabel}',
                        subtitle:
                            'เพิ่มรายวิชาและห้องเรียนพร้อมกำหนดวันสอน เพื่อเริ่มเช็คชื่อและเก็บคะแนนได้ทันที',
                        actionLabel: 'เพิ่มรายวิชาและห้องเรียน',
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
    final filteredClasses = sorter.filterClasses(
      overview.classes,
      todayIsoWeekday: overview.referenceDate.weekday,
      onlyToday: filterState.mode == DashboardFilterMode.today,
      onlyPinned: filterState.mode == DashboardFilterMode.pinned,
      query: filterState.query,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSummaryMetrics(overview: overview),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text('ทั้งหมด (${overview.totalClassesCount})'),
                  selected: filterState.mode == DashboardFilterMode.all,
                  onSelected: (_) => ref
                      .read(dashboardFilterProvider.notifier)
                      .setMode(DashboardFilterMode.all),
                ),
                ChoiceChip(
                  label: Text('มีสอนวันนี้ (${overview.todayClassesCount})'),
                  selected: filterState.mode == DashboardFilterMode.today,
                  onSelected: (_) => ref
                      .read(dashboardFilterProvider.notifier)
                      .setMode(DashboardFilterMode.today),
                ),
                ChoiceChip(
                  label: const Text('ปักหมุด'),
                  selected: filterState.mode == DashboardFilterMode.pinned,
                  onSelected: (_) => ref
                      .read(dashboardFilterProvider.notifier)
                      .setMode(DashboardFilterMode.pinned),
                ),
              ],
            ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    ref.read(dashboardFilterProvider.notifier).setQuery(value),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'ค้นหารหัสวิชา ชื่อวิชา หรือห้อง...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: filterState.query.isNotEmpty
                      ? IconButton(
                          tooltip: 'ล้างคำค้นหา',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(dashboardFilterProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (filteredClasses.isEmpty)
          _EmptyDashboardCard(
            icon: Icons.filter_list_off_rounded,
            title: 'ไม่พบห้องเรียนตามตัวกรองที่เลือก',
            subtitle: 'ลองเปลี่ยนตัวกรองเป็น "ทั้งหมด" หรือล้างคำค้นหา',
            actionLabel: 'แสดงห้องเรียนทั้งหมด',
            onAction: () {
              _searchController.clear();
              ref.read(dashboardFilterProvider.notifier).clear();
            },
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1040
                  ? 3
                  : (constraints.maxWidth >= 680 ? 2 : 1);
              const spacing = 12.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in filteredClasses)
                    SizedBox(
                      width: cardWidth,
                      child: DashboardClassCard(
                        item: item,
                        todayIsoWeekday: overview.referenceDate.weekday,
                        isBusy: isBusy,
                        onTogglePin: () => ref
                            .read(dashboardControllerProvider.notifier)
                            .togglePin(
                              termId: overview.termId,
                              subjectClassId: item.subjectClassId,
                              isPinned: !item.isPinned,
                            ),
                        onOpenAttendance: () => context.go(
                          AppRoutes.teacherAttendanceForClass(
                            item.subjectClassId,
                          ),
                        ),
                        onOpenRoster: () =>
                            context.go(AppRoutes.teacherHomeroomRoster),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  const _EmptyDashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 42, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
