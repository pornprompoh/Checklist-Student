import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
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
              Text(
                'คลังรายชื่อนักเรียนประจำเทอม',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'จัดการรายชื่อกลางระดับเทอม ผูกเข้าหลายรายวิชา ย้ายเข้ากลางเทอม ย้ายออก และเรียงเลขที่ใหม่',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (yearsAsync.isLoading || termsAsync.isLoading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonBox(height: 52),
                  ),
                )
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
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'ยังไม่มีเทอมในระบบ กรุณาสร้างปีการศึกษาและเทอมที่หน้า "โครงสร้างสอน" ก่อนจัดการคลังรายชื่อ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final yearById = {for (final y in academicYears) y.id: y};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(selectedTerm.id),
                  initialValue: selectedTerm.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'เทอมที่กำลังจัดการคลังรายชื่อ',
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
                SegmentedButton<_RosterTabMode>(
                  segments: const [
                    ButtonSegment<_RosterTabMode>(
                      value: _RosterTabMode.homeroomMaster,
                      icon: Icon(Icons.groups_outlined, size: 18),
                      label: Text('คลังห้องเรียนกลาง'),
                    ),
                    ButtonSegment<_RosterTabMode>(
                      value: _RosterTabMode.subjectClassRoster,
                      icon: Icon(Icons.class_outlined, size: 18),
                      label: Text('รายชื่อแยกตามวิชา+ห้อง'),
                    ),
                  ],
                  selected: <_RosterTabMode>{_tabMode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      setState(() => _tabMode = selection.first);
                    }
                  },
                ),
              ],
            ),
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
