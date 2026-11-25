/// Level 2 of the 4-level academic hierarchy (`public.terms`).
///
/// [startDate] and [endDate] are optional (`null` when not specified) and map
/// to nullable ISO `DATE` columns in PostgreSQL. Pure Dart entity.
class Term {
  const Term({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.termLabel,
    this.startDate,
    this.endDate,
    required this.isPinnedActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String academicYearId;
  final String termLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPinnedActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether both [startDate] and [endDate] are specified for this term.
  bool get hasDateRange => startDate != null && endDate != null;

  /// Returns `true` only when [endDate] is specified and strictly before today.
  /// Terms without dates are never flagged as past by date.
  bool isPastTerm({DateTime? now}) {
    final end = endDate;
    if (end == null) {
      return false;
    }
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return today.isAfter(endOnly);
  }

  /// Creates an updated copy of this [Term]. Pass [clearDates] as `true` to
  /// explicitly reset both [startDate] and [endDate] to `null`.
  Term copyWith({
    String? id,
    String? teacherId,
    String? academicYearId,
    String? termLabel,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    bool? isPinnedActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Term(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      academicYearId: academicYearId ?? this.academicYearId,
      termLabel: termLabel ?? this.termLabel,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      isPinnedActive: isPinnedActive ?? this.isPinnedActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
