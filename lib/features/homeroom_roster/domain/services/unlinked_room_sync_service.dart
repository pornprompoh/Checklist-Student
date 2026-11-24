import '../../../academic_structure/domain/entities/subject_class.dart';
import '../entities/homeroom.dart';

/// Group of `subject_classes` in the same term that share a normalized room
/// name and currently have `homeroomId == null`.
///
/// Pure Dart entity.
class UnlinkedRoomGroup {
  const UnlinkedRoomGroup({
    required this.roomName,
    required this.subjectClassIds,
    this.existingHomeroomId,
  });

  final String roomName;
  final List<String> subjectClassIds;

  /// Non-null when a `homerooms` record with the same name already exists in
  /// the term and only needs its `subject_classes.homeroom_id` linked.
  final String? existingHomeroomId;

  int get classCount => subjectClassIds.length;
}

/// Pure Dart service inspecting a term's [Homeroom] and [SubjectClass] lists
/// to surface rooms created in `academic_structure` that are not yet linked
/// to a master homeroom roster.
abstract final class UnlinkedRoomSyncService {
  static List<UnlinkedRoomGroup> findUnlinkedRooms({
    required List<Homeroom> homerooms,
    required List<SubjectClass> subjectClasses,
  }) {
    final homeroomByNormalizedName = <String, Homeroom>{
      for (final room in homerooms) _normalize(room.name): room,
    };

    final displayNameByKey = <String, String>{};
    final classIdsByKey = <String, List<String>>{};

    for (final subjectClass in subjectClasses) {
      if (subjectClass.homeroomId != null) continue;
      final trimmedName = subjectClass.roomName.trim();
      if (trimmedName.isEmpty) continue;

      final key = _normalize(trimmedName);
      displayNameByKey.putIfAbsent(key, () => trimmedName);
      classIdsByKey.putIfAbsent(key, () => <String>[]).add(subjectClass.id);
    }

    final groups = <UnlinkedRoomGroup>[];
    for (final entry in classIdsByKey.entries) {
      final existingHomeroom = homeroomByNormalizedName[entry.key];
      groups.add(
        UnlinkedRoomGroup(
          roomName: existingHomeroom?.name ?? displayNameByKey[entry.key]!,
          subjectClassIds: List<String>.unmodifiable(entry.value),
          existingHomeroomId: existingHomeroom?.id,
        ),
      );
    }

    groups.sort((a, b) => a.roomName.compareTo(b.roomName));
    return List<UnlinkedRoomGroup>.unmodifiable(groups);
  }

  static String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
}
