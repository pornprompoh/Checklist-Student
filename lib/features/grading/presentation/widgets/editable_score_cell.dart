import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/app_feedback_banner.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_table_state.dart';

/// Single score cell inside `FrozenGradeGrid`.
///
/// Enforces Preview Mode accidental-edit protection:
/// - In Preview Mode (`!isEditMode`), single tap does NOTHING; only `onDoubleTap`
///   activates inline editing.
/// - In Edit Mode (`isEditMode`), single tap activates editing and long-press /
///   secondary tap / detail button opens [ScoreCellDetailDialog].
/// - Supports `Enter` (next row), `Tab` / `Shift+Tab` (next/previous column),
///   `Escape` (cancel), and auto-save on blur.
class EditableScoreCell extends StatefulWidget {
  const EditableScoreCell({
    super.key,
    required this.assignment,
    required this.studentScore,
    required this.isEditMode,
    required this.isEditing,
    required this.isReadOnly,
    required this.saveStatus,
    required this.width,
    required this.height,
    required this.onStartEditing,
    required this.onCancelEditing,
    required this.onCommitScore,
    required this.onOpenDetailDialog,
    required this.onMoveNextRow,
    required this.onMoveNextColumn,
    required this.onMovePreviousColumn,
  });

  final Assignment assignment;
  final StudentScore? studentScore;
  final bool isEditMode;
  final bool isEditing;
  final bool isReadOnly;
  final CellSaveStatus saveStatus;
  final double width;
  final double height;
  final VoidCallback onStartEditing;
  final VoidCallback onCancelEditing;
  final Future<void> Function(double? score, SubmissionStatus status)
  onCommitScore;
  final VoidCallback onOpenDetailDialog;
  final VoidCallback onMoveNextRow;
  final VoidCallback onMoveNextColumn;
  final VoidCallback onMovePreviousColumn;

  @override
  State<EditableScoreCell> createState() => _EditableScoreCellState();
}

class _EditableScoreCellState extends State<EditableScoreCell> {
  static const _calculator = ScoreCalculatorService();

