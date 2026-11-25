import '../../../../core/database/local_cache_store.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/dashboard_class_item.dart';
import '../../domain/entities/today_attendance_summary.dart';
import 'dashboard_local_datasource.dart';

/// Drift-backed read-through cache for Teacher Dashboard class cards.
class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  const DashboardLocalDataSourceImpl(this._cache);

  final LocalCacheStore _cache;
  static const String _group = 'dashboard';

  @override
  Future<void> saveDashboardClasses({
    required String teacherId,
    required String termId,
    required DateTime referenceDate,
    required List<DashboardClassItem> items,
  }) async {
    final isoDate = ThaiDateFormatter.toIsoDate(referenceDate);
    final payload = items.map(_itemToJson).toList(growable: false);
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'dashboard_${termId}_$isoDate',
      entityGroup: _group,
      jsonPayload: payload,
    );
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'dashboard_latest_$termId',
      entityGroup: _group,
      jsonPayload: payload,
    );
  }

  @override
  Future<List<DashboardClassItem>?> readDashboardClasses({
    required String teacherId,
    required String termId,
    required DateTime referenceDate,
  }) async {
    final isoDate = ThaiDateFormatter.toIsoDate(referenceDate);
    final exactRaw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'dashboard_${termId}_$isoDate',
    );
    final exact = _decodeItems(exactRaw);
    if (exact != null) return exact;

    final latestRaw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'dashboard_latest_$termId',
    );
    return _decodeItems(latestRaw);
  }

  List<DashboardClassItem>? _decodeItems(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => _itemFromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Map<String, dynamic> _itemToJson(DashboardClassItem item) {
    final summary = item.todayAttendance;
    return <String, dynamic>{
      'subject_class_id': item.subjectClassId,
      'subject_id': item.subjectId,
      'subject_code': item.subjectCode,
      'subject_name': item.subjectName,
      'room_name': item.roomName,
      'teaching_days': item.teachingDays,
      'is_pinned': item.isPinned,
      'active_student_count': item.activeStudentCount,
      'today_attendance': summary == null
          ? null
          : <String, dynamic>{
              'session_id': summary.sessionId,
              'is_locked': summary.isLocked,
              'present_count': summary.presentCount,
              'late_count': summary.lateCount,
              'leave_count': summary.leaveCount,
              'absent_count': summary.absentCount,
            },
    };
  }

  DashboardClassItem _itemFromJson(Map<String, dynamic> json) {
    final rawSummary = json['today_attendance'];
    TodayAttendanceSummary? summary;
    if (rawSummary is Map) {
      final map = Map<String, dynamic>.from(rawSummary);
      summary = TodayAttendanceSummary(
        sessionId: map['session_id'] as String,
        isLocked: (map['is_locked'] as bool?) ?? false,
        presentCount: (map['present_count'] as num?)?.toInt() ?? 0,
        lateCount: (map['late_count'] as num?)?.toInt() ?? 0,
        leaveCount: (map['leave_count'] as num?)?.toInt() ?? 0,
        absentCount: (map['absent_count'] as num?)?.toInt() ?? 0,
      );
    }
    final rawDays = (json['teaching_days'] as List<dynamic>?) ?? const [];
    return DashboardClassItem(
      subjectClassId: json['subject_class_id'] as String,
      subjectId: json['subject_id'] as String,
      subjectCode: (json['subject_code'] as String?) ?? '',
      subjectName: (json['subject_name'] as String?) ?? '',
      roomName: (json['room_name'] as String?) ?? '',
      teachingDays: rawDays.map((e) => (e as num).toInt()).toList(growable: false),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      activeStudentCount: (json['active_student_count'] as num?)?.toInt() ?? 0,
      todayAttendance: summary,
    );
  }
}
