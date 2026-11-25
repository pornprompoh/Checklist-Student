import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/image_pdf_compressor.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../domain/entities/homeroom_student.dart';
import '../../domain/entities/roster_import_result.dart';
import '../../domain/entities/roster_import_row_preview.dart';
import '../../domain/services/ai_roster_preview_adapter_service.dart';
import '../providers/ai_roster_import_controller.dart';
import '../providers/roster_import_controller.dart';
import 'roster_import_preview_step.dart';

/// 2-step AI Roster Import dialog:
/// 1) Pick JPG/PNG/PDF -> compress client-side to `<= 500 KB` -> call Edge Function
/// 2) Preview & resolve duplicates via [RosterImportPreviewStep] -> commit import.
class AiRosterImportDialog extends ConsumerStatefulWidget {
  const AiRosterImportDialog({
    super.key,
    required this.academicYearId,
    required this.homeroomId,
    required this.homeroomName,
    required this.existingStudents,
    required this.linkedClassIds,
    this.defaultEnrolledAt,
  });

  final String academicYearId;
  final String homeroomId;
  final String homeroomName;
  final List<HomeroomStudent> existingStudents;
  final List<String> linkedClassIds;
  final DateTime? defaultEnrolledAt;

  static Future<RosterImportResult?> show(
    BuildContext context, {
    required String academicYearId,
    required String homeroomId,
    required String homeroomName,
    required List<HomeroomStudent> existingStudents,
    required List<String> linkedClassIds,
    DateTime? defaultEnrolledAt,
  }) {
    return showDialog<RosterImportResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AiRosterImportDialog(
        academicYearId: academicYearId,
        homeroomId: homeroomId,
        homeroomName: homeroomName,
        existingStudents: existingStudents,
        linkedClassIds: linkedClassIds,
        defaultEnrolledAt: defaultEnrolledAt,
      ),
    );
  }

  @override
  ConsumerState<AiRosterImportDialog> createState() =>
      _AiRosterImportDialogState();
}

class _AiRosterImportDialogState extends ConsumerState<AiRosterImportDialog> {
  int _step = 0; // 0 = select & analyze, 1 = preview & confirm
  String? _fileName;
  CompressedImportFile? _compressedFile;
  List<RosterImportRowPreview> _previewRows = const <RosterImportRowPreview>[];
  bool _syncOverwritten = true;
  bool _autoEnrollNew = true;
  String? _localError;

  int get _actionableCount => _previewRows
      .where(
        (r) =>
            r.status == RosterImportRowStatus.readyNew ||
            (r.status == RosterImportRowStatus.duplicateExisting &&
                r.duplicateAction == DuplicateResolutionAction.overwrite),
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiRosterImportControllerProvider);
    final commitState = ref.watch(rosterImportControllerProvider);
    final isBusy = aiState.isLoading || commitState.isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    final errorMessage = _localError ??
        (aiState.hasError ? ThaiErrorMapper.map(aiState.error!) : null) ??
        (commitState.hasError ? ThaiErrorMapper.map(commitState.error!) : null);

