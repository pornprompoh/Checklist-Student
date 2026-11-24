import '../entities/term.dart';

/// Pure Dart service resolving the teacher's active [Term].
///
/// Priority order:
/// 1. Manually pinned active term (`isPinnedActive == true`).
/// 2. Term whose `[startDate, endDate]` covers `today` (date-only comparison;
///    if multiple overlap, picks the one with the latest `startDate`).
/// 3. Semester-break fallback: most recently ended term (`endDate < today`,
///    ordered `endDate DESC`); if none, soonest upcoming term (`startDate > today`,
///    ordered `startDate ASC`).
abstract final class ActiveTermResolverService {
  static Term? resolveActiveTerm(List<Term> terms, {DateTime? now}) {
    if (terms.isEmpty) {
      return null;
    }

    for (final term in terms) {
      if (term.isPinnedActive) {
        return term;
      }
    }

    final today = _dateOnly(now ?? DateTime.now());

    final currentTerms =
        terms.where((term) {
          final start = _dateOnly(term.startDate);
          final end = _dateOnly(term.endDate);
          return !today.isBefore(start) && !today.isAfter(end);
        }).toList()..sort(
          (a, b) => _dateOnly(b.startDate).compareTo(_dateOnly(a.startDate)),
        );

    if (currentTerms.isNotEmpty) {
      return currentTerms.first;
    }

    final pastTerms =
        terms.where((term) => _dateOnly(term.endDate).isBefore(today)).toList()
          ..sort(
            (a, b) => _dateOnly(b.endDate).compareTo(_dateOnly(a.endDate)),
          );

    if (pastTerms.isNotEmpty) {
      return pastTerms.first;
    }

    final futureTerms = List<Term>.of(terms)
      ..sort(
        (a, b) => _dateOnly(a.startDate).compareTo(_dateOnly(b.startDate)),
      );
    return futureTerms.first;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
