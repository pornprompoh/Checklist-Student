import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom_student.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/roster_renumber_service.dart';
import 'package:flutter_test/flutter_test.dart';

HomeroomStudent _buildHomeroomStudent({
  required String id,
  required int number,
  required String code,
  StudentLifecycleStatus status = StudentLifecycleStatus.active,
}) {
  final ts = DateTime(2026, 5, 16);
  return HomeroomStudent(
    id: id,
    teacherId: 'teacher-1',
    homeroomId: 'hr-1',
    studentIdentityId: 'ident-$code',
    studentCode: code,
    studentNumber: number,
    prefix: 'ด.ช.',
    firstName: 'ชื่อ$code',
    lastName: 'สกุล',
    status: status,
    transferredOutAt: status == StudentLifecycleStatus.transferredOut
        ? DateTime(2026, 7, 1)
        : null,
    createdAt: ts,
    updatedAt: ts,
  );
}

ClassEnrollment _buildEnrollment({
  required String id,
  required int number,
  required String code,
  StudentLifecycleStatus status = StudentLifecycleStatus.active,
}) {
  final ts = DateTime(2026, 5, 16);
  return ClassEnrollment(
    id: id,
    teacherId: 'teacher-1',
    subjectClassId: 'sc-1',
    homeroomStudentId: 'hs-$id',
    studentIdentityId: 'ident-$code',
    studentCode: code,
    studentNumber: number,
    prefix: 'ด.ญ.',
    firstName: 'ชื่อ$code',
    lastName: 'สกุล',
    status: status,
    enrolledAt: ts,
    transferredOutAt: status == StudentLifecycleStatus.transferredOut
        ? DateTime(2026, 7, 1)
        : null,
    specialGradeOverride: null,
    wasRResolved: false,
    wasMsResolved: false,
    resolvedGradeAt: null,
    version: 1,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('RosterRenumberService', () {
    test('returns empty list when all active students are already 1..N', () {
      final students = <HomeroomStudent>[
        _buildHomeroomStudent(id: 's1', number: 1, code: '65001'),
        _buildHomeroomStudent(id: 's2', number: 2, code: '65002'),
        _buildHomeroomStudent(id: 's3', number: 3, code: '65003'),
      ];

      expect(
        RosterRenumberService.computeHomeroomRenumber(students),
        isEmpty,
      );
    });

    test(
      'renumbers only active students (1, 3, 4 -> 1, 2, 3) and leaves transferred_out #2 untouched',
      () {
        final students = <HomeroomStudent>[
          _buildHomeroomStudent(id: 's1', number: 1, code: '65001'),
          _buildHomeroomStudent(
            id: 's2',
            number: 2,
            code: '65002',
            status: StudentLifecycleStatus.transferredOut,
          ),
          _buildHomeroomStudent(id: 's3', number: 3, code: '65003'),
          _buildHomeroomStudent(id: 's4', number: 4, code: '65004'),
        ];

        final changes = RosterRenumberService.computeHomeroomRenumber(students);

        expect(changes.length, 2);
        expect(changes.any((c) => c.recordId == 's2'), isFalse);
        expect(changes[0].recordId, 's3');
        expect(changes[0].oldNumber, 3);
        expect(changes[0].newNumber, 2);
        expect(changes[1].recordId, 's4');
        expect(changes[1].oldNumber, 4);
        expect(changes[1].newNumber, 3);
      },
    );

    test(
      'resolves duplicate and gapped numbers deterministically by studentNumber ASC, studentCode ASC',
      () {
        final enrollments = <ClassEnrollment>[
          _buildEnrollment(id: 'eB', number: 5, code: '65010'),
          _buildEnrollment(id: 'eA', number: 5, code: '65002'),
          _buildEnrollment(id: 'eC', number: 10, code: '65020'),
          _buildEnrollment(
            id: 'eOut',
            number: 1,
            code: '65001',
            status: StudentLifecycleStatus.transferredOut,
          ),
        ];

        final changes = RosterRenumberService.computeClassEnrollmentRenumber(
          enrollments,
        );

        expect(changes.length, 3);
        expect(changes.map((c) => c.recordId).toList(), <String>['eA', 'eB', 'eC']);
        expect(changes.map((c) => c.newNumber).toList(), <int>[1, 2, 3]);
      },
    );

    test('computes nextStudentNumber for empty lists and lists with gaps', () {
      expect(RosterRenumberService.nextStudentNumber(const <int>[]), 1);
      expect(RosterRenumberService.nextStudentNumber(<int>[1, 2, 3]), 4);
      expect(RosterRenumberService.nextStudentNumber(<int>[1, 5, 3]), 6);
    });
  });
}
