import 'package:flutter/material.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/services/score_calculator_service.dart';
import '../providers/grading_filter_provider.dart';
import '../providers/grading_table_state.dart';
import 'editable_score_cell.dart';
import 'frozen_grade_grid_header.dart';
import 'special_grade_badge.dart';

/// Virtualized 2D grade grid with a frozen left student column and frozen top
/// assignment header row, synchronized via guarded scroll controllers.
class FrozenGradeGrid extends StatefulWidget {
  const FrozenGradeGrid({
    super.key,
    required this.rows,
    required this.assignments,
    required this.scoresByCellKey,
    required this.cellStatuses,
    required this.isEditMode,
    required this.activeCellKey,
    required this.onStartCellEdit,
    required this.onCancelCellEdit,
    required this.onCommitCellScore,
    required this.onOpenCellDetail,
    this.onOpenStudentProfile,
    this.onTapSpecialGrade,
  });

  final List<GradingTableRowData> rows;
  final List<Assignment> assignments;
  final Map<String, StudentScore> scoresByCellKey;
  final Map<String, CellSaveStatus> cellStatuses;
  final bool isEditMode;
  final String? activeCellKey;
  final void Function(String enrollmentId, String assignmentId) onStartCellEdit;
  final VoidCallback onCancelCellEdit;
  final Future<void> Function({
    required String enrollmentId,
    required String assignmentId,
    required double? score,
    required SubmissionStatus status,
  })
  onCommitCellScore;
  final void Function(GradingTableRowData row, Assignment assignment)
  onOpenCellDetail;
  final ValueChanged<ClassEnrollment>? onOpenStudentProfile;
  final ValueChanged<ClassEnrollment>? onTapSpecialGrade;

  @override
  State<FrozenGradeGrid> createState() => _FrozenGradeGridState();
}

class _FrozenGradeGridState extends State<FrozenGradeGrid> {
  static const double _assignmentColWidth = 104;
  static const double _totalColWidth = 96;
  static const double _gradeColWidth = 98;
  static const double _rowHeight = 56;
  static const double _headerHeight = 68;
  static const _calculator = ScoreCalculatorService();

  late final ScrollController _leftVerticalCtrl;
  late final ScrollController _rightVerticalCtrl;
  late final ScrollController _headerHorizontalCtrl;
  late final ScrollController _bodyHorizontalCtrl;
  bool _syncingVertical = false;
  bool _syncingHorizontal = false;

  @override
  void initState() {
    super.initState();
    _leftVerticalCtrl = ScrollController()..addListener(_syncFromLeftVertical);
    _rightVerticalCtrl = ScrollController()
      ..addListener(_syncFromRightVertical);
    _headerHorizontalCtrl = ScrollController()
      ..addListener(_syncFromHeaderHorizontal);
    _bodyHorizontalCtrl = ScrollController()
      ..addListener(_syncFromBodyHorizontal);
  }

  @override
  void dispose() {
    _leftVerticalCtrl
      ..removeListener(_syncFromLeftVertical)
      ..dispose();
    _rightVerticalCtrl
      ..removeListener(_syncFromRightVertical)
      ..dispose();
    _headerHorizontalCtrl
      ..removeListener(_syncFromHeaderHorizontal)
      ..dispose();
    _bodyHorizontalCtrl
      ..removeListener(_syncFromBodyHorizontal)
      ..dispose();
    super.dispose();
  }

  void _syncFromLeftVertical() {
    if (_syncingVertical || !_rightVerticalCtrl.hasClients) return;
    _syncingVertical = true;
    _rightVerticalCtrl.jumpTo(_leftVerticalCtrl.offset);
    _syncingVertical = false;
  }

  void _syncFromRightVertical() {
    if (_syncingVertical || !_leftVerticalCtrl.hasClients) return;
    _syncingVertical = true;
    _leftVerticalCtrl.jumpTo(_rightVerticalCtrl.offset);
    _syncingVertical = false;
  }

  void _syncFromHeaderHorizontal() {
    if (_syncingHorizontal || !_bodyHorizontalCtrl.hasClients) return;
    _syncingHorizontal = true;
    _bodyHorizontalCtrl.jumpTo(_headerHorizontalCtrl.offset);
    _syncingHorizontal = false;
  }

  void _syncFromBodyHorizontal() {
    if (_syncingHorizontal || !_headerHorizontalCtrl.hasClients) return;
    _syncingHorizontal = true;
    _headerHorizontalCtrl.jumpTo(_bodyHorizontalCtrl.offset);
    _syncingHorizontal = false;
  }

  void _moveNextRow(int rowIndex, int colIndex) {
    for (var next = rowIndex + 1; next < widget.rows.length; next++) {
      final candidate = widget.rows[next];
      if (!candidate.enrollment.isTransferredOut) {
        widget.onStartCellEdit(
          candidate.enrollment.id,
          widget.assignments[colIndex].id,
        );
        return;
      }
    }
    widget.onCancelCellEdit();
  }

