import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_container.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../academic_structure/domain/services/term_label_formatter.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../providers/homeroom_roster_controller.dart';
import '../widgets/homeroom_master_tab_view.dart';
import '../widgets/subject_class_roster_tab_view.dart';

enum _RosterTabMode { homeroomMaster, subjectClassRoster }

/// Term-level Homeroom Master Roster & Subject-Class Enrollment page
/// (`/teacher/homeroom-roster`) with Independent Split-Pane Scroll on Desktop
/// and safe vertical fallback on mobile / short viewports.
class HomeroomRosterPage extends ConsumerStatefulWidget {
  const HomeroomRosterPage({super.key});

  @override
  ConsumerState<HomeroomRosterPage> createState() => _HomeroomRosterPageState();
}

class _HomeroomRosterPageState extends ConsumerState<HomeroomRosterPage> {
  _RosterTabMode _tabMode = _RosterTabMode.homeroomMaster;

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final termsAsync = ref.watch(allTermsProvider);
    final isBusy = ref.watch(homeroomRosterControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(homeroomRosterControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplitPane =
            constraints.maxWidth >= 900 && constraints.maxHeight >= 580;

        if (yearsAsync.isLoading || termsAsync.isLoading) {
          return _buildScrollableShell(
            child: const AppSurfaceCard(child: SkeletonBox(height: 52)),
          );
        }

        if (yearsAsync.hasError || termsAsync.hasError) {
          return _buildScrollableShell(
            child: AppFeedbackBanner(
              type: AppFeedbackType.error,
              message: ThaiErrorMapper.map(
                yearsAsync.error ?? termsAsync.error!,
              ),
              onRetry: () {
                ref.invalidate(academicYearsProvider);
                ref.invalidate(allTermsProvider);
              },
            ),
          );
        }

        final academicYears = yearsAsync.asData?.value ?? const <AcademicYear>[];
        final terms = termsAsync.asData?.value ?? const <Term>[];
        final selectedTerm = ref.watch(effectiveSelectedTermProvider);

        if (terms.isEmpty || selectedTerm == null) {
          return _buildScrollableShell(
            child: AppEmptyState(
              icon: Icons.groups_outlined,
              title: 'ยังไม่มีเทอมในระบบ',
              description:
                  'กรุณาสร้างปีการศึกษาและเทอมที่หน้า "โครงสร้างสอน" ก่อนจัดการคลังรายชื่อ',
              actionLabel: 'ไปหน้าโครงสร้างสอน',
              actionIcon: Icons.account_tree_outlined,
              onAction: () => GoRouter.maybeOf(
                context,
              )?.go(AppRoutes.teacherAcademicStructure),
            ),
          );
        }

        final controlsBar = _buildControlsCard(
          context,
          academicYears: academicYears,
          terms: terms,
          selectedTerm: selectedTerm,
          isBusy: isBusy,
          isWide: isSplitPane,
        );
        final activeTabView = _tabMode == _RosterTabMode.homeroomMaster
            ? HomeroomMasterTabView(
                term: selectedTerm,
                isSplitPane: isSplitPane,
                isBusy: isBusy,
              )
            : SubjectClassRosterTabView(
                term: selectedTerm,
                isSplitPane: isSplitPane,
                isBusy: isBusy,
              );

        if (isSplitPane) {
          return AppPageContainer.viewport(
            header: _pageHeader,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                controlsBar,
                const SizedBox(height: 16),
                Expanded(child: activeTabView),
              ],
            ),
          );
        }

        return _buildScrollableShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              controlsBar,
              const SizedBox(height: 16),
              activeTabView,
            ],
          ),
        );
      },
    );
  }

  static const AppPageHeader _pageHeader = AppPageHeader(
    title: 'คลังรายชื่อนักเรียนประจำเทอม',
  );

  Widget _buildScrollableShell({required Widget child}) {
    return AppPageContainer.scrollable(header: _pageHeader, child: child);
  }

  Widget _buildControlsCard(
    BuildContext context, {
    required List<AcademicYear> academicYears,
    required List<Term> terms,
    required Term selectedTerm,
    required bool isBusy,
    required bool isWide,
  }) {
    final yearById = {for (final y in academicYears) y.id: y};
    final termDropdown = DropdownButtonFormField<String>(
      key: ValueKey<String>(selectedTerm.id),
      initialValue: selectedTerm.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'เทอมที่กำลังจัดการคลังรายชื่อ',
        prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        isDense: true,
      ),
      items: [
        for (final term in terms)
          DropdownMenuItem<String>(
            value: term.id,
            child: Text(
              TermLabelFormatter.formatFullLabel(
                term,
                academicYearBe: yearById[term.academicYearId]?.yearBe,
              ),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ),
      ],
      onChanged: isBusy
          ? null
          : (id) {
              if (id != null) {
                ref.read(selectedTermIdProvider.notifier).select(id);
              }
            },
    );

    final segmentSwitcher = LayoutBuilder(
      builder: (context, constraints) {
        final showSegmentIcons = constraints.maxWidth >= 420;
        return SegmentedButton<_RosterTabMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment<_RosterTabMode>(
              value: _RosterTabMode.homeroomMaster,
              icon: showSegmentIcons
                  ? const Icon(Icons.groups_outlined, size: 18)
                  : null,
              label: const Text(
                'คลังห้องเรียนกลาง',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            ButtonSegment<_RosterTabMode>(
              value: _RosterTabMode.subjectClassRoster,
              icon: showSegmentIcons
                  ? const Icon(Icons.class_outlined, size: 18)
                  : null,
              label: const Text(
                'รายชื่อแยกตามวิชา+ห้อง',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          selected: <_RosterTabMode>{_tabMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              setState(() => _tabMode = selection.first);
            }
          },
        );
      },
    );

    return isWide
        ? Row(
            children: [
              Expanded(flex: 5, child: termDropdown),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: segmentSwitcher),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              termDropdown,
              const SizedBox(height: 12),
              segmentSwitcher,
            ],
          );
  }
}