    return PopScope(
      canPop: !isBusy,
      child: AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'นำเข้ารายชื่อด้วย AI — ห้อง ${widget.homeroomName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage != null) ...[
                AppFeedbackBanner(
                  type: AppFeedbackType.error,
                  message: errorMessage,
                  onRetry: (!isBusy && _step == 0 && _compressedFile != null)
                      ? _analyzeWithAi
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              if (isBusy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  aiState.isLoading
                      ? 'กำลังอัปโหลดและให้ AI อ่านรายชื่อจากเอกสาร...'
                      : 'กำลังบันทึกรายชื่อนักเรียนเข้าคลังกลาง...',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_step == 0)
                _buildSelectFileStep(context, isBusy, semantic)
              else
                _buildPreviewStep(context),
            ],
          ),
        ),
        actions: _buildActions(context, isBusy),
      ),
    );
  }

  Widget _buildSelectFileStep(
    BuildContext context,
    bool isBusy,
    AppSemanticColors semantic,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFeedbackBanner(
          type: AppFeedbackType.info,
          message:
              'รองรับไฟล์รูปภาพ (.jpg, .png) และ .pdf ขนาดไม่เกิน 500 KB '
              '(รูปภาพที่มีขนาดเกิน 500 KB จะถูกย่อและบีบอัดอัตโนมัติบนอุปกรณ์ก่อนส่ง)',
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: isBusy ? null : _pickAndCompressFile,
          icon: const Icon(Icons.document_scanner_outlined),
          label: Text(
            _fileName == null
                ? 'เลือกไฟล์รูปภาพหรือ PDF รายชื่อนักเรียน'
                : 'เปลี่ยนไฟล์เอกสาร',
          ),
        ),
        if (_compressedFile != null && _fileName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName!,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'ขนาดเดิม: ${ImagePdfCompressor.formatBytes(_compressedFile!.originalSizeBytes)}',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      'พร้อมส่ง: ${ImagePdfCompressor.formatBytes(_compressedFile!.compressedSizeBytes)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_compressedFile!.wasCompressed)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: semantic.successContainer,
                        label: Text(
                          'บีบอัดอัตโนมัติแล้ว',
                          style: textTheme.labelSmall?.copyWith(
                            color: semantic.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppFeedbackBanner(
          type: AppFeedbackType.info,
          message:
              'กรุณาตรวจสอบความถูกต้องของคำนำหน้า ชื่อ-นามสกุล และรหัสนักเรียนก่อนนำเข้า '
              '(ไฟล์ต้นฉบับถูกเก็บไว้เพื่อตรวจสอบย้อนหลังและลบเคลียร์รายปีได้ในหน้าตั้งค่า)',
        ),
        const SizedBox(height: 12),
        RosterImportPreviewStep(
          rows: _previewRows,
          hasLinkedClasses: widget.linkedClassIds.isNotEmpty,
          syncOverwrittenToLinkedClasses: _syncOverwritten,
          onToggleSyncOverwritten: (v) => setState(() => _syncOverwritten = v),
          autoEnrollNewToLinkedClasses: _autoEnrollNew,
          onToggleAutoEnrollNew: (v) => setState(() => _autoEnrollNew = v),
          onApplyAllDuplicateAction: _applyAllDuplicateAction,
          onRowDuplicateActionChanged: _setRowDuplicateAction,
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, bool isBusy) {
    return <Widget>[
      TextButton(
        onPressed: isBusy ? null : () => Navigator.of(context).pop(),
        child: const Text('ยกเลิก'),
      ),
      if (_step == 1)
        OutlinedButton(
          onPressed: isBusy
              ? null
              : () => setState(() {
                  _step = 0;
                  _localError = null;
                }),
          child: const Text('เลือกไฟล์ใหม่'),
        ),
      if (_step == 0)
        FilledButton.icon(
          onPressed: isBusy || _compressedFile == null ? null : _analyzeWithAi,
          icon: const Icon(Icons.auto_awesome_outlined, size: 18),
          label: const Text('วิเคราะห์รายชื่อด้วย AI'),
        )
      else
        FilledButton.icon(
          onPressed: isBusy || _actionableCount == 0 ? null : _commitImport,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text('นำเข้า $_actionableCount คน'),
        ),
    ];
  }

  Future<void> _pickAndCompressFile() async {
    setState(() => _localError = null);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (picked == null) return;

      final rawBytes = await picked.readAsBytes();
      final compressed = ImagePdfCompressor.compressIfNeeded(
        bytes: rawBytes,
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() {
        _fileName = picked.name;
        _compressedFile = compressed;
        _localError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _compressedFile = null;
        _localError = ThaiErrorMapper.map(error);
      });
    }
  }

  Future<void> _analyzeWithAi() async {
    final file = _compressedFile;
    final name = _fileName;
    if (file == null || name == null) return;

    setState(() => _localError = null);
    final result = await ref
        .read(aiRosterImportControllerProvider.notifier)
        .uploadAndParse(
          academicYearId: widget.academicYearId,
          homeroomId: widget.homeroomId,
          originalFilename: name,
          compressedBytes: file.bytes,
          mimeType: file.mimeType,
          fileExtension: file.fileExtension,
        );
    if (!mounted || result == null) return;

    if (result.students.isEmpty) {
      setState(() {
        _localError =
            'AI ไม่พบรายชื่อนักเรียนในเอกสารนี้ กรุณาตรวจสอบความคมชัดของภาพแล้วลองใหม่อีกครั้ง';
      });
      return;
    }

    final preview = AiRosterPreviewAdapterService.buildPreview(
      aiRows: result.students,
      existingStudents: widget.existingStudents,
    );
    setState(() {
      _previewRows = preview;
      _step = 1;
    });
  }

  void _applyAllDuplicateAction(DuplicateResolutionAction action) {
    setState(() {
      _previewRows = _previewRows
          .map(
            (r) => r.status == RosterImportRowStatus.duplicateExisting
                ? r.copyWith(duplicateAction: action)
                : r,
          )
          .toList(growable: false);
    });
  }

  void _setRowDuplicateAction(int index, DuplicateResolutionAction action) {
    setState(() {
      final updated = List<RosterImportRowPreview>.of(_previewRows);
      updated[index] = updated[index].copyWith(duplicateAction: action);
      _previewRows = updated;
    });
  }

  Future<void> _commitImport() async {
    final result = await ref
        .read(rosterImportControllerProvider.notifier)
        .commitImport(
          homeroomId: widget.homeroomId,
          rows: _previewRows,
          syncOverwrittenToLinkedClasses:
              widget.linkedClassIds.isNotEmpty && _syncOverwritten,
          autoEnrollNewToLinkedClasses:
              widget.linkedClassIds.isNotEmpty && _autoEnrollNew,
          enrolledAt: widget.defaultEnrolledAt,
          linkedClassIds: widget.linkedClassIds,
        );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }
}
