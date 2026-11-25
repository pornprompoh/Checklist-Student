import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../data/datasources/student_portal_remote_datasource.dart';
import '../../data/repositories/student_portal_repository_impl.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../../domain/services/student_pin_validator_service.dart';
import 'student_portal_controller.dart';

final studentPinValidatorServiceProvider = Provider<StudentPinValidatorService>(
  (ref) => const StudentPinValidatorService(),
);

final studentPortalRepositoryProvider = Provider<StudentPortalRepository>((
  ref,
) {
  final remote = EnvConfig.isSupabaseConfigured
      ? ref.watch(studentPortalRemoteDataSourceProvider)
      : null;
  return StudentPortalRepositoryImpl(remoteDataSource: remote);
});

final studentPortalControllerProvider =
    NotifierProvider.autoDispose<StudentPortalController, StudentPortalState>(
      StudentPortalController.new,
    );
