import '../../domain/entities/homeroom.dart';

/// Data Transfer Object mapping `public.homerooms` rows to [Homeroom].
class HomeroomDto {
  const HomeroomDto({
    required this.id,
    required this.teacherId,
    required this.termId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeroomDto.fromJson(Map<String, dynamic> json) {
    return HomeroomDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      termId: json['term_id'] as String,
      name: (json['name'] as String?) ?? '',
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  final String id;
  final String teacherId;
  final String termId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Homeroom toEntity() {
    return Homeroom(
      id: id,
      teacherId: teacherId,
      termId: termId,
      name: name,
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
