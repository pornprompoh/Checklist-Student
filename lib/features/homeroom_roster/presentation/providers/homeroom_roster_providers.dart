import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/datasources/ai_roster_remote_datasource.dart';
import '../../data/datasources/class_enrollment_remote_datasource.dart';
import '../../data/datasources/homeroom_roster_local_datasource.dart';
import '../../data/datasources/homeroom_roster_local_datasource_impl.dart';
import '../../data/datasources/homeroom_roster_remote_datasource.dart';
import '../../data/repositories/homeroom_roster_repository_impl.dart';
import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/entities/homeroom_student.dart';
import '../../domain/repositories/homeroom_roster_repository.dart';

final homeroomRosterLocalDataSourceProvider =
    Provider<HomeroomRosterLocalDataSource>((ref) {
      return HomeroomRosterLocalDataSourceImpl(
        ref.watch(localCacheStoreProvider),
      );
    });

/// Provides offline-first [HomeroomRosterRepository] backed by Supabase and
/// Drift read-through caching.
final homeroomRosterRepositoryProvider = Provider<HomeroomRosterRepository>((
  ref,
) {
  final isConfigured = EnvConfig.isSupabaseConfigured;
  return HomeroomRosterRepositoryImpl(
    homeroomRemote: isConfigured
        ? ref.watch(homeroomRosterRemoteDataSourceProvider)
        : null,
    enrollmentRemote: isConfigured
        ? ref.watch(classEnrollmentRemoteDataSourceProvider)
        : null,
    aiRosterRemote: isConfigured
        ? ref.watch(aiRosterRemoteDataSourceProvider)
        : null,
    localDataSource: ref.watch(homeroomRosterLocalDataSourceProvider),
    currentTeacherId: () => ref.read(authStateProvider).userId,
    isOnline: () => ref.read(connectivityStatusProvider).asData?.value ?? true,
  );
});

/// Loads all master [Homeroom] rosters belonging to [termId].
final homeroomsByTermProvider = FutureProvider.family<List<Homeroom>, String>((
  ref,
  termId,
) {
  return ref.watch(homeroomRosterRepositoryProvider).fetchHomerooms(termId);
});

/// Tracks the currently selected [Homeroom.id] in the Master Roster view.
class SelectedHomeroomIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? homeroomId) => state = homeroomId;
}

final selectedHomeroomIdProvider =
    NotifierProvider<SelectedHomeroomIdNotifier, String?>(
      SelectedHomeroomIdNotifier.new,
    );

/// Tracks the currently selected `SubjectClass.id` in the Class Enrollment view.
class SelectedSubjectClassIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? subjectClassId) => state = subjectClassId;
}

final selectedSubjectClassIdProvider =
    NotifierProvider<SelectedSubjectClassIdNotifier, String?>(
      SelectedSubjectClassIdNotifier.new,
    );

/// Loads all [HomeroomStudent] rows belonging to [homeroomId].
final homeroomStudentsProvider =
    FutureProvider.family<List<HomeroomStudent>, String>((ref, homeroomId) {
      return ref
          .watch(homeroomRosterRepositoryProvider)
          .fetchHomeroomStudents(homeroomId);
    });

/// Loads all [ClassEnrollment] rows belonging to [subjectClassId].
final classEnrollmentsProvider =
    FutureProvider.family<List<ClassEnrollment>, String>((ref, subjectClassId) {
      return ref
          .watch(homeroomRosterRepositoryProvider)
          .fetchClassEnrollments(subjectClassId);
    });
