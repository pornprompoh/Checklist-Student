/// Compile-time environment configuration supplied via `--dart-define`
/// or `--dart-define-from-file`.
///
/// Only public client-safe Supabase parameters are permitted here.
/// Never place Service Role keys or Gemini API keys in Flutter Web client code.
abstract final class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Returns `true` when both [supabaseUrl] and [supabaseAnonKey] are provided.
  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
