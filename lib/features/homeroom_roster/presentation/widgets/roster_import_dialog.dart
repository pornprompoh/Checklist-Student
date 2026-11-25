import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/utils/web_file_downloader.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../domain/entities/homeroom_student.dart';
import '../../domain/entities/parsed_spreadsheet_table.dart';
import '../../domain/entities/roster_column_mapping.dart';
import '../../domain/entities/roster_import_result.dart';
import '../../domain/entities/roster_import_row_preview.dart';
import '../../domain/services/roster_import_preview_service.dart';
import '../../domain/services/roster_spreadsheet_parser_service.dart';
import '../../domain/services/roster_template_builder_service.dart';
import '../providers/roster_import_controller.dart';
import 'roster_column_mapping_step.dart';
import 'roster_import_preview_step.dart';

/// 3-step Excel/CSV student roster import wizard dialog:
/// 1) Select file / Download templates (.xlsx & .csv)
/// 2) Column Mapping (supporting SGS reports)
/// 3) Preview & Duplicate Resolution (Skip / Overwrite)
class RosterImportDialog extends ConsumerStatefulWidget {
  const RosterImportDialog({
    super.key,
    required this.homeroomId,
    required this.homeroomName,
    required this.existingStudents,
    required this.linkedClassIds,
    this.defaultEnrolledAt,
  });

  final String homeroomId;
  final String homeroomName;
  final List<HomeroomStudent> existingStudents;
  final List<String> linkedClassIds;
  final DateTime? defaultEnrolledAt;

  static Future<RosterImportResult?> show(
    BuildContext context, {
    required String homeroomId,
    required String homeroomName,
    required List<HomeroomStudent> existingStudents,
    required List<String> linkedClassIds,
    DateTime? defaultEnrolledAt,
  }) {
    return showDialog<RosterImportResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RosterImportDialog(
        homeroomId: homeroomId,
        homeroomName: homeroomName,
        existingStudents: existingStudents,
        linkedClassIds: linkedClassIds,
        defaultEnrolledAt: defaultEnrolledAt,
      ),
    );
  }

  @override
  ConsumerState<RosterImportDialog> createState() => _RosterImportDialogState();
}

class _RosterImportDialogState extends ConsumerState<RosterImportDialog> {
  int _step = 0;
  ParsedSpreadsheetFile? _parsedFile;
  int _selectedSheetIndex = 0;
  RosterColumnMapping? _mapping;
  List<RosterImportRowPreview> _previewRows = const <RosterImportRowPreview>[];
  bool _syncOverwritten = true;
  bool _autoEnrollNew = true;
  String? _localError;

  void _downloadExcelTemplate() {
    final bytes = RosterTemplateBuilderService.buildExcelTemplateBytes();
    downloadBytesInBrowser(
      bytes: bytes,
      filename: 'template_roster_checklist_student.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message: 'ดาวน์โหลดไฟล์ Template (.xlsx) เรียบร้อยแล้ว',
    );
  }

