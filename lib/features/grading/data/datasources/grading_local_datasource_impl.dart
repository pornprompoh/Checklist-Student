import 'package:drift/drift.dart';

import '../../../../core/constants/submission_status.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_cache_store.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/grading_scale_config.dart';
import '../../domain/entities/score_category.dart';
import '../../domain/entities/student_score.dart';
import '../models/assignment_dto.dart';
import '../models/grading_scale_config_dto.dart';
import '../models/score_category_dto.dart';
import 'grading_local_datasource.dart';

/// Drift-backed offline datasource for `local_student_scores` and cached
/// grading plan entities (`ScoreCategory`, `Assignment`, `GradingScaleConfig`).
class GradingLocalDataSourceImpl implements GradingLocalDataSource {
  const GradingLocalDataSourceImpl(this._db, this._cache);

  final AppDatabase _db;
  final LocalCacheStore _cache;
  static const String _group = 'grading';
  static const String _assignmentClassMapKey = 'assignment_class_map';

  @override
  Future<void> saveScoreCategories(
    String teacherId,
    String subjectClassId,
    List<ScoreCategory> categories,
  ) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'score_categories_$subjectClassId',
      entityGroup: _group,
      jsonPayload: categories.map(_categoryToJson).toList(growable: false),
    );
  }

  @override
  Future<List<ScoreCategory>?> readScoreCategories(
    String teacherId,
    String subjectClassId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'score_categories_$subjectClassId',
    );
    if (raw is! List) return null;
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => ScoreCategoryDto.fromJson(Map<String, dynamic>.from(m)).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> saveAssignments(
    String teacherId,
    String subjectClassId,
    List<Assignment> assignments,
  ) async {
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'assignments_$subjectClassId',
      entityGroup: _group,
      jsonPayload: assignments.map(_assignmentToJson).toList(growable: false),
    );
    final rawMap = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: _assignmentClassMapKey,
    );
    final map = rawMap is Map
        ? Map<String, String>.from(
            rawMap.map((k, v) => MapEntry(k.toString(), v.toString())),
          )
        : <String, String>{};
    for (final a in assignments) {
      map[a.id] = subjectClassId;
    }
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: _assignmentClassMapKey,
      entityGroup: _group,
      jsonPayload: map,
    );
  }

  @override
  Future<List<Assignment>?> readAssignments(
    String teacherId,
    String subjectClassId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'assignments_$subjectClassId',
    );
    if (raw is! List) return null;
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => AssignmentDto.fromJson(Map<String, dynamic>.from(m)).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> saveGradingScaleConfig(
    String teacherId,
    GradingScaleConfig config,
  ) {
    return _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'grading_scale_${config.subjectClassId}',
      entityGroup: _group,
      jsonPayload: <String, dynamic>{
        'id': config.subjectClassId,
        'grading_scale_type': config.scaleType.dbValue,
        'grading_rules': config.rules
            .map((r) => <String, dynamic>{'grade': r.grade, 'min': r.minScore})
            .toList(growable: false),
        'missing_work_threshold': config.missingWorkThreshold,
      },
    );
  }

  @override
  Future<GradingScaleConfig?> readGradingScaleConfig(
    String teacherId,
    String subjectClassId,
  ) async {
    final raw = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: 'grading_scale_$subjectClassId',
    );
    if (raw is! Map) return null;
    return GradingScaleConfigDto.fromJson(
      Map<String, dynamic>.from(raw),
    ).toEntity();
  }

  @override
  Future<List<StudentScore>?> fetchStudentScoresByClass(
    String teacherId,
    String subjectClassId,
  ) async {
    final cachedAssignments = await readAssignments(teacherId, subjectClassId);
    final assignmentIds =
        cachedAssignments?.map((a) => a.id).toList(growable: false) ??
        const <String>[];

    final rows = await (_db.select(_db.localStudentScores)
          ..where((t) {
            final matchClass = t.subjectClassId.equals(subjectClassId);
            final scope = assignmentIds.isEmpty
                ? matchClass
                : (matchClass | t.assignmentId.isIn(assignmentIds));
            return t.teacherId.equals(teacherId) & scope;
          }))
        .get();
    if (rows.isEmpty) {
      final marker = await _cache.readJson(
        teacherId: teacherId,
        cacheKey: 'scores_synced_$subjectClassId',
      );
      if (marker == null) return null;
    }
    return rows.map(_scoreToEntity).toList(growable: false);
  }

  @override
  Future<StudentScore?> fetchStudentScoreById(
    String teacherId,
    String scoreId,
  ) async {
    final row = await (_db.select(_db.localStudentScores)
          ..where((t) => t.teacherId.equals(teacherId) & t.id.equals(scoreId)))
        .getSingleOrNull();
    return row == null ? null : _scoreToEntity(row);
  }

  @override
  Future<StudentScore?> fetchStudentScoreByCell({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
  }) async {
    final row = await (_db.select(_db.localStudentScores)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.assignmentId.equals(assignmentId) &
                t.enrollmentId.equals(enrollmentId),
          ))
        .getSingleOrNull();
    return row == null ? null : _scoreToEntity(row);
  }

  @override
  Future<void> upsertScoresFromRemote(
    String teacherId,
    String subjectClassId,
    List<StudentScore> scores,
  ) async {
    await _db.transaction(() async {
      for (final s in scores) {
        final existing = await _findScoreRow(
          teacherId,
          s.id,
          s.assignmentId,
          s.enrollmentId,
        );
        if (existing != null && existing.isDirty) continue;
        await _db.into(_db.localStudentScores).insertOnConflictUpdate(
          _scoreToCompanion(s, subjectClassId: subjectClassId, isDirty: false),
        );
      }
    });
    await _cache.writeJson(
      teacherId: teacherId,
      cacheKey: 'scores_synced_$subjectClassId',
      entityGroup: _group,
      jsonPayload: const <String, bool>{'cached': true},
    );
  }

  @override
  Future<void> saveScoreOffline(
    StudentScore score, {
    String? subjectClassId,
  }) async {
    final resolvedClassId =
        subjectClassId ??
        await _resolveClassId(score.teacherId, score.assignmentId);
    await _db.into(_db.localStudentScores).insertOnConflictUpdate(
      _scoreToCompanion(score, subjectClassId: resolvedClassId, isDirty: true),
    );
  }

  @override
  Future<void> markScoreSynced(
    StudentScore score, {
    String? subjectClassId,
    String? previousLocalId,
  }) async {
    final resolvedClassId =
        subjectClassId ??
        await _resolveClassId(score.teacherId, score.assignmentId);
    await _db.transaction(() async {
      if (previousLocalId != null && previousLocalId != score.id) {
        await (_db.delete(_db.localStudentScores)
              ..where((t) => t.id.equals(previousLocalId)))
            .go();
      }
      await _db.into(_db.localStudentScores).insertOnConflictUpdate(
        _scoreToCompanion(
          score,
          subjectClassId: resolvedClassId,
          isDirty: false,
        ),
      );
    });
  }

  Future<String> _resolveClassId(String teacherId, String assignmentId) async {
    final rawMap = await _cache.readJson(
      teacherId: teacherId,
      cacheKey: _assignmentClassMapKey,
    );
    if (rawMap is Map) {
      final mapped = rawMap[assignmentId]?.toString();
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }
    final existing = await (_db.select(_db.localStudentScores)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.assignmentId.equals(assignmentId),
          )
          ..limit(1))
        .getSingleOrNull();
    return existing?.subjectClassId ?? '';
  }

  Future<LocalStudentScore?> _findScoreRow(
    String teacherId,
    String id,
    String assignmentId,
    String enrollmentId,
  ) {
    return (_db.select(_db.localStudentScores)
          ..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                (t.id.equals(id) |
                    (t.assignmentId.equals(assignmentId) &
                        t.enrollmentId.equals(enrollmentId))),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  LocalStudentScoresCompanion _scoreToCompanion(
    StudentScore s, {
    required String subjectClassId,
    required bool isDirty,
  }) => LocalStudentScoresCompanion.insert(
    id: s.id,
    teacherId: s.teacherId,
    assignmentId: s.assignmentId,
    enrollmentId: s.enrollmentId,
    subjectClassId: subjectClassId,
    submissionStatus: Value(s.submissionStatus.dbValue),
    score: Value(s.score),
    note: Value(s.note),
    version: Value(s.version),
    isDirty: Value(isDirty),
    updatedAt: s.updatedAt.toUtc(),
  );

  StudentScore _scoreToEntity(LocalStudentScore row) => StudentScore(
    id: row.id,
    teacherId: row.teacherId,
    assignmentId: row.assignmentId,
    enrollmentId: row.enrollmentId,
    submissionStatus: SubmissionStatus.fromDbValue(row.submissionStatus),
    score: row.score,
    note: row.note,
    version: row.version,
    updatedAt: row.updatedAt.toUtc(),
  );

  Map<String, dynamic> _categoryToJson(ScoreCategory c) => <String, dynamic>{
    'id': c.id,
    'teacher_id': c.teacherId,
    'subject_class_id': c.subjectClassId,
    'name': c.name,
    'target_max_score': c.targetMaxScore,
    'sort_order': c.sortOrder,
    'created_at': c.createdAt.toUtc().toIso8601String(),
    'updated_at': c.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _assignmentToJson(Assignment a) => <String, dynamic>{
    'id': a.id,
    'teacher_id': a.teacherId,
    'subject_class_id': a.subjectClassId,
    'category_id': a.categoryId,
    'title': a.title,
    'description': a.description,
    'max_score': a.maxScore,
    'is_mandatory': a.isMandatory,
    'due_date': a.dueDate == null ? null : ThaiDateFormatter.toIsoDate(a.dueDate!),
    'sort_order': a.sortOrder,
    'version': a.version,
    'created_at': a.createdAt.toUtc().toIso8601String(),
    'updated_at': a.updatedAt.toUtc().toIso8601String(),
  };
}
