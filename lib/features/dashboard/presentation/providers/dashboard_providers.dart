import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/services/dashboard_class_sorter_service.dart';

/// Quick filter chips shown above the dashboard class grid.
enum DashboardFilterMode { all, today, pinned }

/// Immutable filter state for the Teacher Dashboard class list.
class DashboardFilterState {
  const DashboardFilterState({
    this.mode = DashboardFilterMode.all,
    this.query = '',
  });

  final DashboardFilterMode mode;
  final String query;

  DashboardFilterState copyWith({DashboardFilterMode? mode, String? query}) {
    return DashboardFilterState(
      mode: mode ?? this.mode,
      query: query ?? this.query,
    );
  }
}

class DashboardFilterNotifier extends Notifier<DashboardFilterState> {
  @override
  DashboardFilterState build() => const DashboardFilterState();

  void setMode(DashboardFilterMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void clear() {
    state = const DashboardFilterState();
  }
}

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterNotifier, DashboardFilterState>(
      DashboardFilterNotifier.new,
    );

final dashboardClassSorterServiceProvider =
    Provider<DashboardClassSorterService>(
      (ref) => const DashboardClassSorterService(),
    );

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remote = EnvConfig.isSupabaseConfigured
      ? ref.watch(dashboardRemoteDataSourceProvider)
      : null;
  return DashboardRepositoryImpl(remoteDataSource: remote);
});

/// Loads and smartly sorts all classes for the effective selected term on today's date.
final dashboardOverviewProvider =
    FutureProvider.autoDispose<DashboardOverview?>((ref) async {
      final userId = ref.watch(
        authStateProvider.select((state) => state.userId),
      );
      if (userId == null) {
        return null;
      }

      final selectedTerm = ref.watch(effectiveSelectedTermProvider);
      if (selectedTerm == null) {
        return null;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final repository = ref.watch(dashboardRepositoryProvider);
      final sorter = ref.watch(dashboardClassSorterServiceProvider);

      final rawClasses = await repository.fetchDashboardClasses(
        termId: selectedTerm.id,
        referenceDate: today,
      );
      final sorted = sorter.sortClasses(
        rawClasses,
        todayIsoWeekday: today.weekday,
      );

      return DashboardOverview(
        termId: selectedTerm.id,
        referenceDate: today,
        classes: sorted,
      );
    });