  void _downloadCsvTemplate() {
    final bytes = RosterTemplateBuilderService.buildCsvTemplateBytes();
    downloadBytesInBrowser(
      bytes: bytes,
      filename: 'template_roster_checklist_student.csv',
      mimeType: 'text/csv;charset=utf-8',
    );
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message: 'ดาวน์โหลดไฟล์ Template (.csv UTF-8 BOM) เรียบร้อยแล้ว',
    );
  }

  Future<void> _pickSpreadsheetFile() async {
    setState(() => _localError = null);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['xlsx', 'csv'],
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        setState(() => _localError = 'ไม่สามารถอ่านข้อมูลจากไฟล์ที่เลือกได้');
        return;
      }

      final parsed = RosterSpreadsheetParserService.parseBytes(
        filename: picked.name,
        bytes: bytes,
      );
      final firstSheet = parsed.sheets.first;
      final mapping = RosterSpreadsheetParserService.suggestColumnMapping(
        firstSheet,
      );

      setState(() {
        _parsedFile = parsed;
        _selectedSheetIndex = 0;
        _mapping = mapping;
        _step = 1;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _localError = ThaiErrorMapper.map(error));
      }
    }
  }

  void _buildPreviewAndAdvance() {
    final file = _parsedFile;
    final mapping = _mapping;
    if (file == null || mapping == null || !mapping.hasRequiredColumns) {
      setState(
        () => _localError =
            'กรุณาเลือกคอลัมน์ "รหัสนักเรียน" และคอลัมน์ชื่อนักเรียนให้ครบก่อนดำเนินการต่อ',
      );
      return;
    }

    final preview = RosterImportPreviewService.buildPreview(
      sheet: file.sheets[_selectedSheetIndex],
      mapping: mapping,
      existingStudents: widget.existingStudents,
    );
    setState(() {
      _localError = null;
      _previewRows = preview;
      _step = 2;
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

  int get _actionableCount => _previewRows.where((r) {
    if (r.status == RosterImportRowStatus.readyNew) return true;
    return r.status == RosterImportRowStatus.duplicateExisting &&
        r.duplicateAction == DuplicateResolutionAction.overwrite;
  }).length;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(rosterImportControllerProvider);
    final isSubmitting = importState.isLoading;
    final stepTitles = const <String>[
      '1. เลือกไฟล์ Excel / CSV',
      '2. จับคู่คอลัมน์ (รองรับ SGS)',
      '3. ตรวจสอบพรีวิวและรหัสซ้ำ',
    ];

    return AlertDialog(
      scrollable: true,
      title: Text('นำเข้ารายชื่อเข้าคลัง ${widget.homeroomName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              stepTitles[_step],
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_localError != null) ...[
              AppFeedbackBanner(
                type: AppFeedbackType.error,
                message: _localError!,
                onDismiss: () => setState(() => _localError = null),
              ),
              const SizedBox(height: 12),
            ],
            if (importState.hasError) ...[
              AppFeedbackBanner(
                type: AppFeedbackType.error,
                message: ThaiErrorMapper.map(importState.error!),
              ),
              const SizedBox(height: 12),
            ],
            if (_step == 0)
              _buildStep1(context)
            else if (_step == 1 && _parsedFile != null && _mapping != null)
              RosterColumnMappingStep(
                file: _parsedFile!,
                selectedSheetIndex: _selectedSheetIndex,
                mapping: _mapping!,
                onSheetChanged: (idx) {
                  final sheet = _parsedFile!.sheets[idx];
                  setState(() {
                    _selectedSheetIndex = idx;
                    _mapping =
                        RosterSpreadsheetParserService.suggestColumnMapping(
                          sheet,
                        );
                  });
                },
                onHeaderRowChanged: (rowIdx) {
                  final sheet = _parsedFile!.sheets[_selectedSheetIndex];
                  setState(() {
                    _mapping =
                        RosterSpreadsheetParserService.suggestColumnMapping(
                          sheet,
                          headerRowIndex: rowIdx,
                        );
                  });
                },
                onMappingChanged: (updated) =>
                    setState(() => _mapping = updated),
              )
            else if (_step == 2)
              RosterImportPreviewStep(
                rows: _previewRows,
                hasLinkedClasses: widget.linkedClassIds.isNotEmpty,
                syncOverwrittenToLinkedClasses: _syncOverwritten,
                onToggleSyncOverwritten: (v) =>
                    setState(() => _syncOverwritten = v),
                autoEnrollNewToLinkedClasses: _autoEnrollNew,
                onToggleAutoEnrollNew: (v) =>
                    setState(() => _autoEnrollNew = v),
                onApplyAllDuplicateAction: (action) {
                  setState(() {
                    _previewRows = [
                      for (final r in _previewRows)
                        r.status == RosterImportRowStatus.duplicateExisting
                            ? r.copyWith(duplicateAction: action)
                            : r,
                    ];
                  });
                },
                onRowDuplicateActionChanged: (index, action) {
                  setState(() {
                    final next = List<RosterImportRowPreview>.of(_previewRows);
                    next[index] = next[index].copyWith(duplicateAction: action);
                    _previewRows = next;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        if (_step > 0)
          OutlinedButton(
            onPressed: isSubmitting ? null : () => setState(() => _step--),
            child: const Text('ย้อนกลับ'),
          ),
        if (_step == 1)
          FilledButton(
            onPressed: (_mapping?.hasRequiredColumns ?? false)
                ? _buildPreviewAndAdvance
                : null,
            child: const Text('ตรวจสอบพรีวิว'),
          ),
        if (_step == 2)
          FilledButton.icon(
            onPressed: (isSubmitting || _actionableCount == 0)
                ? null
                : _commitImport,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_rounded, size: 18),
            label: Text(
              isSubmitting
                  ? 'กำลังนำเข้า...'
                  : 'ยืนยันนำเข้า ($_actionableCount รายการ)',
            ),
          ),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'รองรับไฟล์ Excel (.xlsx) และ CSV (.csv) ทั้งจากไฟล์ Template มาตรฐานและไฟล์ส่งออกจากระบบ SGS',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _downloadExcelTemplate,
              icon: const Icon(Icons.table_view_outlined, size: 18),
              label: const Text('ดาวน์โหลด Template (.xlsx)'),
            ),
            OutlinedButton.icon(
              onPressed: _downloadCsvTemplate,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('ดาวน์โหลด Template (.csv)'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _pickSpreadsheetFile,
          icon: const Icon(Icons.upload_file_rounded, size: 20),
          label: const Text('เลือกไฟล์ Excel (.xlsx) หรือ CSV (.csv)'),
        ),
      ],
    );
  }
}
