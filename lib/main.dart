import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (EnvConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: ChecklistStudentApp()));
}
