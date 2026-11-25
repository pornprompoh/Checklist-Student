import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/datasources/academic_structure_local_datasource.dart';
import '../../data/datasources/academic_structure_local_datasource_impl.dart';
import '../../data/datasources/academic_structure_remote_datasource.dart';
import '../../data/repositories/academic_structure_repository_impl.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import '../../domain/entities/term.dart';
import '../../domain/repositories/academic_structure_repository.dart';
import '../../domain/services/active_term_resolver_service.dart';

final academicStructureLocalDataSourceProvider =
    Provider<AcademicStructureLocalDataSource>((ref) {
      return AcademicStructureLocalDataSourceImpl(
        ref.watch(localCacheStoreProvider),
      );
    });

/// Provides offline-first [AcademicStructureRepository] backed by Supabase
/// and Drift read-through caching.
final academicStructureRepositoryProvider =
    Provider<AcademicStructureRepository>((ref) {
      final remote = EnvConfig.isSupabaseConfigured
          ? ref.watch(academicStructureRemoteDataSourceProvider)
          : null;
      return AcademicStructureRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: ref.watch(academicStructureLocalDataSourceProvider),
        currentTeacherId: () => ref.read(authStateProvider).userId,
        isOnline: () =>
            ref.read(connectivityStatusProvider).asData?.value ?? true,
      );
    });

/// Loads all academic years for the signed-in teacher ordered by `year_be DESC`.
final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  final userId = ref.watch(authStateProvider.select((state) => state.userId));
  if (userId == null) {
    return const <AcademicYear>[];
  }
  return ref.watch(academicStructureRepositoryProvider).fetchAcademicYears();
});

/// Loads all terms across all academic years for the signed-in teacher.
final allTermsProvider = FutureProvider<List<Term>>((ref) async {
  final userId = ref.watch(authStateProvider.select((state) => state.userId));
  if (userId == null) {
    return const <Term>[];
  }
  return ref.watch(academicStructureRepositoryProvider).fetchTerms();
});

/// Resolves the teacher's active term (pinned -> date range -> recency fallback).
final activeTermProvider = Provider<Term?>((ref) {
  final terms = ref.watch(allTermsProvider).asData?.value;
  if (terms == null || terms.isEmpty) {
    return null;
  }
  final years =
      ref.watch(academicYearsProvider).asData?.value ?? const <AcademicYear>[];
  final yearBeById = <String, int>{for (final y in years) y.id: y.yearBe};
  return ActiveTermResolverService.resolveActiveTerm(
    terms,
    yearBeByAcademicYearId: yearBeById.isEmpty ? null : yearBeById,
  );
});

/// Stores the manually selected term ID (`null` means follow [activeTermProvider]).
class SelectedTermIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? termId) {
    state = termId;
  }
}

final selectedTermIdProvider =
    NotifierProvider<SelectedTermIdNotifier, String?>(
      SelectedTermIdNotifier.new,
    );

/// Returns the currently viewed [Term], falling back safely to [activeTermProvider]
/// when no manual override is set or the previously selected term was deleted.
final effectiveSelectedTermProvider = Provider<Term?>((ref) {
  final terms = ref.watch(allTermsProvider).asData?.value;
  if (terms == null || terms.isEmpty) {
    return null;
  }
  final selectedId = ref.watch(selectedTermIdProvider);
  if (selectedId != null) {
    for (final term in terms) {
      if (term.id == selectedId) {
        return term;
      }
    }
  }
  return ref.watch(activeTermProvider);
});

/// Loads all subjects belonging to [termId].
final subjectsByTermProvider = FutureProvider.family<List<Subject>, String>((
  ref,
  termId,
) async {
  return ref.watch(academicStructureRepositoryProvider).fetchSubjects(termId);
});

/// Loads all subject classes belonging to [termId] in a single query.
final subjectClassesByTermProvider =
    FutureProvider.family<List<SubjectClass>, String>((ref, termId) async {
      return ref
          .watch(academicStructureRepositoryProvider)
          .fetchSubjectClassesByTerm(termId);
    });
