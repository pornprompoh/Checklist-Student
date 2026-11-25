import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/audit_log/domain/entities/audit_log_year_summary.dart';
import 'package:checklist_student/features/audit_log/domain/services/audit_log_cleanup_advisor_service.dart';

void main() {
  const service = AuditLogCleanupAdvisorService();
  final now = DateTime.utc(2026, 11, 25);

  group('AuditLogCleanupAdvisorService', () {
    test('returns no alerts for current academic year with recent logs', () {
      final summaries = <AuditLogYearSummary>[
        AuditLogYearSummary(
          academicYearId: 'y-2569',
          yearBe: 2569,
          totalLogsCount: 120,
          scoreLogsCount: 110,
          gradeStatusLogsCount: 10,
          oldestChangedAt: now.subtract(const Duration(days: 60)),
          newestChangedAt: now,
        ),
      ];

      final alerts = service.evaluateCleanupAlerts(
        summaries: summaries,
        currentActiveYearBe: 2569,
        now: now,
      );

      expect(alerts, isEmpty);
    });

    test('alerts for past academic year that still has logs', () {
      final summaries = <AuditLogYearSummary>[
        AuditLogYearSummary(
          academicYearId: 'y-2568',
          yearBe: 2568,
          totalLogsCount: 45,
          scoreLogsCount: 40,
          gradeStatusLogsCount: 5,
          oldestChangedAt: now.subtract(const Duration(days: 200)),
          newestChangedAt: now.subtract(const Duration(days: 150)),
        ),
        AuditLogYearSummary(
          academicYearId: 'y-2569',
          yearBe: 2569,
          totalLogsCount: 30,
          scoreLogsCount: 30,
          gradeStatusLogsCount: 0,
          oldestChangedAt: now.subtract(const Duration(days: 10)),
          newestChangedAt: now,
        ),
      ];

      final alerts = service.evaluateCleanupAlerts(
        summaries: summaries,
        currentActiveYearBe: 2569,
        now: now,
      );

      expect(alerts, hasLength(1));
      expect(alerts.single.summary.yearBe, 2568);
      expect(alerts.single.isPastAcademicYear, isTrue);
      expect(alerts.single.hasLogsNearExpiry, isFalse);
    });

    test('alerts when current year has logs >= 330 days old', () {
      final summaries = <AuditLogYearSummary>[
        AuditLogYearSummary(
          academicYearId: 'y-2569',
          yearBe: 2569,
          totalLogsCount: 80,
          scoreLogsCount: 80,
          gradeStatusLogsCount: 0,
          oldestChangedAt: now.subtract(const Duration(days: 330)),
          newestChangedAt: now,
        ),
      ];

      final alerts = service.evaluateCleanupAlerts(
        summaries: summaries,
        currentActiveYearBe: 2569,
        now: now,
      );

      expect(alerts, hasLength(1));
      expect(alerts.single.isPastAcademicYear, isFalse);
      expect(alerts.single.hasLogsNearExpiry, isTrue);
      expect(alerts.single.oldestLogAgeDays, 330);
    });

    test('ignores past academic year whose logs were already cleaned to 0', () {
      final summaries = <AuditLogYearSummary>[
        AuditLogYearSummary(
          academicYearId: 'y-2568',
          yearBe: 2568,
          totalLogsCount: 0,
          scoreLogsCount: 0,
          gradeStatusLogsCount: 0,
          oldestChangedAt: now.subtract(const Duration(days: 400)),
          newestChangedAt: now.subtract(const Duration(days: 380)),
        ),
      ];

      final alerts = service.evaluateCleanupAlerts(
        summaries: summaries,
        currentActiveYearBe: 2569,
        now: now,
      );

      expect(alerts, isEmpty);
    });
  });
}
