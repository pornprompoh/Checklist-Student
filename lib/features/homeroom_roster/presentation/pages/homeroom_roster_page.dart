import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../providers/homeroom_roster_controller.dart';
import '../widgets/homeroom_master_tab_view.dart';
import '../widgets/subject_class_roster_tab_view.dart';

enum _RosterTabMode { homeroomMaster, subjectClassRoster }

/// Term-level Homeroom Master Roster & Subject-Class Enrollment page
/// (`/teacher/homeroom-roster`).
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    ref.listen<AsyncValue<void>>(homeroomRosterControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageHeader(
                title: 'คลังรายชื่อนักเรียนประจำเทอม',
                subtitle:
                    'จัดการรายชื่อกลางระดับเทอม ผูกเข้าหลายรายวิชา ย้ายเข้ากลางเทอม ย้ายออก และเรียงเลขที่ใหม่',
              ),
              const SizedBox(height: 20),
              if (yearsAsync.isLoading || termsAsync.isLoading)
                const AppSurfaceCard(child: SkeletonBox(height: 52))
              else if (yearsAsync.hasError || termsAsync.hasError)
                AppFeedbackBanner(
                  type: AppFeedbackType.error,
                  message: ThaiErrorMapper.map(
                    yearsAsync.error ?? termsAsync.error!,
                  ),
                  onRetry: () {
                    ref.invalidate(academicYearsProvider);
                    ref.invalidate(allTermsProvider);
                  },
                )
              else
                _buildBody(
                  academicYears: yearsAsync.asData?.value ?? const [],
                  terms: termsAsync.asData?.value ?? const [],
                  isDesktop: isDesktop,
                  isBusy: isBusy,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<AcademicYear> academicYears,
    required List<Term> terms,
    required bool isDesktop,
    required bool isBusy,
  }) {
    final selectedTerm = ref.watch(effectiveSelectedTermProvider);
    if (terms.isEmpty || selectedTerm == null) {
      return AppEmptyState(
        icon: Icons.groups_outlined,
        title: 'ยังไม่มีเทอมในระบบ',
        description:
            'กรุณาสร้างปีการศึกษาและเทอมที่หน้า "โครงสร้างสอน" ก่อนจัดการคลังรายชื่อ',
        actionLabel: 'ไปหน้าโครงสร้างสอน',
        actionIcon: Icons.account_tree_outlined,
        onAction: () =>
            GoRouter.maybeOf(context)?.go(AppRoutes.teacherAcademicStructure),
      );
    }

    final yearById = {for (final y in academicYears) y.id: y};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey<String>(selectedTerm.id),
                initialValue: selectedTerm.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'เทอมที่กำลังจัดการคลังรายชื่อ',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                items: [
                  for (final term in terms)
                    DropdownMenuItem<String>(
                      value: term.id,
                      child: Text(
                        'ปีการศึกษา ${yearById[term.academicYearId]?.yearBe ?? ''} — '
                        'เทอม ${term.termLabel} '
                        '(${ThaiDateFormatter.formatDateRange(term.startDate, term.endDate)})',
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
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final showSegmentIcons = constraints.maxWidth >= 460;
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_tabMode == _RosterTabMode.homeroomMaster)
          HomeroomMasterTabView(
            term: selectedTerm,
            isDesktop: isDesktop,
            isBusy: isBusy,
          )
        else
          SubjectClassRosterTabView(term: selectedTerm, isBusy: isBusy),
      ],
    );
  }
}