  void _moveColumn(int rowIndex, int colIndex, int delta) {
    final targetCol = colIndex + delta;
    if (targetCol < 0 || targetCol >= widget.assignments.length) {
      widget.onCancelCellEdit();
      return;
    }
    widget.onStartCellEdit(
      widget.rows[rowIndex].enrollment.id,
      widget.assignments[targetCol].id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftWidth = constraints.maxWidth < 600 ? 158.0 : 236.0;
        final totalRightWidth =
            widget.assignments.length * _assignmentColWidth +
            _totalColWidth +
            _gradeColWidth;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                FrozenGradeGridHeader(
                  assignments: widget.assignments,
                  leftColumnWidth: leftWidth,
                  assignmentColWidth: _assignmentColWidth,
                  totalColWidth: _totalColWidth,
                  gradeColWidth: _gradeColWidth,
                  headerHeight: _headerHeight,
                  horizontalController: _headerHorizontalCtrl,
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: ListView.builder(
                          controller: _leftVerticalCtrl,
                          itemCount: widget.rows.length,
                          itemExtent: _rowHeight,
                          itemBuilder: (context, index) => _FrozenStudentCell(
                            row: widget.rows[index],
                            height: _rowHeight,
                            onOpenProfile: widget.onOpenStudentProfile == null
                                ? null
                                : () => widget.onOpenStudentProfile!(
                                    widget.rows[index].enrollment,
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _bodyHorizontalCtrl,
                          thumbVisibility: true,
                          notificationPredicate: (n) => n.depth == 0,
                          child: SingleChildScrollView(
                            controller: _bodyHorizontalCtrl,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: totalRightWidth,
                              child: ListView.builder(
                                controller: _rightVerticalCtrl,
                                itemCount: widget.rows.length,
                                itemExtent: _rowHeight,
                                itemBuilder: (context, rowIndex) =>
                                    _buildScoreRow(context, rowIndex),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreRow(BuildContext context, int rowIndex) {
    final row = widget.rows[rowIndex];
    final enrollment = row.enrollment;
    final isReadOnly = enrollment.isTransferredOut;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final result = row.gradeResult;

    return Row(
      children: [
        for (var colIndex = 0; colIndex < widget.assignments.length; colIndex++)
          Builder(
            builder: (context) {
              final assignment = widget.assignments[colIndex];
              final cellKey = gradingCellKey(enrollment.id, assignment.id);
              return EditableScoreCell(
                key: ValueKey<String>(cellKey),
                assignment: assignment,
                studentScore: widget.scoresByCellKey[cellKey],
                isEditMode: widget.isEditMode,
                isEditing: widget.activeCellKey == cellKey,
                isReadOnly: isReadOnly,
                saveStatus:
                    widget.cellStatuses[cellKey] ?? CellSaveStatus.idle,
                width: _assignmentColWidth,
                height: _rowHeight,
                onStartEditing: () =>
                    widget.onStartCellEdit(enrollment.id, assignment.id),
                onCancelEditing: widget.onCancelCellEdit,
                onCommitScore: (score, status) => widget.onCommitCellScore(
                  enrollmentId: enrollment.id,
                  assignmentId: assignment.id,
                  score: score,
                  status: status,
                ),
                onOpenDetailDialog: () =>
                    widget.onOpenCellDetail(row, assignment),
                onMoveNextRow: () => _moveNextRow(rowIndex, colIndex),
                onMoveNextColumn: () => _moveColumn(rowIndex, colIndex, 1),
                onMovePreviousColumn: () => _moveColumn(rowIndex, colIndex, -1),
              );
            },
          ),
        Container(
          width: _totalColWidth,
          height: _rowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: Text(
            _calculator.formatExactScore(result.totalScore),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          width: _gradeColWidth,
          height: _rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: SpecialGradeBadge(
            result: result,
            compact: true,
            onTap: isReadOnly || widget.onTapSpecialGrade == null
                ? null
                : () => widget.onTapSpecialGrade!(enrollment),
          ),
        ),
      ],
    );
  }
}

class _FrozenStudentCell extends StatelessWidget {
  const _FrozenStudentCell({
    required this.row,
    required this.height,
    this.onOpenProfile,
  });

  final GradingTableRowData row;
  final double height;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final enrollment = row.enrollment;

    // SAFETY GUARD: Row/name tap MUST NOT open StudentProfileDrawer; ONLY the
    // trailing IconButton below triggers onOpenProfile.
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: enrollment.isTransferredOut
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${enrollment.studentNumber}',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        enrollment.studentCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (enrollment.isTransferredOut) ...[
                      const SizedBox(width: 4),
                      Text(
                        'ย้ายออก',
                        style: textTheme.labelSmall?.copyWith(
                          color: semantic.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey<String>('open_profile_${enrollment.id}'),
            tooltip: 'ดูสรุปรายบุคคล',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: onOpenProfile,
            icon: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
