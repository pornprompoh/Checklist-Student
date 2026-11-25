import '../../domain/entities/student_score.dart';

/// Auto-save lifecycle status displayed per cell and on `SaveStatusIndicator`.
enum CellSaveStatus { idle, saving, saved, error, conflict }

/// Canonical cell key (`enrollmentId::assignmentId`) for score maps and focus.
String gradingCellKey(String enrollmentId, String assignmentId) =>
    '$enrollmentId::$assignmentId';

/// Immutable UI & cache state for `GradingTablePage`.
class GradingTableState {
  const GradingTableState({
    this.boundClassId,
    this.isEditMode = false,
    this.activeCellKey,
    this.scoresByCellKey = const <String, StudentScore>{},
    this.cellStatuses = const <String, CellSaveStatus>{},
    this.pendingKeys = const <String>{},
    this.overallSaveStatus = CellSaveStatus.idle,
    this.lastSavedAt,
    this.lastErrorMessage,
    this.hasHydratedClass = false,
  });

  final String? boundClassId;
  final bool isEditMode;
  final String? activeCellKey;
  final Map<String, StudentScore> scoresByCellKey;
  final Map<String, CellSaveStatus> cellStatuses;
  final Set<String> pendingKeys;
  final CellSaveStatus overallSaveStatus;
  final DateTime? lastSavedAt;
  final String? lastErrorMessage;
  final bool hasHydratedClass;

  static const Object _sentinel = Object();

  GradingTableState copyWith({
    Object? boundClassId = _sentinel,
    bool? isEditMode,
    Object? activeCellKey = _sentinel,
    Map<String, StudentScore>? scoresByCellKey,
    Map<String, CellSaveStatus>? cellStatuses,
    Set<String>? pendingKeys,
    CellSaveStatus? overallSaveStatus,
    Object? lastSavedAt = _sentinel,
    Object? lastErrorMessage = _sentinel,
    bool? hasHydratedClass,
  }) {
    return GradingTableState(
      boundClassId: identical(boundClassId, _sentinel)
          ? this.boundClassId
          : boundClassId as String?,
      isEditMode: isEditMode ?? this.isEditMode,
      activeCellKey: identical(activeCellKey, _sentinel)
          ? this.activeCellKey
          : activeCellKey as String?,
      scoresByCellKey: scoresByCellKey ?? this.scoresByCellKey,
      cellStatuses: cellStatuses ?? this.cellStatuses,
      pendingKeys: pendingKeys ?? this.pendingKeys,
      overallSaveStatus: overallSaveStatus ?? this.overallSaveStatus,
      lastSavedAt: identical(lastSavedAt, _sentinel)
          ? this.lastSavedAt
          : lastSavedAt as DateTime?,
      lastErrorMessage: identical(lastErrorMessage, _sentinel)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
      hasHydratedClass: hasHydratedClass ?? this.hasHydratedClass,
    );
  }
}
