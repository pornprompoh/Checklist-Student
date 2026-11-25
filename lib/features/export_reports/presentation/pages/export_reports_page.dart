import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/class_workspace_bar.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../academic_structure/domain/entities/academic_year.dart';
import '../../../academic_structure/domain/entities/term.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../domain/entities/export_report_bundle.dart';
import '../providers/export_reports_controller.dart';
import '../providers/export_reports_providers.dart';
import '../widgets/export_config_panel.dart';
import '../widgets/export_document_header_card.dart';
import '../widgets/export_preview_canvas.dart';

enum _MobileExportTab { config, preview }

/// Report configuration & live A4 Document Studio page (`/teacher/export-reports`).
class ExportReportsPage extends ConsumerStatefulWidget {
  const ExportReportsPage({super.key, this.initialClassId});

  final String? initialClassId;

  @override
  ConsumerState<ExportReportsPage> createState() => _ExportReportsPageState();
}

class _ExportReportsPageState extends ConsumerState<ExportReportsPage> {
  _MobileExportTab _mobileTab = _MobileExportTab.config;
  bool _appliedInitialClass = false;

  @override
  void initState() {
    super.initState();
    _scheduleApplyInitialClass();
  }

  @override
  void didUpdateWidget(covariant ExportReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialClassId != widget.initialClassId) {
      _appliedInitialClass = false;
      _scheduleApplyInitialClass();
    }
  }

  void _scheduleApplyInitialClass() {
    final initial = widget.initialClassId?.trim();
    if (initial == null || initial.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(exportReportsControllerProvider.notifier).selectClass(initial);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authStateProvider.select((s) => s.profile));
    final yearsAsync = ref.watch(academicYearsProvider);
    final termsAsync = ref.watch(allTermsProvider);
    final selectedTerm = ref.watch(effectiveSelectedTermProvider);
    final allClassesAsync = ref.watch(allCopyableClassesProvider);
    final configState = ref.watch(exportReportsControllerProvider);

    final years = yearsAsync.asData?.value ?? const <AcademicYear>[];
    final terms = termsAsync.asData?.value ?? const <Term>[];
    final allClasses =
        allClassesAsync.asData?.value ?? const <CopyPlanSourceClassOption>[];

    // If initialClassId belongs to another term, sync selectedTerm once.
    final initialId = widget.initialClassId?.trim();
    if (!_appliedInitialClass &&
        initialId != null &&
        initialId.isNotEmpty &&
        allClasses.isNotEmpty) {
      final matched = allClasses
          .where((c) => c.subjectClassId == initialId)
          .firstOrNull;
      if (matched != null && matched.termId != selectedTerm?.id) {
        _appliedInitialClass = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(selectedTermIdProvider.notifier).select(matched.termId);
          ref
              .read(exportReportsControllerProvider.notifier)
              .selectClass(matched.subjectClassId);
        });
      } else {
        _appliedInitialClass = true;
      }
    }

    final activeTermId = selectedTerm?.id;
    final classesInTerm = activeTermId == null
        ? const <CopyPlanSourceClassOption>[]
        : allClasses
              .where((c) => c.termId == activeTermId)
              .toList(growable: false);

    final effectiveClassOption = _resolveClassOption(
      classesInTerm,
      configState.selectedClassId,
    );

    if ((yearsAsync.isLoading ||
            termsAsync.isLoading ||
            allClassesAsync.isLoading) &&
        allClasses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SkeletonBox(height: 80),
            SizedBox(height: 16),
            SkeletonBox(height: 260),
          ],
        ),
      );
    }

    final loadError =
        yearsAsync.error ?? termsAsync.error ?? allClassesAsync.error;
    if (loadError != null && allClasses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: AppFeedbackBanner(
          type: AppFeedbackType.error,
          message: ThaiErrorMapper.map(loadError),
          onRetry: () {
            ref
              ..invalidate(academicYearsProvider)
              ..invalidate(allTermsProvider)
              ..invalidate(allCopyableClassesProvider);
          },
        ),
      );
    }

    if (terms.isEmpty || allClasses.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppPageHeader(
                  title: 'ส่งออกรายงานและเอกสาร ปพ.5',
                  subtitle:
                      'เลือกหัวข้อรายงาน ปรับหัวเอกสารเฉพาะใบ สลับแนวกระดาษ A4 และตรวจสอบตัวอย่างก่อนส่งออก',
                ),
                const SizedBox(height: 20),
                AppEmptyState(
                  icon: Icons.description_outlined,
                  title: 'ยังไม่มีห้องเรียนสำหรับส่งออกรายงาน',
                  description:
                      'กรุณาสร้างปีการศึกษา เทอม รายวิชา และห้องเรียนก่อนเริ่มสร้างเอกสาร ปพ.5',
                  actionLabel: 'ไปหน้าโครงสร้างสอน',
                  actionIcon: Icons.account_tree_outlined,
                  onAction: () => GoRouter.maybeOf(
                    context,
                  )?.go(AppRoutes.teacherAcademicStructure),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rawAsync = effectiveClassOption == null
        ? null
        : ref.watch(
            exportRawClassDataProvider(effectiveClassOption.subjectClassId),
          );
    final controller = ref.read(exportReportsControllerProvider.notifier);
    final effectiveHeader = effectiveClassOption == null
        ? null
        : controller.resolveEffectiveHeader(
            profile: profile,
            classOption: effectiveClassOption,
          );
    final rawData = rawAsync?.asData?.value;
    final ExportReportBundle? bundle =
        (rawData != null && effectiveHeader != null)
        ? ref
              .read(exportReportBuilderServiceProvider)
              .buildBundle(
                raw: rawData,
                header: effectiveHeader,
                options: configState.options,
              )
        : null;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'ส่งออกรายงานและเอกสาร ปพ.5',
                subtitle:
                    'เลือกหัวข้อรายงาน ปรับหัวเอกสารเฉพาะใบ สลับแนวกระดาษ A4 และตรวจสอบตัวอย่างก่อนส่งออก',
                bottom: effectiveClassOption == null
                    ? null
                    : ClassWorkspaceBar(
                        subjectClassId: effectiveClassOption.subjectClassId,
                        activeTab: ClassWorkspaceTab.export,
                      ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final configColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExportConfigPanel(
                        academicYears: years,
                        terms: terms,
                        selectedTermId: activeTermId,
                        classOptionsInTerm: classesInTerm,
                        selectedClassId: effectiveClassOption?.subjectClassId,
                        options: configState.options,
                        orientationDecision: bundle?.orientationDecision,
                        onSelectTerm: (termId) {
                          ref
                              .read(selectedTermIdProvider.notifier)
                              .select(termId);
                          controller.selectClass(null);
                        },
                        onSelectClass: controller.selectClass,
                        onToggleSection: (section) {
                          final ok = controller.toggleSection(section);
                          if (!ok) {
                            AppFeedbackBanner.showSnackBar(
                              context,
                              type: AppFeedbackType.warning,
                              message:
                                  'ต้องเลือกหัวข้อรายงานอย่างน้อย 1 หัวข้อ',
                            );
                          }
                        },
                        onSelectOrientationMode: controller.setOrientationMode,
                        onToggleTransferredOut:
                            controller.setIncludeTransferredOut,
                        onToggleSignatureLines:
                            controller.setIncludeSignatureLines,
                      ),
                      if (effectiveHeader != null) ...[
                        const SizedBox(height: 16),
                        ExportDocumentHeaderCard(
                          header: effectiveHeader,
                          hasCustomOverride: configState.headerOverride != null,
                          previewXlsxFilename: controller.buildPreviewFilename(
                            header: effectiveHeader,
                            extension: 'xlsx',
                          ),
                          previewPdfFilename: controller.buildPreviewFilename(
                            header: effectiveHeader,
                            extension: 'pdf',
                          ),
                          previewDocxFilename: controller.buildPreviewFilename(
                            header: effectiveHeader,
                            extension: 'docx',
                          ),
                          onHeaderChanged: controller.updateHeader,
                          onResetToProfile:
                              controller.resetHeaderToProfileDefaults,
                        ),
                      ],
                    ],
                  );

                  final previewSection = _buildPreviewSection(
                    context,
                    effectiveClassOption: effectiveClassOption,
                    rawAsync: rawAsync,
                    bundle: bundle,
                  );

                  if (constraints.maxWidth >= 1040) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 390, child: configColumn),
                        const SizedBox(width: 20),
                        Expanded(child: previewSection),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<_MobileExportTab>(
                        showSelectedIcon: false,
                        segments: const <ButtonSegment<_MobileExportTab>>[
                          ButtonSegment(
                            value: _MobileExportTab.config,
                            label: Text(
                              'ตั้งค่าเอกสาร',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          ButtonSegment(
                            value: _MobileExportTab.preview,
                            label: Text(
                              'ตัวอย่างก่อนส่งออก (Preview)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                        selected: <_MobileExportTab>{_mobileTab},
                        onSelectionChanged: (sel) =>
                            setState(() => _mobileTab = sel.first),
                      ),
                      const SizedBox(height: 16),
                      if (_mobileTab == _MobileExportTab.config)
                        configColumn
                      else
                        previewSection,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  CopyPlanSourceClassOption? _resolveClassOption(
    List<CopyPlanSourceClassOption> classesInTerm,
    String? selectedClassId,
  ) {
    if (classesInTerm.isEmpty) return null;
    if (selectedClassId != null) {
      final matched = classesInTerm
          .where((c) => c.subjectClassId == selectedClassId)
          .firstOrNull;
      if (matched != null) return matched;
    }
    return classesInTerm.first;
  }

  Widget _buildPreviewSection(
    BuildContext context, {
    required CopyPlanSourceClassOption? effectiveClassOption,
    required AsyncValue<ExportRawClassData>? rawAsync,
    required ExportReportBundle? bundle,
  }) {
    if (effectiveClassOption == null) {
      return const AppEmptyState(
        icon: Icons.class_outlined,
        title: 'ไม่พบห้องเรียนในภาคเรียนที่เลือก',
        description: 'กรุณาเลือกภาคเรียนอื่นจากแผงตั้งค่าด้านซ้าย',
      );
    }
    if (rawAsync == null || (rawAsync.isLoading && bundle == null)) {
      return const Column(
        children: [
          SkeletonBox(height: 60),
          SizedBox(height: 12),
          SkeletonBox(height: 420),
        ],
      );
    }
    if (rawAsync.hasError && bundle == null) {
      return AppFeedbackBanner(
        type: AppFeedbackType.error,
        message: ThaiErrorMapper.map(rawAsync.error!),
        onRetry: () => ref.invalidate(
          exportRawClassDataProvider(effectiveClassOption.subjectClassId),
        ),
      );
    }
    if (bundle == null) {
      return const SizedBox.shrink();
    }
    final configState = ref.watch(exportReportsControllerProvider);
    final controller = ref.read(exportReportsControllerProvider.notifier);

    return ExportPreviewCanvas(
      bundle: bundle,
      isExportingExcel: configState.isExportingExcel,
      isExportingPdf: configState.isExportingPdf,
      isExportingDocx: configState.isExportingDocx,
      onExportExcel: () => _handleExportAction(
        context,
        label: 'Excel',
        action: () => controller.exportToExcel(bundle),
      ),
      onExportPdf: () => _handleExportAction(
        context,
        label: 'PDF',
        action: () => controller.exportToPdf(bundle),
      ),
      onExportWord: () => _handleExportAction(
        context,
        label: 'Word',
        action: () => controller.exportToDocx(bundle),
      ),
    );
  }

  Future<void> _handleExportAction(
    BuildContext context, {
    required String label,
    required Future<String?> Function() action,
  }) async {
    final filename = await action();
    if (!context.mounted) return;
    if (filename != null) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message: 'ส่งออก $label สำเร็จ: $filename',
      );
      return;
    }
    final err = ref.read(exportReportsControllerProvider).lastExportError;
    if (err != null) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.error,
        message: err,
      );
    }
  }
}
