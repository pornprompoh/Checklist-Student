import 'package:checklist_student/features/academic_structure/domain/entities/subject_class.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/unlinked_room_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnlinkedRoomSyncService', () {
    final now = DateTime(2026, 5, 16);

    SubjectClass makeClass({
      required String id,
      required String subjectId,
      required String roomName,
      String? homeroomId,
    }) {
      return SubjectClass(
        id: id,
        teacherId: 't-1',
        subjectId: subjectId,
        homeroomId: homeroomId,
        roomName: roomName,
        teachingDays: const <int>[1, 3],
        isPinned: false,
        showScoreToStudent: true,
        showGradeToStudent: false,
        absentThresholdPct: 20,
        missingWorkThreshold: 3,
        lateToAbsentRatio: null,
        countLeaveAsAbsent: false,
        attendanceScoreWeight: null,
        gradingScaleType: '0-4',
        gradingRules: const <GradingRuleTier>[],
        createdAt: now,
        updatedAt: now,
      );
    }

    Homeroom makeHomeroom({required String id, required String name}) {
      return Homeroom(
        id: id,
        teacherId: 't-1',
        termId: 'term-1',
        name: name,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('groups duplicate unlinked room names across subjects into one master room', () {
      final homerooms = <Homeroom>[
        makeHomeroom(id: 'hr-m42', name: 'ม.4/2'),
      ];
      final subjectClasses = <SubjectClass>[
        // Two subjects teaching unlinked ม.4/1 -> must merge into 1 group
        makeClass(id: 'sc-1', subjectId: 'sub-math', roomName: 'ม.4/1'),
        makeClass(id: 'sc-2', subjectId: 'sub-sci', roomName: '  ม.4/1  '),
        // Unlinked class whose homeroom name already exists -> attach existingHomeroomId
        makeClass(id: 'sc-3', subjectId: 'sub-eng', roomName: 'ม.4/2'),
        // Already linked class -> must be excluded
        makeClass(
          id: 'sc-4',
          subjectId: 'sub-math',
          roomName: 'ม.4/2',
          homeroomId: 'hr-m42',
        ),
      ];

      final groups = UnlinkedRoomSyncService.findUnlinkedRooms(
        homerooms: homerooms,
        subjectClasses: subjectClasses,
      );

      expect(groups, hasLength(2));

      expect(groups[0].roomName, 'ม.4/1');
      expect(groups[0].subjectClassIds, <String>['sc-1', 'sc-2']);
      expect(groups[0].classCount, 2);
      expect(groups[0].existingHomeroomId, isNull);

      expect(groups[1].roomName, 'ม.4/2');
      expect(groups[1].subjectClassIds, <String>['sc-3']);
      expect(groups[1].existingHomeroomId, 'hr-m42');
    });

    test('returns empty list when all subject classes are already linked', () {
      final groups = UnlinkedRoomSyncService.findUnlinkedRooms(
        homerooms: <Homeroom>[makeHomeroom(id: 'hr-1', name: 'ม.4/1')],
        subjectClasses: <SubjectClass>[
          makeClass(
            id: 'sc-1',
            subjectId: 'sub-1',
            roomName: 'ม.4/1',
            homeroomId: 'hr-1',
          ),
        ],
      );
      expect(groups, isEmpty);
    });
  });
}
