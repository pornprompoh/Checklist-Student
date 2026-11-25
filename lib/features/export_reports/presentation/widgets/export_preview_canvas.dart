import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_subtle_scrollbar.dart';
import '../../domain/entities/export_orientation.dart';
import '../../domain/entities/export_report_bundle.dart';
import 'export_preview_section_tables.dart';

/// Document Studio preview canvas: primary PDF / secondary Excel & Word action
/// bar above a neutral-backdrop A4 paper sheet adapting to Portrait vs Landscape.
///
/// When [pinActionBar] is `true`, the top export action bar remains pinned while
/// only the A4 paper canvas scrolls inside an [Expanded] region using
/// [previewScrollController].
class ExportPreviewCanvas extends StatelessWidget {
  const ExportPreviewCanvas({
    super.key,
    required this.bundle,
    this.isExportingExcel = false,
    this.isExportingPdf = false,
    this.isExportingDocx = false,
    this.onExportExcel,
    this.onExportPdf,
    this.onExportWord,
    this.pinActionBar = false,
    this.showExportActions = true,
    this.previewScrollController,
  });

  final ExportReportBundle bundle;
  final bool isExportingExcel;
  final bool isExportingPdf;
  final bool isExportingDocx;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportWord;
  final bool pinActionBar;
  final bool showExportActions;
  final ScrollController? previewScrollController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLandscape =
        bundle.orientationDecision.orientation ==
        ExportPageOrientation.landscape;
    final header = bundle.header;

    final actionBar = Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLandscape
                    ? Icons.crop_landscape_rounded
                    : Icons.crop_portrait_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'ตัวอย่างเอกสาร · ${bundle.orientationDecision.orientation.dimensionThaiLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showExportActions)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExportActionButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'ส่งออก PDF (Sarabun)',
                isPrimary: true,
                isLoading: isExportingPdf,
                onPressed: isExportingPdf ? null : onExportPdf,
              ),
              _ExportActionButton(
                icon: Icons.table_view_outlined,
                label: 'ส่งออก Excel (.xlsx)',
                isLoading: isExportingExcel,
                onPressed: isExportingExcel ? null : onExportExcel,
              ),
              _ExportActionButton(
                icon: Icons.description_outlined,
                label: 'ส่งออก Word (.docx)',
                isLoading: isExportingDocx,
                onPressed: isExportingDocx ? null : onExportWord,
              ),
            ],
          ),
      ],
    );

    final paperStage = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isLandscape ? 980 : 680),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  header.schoolName,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (header.department.trim().isNotEmpty)
                  Text(
                    header.department,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  header.reportTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'รายวิชา ${header.subjectCode} ${header.subjectName}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'ห้อง ${header.roomName}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'ภาคเรียนที่ ${header.termLabel} ปีการศึกษา ${header.academicYearBe}',
                      style: textTheme.bodySmall?.copyWith(
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ครูผู้สอน: ${header.teacherName} · '
                  'วันที่ออกเอกสาร: ${ThaiDateFormatter.formatFullDate(header.exportedAt)}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                const Divider(height: 24),
                ExportPreviewSectionTables(bundle: bundle),
                if (bundle.options.includeSignatureLines) ...[
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _SignatureBlock(
                        role: 'ครูผู้สอน',
                        name: header.teacherName,
                      ),
                      const _SignatureBlock(
                        role: 'หัวหน้ากลุ่มสาระการเรียนรู้',
                      ),
                      const _SignatureBlock(role: 'ผู้อำนวยการสถานศึกษา'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (pinActionBar) {
      final scrollView = SingleChildScrollView(
        controller: previewScrollController,
        primary: false,
        padding: const EdgeInsets.only(right: 10, bottom: 8),
        child: paperStage,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          actionBar,
          const SizedBox(height: 12),
          Expanded(
            child: previewScrollController != null
                ? AppSubtleScrollbar(
                    controller: previewScrollController,
                    child: scrollView,
                  )
                : scrollView,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [actionBar, const SizedBox(height: 16), paperStage],
    );
  }
}

class _ExportActionButton extends StatelessWidget {
  const _ExportActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isLoading = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final leading = isLoading
        ? const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 17);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return Tooltip(
      message: label,
      child: isPrimary
          ? FilledButton(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  const _SignatureBlock({required this.role, this.name});

  final String role;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 185,
      child: Column(
        children: [
          const Text('ลงชื่อ .......................................'),
          const SizedBox(height: 4),
          Text(
            name != null && name!.trim().isNotEmpty
                ? '($name)'
                : '(.......................................)',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          Text(
            role,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
