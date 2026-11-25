import '../../domain/entities/academic_year.dart';

/// Data Transfer Object mapping `public.academic_years` rows to [AcademicYear].
class AcademicYearDto {
  const AcademicYearDto({
    required this.id,
    required this.teacherId,
    required this.yearBe,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcademicYearDto.fromJson(Map<String, dynamic> json) {
    return AcademicYearDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      yearBe: (json['year_be'] as num).toInt(),
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  final String id;
  final String teacherId;
  final int yearBe;
  final DateTime createdAt;
  final DateTime updatedAt;

  AcademicYear toEntity() {
    return AcademicYear(
      id: id,
      teacherId: teacherId,
      yearBe: yearBe,
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
