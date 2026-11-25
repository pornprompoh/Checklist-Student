import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../academic_structure/domain/entities/subject.dart';
import '../../../academic_structure/domain/entities/subject_class.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../../sync_queue/presentation/providers/sync_queue_providers.dart';
import '../../data/datasources/grading_local_datasource.dart';
import '../../data/datasources/grading_local_datasource_impl.dart';
import '../../data/datasources/grading_remote_datasource.dart';
import '../../data/repositories/grading_repository_impl.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_portal_visibility_config.dart';
import '../../domain/entities/student_score.dart';
import '../../domain/repositories/grading_repository.dart';
import '../../domain/services/grade_evaluator_service.dart';
import '../../domain/services/score_calculator_service.dart';
import '../../domain/services/special_grade_advisor_service.dart';

/// Selectable source class entry across all terms/years for [CopyPlanDialog].
class CopyPlanSourceClassOption {
  const CopyPlanSourceClassOption({
    required this.subjectClassId,
    required this.academicYearBe,
    required this.termId,
    required this.termLabel,
    required this.subjectCode,
    required this.subjectName,
    required this.roomName,
  });

  final String subjectClassId;
  final int academicYearBe;
  final String termId;
  final String termLabel;
  final String subjectCode;
  final String subjectName;
  final String roomName;

  String get termGroupLabel => 'ปีการศึกษา $academicYearBe · เทอม $termLabel';

  String get displayLabel => '$subjectCode $subjectName — ห้อง $roomName';
}

/// Preview counts shown in [CopyPlanDialog] before confirming a plan copy.
class CopyPlanSourcePreview {
  const CopyPlanSourcePreview({
    required this.categoryCount,
    required this.assignmentCount,
    required this.gradingScaleType,
  });

  final int categoryCount;
  final int assignmentCount;
  final GradingScaleType gradingScaleType;
}

final gradingLocalDataSourceProvider = Provider<GradingLocalDataSource>((ref) {
  return GradingLocalDataSourceImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(localCacheStoreProvider),
  );
});

final gradingRepositoryProvider = Provider<GradingRepository>((ref) {
  final remote = EnvConfig.isSupabaseConfigured
      ? ref.watch(gradingRemoteDataSourceProvider)
      : null;
  return GradingRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: ref.watch(gradingLocalDataSourceProvider),
    homeroomRosterLocalDataSource: ref.watch(
      homeroomRosterLocalDataSourceProvider,
    ),
    syncQueueRepository: ref.watch(syncQueueRepositoryProvider),
    currentTeacherId: () => ref.read(authStateProvider).userId,
    isOnline: () => ref.read(connectivityStatusProvider).asData?.value ?? true,
  );
});

final scoreCalculatorServiceProvider = Provider<ScoreCalculatorService>((ref) {
  return const ScoreCalculatorService();
});

final gradeEvaluatorServiceProvider = Provider<GradeEvaluatorService>((ref) {
  return const GradeEvaluatorService();
});

final specialGradeAdvisorServiceProvider = Provider<SpecialGradeAdvisorService>(
  (ref) => const SpecialGradeAdvisorService(),
);

final scoreCategoriesProvider =
    FutureProvider.family<List<ScoreCategory>, String>((ref, classId) async {
      if (classId.trim().isEmpty) {
        return const <ScoreCategory>[];
      }
      return ref.watch(gradingRepositoryProvider).fetchScoreCategories(classId);
    });

final assignmentsProvider = FutureProvider.family<List<Assignment>, String>((
  ref,
  classId,
) async {
  if (classId.trim().isEmpty) {
    return const <Assignment>[];
  }
  return ref.watch(gradingRepositoryProvider).fetchAssignments(classId);
});

final studentScoresByClassProvider =
    FutureProvider.family<List<StudentScore>, String>((ref, classId) async {
      if (classId.trim().isEmpty) {
        return const <StudentScore>[];
      }
      return ref
          .watch(gradingRepositoryProvider)
          .fetchStudentScoresByClass(classId);
    });

final gradingScaleConfigProvider =
    FutureProvider.family<GradingScaleConfig, String>((ref, classId) async {
      return ref
          .watch(gradingRepositoryProvider)
          .fetchGradingScaleConfig(classId);
    });

