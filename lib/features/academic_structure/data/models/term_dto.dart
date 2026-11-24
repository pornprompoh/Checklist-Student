import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/term.dart';

/// Data Transfer Object mapping `public.terms` rows to [Term].
///
/// Serializes and parses `start_date` and `end_date` strictly via
/// [ThaiDateFormatter.toIsoDate] and [ThaiDateFormatter.parseIsoDate].
class TermDto {
  const TermDto({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.termLabel,
    required this.startDate,
    required this.endDate,
    required this.isPinnedActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TermDto.fromJson(Map<String, dynamic> json) {
    final fallbackDate = DateTime.fromMillisecondsSinceEpoch(0);
    return TermDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      termLabel: (json['term_label'] as String?) ?? '',
      startDate:
          ThaiDateFormatter.parseIsoDate(json['start_date'] as String?) ??
          fallbackDate,
      endDate:
          ThaiDateFormatter.parseIsoDate(json['end_date'] as String?) ??
          fallbackDate,
      isPinnedActive: (json['is_pinned_active'] as bool?) ?? false,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  final String id;
  final String teacherId;
  final String academicYearId;
  final String termLabel;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPinnedActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Builds the `INSERT` payload for `public.terms`.
  static Map<String, dynamic> toInsertJson({
    required String teacherId,
    required String academicYearId,
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return <String, dynamic>{
      'teacher_id': teacherId,
      'academic_year_id': academicYearId,
      'term_label': termLabel.trim(),
      'start_date': ThaiDateFormatter.toIsoDate(startDate),
      'end_date': ThaiDateFormatter.toIsoDate(endDate),
    };
  }

  /// Builds the `UPDATE` payload for `public.terms`.
  static Map<String, dynamic> toUpdateJson({
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return <String, dynamic>{
      'term_label': termLabel.trim(),
      'start_date': ThaiDateFormatter.toIsoDate(startDate),
      'end_date': ThaiDateFormatter.toIsoDate(endDate),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Term toEntity() {
    return Term(
      id: id,
      teacherId: teacherId,
      academicYearId: academicYearId,
      termLabel: termLabel,
      startDate: startDate,
      endDate: endDate,
      isPinnedActive: isPinnedActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseTimestamp(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
