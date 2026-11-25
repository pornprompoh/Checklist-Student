import 'package:checklist_student/features/dashboard/domain/entities/dashboard_class_item.dart';
import 'package:checklist_student/features/dashboard/domain/entities/today_attendance_summary.dart';
import 'package:checklist_student/features/dashboard/domain/services/dashboard_class_sorter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sorter = DashboardClassSorterService();

  DashboardClassItem makeItem({
    required String id,
    required String subjectCode,
    required String subjectName,
    required String roomName,
    required List<int> teachingDays,
    required bool isPinned,
    TodayAttendanceSummary? todayAttendance,
  }) {
    return DashboardClassItem(
      subjectClassId: id,
      subjectId: 'sub-$subjectCode',
      subjectCode: subjectCode,
      subjectName: subjectName,
      roomName: roomName,
      teachingDays: teachingDays,
      isPinned: isPinned,
      activeStudentCount: 30,
      todayAttendance: todayAttendance,
    );
  }

  group('DashboardClassSorterService', () {
    test(
      'sorts into 4 priority buckets with deterministic subjectCode + roomName tie-breakers',
      () {
        // Tuesday (ISO weekday 2)
        const tuesday = 2;

        final items = <DashboardClassItem>[
          makeItem(
            id: 'other-b',
            subjectCode: 'ว31102',
            subjectName: 'วิทยาศาสตร์',
            roomName: 'ม.4/2',
            teachingDays: const <int>[4],
            isPinned: false,
          ),
          makeItem(
            id: 'pinned-only',
            subjectCode: 'ค31101',
            subjectName: 'คณิตศาสตร์',
            roomName: 'ม.4/3',
            teachingDays: const <int>[1, 3],
            isPinned: true,
          ),
          makeItem(
            id: 'today-only-b',
            subjectCode: 'ค31101',
            subjectName: 'คณิตศาสตร์',
            roomName: 'ม.4/2',
            teachingDays: const <int>[2, 4],
            isPinned: false,
          ),
          makeItem(
            id: 'today-pinned-b',
            subjectCode: 'ว31101',
            subjectName: 'ฟิสิกส์',
            roomName: 'ม.4/1',
            teachingDays: const <int>[2],
            isPinned: true,
          ),
          makeItem(
            id: 'today-pinned-a',
            subjectCode: 'ค31101',
            subjectName: 'คณิตศาสตร์',
            roomName: 'ม.4/1',
            teachingDays: const <int>[2, 5],
            isPinned: true,
          ),
          makeItem(
            id: 'today-only-a',
            subjectCode: 'ค31101',
            subjectName: 'คณิตศาสตร์',
            roomName: 'ม.4/1',
            teachingDays: const <int>[2],
            isPinned: false,
          ),
          makeItem(
            id: 'other-a',
            subjectCode: 'ท31101',
            subjectName: 'ภาษาไทย',
            roomName: 'ม.4/1',
            teachingDays: const <int>[5],
            isPinned: false,
          ),
        ];

        final sorted = sorter.sortClasses(items, todayIsoWeekday: tuesday);

        expect(
          sorted.map((e) => e.subjectClassId).toList(),
          <String>[
            // Bucket 0: teachesToday && isPinned (sorted by subjectCode ASC)
            'today-pinned-a',
            'today-pinned-b',
            // Bucket 1: teachesToday && !isPinned (sorted by roomName ASC)
            'today-only-a',
            'today-only-b',
            // Bucket 2: !teachesToday && isPinned
            'pinned-only',
            // Bucket 3: !teachesToday && !isPinned (sorted by subjectCode ASC)
            'other-a',
            'other-b',
          ],
        );
      },
    );

    test('filters by onlyToday, onlyPinned, and case-insensitive search query', () {
      const wednesday = 3;
      final items = <DashboardClassItem>[
        makeItem(
          id: 'c1',
          subjectCode: 'MA301',
          subjectName: 'คณิตศาสตร์เพิ่มเติม',
          roomName: 'ม.4/1',
          teachingDays: const <int>[1, 3],
          isPinned: true,
        ),
        makeItem(
          id: 'c2',
          subjectCode: 'SC301',
          subjectName: 'เคมีพื้นฐาน',
          roomName: 'ม.4/2',
          teachingDays: const <int>[3, 5],
          isPinned: false,
        ),
        makeItem(
          id: 'c3',
          subjectCode: 'EN301',
          subjectName: 'ภาษาอังกฤษ',
          roomName: 'ม.5/1',
          teachingDays: const <int>[2, 4],
          isPinned: true,
        ),
      ];

      final todayOnly = sorter.filterClasses(
        items,
        todayIsoWeekday: wednesday,
        onlyToday: true,
        onlyPinned: false,
      );
      expect(todayOnly.map((e) => e.subjectClassId), <String>['c1', 'c2']);

      final pinnedOnly = sorter.filterClasses(
        items,
        todayIsoWeekday: wednesday,
        onlyToday: false,
        onlyPinned: true,
      );
      expect(pinnedOnly.map((e) => e.subjectClassId), <String>['c1', 'c3']);

      final bySubjectCode = sorter.filterClasses(
        items,
        todayIsoWeekday: wednesday,
        onlyToday: false,
        onlyPinned: false,
        query: 'sc301',
      );
      expect(bySubjectCode.map((e) => e.subjectClassId), <String>['c2']);

      final byRoomName = sorter.filterClasses(
        items,
        todayIsoWeekday: wednesday,
        onlyToday: false,
        onlyPinned: false,
        query: 'ม.5/1',
      );
      expect(byRoomName.map((e) => e.subjectClassId), <String>['c3']);

      final byThaiName = sorter.filterClasses(
        items,
        todayIsoWeekday: wednesday,
        onlyToday: false,
        onlyPinned: false,
        query: 'คณิต',
      );
      expect(byThaiName.map((e) => e.subjectClassId), <String>['c1']);
    });
  });
}
