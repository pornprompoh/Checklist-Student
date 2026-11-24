import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/attendance_rule_config.dart';
import 'attendance_providers.dart';

/// Controller managing persistence of per-subject-class [AttendanceRuleConfig].
class AttendanceRuleController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<AttendanceRuleConfig?> saveRuleConfig(
    AttendanceRuleConfig config,
  ) async {
    final validationError = config.validate();
    if (validationError != null) {
      state = AsyncError<void>(
        ValidationException(validationError, code: 'INVALID_ATTENDANCE_RULE'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading<void>();
    try {
      final updated = await ref
          .read(attendanceRepositoryProvider)
          .updateRuleConfig(config);
      ref.invalidate(attendanceRuleConfigProvider(config.subjectClassId));
      ref.invalidate(dashboardOverviewProvider);
      if (ref.mounted) {
        state = const AsyncData<void>(null);
      }
      return updated;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(
          ThaiErrorMapper.toAppException(error),
          stackTrace,
        );
      }
      return null;
    }
  }
}

final attendanceRuleControllerProvider =
    AsyncNotifierProvider<AttendanceRuleController, void>(
      AttendanceRuleController.new,
    );
