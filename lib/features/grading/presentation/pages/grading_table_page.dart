import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_score.dart';
import '../providers/grading_filter_provider.dart';
import '../providers/grading_providers.dart';
import '../providers/grading_table_controller.dart';
import '../providers/student_profile_drawer_controller.dart';
import '../widgets/frozen_grade_grid.dart';
import '../widgets/grading_table_toolbar.dart';
import '../widgets/score_cell_detail_dialog.dart';
import '../widgets/special_grade_action_dialog.dart';
import '../widgets/student_profile_drawer.dart';

/// Main teacher gradebook table page (`/teacher/grading?classId=...`).
///
/// Defaults to Preview Mode (accidental-edit protection), supports per-cell
/// Optimistic Locking auto-save, keyboard navigation (`Enter`/`Tab`), search,
/// and quick filter chips.
class GradingTablePage extends ConsumerStatefulWidget {
  const GradingTablePage({super.key, this.initialClassId});

  final String? initialClassId;

  @override
  ConsumerState<GradingTablePage> createState() => _GradingTablePageState();
}

class _GradingTablePageState extends ConsumerState<GradingTablePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String? _selectedClassId;
  String? _selectedDrawerEnrollmentId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialClassId?.trim();
    _selectedClassId = (initial == null || initial.isEmpty) ? null : initial;
  }

  @override
  void didUpdateWidget(covariant GradingTablePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextInitial = widget.initialClassId?.trim();
    if (nextInitial != null &&
        nextInitial.isNotEmpty &&
        nextInitial != oldWidget.initialClassId?.trim()) {
      setState(() => _selectedClassId = nextInitial);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _resolveEffectiveClassId(List<CopyPlanSourceClassOption> options) {
    if (options.isEmpty) return _selectedClassId;
    if (_selectedClassId != null &&
        options.any((opt) => opt.subjectClassId == _selectedClassId)) {
      return _selectedClassId;
    }
    return options.first.subjectClassId;
  }

  Future<void> _openCellDetail(
    BuildContext context, {
    required String teacherId,
    required GradingTableRowData row,
    required Assignment assignment,
    required StudentScore? existingScore,
  }) async {
    final result = await ScoreCellDetailDialog.show(
      context,
      studentLabel:
          'เลขที่ ${row.enrollment.studentNumber} ${row.enrollment.fullName}',
      assignment: assignment,
      existingScore: existingScore,
    );
    if (result == null || !mounted) return;
    await ref
        .read(gradingTableControllerProvider.notifier)
        .autoSaveCellScore(
          teacherId: teacherId,
          enrollmentId: row.enrollment.id,
          assignmentId: assignment.id,
          score: result.score,
          status: result.status,
          note: result.note,
        );
  }

  Future<void> _handleManageSpecialGrade(
    BuildContext context, {
    required String classId,
    required GradingTableRowData row,
  }) async {
    final decision = await SpecialGradeActionDialog.show(
      context,
      studentLabel:
          'เลขที่ ${row.enrollment.studentNumber} ${row.enrollment.fullName}',
      gradeResult: row.gradeResult,
    );
    if (decision == null || !mounted) return;
    final ok = await ref
        .read(studentProfileDrawerControllerProvider.notifier)
        .updateSpecialGrade(
          subjectClassId: classId,
          enrollmentId: row.enrollment.id,
          expectedVersion: row.enrollment.version,
          specialGradeOverride: decision.specialGradeOverride,
          markRResolved: decision.markRResolved,
          markMsResolved: decision.markMsResolved,
        );
    if (ok && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: decision.feedbackMessage,
      );
    }
  }

  void _openStudentProfileDrawer(ClassEnrollment enrollment) {
    setState(() => _selectedDrawerEnrollmentId = enrollment.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scaffoldKey.currentState?.openEndDrawer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = ref.watch(authStateProvider.select((s) => s.userId)) ?? '';
    final classOptionsAsync = ref.watch(allCopyableClassesProvider);
    final filterState = ref.watch(gradingFilterProvider);
    final tableState = ref.watch(gradingTableControllerProvider);

    ref.listen<AsyncValue<void>>(studentProfileDrawerControllerProvider, (
      prev,
      next,
    ) {
      if (next.hasError && prev?.error != next.error) {
        final err = next.error!;
        if (err is ConflictException) {
          AppFeedbackBanner.showSnackBar(
            context,
            type: AppFeedbackType.warning,
            message: ThaiErrorMapper.map(err),
            retryLabel: 'โหลดล่าสุด',
            onRetry: () {
              final activeId = _selectedClassId;
              if (activeId != null) {
                ref.invalidate(classEnrollmentsProvider(activeId));
              }
            },
          );
        } else {
          AppFeedbackBanner.showErrorSnackBar(context, err);
        }
      }
    });

    final options =
        classOptionsAsync.asData?.value ?? const <CopyPlanSourceClassOption>[];
    final classId = _resolveEffectiveClassId(options);

    if (classOptionsAsync.isLoading && options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 96),
            SizedBox(height: 12),
            Expanded(child: SkeletonBox(height: 360)),
          ],
        ),
      );
    }
    if (classOptionsAsync.hasError && options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppFeedbackBanner(
          type: AppFeedbackType.error,
          message: ThaiErrorMapper.map(classOptionsAsync.error!),
          onRetry: () => ref.invalidate(allCopyableClassesProvider),
        ),
      );
    }
    if (classId == null || options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppFeedbackBanner(
          type: AppFeedbackType.info,
          message:
              'ยังไม่มีห้องเรียนในระบบ กรุณาสร้างปีการศึกษา เทอม รายวิชา และห้องเรียนก่อน',
          retryLabel: 'ไปหน้าโครงสร้างสอน',
          onRetry: () => context.go(AppRoutes.teacherAcademicStructure),
        ),
      );
    }

    final enrollmentsAsync = ref.watch(classEnrollmentsProvider(classId));
    final categoriesAsync = ref.watch(scoreCategoriesProvider(classId));
    final assignmentsAsync = ref.watch(assignmentsProvider(classId));
    final scoresAsync = ref.watch(studentScoresByClassProvider(classId));
    final scaleAsync = ref.watch(gradingScaleConfigProvider(classId));
    final attendanceMap = ref.watch(classAttendanceSummariesProvider(classId));

    final serverScores = scoresAsync.asData?.value;
    if (serverScores != null &&
        (tableState.boundClassId != classId || !tableState.hasHydratedClass)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(gradingTableControllerProvider.notifier)
            .hydrateFromServer(
              subjectClassId: classId,
              serverScores: serverScores,
            );
      });
    }

    final isInitialLoading =
        (enrollmentsAsync.isLoading && !enrollmentsAsync.hasValue) ||
        (assignmentsAsync.isLoading && !assignmentsAsync.hasValue) ||
        (scoresAsync.isLoading && !scoresAsync.hasValue) ||
        (scaleAsync.isLoading && !scaleAsync.hasValue);

    final loadError =
        enrollmentsAsync.error ??
        assignmentsAsync.error ??
        scoresAsync.error ??
        scaleAsync.error;

    final enrollments =
        enrollmentsAsync.asData?.value ?? const <ClassEnrollment>[];
    final categories =
        categoriesAsync.asData?.value ?? const <ScoreCategory>[];
    final assignments = assignmentsAsync.asData?.value ?? const <Assignment>[];
    final scaleConfig =
        scaleAsync.asData?.value ??
        GradingScaleConfig(
          subjectClassId: classId,
          scaleType: GradingScaleType.scale0To4,
          rules: GradingScaleConfig.defaultZeroToFourRules,
          missingWorkThreshold: 3,
        );

    final allRows = ref
        .read(gradingTableControllerProvider.notifier)
        .buildLiveRows(
          enrollments: enrollments,
          categories: categories,
          assignments: assignments,
          scaleConfig: scaleConfig,
          attendanceSummaries: attendanceMap,
        );
    final filterCounts = countQuickFilterBuckets(
      rows: allRows,
      showTransferredOut: filterState.showTransferredOut,
    );
    final visibleRows = filterGradingRows(rows: allRows, filter: filterState);
    final transferredOutCount = enrollments
        .where((e) => e.isTransferredOut)
        .length;
    final controller = ref.read(gradingTableControllerProvider.notifier);
    final drawerRow = _selectedDrawerEnrollmentId == null
        ? null
        : allRows
              .where((r) => r.enrollment.id == _selectedDrawerEnrollmentId)
              .firstOrNull;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: drawerRow == null
          ? null
          : StudentProfileDrawer(
              rowData: drawerRow,
              assignments: assignments,
              scoresByCellKey: tableState.scoresByCellKey,
              onManageSpecialGrade: () => _handleManageSpecialGrade(
                context,
                classId: classId,
                row: drawerRow,
              ),
              onOpenStudentAuditLog: () {
                Navigator.of(context).maybePop();
                context.go(
                  AppRoutes.teacherAuditLogForClass(
                    classId,
                    enrollmentId: drawerRow.enrollment.id,
                  ),
                );
              },
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useScrollableLayout =
              constraints.maxHeight < 640 || constraints.maxWidth < 600;
          final toolbar = GradingTableToolbar(
            classOptions: options,
            selectedClassId: classId,
            isEditMode: tableState.isEditMode,
            saveStatus: tableState.overallSaveStatus,
            lastSavedAt: tableState.lastSavedAt,
            filterState: filterState,
            filterCounts: filterCounts,
            transferredOutCount: transferredOutCount,
            searchController: _searchController,
            onSelectClass: (nextId) {
              setState(() {
                _selectedClassId = nextId;
                _selectedDrawerEnrollmentId = null;
              });
              ref.read(gradingFilterProvider.notifier).reset();
              _searchController.clear();
            },
            onOpenPlanPage: () =>
                context.go(AppRoutes.teacherGradingPlanForClass(classId)),
            onOpenAuditLog: () =>
                context.go(AppRoutes.teacherAuditLogForClass(classId)),
            onOpenExportReports: () =>
                context.go(AppRoutes.teacherExportReportsForClass(classId)),
            onToggleEditMode: controller.toggleEditMode,
            onRetrySave: controller.retryLastFailedSave,
            onReloadLatest: () => controller.reloadFromServer(classId),
            onSearchChanged: (q) =>
                ref.read(gradingFilterProvider.notifier).setSearchQuery(q),
            onSelectFilter: (f) =>
                ref.read(gradingFilterProvider.notifier).setQuickFilter(f),
            onToggleShowTransferredOut: (v) => ref
                .read(gradingFilterProvider.notifier)
                .setShowTransferredOut(v),
          );
          final previewBanner =
              !tableState.isEditMode &&
                  !isInitialLoading &&
                  loadError == null &&
                  enrollments.isNotEmpty &&
                  assignments.isNotEmpty
              ? const AppFeedbackBanner(
                  type: AppFeedbackType.info,
                  message:
                      'โหมดพรีวิว: ดับเบิลคลิกที่ช่องคะแนน หรือกดปุ่ม "โหมดพรีวิว · กดเพื่อแก้ไข" เพื่อเริ่มกรอกคะแนน (กด Enter เลื่อนลง / Tab เลื่อนขวา)',
                )
              : null;
          final errorBanner = tableState.lastErrorMessage == null
              ? null
              : AppFeedbackBanner(
                  type: tableState.overallSaveStatus == CellSaveStatus.conflict
                      ? AppFeedbackType.warning
                      : AppFeedbackType.error,
                  message: tableState.lastErrorMessage!,
                  retryLabel:
                      tableState.overallSaveStatus == CellSaveStatus.conflict
                      ? 'โหลดข้อมูลล่าสุด'
                      : 'ลองใหม่',
                  onRetry:
                      tableState.overallSaveStatus == CellSaveStatus.conflict
                      ? () => controller.reloadFromServer(classId)
                      : controller.retryLastFailedSave,
                );
          final gridArea = _buildGridArea(
            context,
            teacherId: teacherId,
            classId: classId,
            isInitialLoading: isInitialLoading,
            loadError: loadError,
            enrollments: enrollments,
            assignments: assignments,
            visibleRows: visibleRows,
            tableState: tableState,
          );

          if (useScrollableLayout) {
            final gridHeight = math.max(320.0, constraints.maxHeight * 0.65);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  if (previewBanner != null) ...[
                    const SizedBox(height: 8),
                    previewBanner,
                  ],
                  if (errorBanner != null) ...[
                    const SizedBox(height: 8),
                    errorBanner,
                  ],
                  const SizedBox(height: 10),
                  SizedBox(height: gridHeight, child: gridArea),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                toolbar,
                if (previewBanner != null) ...[
                  const SizedBox(height: 8),
                  previewBanner,
                ],
                if (errorBanner != null) ...[
                  const SizedBox(height: 8),
                  errorBanner,
                ],
                const SizedBox(height: 10),
                Expanded(child: gridArea),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridArea(
    BuildContext context, {
    required String teacherId,
    required String classId,
    required bool isInitialLoading,
    required Object? loadError,
    required List<ClassEnrollment> enrollments,
    required List<Assignment> assignments,
    required List<GradingTableRowData> visibleRows,
    required GradingTableState tableState,
  }) {
    final controller = ref.read(gradingTableControllerProvider.notifier);

    if (isInitialLoading) {
      return const SkeletonBox(height: 360);
    }
    if (loadError != null) {
      return AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(loadError),
        onRetry: () => controller.reloadFromServer(classId),
      );
    }
    if (enrollments.isEmpty) {
      return AppFeedbackBanner(
        type: AppFeedbackType.info,
        message: 'ยังไม่มีรายชื่อนักเรียนในห้องนี้ กรุณาเพิ่มรายชื่อจากคลังรายชื่อก่อน',
        retryLabel: 'ไปหน้าคลังรายชื่อ',
        onRetry: () => context.go(AppRoutes.teacherHomeroomRoster),
      );
    }
    if (assignments.isEmpty) {
      return AppFeedbackBanner(
        type: AppFeedbackType.info,
        message:
            'ยังไม่มีชิ้นงานหรือรายการสอบในห้องนี้ กรุณาออกแบบแผนเก็บงานก่อนเริ่มกรอกคะแนน',
        retryLabel: 'ไปหน้าออกแบบแผนเก็บงาน',
        onRetry: () =>
            context.go(AppRoutes.teacherGradingPlanForClass(classId)),
      );
    }
    if (visibleRows.isEmpty) {
      return AppFeedbackBanner(
        type: AppFeedbackType.info,
        message: 'ไม่พบนักเรียนที่ตรงกับคำค้นหาหรือตัวกรองที่เลือก',
        retryLabel: 'ล้างตัวกรอง',
        onRetry: () {
          _searchController.clear();
          ref.read(gradingFilterProvider.notifier).reset();
        },
      );
    }

    return FrozenGradeGrid(
      rows: visibleRows,
      assignments: assignments,
      scoresByCellKey: tableState.scoresByCellKey,
      cellStatuses: tableState.cellStatuses,
      isEditMode: tableState.isEditMode,
      activeCellKey: tableState.activeCellKey,
      onStartCellEdit: controller.enterCellEdit,
      onCancelCellEdit: controller.exitCellEdit,
      onCommitCellScore: ({
        required enrollmentId,
        required assignmentId,
        required score,
        required status,
      }) async {
        await controller.autoSaveCellScore(
          teacherId: teacherId,
          enrollmentId: enrollmentId,
          assignmentId: assignmentId,
          score: score,
          status: status,
        );
      },
      onOpenCellDetail: (row, assignment) => _openCellDetail(
        context,
        teacherId: teacherId,
        row: row,
        assignment: assignment,
        existingScore: tableState
            .scoresByCellKey[gradingCellKey(row.enrollment.id, assignment.id)],
      ),
      onOpenStudentProfile: _openStudentProfileDrawer,
      onTapSpecialGrade: (enrollment) {
        final matchedRow = visibleRows
            .where((r) => r.enrollment.id == enrollment.id)
            .firstOrNull;
        if (matchedRow != null) {
          _handleManageSpecialGrade(context, classId: classId, row: matchedRow);
        }
      },
    );
  }
}
