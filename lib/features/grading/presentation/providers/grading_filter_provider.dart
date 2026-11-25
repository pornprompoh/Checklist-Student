import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/domain/entities/student_attendance_summary.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../domain/entities/grade_result.dart';

/// Quick filter chips displayed on `GradingTableToolbar`.
enum GradingQuickFilter {
  all('ทั้งหมด'),
  missingWork('ค้างงาน'),
  atRiskMs('เสี่ยง มส'),
  hasSpecialGrade('ติด ร-มส');

  const GradingQuickFilter(this.thaiLabel);

  final String thaiLabel;
}

/// Aggregated row view-model combining enrollment, live [GradeResult], and
/// Phase 3 attendance risk summary for one student in `GradingTablePage`.
class GradingTableRowData {
  const GradingTableRowData({
    required this.enrollment,
    required this.gradeResult,
    this.attendanceSummary,
  });

  final ClassEnrollment enrollment;
  final GradeResult gradeResult;
  final StudentAttendanceSummary? attendanceSummary;
}

/// Immutable filter state for `GradingTablePage`.
class GradingFilterState {
  const GradingFilterState({
    this.searchQuery = '',
    this.quickFilter = GradingQuickFilter.all,
    this.showTransferredOut = false,
  });

  final String searchQuery;
  final GradingQuickFilter quickFilter;
  final bool showTransferredOut;

  GradingFilterState copyWith({
    String? searchQuery,
    GradingQuickFilter? quickFilter,
    bool? showTransferredOut,
  }) {
    return GradingFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilter: quickFilter ?? this.quickFilter,
      showTransferredOut: showTransferredOut ?? this.showTransferredOut,
    );
  }
}

class GradingFilterNotifier extends Notifier<GradingFilterState> {
  @override
  GradingFilterState build() => const GradingFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setQuickFilter(GradingQuickFilter filter) {
    state = state.copyWith(quickFilter: filter);
  }

  void setShowTransferredOut(bool show) {
    state = state.copyWith(showTransferredOut: show);
  }

  void reset() {
    state = const GradingFilterState();
  }
}

final gradingFilterProvider =
    NotifierProvider<GradingFilterNotifier, GradingFilterState>(
      GradingFilterNotifier.new,
    );

/// Pure helper filtering [rows] by active/transferred-out visibility, search
/// query (full name, student code, or student number), and [GradingQuickFilter].
List<GradingTableRowData> filterGradingRows({
  required List<GradingTableRowData> rows,
  required GradingFilterState filter,
}) {
  final normalizedQuery = filter.searchQuery.trim().toLowerCase();

  return rows
      .where((row) {
        if (!filter.showTransferredOut && row.enrollment.isTransferredOut) {
          return false;
        }
        if (normalizedQuery.isNotEmpty &&
            !_matchesQuery(row.enrollment, normalizedQuery)) {
          return false;
        }
        return _matchesQuickFilter(row, filter.quickFilter);
      })
      .toList(growable: false);
}

/// Pure helper computing badge counts for each [GradingQuickFilter] chip.
Map<GradingQuickFilter, int> countQuickFilterBuckets({
  required List<GradingTableRowData> rows,
  required bool showTransferredOut,
}) {
  final eligible = showTransferredOut
      ? rows
      : rows.where((r) => !r.enrollment.isTransferredOut).toList();
  return <GradingQuickFilter, int>{
    for (final chip in GradingQuickFilter.values)
      chip: eligible.where((row) => _matchesQuickFilter(row, chip)).length,
  };
}

bool _matchesQuery(ClassEnrollment enrollment, String normalizedQuery) {
  if (enrollment.fullName.toLowerCase().contains(normalizedQuery)) {
    return true;
  }
  if (enrollment.studentCode.toLowerCase().contains(normalizedQuery)) {
    return true;
  }
  if (enrollment.studentNumber.toString() == normalizedQuery) {
    return true;
  }
  return false;
}

bool _matchesQuickFilter(GradingTableRowData row, GradingQuickFilter filter) {
  switch (filter) {
    case GradingQuickFilter.all:
      return true;
    case GradingQuickFilter.missingWork:
      return row.gradeResult.missingAssignmentsCount > 0;
    case GradingQuickFilter.atRiskMs:
      return row.attendanceSummary != null &&
          row.attendanceSummary!.isAtRiskOrExceededMs;
    case GradingQuickFilter.hasSpecialGrade:
      final advice = row.gradeResult.specialGradeAdvice;
      return row.enrollment.specialGradeOverride != null ||
          advice.recommendR ||
          advice.recommendMs;
  }
}
