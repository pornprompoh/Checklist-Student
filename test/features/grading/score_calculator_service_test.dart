import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/grading/domain/services/score_calculator_service.dart';

void main() {
  const service = ScoreCalculatorService();
  final now = DateTime.utc(2026, 11, 25);

  ScoreCategory buildCategory(
    String id,
    String name, {
    double? targetMaxScore,
    int sortOrder = 0,
  }) {
    return ScoreCategory(
      id: id,
      teacherId: 'teacher-1',
      subjectClassId: 'class-1',
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  Assignment buildAssignment(
    String id, {
    String? categoryId,
    required double maxScore,
    bool isMandatory = false,
  }) {
    return Assignment(
      id: id,
      teacherId: 'teacher-1',
      subjectClassId: 'class-1',
      categoryId: categoryId,
      title: 'งาน $id',
      maxScore: maxScore,
      isMandatory: isMandatory,
      createdAt: now,
      updatedAt: now,
    );
  }

  StudentScore buildScore(
    String assignmentId, {
    String enrollmentId = 'enr-1',
    SubmissionStatus status = SubmissionStatus.submitted,
    double? score,
  }) {
    return StudentScore(
      id: 'score-$enrollmentId-$assignmentId',
      teacherId: 'teacher-1',
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      submissionStatus: status,
      score: score,
      updatedAt: now,
    );
  }

  group('ScoreCalculatorService', () {
    test('sums decimal scores accurately without floating-point drift', () {
      final assignments = <Assignment>[
        buildAssignment('a1', maxScore: 10),
        buildAssignment('a2', maxScore: 10),
        buildAssignment('a3', maxScore: 80),
      ];
      final scores = <StudentScore>[
        buildScore('a1', score: 7.1),
        buildScore('a2', score: 7.2),
        buildScore('a3', score: 65.45),
      ];

      final result = service.calculateStudentScores(
        enrollmentId: 'enr-1',
        categories: const <ScoreCategory>[],
        assignments: assignments,
        studentScores: scores,
      );

      expect(result.totalScore, 79.75);
      expect(result.totalMaxScore, 100.0);
      expect(result.percentage, 79.75);
      expect(result.missingAssignmentsCount, 0);
      expect(result.missingMandatoryCount, 0);
      expect(result.overMaxAssignmentIds, isEmpty);
    });

    test('never auto-rounds near-threshold total score such as 79.99', () {
      final assignments = <Assignment>[
        buildAssignment('a1', maxScore: 50),
        buildAssignment('a2', maxScore: 50),
      ];
      final scores = <StudentScore>[
        buildScore('a1', score: 40.50),
        buildScore('a2', score: 39.49),
      ];

      final result = service.calculateStudentScores(
        enrollmentId: 'enr-1',
        categories: const <ScoreCategory>[],
        assignments: assignments,
        studentScores: scores,
      );

      expect(result.totalScore, 79.99);
      expect(result.totalScore, isNot(80.0));
      expect(result.percentage, 79.99);
    });

    test('computes per-category totals and groups uncategorized items', () {
      final categories = <ScoreCategory>[
        buildCategory('cat-work', 'คะแนนเก็บ', targetMaxScore: 60),
        buildCategory('cat-exam', 'สอบปลายภาค', targetMaxScore: 40),
        buildCategory('cat-empty', 'จิตพิสัย', targetMaxScore: 10),
      ];
      final assignments = <Assignment>[
        buildAssignment('a1', categoryId: 'cat-work', maxScore: 30),
        buildAssignment('a2', categoryId: 'cat-work', maxScore: 30),
        buildAssignment('a3', categoryId: 'cat-exam', maxScore: 40),
        buildAssignment('a4', categoryId: null, maxScore: 5),
      ];
      final scores = <StudentScore>[
        buildScore('a1', score: 25.5),
        buildScore('a2', score: 24.25),
        buildScore('a3', score: 32.0),
        buildScore('a4', score: 4.5),
        // Score for another student must be ignored.
        buildScore('a1', enrollmentId: 'enr-other', score: 1.0),
      ];

      final result = service.calculateStudentScores(
        enrollmentId: 'enr-1',
        categories: categories,
        assignments: assignments,
        studentScores: scores,
      );

      expect(result.totalScore, 86.25);
      expect(result.totalMaxScore, 105.0);
      expect(result.categorySummaries.length, 4);

      final workSummary = result.categorySummaries[0];
      expect(workSummary.categoryId, 'cat-work');
      expect(workSummary.earnedScore, 49.75);
      expect(workSummary.maxScore, 60.0);
      expect(workSummary.targetMaxScore, 60.0);
      expect(workSummary.assignmentCount, 2);

      final examSummary = result.categorySummaries[1];
      expect(examSummary.categoryId, 'cat-exam');
      expect(examSummary.earnedScore, 32.0);
      expect(examSummary.maxScore, 40.0);
      expect(examSummary.assignmentCount, 1);

      final emptySummary = result.categorySummaries[2];
      expect(emptySummary.categoryId, 'cat-empty');
      expect(emptySummary.earnedScore, 0.0);
      expect(emptySummary.maxScore, 0.0);
      expect(emptySummary.assignmentCount, 0);

      final uncategorizedSummary = result.categorySummaries[3];
      expect(uncategorizedSummary.categoryId, isNull);
      expect(
        uncategorizedSummary.categoryName,
        ScoreCalculatorService.uncategorizedLabel,
      );
      expect(uncategorizedSummary.earnedScore, 4.5);
      expect(uncategorizedSummary.maxScore, 5.0);
      expect(uncategorizedSummary.assignmentCount, 1);
    });

    test('counts missing assignments, mandatory missing, and over-max IDs', () {
      final assignments = <Assignment>[
        buildAssignment('a1', maxScore: 10, isMandatory: true),
        buildAssignment('a2', maxScore: 10, isMandatory: true),
        buildAssignment('a3', maxScore: 10, isMandatory: false),
        buildAssignment('a4', maxScore: 10, isMandatory: false),
        buildAssignment('a5', maxScore: 10, isMandatory: false),
      ];
      final scores = <StudentScore>[
        // a1: over max score (bonus score allowed but flagged)
        buildScore('a1', status: SubmissionStatus.submitted, score: 11.5),
        // a2: explicitly missing mandatory
        buildScore('a2', status: SubmissionStatus.missing, score: null),
        // a3: late submission (NOT missing), exact max score (NOT over-max)
        buildScore('a3', status: SubmissionStatus.late, score: 10.0),
        // a4: no record at all -> counted as missing
        // a5: missing with score 0 -> still counted as missing
        buildScore('a5', status: SubmissionStatus.missing, score: 0.0),
      ];

      final result = service.calculateStudentScores(
        enrollmentId: 'enr-1',
        categories: const <ScoreCategory>[],
        assignments: assignments,
        studentScores: scores,
      );

      expect(result.totalScore, 21.5);
      expect(result.missingAssignmentsCount, 3);
      expect(result.missingMandatoryCount, 1);
      expect(result.overMaxAssignmentIds, <String>['a1']);
    });

    test('returns null percentage when totalMaxScore is zero', () {
      final result = service.calculateStudentScores(
        enrollmentId: 'enr-1',
        categories: const <ScoreCategory>[],
        assignments: const <Assignment>[],
        studentScores: const <StudentScore>[],
      );

      expect(result.totalScore, 0.0);
      expect(result.totalMaxScore, 0.0);
      expect(result.percentage, isNull);
    });

    test('formatExactScore preserves decimals without integer rounding', () {
      expect(service.formatExactScore(79.99), '79.99');
      expect(service.formatExactScore(79.75), '79.75');
      expect(service.formatExactScore(80.0), '80');
      expect(service.formatExactScore(7.50), '7.5');
      expect(service.formatExactScore(7.05), '7.05');
      expect(service.formatExactScore(0.0), '0');
      expect(service.formatExactScore(-2.25), '-2.25');
    });
  });
}
