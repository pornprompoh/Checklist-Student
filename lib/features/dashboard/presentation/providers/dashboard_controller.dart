import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import 'dashboard_providers.dart';

/// Controller handling Teacher Dashboard actions (`togglePin` and `refresh`)
/// and keeping both Dashboard and Academic Structure caches synchronized.
class DashboardController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> togglePin({
    required String termId,
    required String subjectClassId,
    required bool isPinned,
  }) async {
    state = const AsyncLoading<void>();
    try {
      await ref
          .read(dashboardRepositoryProvider)
          .toggleClassPin(subjectClassId: subjectClassId, isPinned: isPinned);
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(subjectClassesByTermProvider(termId));
      if (ref.mounted) {
        state = const AsyncData<void>(null);
      }
      return true;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(
          ThaiErrorMapper.toAppException(error),
          stackTrace,
        );
      }
      return false;
    }
  }

  void refresh() {
    ref.invalidate(academicYearsProvider);
    ref.invalidate(allTermsProvider);
    ref.invalidate(dashboardOverviewProvider);
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, void>(DashboardController.new);
