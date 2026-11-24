import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/image_pdf_compressor.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/typed_confirm_dialog.dart';
import '../../domain/entities/academic_year_storage_summary.dart';
import '../../domain/entities/import_file_record.dart';
import '../../domain/services/storage_cleanup_summary_service.dart';
import '../providers/settings_providers.dart';
import '../providers/storage_cleanup_controller.dart';

/// Settings card for inspecting and yearly cleaning up `import-sources` files
/// uploaded during AI roster imports (`public.import_files`).
class StorageCleanupSectionCard extends ConsumerWidget {
  const StorageCleanupSectionCard({super.key, required this.canUseAi});

  final bool canUseAi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(activeImportFilesProvider);
    final controllerState = ref.watch(storageCleanupControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    ref.listen<AsyncValue<void>>(storageCleanupControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error) {
        AppFeedbackBanner.showErrorSnackBar(context, next.error!);
      }
    });

    final loadedFiles = filesAsync.asData?.value;
    if (!canUseAi && (loadedFiles == null || loadedFiles.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.folder_delete_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'จัดการพื้นที่เก็บไฟล์นำเข้าด้วย AI',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'รีเฟรชรายการไฟล์',
                  onPressed: controllerState.isLoading
                      ? null
                      : () => ref.invalidate(activeImportFilesProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ไฟล์รูปภาพ/PDF ต้นฉบับที่ใช้นำเข้ารายชื่อจะถูกเก็บไว้ในพื้นที่ส่วนตัวเพื่อตรวจสอบย้อนหลัง '
              'แนะนำให้เคลียร์ไฟล์ของปีการศึกษาเก่าออกเพื่อประหยัดโควตา Free Tier (1 GB)',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            filesAsync.when(
              loading: () => const Column(
                children: [
                  SkeletonBox(height: 56),
                  SizedBox(height: 8),
                  SkeletonBox(height: 56),
                ],
              ),
              error: (error, _) => AppFeedbackBanner(
                type: AppFeedbackType.error,
                message: ThaiErrorMapper.map(error),
                onRetry: () => ref.invalidate(activeImportFilesProvider),
              ),
              data: (records) {
                final summaries =
                    StorageCleanupSummaryService.summarizeByAcademicYear(
                      records,
                    );
                if (summaries.isEmpty) {
                  return AppFeedbackBanner(
                    type: AppFeedbackType.info,
                    message:
                        'ยังไม่มีไฟล์ต้นฉบับค้างอยู่ในพื้นที่เก็บไฟล์ (0 KB)',
                  );
                }

                final totalBytes = summaries.fold<int>(
                  0,
                  (sum, item) => sum + item.totalBytes,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'พื้นที่ใช้งานรวม: ${ImagePdfCompressor.formatBytes(totalBytes)} (${records.length} ไฟล์)',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final summary in summaries) ...[
                      _AcademicYearStorageTile(
                        summary: summary,
                        semantic: semantic,
                        isBusy: controllerState.isLoading,
                        onOpenFile: (file) => _openFile(context, ref, file),
                        onCleanupYear: () => _cleanupYear(context, ref, summary),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(
    BuildContext context,
    WidgetRef ref,
    ImportFileRecord file,
  ) async {
    final opened = await ref
        .read(storageCleanupControllerProvider.notifier)
        .openImportFile(file.storagePath);
    if (!opened && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.warning,
        message: 'ไม่สามารถเปิดแท็บใหม่ได้ กรุณาอนุญาตป๊อปอัปบนเบราว์เซอร์',
      );
    }
  }

  Future<void> _cleanupYear(
    BuildContext context,
    WidgetRef ref,
    AcademicYearStorageSummary summary,
  ) async {
    final yearText = summary.yearBe > 0
        ? summary.yearBe.toString()
        : summary.academicYearId;
    final confirmed = await TypedConfirmDialog.show(
      context,
      title: 'ยืนยันการเคลียร์ไฟล์นำเข้า ปี พ.ศ. $yearText',
      description:
          'ระบบจะลบไฟล์รูปภาพ/PDF ต้นฉบับทั้งหมดของปี พ.ศ. $yearText ออกจาก Supabase Storage ถาวร '
          '(รายชื่อนักเรียนและคะแนนที่นำเข้าไว้แล้วจะไม่ถูกลบ)',
      expectedText: yearText,
      confirmLabel: 'ลบไฟล์ปี พ.ศ. $yearText',
      impactSummary: <DeleteImpactItem>[
        DeleteImpactItem(
          label:
              'ไฟล์ต้นฉบับที่จะถูกลบ (${ImagePdfCompressor.formatBytes(summary.totalBytes)})',
          count: summary.fileCount,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final deletedCount = await ref
        .read(storageCleanupControllerProvider.notifier)
        .cleanupAcademicYear(summary.academicYearId);
    if (deletedCount != null && context.mounted) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.success,
        message:
            'เคลียร์ไฟล์นำเข้าปี พ.ศ. $yearText เรียบร้อยแล้ว ($deletedCount ไฟล์)',
      );
    }
  }
}

class _AcademicYearStorageTile extends StatelessWidget {
  const _AcademicYearStorageTile({
    required this.summary,
    required this.semantic,
    required this.isBusy,
    required this.onOpenFile,
    required this.onCleanupYear,
  });

  final AcademicYearStorageSummary summary;
  final AppSemanticColors semantic;
  final bool isBusy;
  final ValueChanged<ImportFileRecord> onOpenFile;
  final VoidCallback onCleanupYear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final yearLabel = summary.yearBe > 0
        ? 'ปีการศึกษา ${summary.yearBe}'
        : 'ปีการศึกษาไม่ระบุ';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: summary.isRecommendedForCleanup
              ? semantic.warning.withValues(alpha: 0.7)
              : colorScheme.outlineVariant,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              yearLabel,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (summary.isRecommendedForCleanup)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: semantic.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'แนะนำให้เคลียร์',
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${summary.fileCount} ไฟล์ · '
          '${ImagePdfCompressor.formatBytes(summary.totalBytes)} · '
          'อัปโหลดล่าสุด ${ThaiDateFormatter.formatShortDate(summary.latestUploadedAt)}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: OutlinedButton.icon(
          onPressed: isBusy ? null : onCleanupYear,
          style: OutlinedButton.styleFrom(
            foregroundColor: semantic.danger,
            side: BorderSide(color: semantic.danger.withValues(alpha: 0.6)),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: Text(
            summary.yearBe > 0 ? 'ลบปี ${summary.yearBe}' : 'ลบไฟล์',
          ),
        ),
        children: [
          for (final file in summary.files)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                file.mimeType == 'application/pdf'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                size: 20,
              ),
              title: Text(
                file.originalFilename,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${ImagePdfCompressor.formatBytes(file.fileSizeBytes)} · '
                '${ThaiDateFormatter.formatDateTime(file.createdAt)}',
                style: textTheme.bodySmall,
              ),
              trailing: TextButton.icon(
                onPressed: isBusy ? null : () => onOpenFile(file),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('เปิดดู'),
              ),
            ),
        ],
      ),
    );
  }
}
