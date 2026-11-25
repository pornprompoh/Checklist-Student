import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the initialized [SupabaseClient] instance.
///
/// **Architecture Rule (Repository Pattern):**
/// This provider MUST ONLY be used inside the `data/datasources/` layer.
/// `presentation/` and `domain/` layers must NEVER import `supabase_flutter`
/// or access this provider directly.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
