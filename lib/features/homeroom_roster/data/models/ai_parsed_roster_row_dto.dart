import '../../domain/entities/ai_parsed_roster_row.dart';

/// DTO mapping JSON items returned by `parse-roster-ai` Edge Function to
/// [AiParsedRosterRow].
class AiParsedRosterRowDto {
  const AiParsedRosterRowDto({
    required this.studentNumber,
    required this.studentCode,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    required this.rawFullName,
  });

  factory AiParsedRosterRowDto.fromJson(Map<String, dynamic> json) {
    return AiParsedRosterRowDto(
      studentNumber: _parseNullableInt(json['student_number']),
      studentCode: (json['student_code']?.toString() ?? '').trim(),
      prefix: (json['prefix']?.toString() ?? '').trim(),
      firstName: (json['first_name']?.toString() ?? '').trim(),
      lastName: (json['last_name']?.toString() ?? '').trim(),
      rawFullName: (json['raw_full_name']?.toString() ?? '').trim(),
    );
  }

  final int? studentNumber;
  final String studentCode;
  final String prefix;
  final String firstName;
  final String lastName;
  final String rawFullName;

  AiParsedRosterRow toEntity() {
    return AiParsedRosterRow(
      studentNumber: studentNumber,
      studentCode: studentCode,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
      rawFullName: rawFullName,
    );
  }

  static int? _parseNullableInt(Object? value) {
    if (value is int) return value > 0 ? value : null;
    if (value is num) {
      final n = value.toInt();
      return n > 0 ? n : null;
    }
    if (value is String) {
      final n = int.tryParse(value.trim());
      return (n != null && n > 0) ? n : null;
    }
    return null;
  }
}
