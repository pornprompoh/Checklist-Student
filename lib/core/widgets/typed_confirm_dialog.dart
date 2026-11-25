import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';
import '../theme/app_theme.dart';

/// Single row in a structural deletion impact summary (e.g., student count,
/// attendance sessions, or graded assignments affected).
@immutable
class DeleteImpactItem {
  const DeleteImpactItem({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

/// High-friction confirmation dialog for destructive structural deletions
/// (terms, subjects, classes).
///
/// Displays affected item counts and keeps the destructive action disabled
/// until the user types [expectedText] verbatim.
class TypedConfirmDialog extends StatefulWidget {
  const TypedConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    required this.expectedText,
    this.impactSummary = const <DeleteImpactItem>[],
    this.confirmLabel = 'ยืนยันการลบ',
    this.cancelLabel = 'ยกเลิก',
  });

  final String title;
  final String description;
  final String expectedText;
  final List<DeleteImpactItem> impactSummary;
  final String confirmLabel;
  final String cancelLabel;

  /// Shows [TypedConfirmDialog] and returns `true` only when the user types
  /// [expectedText] accurately and taps the confirm button.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    required String expectedText,
    List<DeleteImpactItem> impactSummary = const <DeleteImpactItem>[],
    String confirmLabel = 'ยืนยันการลบ',
    String cancelLabel = 'ยกเลิก',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => TypedConfirmDialog(
        title: title,
        description: description,
        expectedText: expectedText,
        impactSummary: impactSummary,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }

  @override
  State<TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<TypedConfirmDialog> {
  late final TextEditingController _controller;
  bool _isMatched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleInputChanged);
  }

  void _handleInputChanged() {
    final matched = _controller.text.trim() == widget.expectedText.trim();
    if (matched != _isMatched) {
      setState(() => _isMatched = matched);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleInputChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semanticColors = AppSemanticColors.of(context);

    return AlertDialog(
      scrollable: true,
      icon: Icon(
        Icons.warning_amber_rounded,
        color: semanticColors.danger,
        size: 32,
      ),
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.impactSummary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: semanticColors.dangerContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: semanticColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผลกระทบจากการลบ',
                      style: textTheme.labelLarge?.copyWith(
                        color: semanticColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in widget.impactSummary)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: textTheme.bodySmall?.copyWith(
                                  color: semanticColors.danger,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.count} รายการ',
                              style: textTheme.bodySmall?.copyWith(
                                color: semanticColors.danger,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'พิมพ์ข้อความด้านล่างให้ตรงเพื่อยืนยัน:',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SelectableText(
                widget.expectedText,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.expectedText,
                labelText: 'พิมพ์ชื่อเพื่อยืนยัน',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: semanticColors.danger,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: _isMatched ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
