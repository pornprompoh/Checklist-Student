import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../domain/services/teacher_code_validator_service.dart';
import '../providers/settings_providers.dart';

/// Card for viewing/copying the Student Portal link, changing `teacher_code`
/// with confirmation, and listing archived codes from `teacher_code_history`.
class TeacherCodeSectionCard extends ConsumerStatefulWidget {
  const TeacherCodeSectionCard({
    super.key,
    required this.currentCode,
    required this.isSaving,
    required this.onChangeCode,
    this.onDirtyChanged,
  });

  final String currentCode;
  final bool isSaving;
  final Future<bool> Function(String newCode) onChangeCode;
  final ValueChanged<bool>? onDirtyChanged;

  @override
  ConsumerState<TeacherCodeSectionCard> createState() =>
      _TeacherCodeSectionCardState();
}

class _TeacherCodeSectionCardState
    extends ConsumerState<TeacherCodeSectionCard> {
  late final TextEditingController _codeController;
  String? _validationError;
  bool _isDirty = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.currentCode)
      ..addListener(_handleCodeChanged);
  }

  @override
  void didUpdateWidget(covariant TeacherCodeSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCode != widget.currentCode) {
      _isSyncing = true;
      _codeController.text = widget.currentCode;
      _isSyncing = false;
      _validationError = null;
      if (_isDirty) {
        _isDirty = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onDirtyChanged?.call(false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController
      ..removeListener(_handleCodeChanged)
      ..dispose();
    super.dispose();
  }

  void _handleCodeChanged() {
    if (_isSyncing) {
      return;
    }
    final normalized = TeacherCodeValidatorService.normalize(
      _codeController.text,
    );
    final nextError = TeacherCodeValidatorService.validate(
      _codeController.text,
    );
    final nextDirty = normalized != widget.currentCode;

    // Always rebuild so button enabled state reacts immediately even when
    // validation remains null (e.g., switching from one valid code to another).
    setState(() {
      _validationError = nextError;
    });

    if (nextDirty != _isDirty) {
      _isDirty = nextDirty;
      widget.onDirtyChanged?.call(nextDirty);
    }
  }

  String _universalPortalUrl(String code) {
    final path = AppRoutes.studentPortalPath(code, openExternalBrowser: true);
    if (!kIsWeb) {
      return path;
    }
    final origin = Uri.base.origin.replaceFirst(RegExp(r'/$'), '');
    return '$origin$path';
  }

  Future<void> _copyUniversalLink() async {
    await Clipboard.setData(
      ClipboardData(text: _universalPortalUrl(widget.currentCode)),
    );
    if (!mounted) return;
    AppFeedbackBanner.showSnackBar(
      context,
      type: AppFeedbackType.success,
      message: 'คัดลอกลิงก์พอร์ทัลนักเรียนแล้ว',
    );
  }

  Future<void> _confirmAndChangeCode() async {
    final normalized = TeacherCodeValidatorService.normalize(
      _codeController.text,
    );
    final error = TeacherCodeValidatorService.validate(normalized);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    if (normalized == widget.currentCode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการเปลี่ยนรหัสครู'),
        content: Text(
          'ต้องการเปลี่ยนรหัสครูจาก "${widget.currentCode}" เป็น "$normalized" หรือไม่?\n\n'
          'รหัสเก่าจะถูกบันทึกไว้ในประวัติเพื่อให้ลิงก์เดิมในโน้ตกลุ่ม LINE Redirect มายังรหัสใหม่โดยอัตโนมัติ '
          'แต่แนะนำให้อัปเดตลิงก์ในโน้ตกลุ่มให้เป็นลิงก์ใหม่ด้วย',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ยืนยันเปลี่ยนรหัส'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final changed = await widget.onChangeCode(normalized);
      if (changed && mounted && _isDirty) {
        setState(() => _isDirty = false);
        widget.onDirtyChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final historyAsync = ref.watch(teacherCodeHistoryProvider);
    final normalizedInput = TeacherCodeValidatorService.normalize(
      _codeController.text,
    );
    final canSubmit =
        !widget.isSaving &&
        _validationError == null &&
        normalizedInput != widget.currentCode &&
        normalizedInput.isNotEmpty;

    return AppSurfaceCard(
      title: 'รหัสครูและลิงก์ Student Portal',
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  _universalPortalUrl(widget.currentCode),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: _copyUniversalLink,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('คัดลอกลิงก์'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'รหัสครูสั้น (Teacher Code)',
              helperText: 'ใช้ตัวอักษร a-z, ตัวเลข 0-9 และ - ความยาว 3–30 ตัว',
              errorText: _validationError,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: canSubmit ? _confirmAndChangeCode : null,
              icon: widget.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_rounded, size: 18),
              label: Text(
                widget.isSaving ? 'กำลังเปลี่ยนรหัส...' : 'เปลี่ยนรหัสครู',
              ),
            ),
          ),
          const Divider(height: 28),
          Text(
            'ประวัติรหัสครูเก่า (Redirect อัตโนมัติ)',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Column(
              children: [
                SkeletonBox.line(height: 16),
                SizedBox(height: 8),
                SkeletonBox.line(width: 220, height: 14),
              ],
            ),
            error: (error, stackTrace) => AppFeedbackBanner(
              type: AppFeedbackType.error,
              message: ThaiErrorMapper.map(error),
              onRetry: () => ref.invalidate(teacherCodeHistoryProvider),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Text(
                  'ยังไม่มีประวัติการเปลี่ยนรหัสครู',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: [
                  for (final entry in entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        entry.oldCode,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'เปลี่ยนเมื่อ ${ThaiDateFormatter.formatShortDate(entry.changedAt.toLocal())}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