final studentPortalVisibilityProvider =
    FutureProvider.family<StudentPortalVisibilityConfig, String>((
      ref,
      classId,
    ) async {
      return ref
          .watch(gradingRepositoryProvider)
          .fetchStudentPortalVisibility(classId);
    });

/// Counts how many students have `score > assignment.maxScore` per assignment.
final overMaxScoreCountsByAssignmentProvider =
    Provider.family<Map<String, int>, String>((ref, classId) {
      final assignments =
          ref.watch(assignmentsProvider(classId)).asData?.value ??
          const <Assignment>[];
      final scores =
          ref.watch(studentScoresByClassProvider(classId)).asData?.value ??
          const <StudentScore>[];
      if (assignments.isEmpty || scores.isEmpty) {
        return const <String, int>{};
      }
      final maxCentsByAssignment = <String, int>{
        for (final item in assignments) item.id: (item.maxScore * 100).round(),
      };
      final counts = <String, int>{};
      for (final score in scores) {
        final rawScore = score.score;
        final maxCents = maxCentsByAssignment[score.assignmentId];
        if (rawScore != null &&
            maxCents != null &&
            (rawScore * 100).round() > maxCents) {
          counts[score.assignmentId] = (counts[score.assignmentId] ?? 0) + 1;
        }
      }
      return Map<String, int>.unmodifiable(counts);
    });

/// Loads all classes across all terms and academic years for [CopyPlanDialog].
final allCopyableClassesProvider =
    FutureProvider<List<CopyPlanSourceClassOption>>((ref) async {
      final userId = ref.watch(authStateProvider.select((s) => s.userId));
      if (userId == null) {
        return const <CopyPlanSourceClassOption>[];
      }
      final structureRepo = ref.watch(academicStructureRepositoryProvider);
      final years = await ref.watch(academicYearsProvider.future);
      final terms = await ref.watch(allTermsProvider.future);
      if (terms.isEmpty) {
        return const <CopyPlanSourceClassOption>[];
      }

      final yearBeById = <String, int>{
        for (final year in years) year.id: year.yearBe,
      };
      final perTermResults = await Future.wait(
        terms.map((term) async {
          final pair = await Future.wait<dynamic>(<Future<dynamic>>[
            structureRepo.fetchSubjects(term.id),
            structureRepo.fetchSubjectClassesByTerm(term.id),
          ]);
          return (
            term: term,
            subjects: pair[0] as List<Subject>,
            classes: pair[1] as List<SubjectClass>,
          );
        }),
      );

      final options = <CopyPlanSourceClassOption>[];
      for (final entry in perTermResults) {
        final yearBe = yearBeById[entry.term.academicYearId] ?? 0;
        final subjectById = <String, Subject>{
          for (final subject in entry.subjects) subject.id: subject,
        };
        for (final item in entry.classes) {
          final subject = subjectById[item.subjectId];
          options.add(
            CopyPlanSourceClassOption(
              subjectClassId: item.id,
              academicYearBe: yearBe,
              termId: entry.term.id,
              termLabel: entry.term.termLabel,
              subjectCode: subject?.subjectCode ?? '-',
              subjectName: subject?.subjectName ?? 'รายวิชา',
              roomName: item.roomName,
            ),
          );
        }
      }

      options.sort((a, b) {
        final yearCmp = b.academicYearBe.compareTo(a.academicYearBe);
        if (yearCmp != 0) return yearCmp;
        final termCmp = b.termLabel.compareTo(a.termLabel);
        if (termCmp != 0) return termCmp;
        final codeCmp = a.subjectCode.compareTo(b.subjectCode);
        if (codeCmp != 0) return codeCmp;
        return a.roomName.compareTo(b.roomName);
      });
      return List<CopyPlanSourceClassOption>.unmodifiable(options);
    });

/// Lightweight summary of a selected source class inside [CopyPlanDialog].
final classPlanSummaryProvider =
    FutureProvider.family<CopyPlanSourcePreview, String>((ref, classId) async {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        ref.watch(scoreCategoriesProvider(classId).future),
        ref.watch(assignmentsProvider(classId).future),
        ref.watch(gradingScaleConfigProvider(classId).future),
      ]);
      final categories = results[0] as List<ScoreCategory>;
      final assignments = results[1] as List<Assignment>;
      final config = results[2] as GradingScaleConfig;
      return CopyPlanSourcePreview(
        categoryCount: categories.length,
        assignmentCount: assignments.length,
        gradingScaleType: config.scaleType,
      );
    });
