import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_rule_config.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_session.dart';
import 'package:checklist_student/features/attendance/domain/entities/student_attendance_summary.dart';
import 'package:checklist_student/features/attendance/domain/services/attendance_statistics_service.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AttendanceStatisticsService();
  final baseDate = DateTime(2026, 5, 18);

  List<AttendanceSession> makeSessions(int count) {
    return List<AttendanceSession>.generate(count, (i) {
      final date = baseDate.add(Duration(days: i));
      return AttendanceSession(
        id: 'sess-${i + 1}',
        teacherId: 't-1',
        subjectClassId: 'sc-1',
        sessionDate: date,
        isLocked: false,
        note: '',
        version: 1,
        createdAt: date,
        updatedAt: date,
      );
    });
  }

  AttendanceRecord makeRecord({
    required String sessionId,
    required AttendanceStatus status,
    String enrollmentId = 'enr-1',
  }) {
    return AttendanceRecord(
      id: 'rec-$sessionId-$enrollmentId',
      teacherId: 't-1',
      sessionId: sessionId,
      enrollmentId: enrollmentId,
      status: status,
      note: '',
      version: 1,
      updatedAt: baseDate,
    );
  }

  const defaultRule = AttendanceRuleConfig(
    subjectClassId: 'sc-1',
    absentThresholdPct: 20.0,
    lateToAbsentRatio: null,
    countLeaveAsAbsent: false,
  );

  group('AttendanceStatisticsService', () {
    test(
      '1. default rule ignores late & leave: 10 late + 5 leave + 0 absent => 0% normal',
      () {
        final sessions = makeSessions(15);
        final records = <AttendanceRecord>[
          for (var i = 0; i < 10; i++)
            makeRecord(sessionId: sessions[i].id, status: AttendanceStatus.late),
          for (var i = 10; i < 15; i++)
            makeRecord(
              sessionId: sessions[i].id,
              status: AttendanceStatus.leave,
            ),
        ];

        final summary = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          sessions: sessions,
          records: records,
          ruleConfig: defaultRule,
        );

        expect(summary.totalEligibleSessions, 15);
        expect(summary.recordedSessions, 15);
        expect(summary.lateCount, 10);
        expect(summary.leaveCount, 5);
        expect(summary.absentCount, 0);
        expect(summary.convertedLateAbsentCount, 0);
        expect(summary.countedLeaveAbsentCount, 0);
        expect(summary.effectiveAbsentCount, 0);
        expect(summary.absentPercentage, 0.0);
        expect(summary.riskLevel, AttendanceRiskLevel.normal);
        expect(summary.isAtRiskOrExceededMs, isFalse);
      },
    );

    test(
      '2. exact 20.0% boundary is approachingMs while strictly > 20.0% is exceededMs',
      () {
        final sessions10 = makeSessions(10);
        final twoAbsents = <AttendanceRecord>[
          makeRecord(sessionId: sessions10[0].id, status: AttendanceStatus.absent),
          makeRecord(sessionId: sessions10[1].id, status: AttendanceStatus.absent),
          for (var i = 2; i < 10; i++)
            makeRecord(
              sessionId: sessions10[i].id,
              status: AttendanceStatus.present,
            ),
        ];

        final atBoundary = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          sessions: sessions10,
          records: twoAbsents,
          ruleConfig: defaultRule,
        );
        expect(atBoundary.absentPercentage, 20.0);
        expect(atBoundary.riskLevel, AttendanceRiskLevel.approachingMs);
        expect(atBoundary.exceedsMsThreshold, isFalse);

        final threeAbsents = <AttendanceRecord>[
          for (var i = 0; i < 3; i++)
            makeRecord(
              sessionId: sessions10[i].id,
              status: AttendanceStatus.absent,
            ),
          for (var i = 3; i < 10; i++)
            makeRecord(
              sessionId: sessions10[i].id,
              status: AttendanceStatus.present,
            ),
        ];
        final exceeded30 = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          sessions: sessions10,
          records: threeAbsents,
          ruleConfig: defaultRule,
        );
        expect(exceeded30.absentPercentage, 30.0);
        expect(exceeded30.riskLevel, AttendanceRiskLevel.exceededMs);
        expect(exceeded30.exceedsMsThreshold, isTrue);

        // 21 / 100 = 21.0% -> exceededMs
        final sessions100 = makeSessions(100);
        final absents21 = <AttendanceRecord>[
          for (var i = 0; i < 21; i++)
            makeRecord(
              sessionId: sessions100[i].id,
              status: AttendanceStatus.absent,
            ),
        ];
        final exceeded21 = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          sessions: sessions100,
          records: absents21,
          ruleConfig: defaultRule,
        );
        expect(exceeded21.absentPercentage, 21.0);
        expect(exceeded21.riskLevel, AttendanceRiskLevel.exceededMs);
      },
    );

    test(
      '3. approachingMs triggers at >= 75% of threshold (15% of 20%) and stays normal below',
      () {
        final sessions20 = makeSessions(20);
        final threeOf20 = <AttendanceRecord>[
          for (var i = 0; i < 3; i++)
            makeRecord(
              sessionId: sessions20[i].id,
              status: AttendanceStatus.absent,
            ),
        ];
        final approaching = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          sessions: sessions20,
          records: threeOf20,
          ruleConfig: defaultRule,
        );
        expect(approaching.absentPercentage, 15.0);
        expect(approaching.riskLevel, AttendanceRiskLevel.approachingMs);

        final twoOf20 = <AttendanceRecord>[
          for (var i = 0; i < 2; i++)
            makeRecord(
              sessionId: sessions20[i].id,
              status: AttendanceStatus.absent,
            ),
        ];
        final normal = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          sessions: sessions20,
          records: twoOf20,
          ruleConfig: defaultRule,
        );
        expect(normal.absentPercentage, 10.0);
        expect(normal.riskLevel, AttendanceRiskLevel.normal);
      },
    );

    test(
      '4. lateToAbsentRatio = 3 floors conversions: 2->0, 3->1, 7->2',
      () {
        const lateRule = AttendanceRuleConfig(
          subjectClassId: 'sc-1',
          absentThresholdPct: 20.0,
          lateToAbsentRatio: 3,
          countLeaveAsAbsent: false,
        );
        final sessions = makeSessions(10);

        StudentAttendanceSummary runWithLates(int lates) {
          final records = <AttendanceRecord>[
            for (var i = 0; i < lates; i++)
              makeRecord(
                sessionId: sessions[i].id,
                status: AttendanceStatus.late,
              ),
          ];
          return service.calculateStudentSummary(
            enrollmentId: 'enr-1',
            enrolledAt: baseDate,
            sessions: sessions,
            records: records,
            ruleConfig: lateRule,
          );
        }

        expect(runWithLates(2).convertedLateAbsentCount, 0);
        expect(runWithLates(2).effectiveAbsentCount, 0);

        expect(runWithLates(3).convertedLateAbsentCount, 1);
        expect(runWithLates(3).effectiveAbsentCount, 1);
        expect(runWithLates(3).absentPercentage, 10.0);

        expect(runWithLates(7).convertedLateAbsentCount, 2);
        expect(runWithLates(7).effectiveAbsentCount, 2);
        expect(runWithLates(7).absentPercentage, 20.0);
      },
    );

    test(
      '5. countLeaveAsAbsent = true adds leaveCount to effectiveAbsentCount',
      () {
        const leaveRule = AttendanceRuleConfig(
          subjectClassId: 'sc-1',
          absentThresholdPct: 20.0,
          lateToAbsentRatio: null,
          countLeaveAsAbsent: true,
        );
        final sessions = makeSessions(10);
        final records = <AttendanceRecord>[
          makeRecord(sessionId: sessions[0].id, status: AttendanceStatus.absent),
          makeRecord(sessionId: sessions[1].id, status: AttendanceStatus.leave),
          makeRecord(sessionId: sessions[2].id, status: AttendanceStatus.leave),
        ];

        final summary = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          sessions: sessions,
          records: records,
          ruleConfig: leaveRule,
        );
        expect(summary.countedLeaveAbsentCount, 2);
        expect(summary.effectiveAbsentCount, 3);
        expect(summary.absentPercentage, 30.0);
        expect(summary.riskLevel, AttendanceRiskLevel.exceededMs);
      },
    );

    test(
      '6. mid-term enrollment excludes sessions before enrolledAt from denominator & absences',
      () {
        final sessions = makeSessions(10);
        // Student enrolled on day 6 (sessions[5]..sessions[9] = 5 eligible sessions)
        final midTermDate = baseDate.add(const Duration(days: 5));
        final records = <AttendanceRecord>[
          // Even if an old stray absent record existed before enrolledAt, ignore it.
          makeRecord(sessionId: sessions[0].id, status: AttendanceStatus.absent),
          makeRecord(sessionId: sessions[5].id, status: AttendanceStatus.absent),
          makeRecord(
            sessionId: sessions[6].id,
            status: AttendanceStatus.present,
          ),
        ];

        final summary = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: DateTime(
            midTermDate.year,
            midTermDate.month,
            midTermDate.day,
            14,
            30,
          ),
          sessions: sessions,
          records: records,
          ruleConfig: defaultRule,
        );

        expect(summary.totalEligibleSessions, 5);
        expect(summary.absentCount, 1);
        expect(summary.absentPercentage, 20.0);
        expect(summary.riskLevel, AttendanceRiskLevel.approachingMs);
      },
    );

    test(
      '7. transferredOutAt excludes sessions on or after exit date (sessionDate >= transferredOutAt)',
      () {
        final sessions = makeSessions(10);
        // Transferred out on day 4 (sessions[3]): eligible are strictly before -> sessions[0..2] (3 sessions)
        final outDate = baseDate.add(const Duration(days: 3));
        final records = <AttendanceRecord>[
          makeRecord(
            sessionId: sessions[0].id,
            status: AttendanceStatus.present,
          ),
          // Session on exact exit date must be excluded.
          makeRecord(sessionId: sessions[3].id, status: AttendanceStatus.absent),
          makeRecord(sessionId: sessions[8].id, status: AttendanceStatus.absent),
        ];

        final summary = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          transferredOutAt: outDate,
          status: StudentLifecycleStatus.transferredOut,
          sessions: sessions,
          records: records,
          ruleConfig: defaultRule,
        );

        expect(summary.totalEligibleSessions, 3);
        expect(summary.absentCount, 0);
        expect(summary.absentPercentage, 0.0);
        expect(summary.riskLevel, AttendanceRiskLevel.normal);

        // Transferred out with null date has 0 eligible sessions.
        final noDateSummary = service.calculateStudentSummary(
          enrollmentId: 'enr-1',
          enrolledAt: baseDate,
          transferredOutAt: null,
          status: StudentLifecycleStatus.transferredOut,
          sessions: sessions,
          records: records,
          ruleConfig: defaultRule,
        );
        expect(noDateSummary.totalEligibleSessions, 0);
        expect(noDateSummary.riskLevel, AttendanceRiskLevel.normal);
      },
    );

    test(
      'isEligibleForDate returns false for transferredOut on both past and future dates',
      () {
        final transferred = ClassEnrollment(
          id: 'enr-out',
          teacherId: 't-1',
          subjectClassId: 'sc-1',
          homeroomStudentId: null,
          studentIdentityId: 'sid-out',
          studentCode: '65001',
          studentNumber: 1,
          prefix: 'ด.ช.',
          firstName: 'สมชาย',
          lastName: 'ใจดี',
          status: StudentLifecycleStatus.transferredOut,
          enrolledAt: baseDate,
          transferredOutAt: baseDate.add(const Duration(days: 5)),
          specialGradeOverride: null,
          wasRResolved: false,
          wasMsResolved: false,
          resolvedGradeAt: null,
          version: 1,
          createdAt: baseDate,
          updatedAt: baseDate,
        );

        expect(
          service.isEligibleForDate(
            enrollment: transferred,
            sessionDate: baseDate.add(const Duration(days: 1)),
          ),
          isFalse,
        );
        expect(
          service.isEligibleForDate(
            enrollment: transferred,
            sessionDate: baseDate.add(const Duration(days: 10)),
          ),
          isFalse,
        );
      },
    );

    test('8. zero eligible sessions safely avoids division by zero', () {
      final summary = service.calculateStudentSummary(
        enrollmentId: 'enr-1',
        enrolledAt: baseDate,
        sessions: const <AttendanceSession>[],
        records: const <AttendanceRecord>[],
        ruleConfig: defaultRule,
      );

      expect(summary.totalEligibleSessions, 0);
      expect(summary.absentPercentage, 0.0);
      expect(summary.riskLevel, AttendanceRiskLevel.normal);
    });

    test('calculateClassSummaries and countByStatus aggregate batch data cleanly', () {
      final sessions = makeSessions(4);
      final enrollments = <ClassEnrollment>[
        ClassEnrollment(
          id: 'enr-1',
          teacherId: 't-1',
          subjectClassId: 'sc-1',
          homeroomStudentId: null,
          studentIdentityId: 'sid-1',
          studentCode: '65001',
          studentNumber: 1,
          prefix: 'ด.ช.',
          firstName: 'สมชาย',
          lastName: 'ใจดี',
          status: StudentLifecycleStatus.active,
          enrolledAt: baseDate,
          transferredOutAt: null,
          specialGradeOverride: null,
          wasRResolved: false,
          wasMsResolved: false,
          resolvedGradeAt: null,
          version: 1,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
        ClassEnrollment(
          id: 'enr-2',
          teacherId: 't-1',
          subjectClassId: 'sc-1',
          homeroomStudentId: null,
          studentIdentityId: 'sid-2',
          studentCode: '65002',
          studentNumber: 2,
          prefix: 'ด.ญ.',
          firstName: 'สมหญิง',
          lastName: 'รักเรียน',
          status: StudentLifecycleStatus.active,
          enrolledAt: baseDate,
          transferredOutAt: null,
          specialGradeOverride: null,
          wasRResolved: false,
          wasMsResolved: false,
          resolvedGradeAt: null,
          version: 1,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      ];
      final records = <AttendanceRecord>[
        makeRecord(
          sessionId: sessions[0].id,
          enrollmentId: 'enr-1',
          status: AttendanceStatus.absent,
        ),
        makeRecord(
          sessionId: sessions[0].id,
          enrollmentId: 'enr-2',
          status: AttendanceStatus.present,
        ),
      ];

      final map = service.calculateClassSummaries(
        enrollments: enrollments,
        sessions: sessions,
        records: records,
        ruleConfig: defaultRule,
      );
      expect(map['enr-1']?.absentPercentage, 25.0);
      expect(map['enr-1']?.riskLevel, AttendanceRiskLevel.exceededMs);
      expect(map['enr-2']?.absentPercentage, 0.0);
      expect(map['enr-2']?.riskLevel, AttendanceRiskLevel.normal);

      final counts = service.countByStatus(records);
      expect(counts[AttendanceStatus.absent], 1);
      expect(counts[AttendanceStatus.present], 1);
      expect(counts[AttendanceStatus.late], 0);
      expect(counts[AttendanceStatus.leave], 0);
    });

    test('AttendanceRuleConfig.validate rejects invalid thresholds and ratios', () {
      expect(defaultRule.isValid, isTrue);
      expect(
        defaultRule.copyWith(absentThresholdPct: 0).validate(),
        isNotNull,
      );
      expect(
        defaultRule.copyWith(absentThresholdPct: 105).validate(),
        isNotNull,
      );
      expect(
        defaultRule.copyWith(lateToAbsentRatio: 0).validate(),
        isNotNull,
      );
    });
  });
}
