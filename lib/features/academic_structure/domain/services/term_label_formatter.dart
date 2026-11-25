import '../../../../core/utils/thai_date_formatter.dart';
import '../entities/term.dart';

/// Pure Dart helper formatting [Term] labels consistently across all pages,
/// omitting date parentheses cleanly when a term has no date range.
abstract final class TermLabelFormatter {
  /// Full dropdown label:
  /// - With dates: `"ปีการศึกษา 2569 — เทอม 1 (16 พ.ค. 2569 – 10 ต.ค. 2569)"`
  /// - Without dates: `"ปีการศึกษา 2569 — เทอม 1"`
  static String formatFullLabel(Term term, {int? academicYearBe}) {
    final prefix = academicYearBe != null ? 'ปีการศึกษา $academicYearBe — ' : '';
    final range = formatDateRangeOrNull(term);
    if (range != null) {
      return '$prefixเทอม ${term.termLabel} ($range)';
    }
    return '$prefixเทอม ${term.termLabel}';
  }

  /// Compact badge/pill label: `"เทอม 1/2569"` (or `"เทอม 1"` if year unknown).
  static String formatCompactLabel(Term term, {int? academicYearBe}) {
    if (academicYearBe != null) {
      return 'เทอม ${term.termLabel}/$academicYearBe';
    }
    return 'เทอม ${term.termLabel}';
  }

  /// Returns formatted Buddhist Era date range when both dates exist, or `null`.
  static String? formatDateRangeOrNull(Term term) {
    final start = term.startDate;
    final end = term.endDate;
    if (start == null || end == null) {
      return null;
    }
    return ThaiDateFormatter.formatDateRange(start, end);
  }
}
