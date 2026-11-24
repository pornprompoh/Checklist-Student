import 'package:checklist_student/features/academic_structure/domain/entities/term.dart';
import 'package:checklist_student/features/academic_structure/domain/services/active_term_resolver_service.dart';
import 'package:flutter_test/flutter_test.dart';

Term _buildTerm({
  required String id,
  required String label,
  required DateTime start,
  required DateTime end,
  bool isPinnedActive = false,
}) {
  final ts = DateTime(2026, 1, 1);
  return Term(
    id: id,
    teacherId: 'teacher-1',
    academicYearId: 'year-2569',
    termLabel: label,
    startDate: start,
    endDate: end,
    isPinnedActive: isPinnedActive,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('ActiveTermResolverService', () {
    test('returns null when term list is empty', () {
      expect(
        ActiveTermResolverService.resolveActiveTerm(
          const <Term>[],
          now: DateTime(2026, 7, 1),
        ),
        isNull,
      );
    });

    test('prioritizes pinned active term over date-matching term', () {
      final term1Pinned = _buildTerm(
        id: 'term-1',
        label: '1',
        start: DateTime(2026, 5, 16),
        end: DateTime(2026, 10, 10),
        isPinnedActive: true,
      );
      final term2Current = _buildTerm(
        id: 'term-2',
        label: '2',
        start: DateTime(2026, 11, 1),
        end: DateTime(2027, 3, 31),
      );

      final resolved = ActiveTermResolverService.resolveActiveTerm(
        <Term>[term1Pinned, term2Current],
        now: DateTime(2026, 11, 24),
      );

      expect(resolved?.id, 'term-1');
    });

    test('matches term covering today including exact start and end dates', () {
      final term1 = _buildTerm(
        id: 'term-1',
        label: '1',
        start: DateTime(2026, 5, 16),
        end: DateTime(2026, 10, 10),
      );
      final term2 = _buildTerm(
        id: 'term-2',
        label: '2',
        start: DateTime(2026, 11, 1),
        end: DateTime(2027, 3, 31),
      );

      // Exact start boundary
      expect(
        ActiveTermResolverService.resolveActiveTerm(
          <Term>[term1, term2],
          now: DateTime(2026, 5, 16, 0, 0),
        )?.id,
        'term-1',
      );

      // Exact end boundary late in the evening (date-only check)
      expect(
        ActiveTermResolverService.resolveActiveTerm(
          <Term>[term1, term2],
          now: DateTime(2026, 10, 10, 23, 59),
        )?.id,
        'term-1',
      );

      // Middle of term 2
      expect(
        ActiveTermResolverService.resolveActiveTerm(
          <Term>[term1, term2],
          now: DateTime(2026, 11, 24),
        )?.id,
        'term-2',
      );
    });

    test('chooses latest startDate when date ranges overlap', () {
      final earlierTerm = _buildTerm(
        id: 'term-early',
        label: '1',
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 10, 31),
      );
      final laterTerm = _buildTerm(
        id: 'term-late',
        label: 'ฤดูร้อน',
        start: DateTime(2026, 10, 15),
        end: DateTime(2026, 11, 15),
      );

      final resolved = ActiveTermResolverService.resolveActiveTerm(
        <Term>[earlierTerm, laterTerm],
        now: DateTime(2026, 10, 20),
      );

      expect(resolved?.id, 'term-late');
    });

    test('falls back to most recently ended term during semester break', () {
      final oldTerm = _buildTerm(
        id: 'term-old',
        label: '2/2568',
        start: DateTime(2025, 11, 1),
        end: DateTime(2026, 3, 31),
      );
      final recentTerm = _buildTerm(
        id: 'term-recent',
        label: '1/2569',
        start: DateTime(2026, 5, 16),
        end: DateTime(2026, 10, 10),
      );
      final upcomingTerm = _buildTerm(
        id: 'term-upcoming',
        label: '2/2569',
        start: DateTime(2026, 11, 1),
        end: DateTime(2027, 3, 31),
      );

      final resolved = ActiveTermResolverService.resolveActiveTerm(
        <Term>[oldTerm, recentTerm, upcomingTerm],
        now: DateTime(2026, 10, 20),
      );

      expect(resolved?.id, 'term-recent');
    });

    test('falls back to soonest upcoming term when only future terms exist', () {
      final farTerm = _buildTerm(
        id: 'term-far',
        label: '2',
        start: DateTime(2026, 11, 1),
        end: DateTime(2027, 3, 31),
      );
      final soonTerm = _buildTerm(
        id: 'term-soon',
        label: '1',
        start: DateTime(2026, 5, 16),
        end: DateTime(2026, 10, 10),
      );

      final resolved = ActiveTermResolverService.resolveActiveTerm(
        <Term>[farTerm, soonTerm],
        now: DateTime(2026, 4, 1),
      );

      expect(resolved?.id, 'term-soon');
    });
  });
}
