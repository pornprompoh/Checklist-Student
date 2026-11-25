import 'package:checklist_student/features/academic_structure/data/models/term_dto.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/term.dart';
import 'package:checklist_student/features/academic_structure/domain/services/active_term_resolver_service.dart';
import 'package:checklist_student/features/academic_structure/domain/services/term_label_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

Term _buildTerm({
  required String id,
  required String label,
  String academicYearId = 'year-2569',
  DateTime? start,
  DateTime? end,
  bool isPinnedActive = false,
  DateTime? createdAt,
}) {
  final ts = createdAt ?? DateTime(2026, 1, 1);
  return Term(
    id: id,
    teacherId: 'teacher-1',
    academicYearId: academicYearId,
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

    test('prioritizes pinned undated term over date-matching term', () {
      final pinnedUndated = _buildTerm(
        id: 'term-undated-pinned',
        label: '1',
        isPinnedActive: true,
      );
      final datedCurrent = _buildTerm(
        id: 'term-dated',
        label: '2',
        start: DateTime(2026, 11, 1),
        end: DateTime(2027, 3, 31),
      );

      final resolved = ActiveTermResolverService.resolveActiveTerm(
        <Term>[pinnedUndated, datedCurrent],
        now: DateTime(2026, 11, 24),
      );

      expect(resolved?.id, 'term-undated-pinned');
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

      expect(
        ActiveTermResolverService.resolveActiveTerm(
          <Term>[term1, term2],
          now: DateTime(2026, 5, 16, 0, 0),
        )?.id,
        'term-1',
      );
      expect(
        ActiveTermResolverService.resolveActiveTerm(
          <Term>[term1, term2],
          now: DateTime(2026, 10, 10, 23, 59),
        )?.id,
        'term-1',
      );
      expect(
        ActiveTermResolverService.resolveActiveTerm(
          <Term>[term1, term2],
          now: DateTime(2026, 11, 24),
        )?.id,
        'term-2',
      );
    });

    test('prefers date-covering term over unpinned undated term', () {
      final undated = _buildTerm(
        id: 'term-undated',
        label: '2',
        createdAt: DateTime(2026, 12, 1),
      );
      final covering = _buildTerm(
        id: 'term-covering',
        label: '1',
        start: DateTime(2026, 5, 16),
        end: DateTime(2026, 10, 10),
      );

      final resolved = ActiveTermResolverService.resolveActiveTerm(
        <Term>[undated, covering],
        now: DateTime(2026, 7, 1),
      );

      expect(resolved?.id, 'term-covering');
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

    test(
      'falls back to newest undated term by academicYearBe DESC, termLabel DESC, createdAt DESC',
      () {
        final olderYear = _buildTerm(
          id: 't-2568-2',
          label: '2',
          academicYearId: 'y-2568',
          createdAt: DateTime(2026, 1, 1),
        );
        final currentYear1 = _buildTerm(
          id: 't-2569-1',
          label: '1',
          academicYearId: 'y-2569',
          createdAt: DateTime(2026, 5, 1),
        );
        final currentYear2 = _buildTerm(
          id: 't-2569-2',
          label: '2',
          academicYearId: 'y-2569',
          createdAt: DateTime(2026, 10, 1),
        );

        final resolved = ActiveTermResolverService.resolveActiveTerm(
          <Term>[olderYear, currentYear1, currentYear2],
          now: DateTime(2026, 11, 25),
          yearBeByAcademicYearId: const <String, int>{
            'y-2568': 2568,
            'y-2569': 2569,
          },
        );

        expect(resolved?.id, 't-2569-2');
      },
    );
  });

  group('Term, TermDto & TermLabelFormatter (Optional Term Dates)', () {
    test('TermDto parses and serializes both dated and null-date rows', () {
      final nullDto = TermDto.fromJson(<String, dynamic>{
        'id': 't-null',
        'teacher_id': 'teacher-1',
        'academic_year_id': 'y-2569',
        'term_label': '1',
        'start_date': null,
        'end_date': null,
        'is_pinned_active': false,
        'created_at': '2026-11-25T00:00:00Z',
        'updated_at': '2026-11-25T00:00:00Z',
      });
      final nullEntity = nullDto.toEntity();
      expect(nullEntity.startDate, isNull);
      expect(nullEntity.endDate, isNull);
      expect(nullEntity.hasDateRange, isFalse);
      expect(nullEntity.isPastTerm(now: DateTime(2026, 11, 25)), isFalse);

      final insertNullPayload = TermDto.toInsertJson(
        teacherId: 'teacher-1',
        academicYearId: 'y-2569',
        termLabel: '1',
      );
      expect(insertNullPayload['start_date'], isNull);
      expect(insertNullPayload['end_date'], isNull);

      final datedDto = TermDto.fromJson(<String, dynamic>{
        'id': 't-dated',
        'teacher_id': 'teacher-1',
        'academic_year_id': 'y-2569',
        'term_label': '1',
        'start_date': '2026-05-16',
        'end_date': '2026-10-10',
        'is_pinned_active': true,
        'created_at': '2026-05-01T00:00:00Z',
        'updated_at': '2026-05-01T00:00:00Z',
      });
      final datedEntity = datedDto.toEntity();
      expect(datedEntity.hasDateRange, isTrue);
      expect(datedEntity.startDate, DateTime(2026, 5, 16));
      expect(datedEntity.endDate, DateTime(2026, 10, 10));
      expect(datedEntity.isPastTerm(now: DateTime(2026, 11, 25)), isTrue);
      expect(datedEntity.isPastTerm(now: DateTime(2026, 10, 10)), isFalse);

      final cleared = datedEntity.copyWith(clearDates: true);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
      expect(cleared.hasDateRange, isFalse);

      final updateClearedPayload = TermDto.toUpdateJson(
        termLabel: '1',
        startDate: null,
        endDate: null,
      );
      expect(updateClearedPayload['start_date'], isNull);
      expect(updateClearedPayload['end_date'], isNull);
    });

    test(
      'TermLabelFormatter formats clean Thai labels without null or empty parentheses',
      () {
        final undated = _buildTerm(id: 't-1', label: '1');
        expect(
          TermLabelFormatter.formatFullLabel(undated, academicYearBe: 2569),
          'ปีการศึกษา 2569 — เทอม 1',
        );
        expect(TermLabelFormatter.formatDateRangeOrNull(undated), isNull);

        final dated = _buildTerm(
          id: 't-2',
          label: '1',
          start: DateTime(2026, 5, 16),
          end: DateTime(2026, 10, 10),
        );
        final fullDated = TermLabelFormatter.formatFullLabel(
          dated,
          academicYearBe: 2569,
        );
        expect(fullDated, startsWith('ปีการศึกษา 2569 — เทอม 1 ('));
        expect(fullDated, contains('2569'));
        expect(fullDated, isNot(contains('null')));
        expect(fullDated, isNot(contains('()')));
      },
    );
  });
}