  late final TextEditingController _textCtrl;
  late final FocusNode _focusNode;
  bool _handledExit = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _formatCurrentScore());
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    if (widget.isEditing && !widget.isReadOnly) {
      _activateInlineFocus();
    }
  }

  @override
  void didUpdateWidget(covariant EditableScoreCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing && !widget.isReadOnly) {
      _handledExit = false;
      _textCtrl.text = _formatCurrentScore();
      _activateInlineFocus();
    } else if (!widget.isEditing && oldWidget.isEditing) {
      _handledExit = true;
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
      _textCtrl.text = _formatCurrentScore();
    } else if (!widget.isEditing &&
        oldWidget.studentScore?.score != widget.studentScore?.score) {
      _textCtrl.text = _formatCurrentScore();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  String _formatCurrentScore() {
    final score = widget.studentScore?.score;
    return score == null ? '' : _calculator.formatExactScore(score);
  }

  void _activateInlineFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isEditing) return;
      _focusNode.requestFocus();
      _textCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textCtrl.text.length,
      );
    });
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && widget.isEditing && !_handledExit) {
      _handledExit = true;
      _commitDraft();
      widget.onCancelEditing();
    }
  }

  void _commitDraft() {
    final trimmed = _textCtrl.text.trim();
    final existing = widget.studentScore;
    if (trimmed.isEmpty) {
      final status = existing?.submissionStatus ?? SubmissionStatus.missing;
      widget.onCommitScore(null, status);
      return;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      AppFeedbackBanner.showSnackBar(
        context,
        type: AppFeedbackType.error,
        message: 'กรุณากรอกคะแนนเป็นตัวเลขที่ไม่ติดลบ',
      );
      _textCtrl.text = _formatCurrentScore();
      return;
    }
    final nextStatus =
        existing == null || existing.submissionStatus == SubmissionStatus.missing
        ? SubmissionStatus.submitted
        : existing.submissionStatus;
    widget.onCommitScore(parsed, nextStatus);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _handledExit = true;
      _commitDraft();
      widget.onMoveNextRow();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _handledExit = true;
      _commitDraft();
      if (HardwareKeyboard.instance.isShiftPressed) {
        widget.onMovePreviousColumn();
      } else {
        widget.onMoveNextColumn();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _handledExit = true;
      _textCtrl.text = _formatCurrentScore();
      widget.onCancelEditing();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final score = widget.studentScore?.score;
    final status =
        widget.studentScore?.submissionStatus ?? SubmissionStatus.missing;
    final note = widget.studentScore?.note ?? '';
    final isOverMax =
        score != null &&
        (score * 100).round() > (widget.assignment.maxScore * 100).round();

    if (widget.isEditing && !widget.isReadOnly) {
      return Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          border: Border.all(color: colorScheme.primary, width: 1.8),
        ),
        child: Focus(
          onKeyEvent: _handleKeyEvent,
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      );
    }

    final borderColor = isOverMax
        ? semantic.danger
        : (widget.saveStatus == CellSaveStatus.conflict ||
                  widget.saveStatus == CellSaveStatus.error
              ? semantic.warning
              : colorScheme.outlineVariant.withValues(alpha: 0.6));
    final bgColor = isOverMax
        ? semantic.dangerContainer.withValues(alpha: 0.55)
        : (widget.isReadOnly
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : null);

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isOverMax ? 1.5 : 0.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildDisplayValue(context, score, status, isOverMax),
          if (note.isNotEmpty)
            Positioned(
              top: 1,
              right: 1,
              child: Tooltip(
                message: note,
                child: Icon(
                  Icons.sticky_note_2_outlined,
                  size: 13,
                  color: colorScheme.primary,
                ),
              ),
            ),
          if (isOverMax)
            Positioned(
              bottom: 1,
              left: 1,
              child: Icon(
                Icons.warning_amber_rounded,
                size: 13,
                color: semantic.danger,
              ),
            ),
          if (widget.saveStatus == CellSaveStatus.saving)
            Positioned(
              bottom: 2,
              right: 2,
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: colorScheme.primary,
                ),
              ),
            ),
          if (widget.isEditMode && !widget.isReadOnly)
            Positioned(
              top: 0,
              left: 0,
              child: InkWell(
                onTap: widget.onOpenDetailDialog,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (isOverMax) {
      content = Tooltip(
        message:
            'คะแนนเกินคะแนนเต็ม (${_calculator.formatExactScore(widget.assignment.maxScore)})',
        child: content,
      );
    }

    if (widget.isReadOnly) {
      return content;
    }

    // Preview Mode: single tap MUST NOT start editing; double tap enters edit.
    if (!widget.isEditMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onStartEditing,
        child: content,
      );
    }

    return InkWell(
      onTap: widget.onStartEditing,
      onLongPress: widget.onOpenDetailDialog,
      onSecondaryTap: widget.onOpenDetailDialog,
      child: content,
    );
  }

  Widget _buildDisplayValue(
    BuildContext context,
    double? score,
    SubmissionStatus status,
    bool isOverMax,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (score != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _calculator.formatExactScore(score),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isOverMax ? semantic.danger : colorScheme.onSurface,
            ),
          ),
          if (status == SubmissionStatus.late)
            Text(
              'ส่งช้า',
              style: textTheme.labelSmall?.copyWith(
                color: semantic.late,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      );
    }

    final (Color textColor, String label) = switch (status) {
      SubmissionStatus.submitted => (semantic.success, 'ส่งแล้ว'),
      SubmissionStatus.late => (semantic.late, 'ส่งช้า'),
      SubmissionStatus.missing => (
        colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
        'ยังไม่ส่ง',
      ),
    };
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelSmall?.copyWith(
        color: textColor,
        fontWeight: status == SubmissionStatus.missing
            ? FontWeight.w400
            : FontWeight.w600,
      ),
    );
  }
}
