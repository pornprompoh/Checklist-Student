import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../domain/entities/audit_log_year_summary.dart';
import '../../domain/entities/score_audit_log_entry.dart';
import '../providers/audit_log_controller.dart';
import '../providers/audit_log_providers.dart';
import '../widgets/audit_log_cleanup_banner.dart';
import '../widgets/audit_log_entry_tile.dart';
import '../widgets/audit_log_filter_bar.dart';
import '../widgets/audit_log_yearly_cleanup_card.dart';

enum _AuditLogTab { history, yearlyCleanup }

/// Teacher Audit Log Viewer & Yearly Cleanup page (`/teacher/audit-log`).
class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({
    super.key,
    this.initialClassId,
    this.initialEnrollmentId,
  });

  final String? initialClassId;
  final String? initialEnrollmentId;

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  final _searchCtrl = TextEditingController();
  _AuditLogTab _tab = _AuditLogTab.history;

  @override
  void initState() {
    super.initState();
    _scheduleApplyInitialFilters();
  }

  @override
  void didUpdateWidget(covariant AuditLogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialClassId != widget.initialClassId ||
        oldWidget.initialEnrollmentId != widget.initialEnrollmentId) {
      _scheduleApplyInitialFilters();
    }
  }

  void _scheduleApplyInitialFilters() {
    final classId = widget.initialClassId?.trim();
    final enrollmentId = widget.initialEnrollmentId?.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(auditLogFilterProvider.notifier)
          .applyInitial(
            subjectClassId: (classId == null || classId.isEmpty)
                ? null
                : classId,
            enrollmentId: (enrollmentId == null || enrollmentId.isEmpty)
                ? null
                : enrollmentId,
          );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportYear(
    AuditLogYearSummary summary, {
    required bool asJson,
  }) async {
    final count = await ref
        .read(auditLogControllerProvider.notifier)
        .exportYearLogs(
          academicYearId: summary.academicYearId,
          yearBe: summary.yearBe,
          asJson: asJson,
        );
    if (count != null && mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message:
            'ส่งออกประวัติปี พ.ศ. ${summary.yearBe} ($count รายการ) เป็น '
            '${asJson ? '.json' : '.csv'} เรียบร้อยแล้ว',
      );
    }
  }

  Future<void> _deleteYear(AuditLogYearSummary summary) async {
    final deleted = await ref
        .read(auditLogControllerProvider.notifier)
        .deleteLogsForAcademicYear(summary.academicYearId);
    if (deleted != null && mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message:
            'ล้างประวัติ Log ปี พ.ศ. ${summary.yearBe} จำนวน $deleted รายการแล้ว '
            '(คะแนนจริงของนักเรียนยังคงอยู่ครบ)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(auditLogFilterProvider);
    final entriesAsync = ref.watch(auditLogEntriesProvider);
    final summariesAsync = ref.watch(auditLogYearSummariesProvider);
    final cleanupAlerts = ref.watch(auditLogCleanupAlertsProvider);
    final exportedYearIds = ref.watch(exportedAuditLogYearIdsProvider);
    final years =
        ref.watch(academicYearsProvider).asData?.value ??
        const <AcademicYear>[];
    final classOptions =
        ref.watch(allCopyableClassesProvider).asData?.value ??
        const <CopyPlanSourceClassOption>[];
    final isBusy = ref.watch(auditLogControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(auditLogControllerProvider, (prev, next) {
      if (next.hasError && prev?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    final rawEntries =
        entriesAsync.asData?.value ?? const <ScoreAuditLogEntry>[];
    final filteredEntries = rawEntries
        .where(filter.matchesSearch)
        .toList(growable: false);
    final selectedYearBe = filter.academicYearId == null
        ? null
        : years
              .where((y) => y.id == filter.academicYearId)
              .firstOrNull
              ?.yearBe;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useScrollableLayout =
            constraints.maxHeight < 680 || constraints.maxWidth < 640;

        final headerSection = AppPageHeader(
          title: 'ประวัติการแก้ไขคะแนนและสถานะเกรด',
          subtitle:
              'บันทึกอัตโนมัติแบบอ่านอย่างเดียว พร้อมส่งออก CSV/JSON และล้าง Log ประจำปี',
          actions: [
            SegmentedButton<_AuditLogTab>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<_AuditLogTab>>[
                ButtonSegment(
                  value: _AuditLogTab.history,
                  label: Text(
                    'ประวัติการแก้ไข',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                ButtonSegment(
                  value: _AuditLogTab.yearlyCleanup,
                  label: Text(
                    'จัดการล้าง Log รายปี',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
              selected: <_AuditLogTab>{_tab},
              onSelectionChanged: (sel) => setState(() => _tab = sel.first),
            ),
          ],
        );

        final filterBar = AuditLogFilterBar(
          filter: filter,
          academicYears: years,
          classOptions: classOptions,
          searchController: _searchCtrl,
          filteredCount: filteredEntries.length,
          isBusy: isBusy,
          onYearChanged: (id) =>
              ref.read(auditLogFilterProvider.notifier).setAcademicYearId(id),
          onClassChanged: (id) =>
              ref.read(auditLogFilterProvider.notifier).setSubjectClassId(id),
          onClearEnrollmentFilter: () => ref
              .read(auditLogFilterProvider.notifier)
              .clearEnrollmentFilter(),
          onTargetTypeChanged: (type) =>
              ref.read(auditLogFilterProvider.notifier).setTargetType(type),
          onSearchChanged: (q) =>
              ref.read(auditLogFilterProvider.notifier).setSearchQuery(q),
          onExportCsv: () {
            ref
                .read(auditLogControllerProvider.notifier)
                .exportEntries(
                  entries: filteredEntries,
                  asJson: false,
                  yearBe: selectedYearBe,
                  academicYearId: filter.academicYearId,
                );
            AppFeedbackBanner.showSnackBar(
              context,
              type: AppFeedbackType.success,
              message:
                  'ส่งออกไฟล์ .csv (${filteredEntries.length} รายการ) เรียบร้อยแล้ว',
            );
          },
          onExportJson: () {
            ref
                .read(auditLogControllerProvider.notifier)
                .exportEntries(
                  entries: filteredEntries,
                  asJson: true,
                  yearBe: selectedYearBe,
                  academicYearId: filter.academicYearId,
                );
            AppFeedbackBanner.showSnackBar(
              context,
              type: AppFeedbackType.success,
              message:
                  'ส่งออกไฟล์ .json (${filteredEntries.length} รายการ) เรียบร้อยแล้ว',
            );
          },
        );

        Widget buildHistoryBody({required bool shrinkWrap}) {
          return entriesAsync.when(
            loading: () => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 92),
                SizedBox(height: 12),
                SkeletonBox(height: 92),
              ],
            ),
            error: (error, _) => AppFeedbackBanner(
              type: AppFeedbackType.error,
              message: ThaiErrorMapper.map(error),
              onRetry: () => ref.invalidate(auditLogEntriesProvider),
            ),
            data: (_) {
              if (filteredEntries.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.history_rounded,
                  title: 'ไม่พบประวัติการแก้ไขคะแนนตามตัวกรองที่เลือก',
                  description:
                      'เมื่อมีการกรอกหรือแก้ไขคะแนนและสถานะ ร/มส ระบบจะบันทึกประวัติให้อัตโนมัติ',
                );
              }
              return ListView.separated(
                shrinkWrap: shrinkWrap,
                physics: shrinkWrap
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: filteredEntries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) =>
                    AuditLogEntryTile(entry: filteredEntries[index]),
              );
            },
          );
        }

        final cleanupBody = summariesAsync.when(
          loading: () => const SkeletonBox(height: 180),
          error: (error, _) => AppFeedbackBanner(
            type: AppFeedbackType.error,
            message: ThaiErrorMapper.map(error),
            onRetry: () => ref.invalidate(auditLogYearSummariesProvider),
          ),
          data: (summaries) => AuditLogYearlyCleanupCard(
            summaries: summaries,
            exportedYearIds: exportedYearIds,
            isBusy: isBusy,
            onExportYearCsv: (s) => _exportYear(s, asJson: false),
            onExportYearJson: (s) => _exportYear(s, asJson: true),
            onDeleteYearLogs: _deleteYear,
          ),
        );

        final bannerWidgets = cleanupAlerts.isEmpty
            ? const <Widget>[]
            : const <Widget>[
                AuditLogCleanupBanner(showNavigationAction: false),
                SizedBox(height: 12),
              ];

        if (useScrollableLayout) {
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerSection,
                    const SizedBox(height: 16),
                    ...bannerWidgets,
                    if (_tab == _AuditLogTab.history) ...[
                      filterBar,
                      const SizedBox(height: 12),
                      buildHistoryBody(shrinkWrap: true),
                    ] else
                      cleanupBody,
                  ],
                ),
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerSection,
                  const SizedBox(height: 16),
                  ...bannerWidgets,
                  if (_tab == _AuditLogTab.history) ...[
                    filterBar,
                    const SizedBox(height: 12),
                    Expanded(child: buildHistoryBody(shrinkWrap: false)),
                  ] else
                    Expanded(child: SingleChildScrollView(child: cleanupBody)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
