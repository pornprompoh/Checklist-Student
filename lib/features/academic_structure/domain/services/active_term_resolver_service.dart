import '../entities/term.dart';

/// Pure Dart service resolving the teacher's active [Term].
///
/// Priority order:
/// 1. Manually pinned active term (`isPinnedActive == true`).
/// 2. Dated term (`hasDateRange == true`) whose `[startDate, endDate]` covers
///    `today` (date-only comparison; if multiple overlap, picks latest `startDate`).
/// 3. Fallback when no term covers `today`:
///    - If undated terms exist, orders them by `academicYearBe DESC`,
///      term order (`termLabel`) `DESC`, and `createdAt DESC`, preferring an
///      undated term in an equal-or-newer academic year over older ended terms.
///    - Otherwise preserves semester-break fallback for dated terms: most
///      recently ended (`endDate < today`, `endDate DESC`), or soonest upcoming
///      (`startDate ASC`).
abstract final class ActiveTermResolverService {
  static Term? resolveActiveTerm(
    List<Term> terms, {
    DateTime? now,
    Map<String, int>? yearBeByAcademicYearId,
  }) {
    if (terms.isEmpty) {
      return null;
    }

    // 1. Pinned active term always wins.
    for (final term in terms) {
      if (term.isPinnedActive) {
        return term;
      }
    }

    final today = _dateOnly(now ?? DateTime.now());
    final datedTerms = terms.where((t) => t.hasDateRange).toList();
    final undatedTerms = terms.where((t) => !t.hasDateRange).toList();

    // 2. Dated term covering today.
    final currentTerms =
        datedTerms.where((term) {
          final start = term.startDate;
          final end = term.endDate;
          if (start == null || end == null) return false;
          final startOnly = _dateOnly(start);
          final endOnly = _dateOnly(end);
          return !today.isBefore(startOnly) && !today.isAfter(endOnly);
        }).toList()..sort((a, b) {
          final aStart = a.startDate;
          final bStart = b.startDate;
          if (aStart == null || bStart == null) return 0;
          return _dateOnly(bStart).compareTo(_dateOnly(aStart));
        });

    if (currentTerms.isNotEmpty) {
      return currentTerms.first;
    }

    // 3. Resolve best undated fallback (newest academic year, term, createdAt).
    undatedTerms.sort(
      (a, b) => _compareRecencyDesc(a, b, yearBeByAcademicYearId),
    );
    final bestUndated = undatedTerms.isEmpty ? null : undatedTerms.first;

    // 4. Resolve best dated fallback (semester break: most recently ended, else soonest upcoming).
    final Term? bestDated = _resolveDatedFallback(datedTerms, today);

    if (bestUndated == null) {
      return bestDated;
    }
    if (bestDated == null) {
      return bestUndated;
    }

    // Compare best undated vs dated fallback: prefer undated if it belongs to
    // a newer/equal academic year (or was created later when years aren't mapped).
    return _compareRecencyDesc(bestUndated, bestDated, yearBeByAcademicYearId) <=
            0
        ? bestUndated
        : bestDated;
  }

  static Term? _resolveDatedFallback(List<Term> datedTerms, DateTime today) {
    if (datedTerms.isEmpty) {
      return null;
    }
    final pastTerms =
        datedTerms.where((term) {
          final end = term.endDate;
          return end != null && _dateOnly(end).isBefore(today);
        }).toList()..sort((a, b) {
          final aEnd = a.endDate;
          final bEnd = b.endDate;
          if (aEnd == null || bEnd == null) return 0;
          return _dateOnly(bEnd).compareTo(_dateOnly(aEnd));
        });

    if (pastTerms.isNotEmpty) {
      return pastTerms.first;
    }

    final futureTerms = List<Term>.of(datedTerms)
      ..sort((a, b) {
        final aStart = a.startDate;
        final bStart = b.startDate;
        if (aStart == null || bStart == null) return 0;
        return _dateOnly(aStart).compareTo(_dateOnly(bStart));
      });
    return futureTerms.first;
  }

  static int _compareRecencyDesc(
    Term a,
    Term b,
    Map<String, int>? yearBeByAcademicYearId,
  ) {
    final yearA = yearBeByAcademicYearId?[a.academicYearId] ?? 0;
    final yearB = yearBeByAcademicYearId?[b.academicYearId] ?? 0;
    if (yearA != yearB) {
      return yearB.compareTo(yearA);
    }
    final numA = _extractTermOrder(a.termLabel);
    final numB = _extractTermOrder(b.termLabel);
    if (numA != numB) {
      return numB.compareTo(numA);
    }
    final createdCmp = b.createdAt.compareTo(a.createdAt);
    if (createdCmp != 0) {
      return createdCmp;
    }
    return b.termLabel.compareTo(a.termLabel);
  }

  static int _extractTermOrder(String label) {
    final trimmed = label.trim();
    final direct = int.tryParse(trimmed);
    if (direct != null) return direct;
    final match = RegExp(r'\d+').firstMatch(trimmed);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '') ?? 0;
    }
    if (trimmed.contains('ฤดูร้อน') || trimmed.toLowerCase().contains('summer')) {
      return 3;
    }
    return 0;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
