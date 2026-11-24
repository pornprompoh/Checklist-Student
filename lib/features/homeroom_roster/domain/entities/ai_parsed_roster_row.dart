/// Single student row extracted by the `parse-roster-ai` Edge Function.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class AiParsedRosterRow {
  const AiParsedRosterRow({
    required this.studentNumber,
    required this.studentCode,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    required this.rawFullName,
  });

  final int? studentNumber;
  final String studentCode;
  final String prefix;
  final String firstName;
  final String lastName;
  final String rawFullName;
}
