import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/sync_queue/presentation/providers/sync_queue_providers.dart';

/// Root application widget wiring [AppTheme], [themeModeProvider],
/// [appRouterProvider], and [syncEngineAutoCoordinatorProvider].
class ChecklistStudentApp extends ConsumerWidget {
  const ChecklistStudentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncEngineAutoCoordinatorProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Checklist-Student',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
