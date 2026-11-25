// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalEntityCachesTable extends LocalEntityCaches
    with TableInfo<$LocalEntityCachesTable, LocalEntityCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEntityCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherIdMeta = const VerificationMeta(
    'teacherId',
  );
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
    'teacher_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityGroupMeta = const VerificationMeta(
    'entityGroup',
  );
  @override
  late final GeneratedColumn<String> entityGroup = GeneratedColumn<String>(
    'entity_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    teacherId,
    entityGroup,
    payloadJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_entity_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEntityCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(
        _teacherIdMeta,
        teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    if (data.containsKey('entity_group')) {
      context.handle(
        _entityGroupMeta,
        entityGroup.isAcceptableOrUnknown(
          data['entity_group']!,
          _entityGroupMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityGroupMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {teacherId, cacheKey};
  @override
  LocalEntityCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEntityCache(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      teacherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_id'],
      )!,
      entityGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_group'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalEntityCachesTable createAlias(String alias) {
    return $LocalEntityCachesTable(attachedDatabase, alias);
  }
}

class LocalEntityCache extends DataClass
    implements Insertable<LocalEntityCache> {
  final String cacheKey;
  final String teacherId;
  final String entityGroup;
  final String payloadJson;
  final DateTime updatedAt;
  const LocalEntityCache({
    required this.cacheKey,
    required this.teacherId,
    required this.entityGroup,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['teacher_id'] = Variable<String>(teacherId);
    map['entity_group'] = Variable<String>(entityGroup);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalEntityCachesCompanion toCompanion(bool nullToAbsent) {
    return LocalEntityCachesCompanion(
      cacheKey: Value(cacheKey),
      teacherId: Value(teacherId),
      entityGroup: Value(entityGroup),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalEntityCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEntityCache(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
      entityGroup: serializer.fromJson<String>(json['entityGroup']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'teacherId': serializer.toJson<String>(teacherId),
      'entityGroup': serializer.toJson<String>(entityGroup),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalEntityCache copyWith({
    String? cacheKey,
    String? teacherId,
    String? entityGroup,
    String? payloadJson,
    DateTime? updatedAt,
  }) => LocalEntityCache(
    cacheKey: cacheKey ?? this.cacheKey,
    teacherId: teacherId ?? this.teacherId,
    entityGroup: entityGroup ?? this.entityGroup,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalEntityCache copyWithCompanion(LocalEntityCachesCompanion data) {
    return LocalEntityCache(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
      entityGroup: data.entityGroup.present
          ? data.entityGroup.value
          : this.entityGroup,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEntityCache(')
          ..write('cacheKey: $cacheKey, ')
          ..write('teacherId: $teacherId, ')
          ..write('entityGroup: $entityGroup, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheKey, teacherId, entityGroup, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEntityCache &&
          other.cacheKey == this.cacheKey &&
          other.teacherId == this.teacherId &&
          other.entityGroup == this.entityGroup &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class LocalEntityCachesCompanion extends UpdateCompanion<LocalEntityCache> {
  final Value<String> cacheKey;
  final Value<String> teacherId;
  final Value<String> entityGroup;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalEntityCachesCompanion({
    this.cacheKey = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.entityGroup = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalEntityCachesCompanion.insert({
    required String cacheKey,
    required String teacherId,
    required String entityGroup,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       teacherId = Value(teacherId),
       entityGroup = Value(entityGroup),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<LocalEntityCache> custom({
    Expression<String>? cacheKey,
    Expression<String>? teacherId,
    Expression<String>? entityGroup,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (teacherId != null) 'teacher_id': teacherId,
      if (entityGroup != null) 'entity_group': entityGroup,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalEntityCachesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? teacherId,
    Value<String>? entityGroup,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalEntityCachesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      teacherId: teacherId ?? this.teacherId,
      entityGroup: entityGroup ?? this.entityGroup,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (entityGroup.present) {
      map['entity_group'] = Variable<String>(entityGroup.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEntityCachesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('teacherId: $teacherId, ')
          ..write('entityGroup: $entityGroup, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAttendanceSessionsTable extends LocalAttendanceSessions
    with TableInfo<$LocalAttendanceSessionsTable, LocalAttendanceSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttendanceSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherIdMeta = const VerificationMeta(
    'teacherId',
  );
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
    'teacher_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectClassIdMeta = const VerificationMeta(
    'subjectClassId',
  );
  @override
  late final GeneratedColumn<String> subjectClassId = GeneratedColumn<String>(
    'subject_class_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionDateIsoMeta = const VerificationMeta(
    'sessionDateIso',
  );
  @override
  late final GeneratedColumn<String> sessionDateIso = GeneratedColumn<String>(
    'session_date_iso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teacherId,
    subjectClassId,
    sessionDateIso,
    isLocked,
    note,
    version,
    isDirty,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attendance_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAttendanceSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(
        _teacherIdMeta,
        teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    if (data.containsKey('subject_class_id')) {
      context.handle(
        _subjectClassIdMeta,
        subjectClassId.isAcceptableOrUnknown(
          data['subject_class_id']!,
          _subjectClassIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectClassIdMeta);
    }
    if (data.containsKey('session_date_iso')) {
      context.handle(
        _sessionDateIsoMeta,
        sessionDateIso.isAcceptableOrUnknown(
          data['session_date_iso']!,
          _sessionDateIsoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionDateIsoMeta);
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {subjectClassId, sessionDateIso},
  ];
  @override
  LocalAttendanceSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttendanceSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teacherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_id'],
      )!,
      subjectClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_class_id'],
      )!,
      sessionDateIso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_date_iso'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalAttendanceSessionsTable createAlias(String alias) {
    return $LocalAttendanceSessionsTable(attachedDatabase, alias);
  }
}

class LocalAttendanceSession extends DataClass
    implements Insertable<LocalAttendanceSession> {
  final String id;
  final String teacherId;
  final String subjectClassId;
  final String sessionDateIso;
  final bool isLocked;
  final String note;
  final int version;
  final bool isDirty;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalAttendanceSession({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
    required this.sessionDateIso,
    required this.isLocked,
    required this.note,
    required this.version,
    required this.isDirty,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['teacher_id'] = Variable<String>(teacherId);
    map['subject_class_id'] = Variable<String>(subjectClassId);
    map['session_date_iso'] = Variable<String>(sessionDateIso);
    map['is_locked'] = Variable<bool>(isLocked);
    map['note'] = Variable<String>(note);
    map['version'] = Variable<int>(version);
    map['is_dirty'] = Variable<bool>(isDirty);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalAttendanceSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalAttendanceSessionsCompanion(
      id: Value(id),
      teacherId: Value(teacherId),
      subjectClassId: Value(subjectClassId),
      sessionDateIso: Value(sessionDateIso),
      isLocked: Value(isLocked),
      note: Value(note),
      version: Value(version),
      isDirty: Value(isDirty),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalAttendanceSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttendanceSession(
      id: serializer.fromJson<String>(json['id']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
      subjectClassId: serializer.fromJson<String>(json['subjectClassId']),
      sessionDateIso: serializer.fromJson<String>(json['sessionDateIso']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      note: serializer.fromJson<String>(json['note']),
      version: serializer.fromJson<int>(json['version']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teacherId': serializer.toJson<String>(teacherId),
      'subjectClassId': serializer.toJson<String>(subjectClassId),
      'sessionDateIso': serializer.toJson<String>(sessionDateIso),
      'isLocked': serializer.toJson<bool>(isLocked),
      'note': serializer.toJson<String>(note),
      'version': serializer.toJson<int>(version),
      'isDirty': serializer.toJson<bool>(isDirty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalAttendanceSession copyWith({
    String? id,
    String? teacherId,
    String? subjectClassId,
    String? sessionDateIso,
    bool? isLocked,
    String? note,
    int? version,
    bool? isDirty,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalAttendanceSession(
    id: id ?? this.id,
    teacherId: teacherId ?? this.teacherId,
    subjectClassId: subjectClassId ?? this.subjectClassId,
    sessionDateIso: sessionDateIso ?? this.sessionDateIso,
    isLocked: isLocked ?? this.isLocked,
    note: note ?? this.note,
    version: version ?? this.version,
    isDirty: isDirty ?? this.isDirty,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalAttendanceSession copyWithCompanion(
    LocalAttendanceSessionsCompanion data,
  ) {
    return LocalAttendanceSession(
      id: data.id.present ? data.id.value : this.id,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
      subjectClassId: data.subjectClassId.present
          ? data.subjectClassId.value
          : this.subjectClassId,
      sessionDateIso: data.sessionDateIso.present
          ? data.sessionDateIso.value
          : this.sessionDateIso,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      note: data.note.present ? data.note.value : this.note,
      version: data.version.present ? data.version.value : this.version,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceSession(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('subjectClassId: $subjectClassId, ')
          ..write('sessionDateIso: $sessionDateIso, ')
          ..write('isLocked: $isLocked, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teacherId,
    subjectClassId,
    sessionDateIso,
    isLocked,
    note,
    version,
    isDirty,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttendanceSession &&
          other.id == this.id &&
          other.teacherId == this.teacherId &&
          other.subjectClassId == this.subjectClassId &&
          other.sessionDateIso == this.sessionDateIso &&
          other.isLocked == this.isLocked &&
          other.note == this.note &&
          other.version == this.version &&
          other.isDirty == this.isDirty &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalAttendanceSessionsCompanion
    extends UpdateCompanion<LocalAttendanceSession> {
  final Value<String> id;
  final Value<String> teacherId;
  final Value<String> subjectClassId;
  final Value<String> sessionDateIso;
  final Value<bool> isLocked;
  final Value<String> note;
  final Value<int> version;
  final Value<bool> isDirty;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalAttendanceSessionsCompanion({
    this.id = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.subjectClassId = const Value.absent(),
    this.sessionDateIso = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.note = const Value.absent(),
    this.version = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAttendanceSessionsCompanion.insert({
    required String id,
    required String teacherId,
    required String subjectClassId,
    required String sessionDateIso,
    this.isLocked = const Value.absent(),
    this.note = const Value.absent(),
    this.version = const Value.absent(),
    this.isDirty = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teacherId = Value(teacherId),
       subjectClassId = Value(subjectClassId),
       sessionDateIso = Value(sessionDateIso),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalAttendanceSession> custom({
    Expression<String>? id,
    Expression<String>? teacherId,
    Expression<String>? subjectClassId,
    Expression<String>? sessionDateIso,
    Expression<bool>? isLocked,
    Expression<String>? note,
    Expression<int>? version,
    Expression<bool>? isDirty,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teacherId != null) 'teacher_id': teacherId,
      if (subjectClassId != null) 'subject_class_id': subjectClassId,
      if (sessionDateIso != null) 'session_date_iso': sessionDateIso,
      if (isLocked != null) 'is_locked': isLocked,
      if (note != null) 'note': note,
      if (version != null) 'version': version,
      if (isDirty != null) 'is_dirty': isDirty,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAttendanceSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? teacherId,
    Value<String>? subjectClassId,
    Value<String>? sessionDateIso,
    Value<bool>? isLocked,
    Value<String>? note,
    Value<int>? version,
    Value<bool>? isDirty,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalAttendanceSessionsCompanion(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      subjectClassId: subjectClassId ?? this.subjectClassId,
      sessionDateIso: sessionDateIso ?? this.sessionDateIso,
      isLocked: isLocked ?? this.isLocked,
      note: note ?? this.note,
      version: version ?? this.version,
      isDirty: isDirty ?? this.isDirty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (subjectClassId.present) {
      map['subject_class_id'] = Variable<String>(subjectClassId.value);
    }
    if (sessionDateIso.present) {
      map['session_date_iso'] = Variable<String>(sessionDateIso.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceSessionsCompanion(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('subjectClassId: $subjectClassId, ')
          ..write('sessionDateIso: $sessionDateIso, ')
          ..write('isLocked: $isLocked, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAttendanceRecordsTable extends LocalAttendanceRecords
    with TableInfo<$LocalAttendanceRecordsTable, LocalAttendanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherIdMeta = const VerificationMeta(
    'teacherId',
  );
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
    'teacher_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enrollmentIdMeta = const VerificationMeta(
    'enrollmentId',
  );
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
    'enrollment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teacherId,
    sessionId,
    enrollmentId,
    status,
    note,
    version,
    isDirty,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attendance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAttendanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(
        _teacherIdMeta,
        teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
        _enrollmentIdMeta,
        enrollmentId.isAcceptableOrUnknown(
          data['enrollment_id']!,
          _enrollmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enrollmentIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, enrollmentId},
  ];
  @override
  LocalAttendanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttendanceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teacherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      enrollmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrollment_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalAttendanceRecordsTable createAlias(String alias) {
    return $LocalAttendanceRecordsTable(attachedDatabase, alias);
  }
}

class LocalAttendanceRecord extends DataClass
    implements Insertable<LocalAttendanceRecord> {
  final String id;
  final String teacherId;
  final String sessionId;
  final String enrollmentId;
  final String status;
  final String note;
  final int version;
  final bool isDirty;
  final DateTime updatedAt;
  const LocalAttendanceRecord({
    required this.id,
    required this.teacherId,
    required this.sessionId,
    required this.enrollmentId,
    required this.status,
    required this.note,
    required this.version,
    required this.isDirty,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['teacher_id'] = Variable<String>(teacherId);
    map['session_id'] = Variable<String>(sessionId);
    map['enrollment_id'] = Variable<String>(enrollmentId);
    map['status'] = Variable<String>(status);
    map['note'] = Variable<String>(note);
    map['version'] = Variable<int>(version);
    map['is_dirty'] = Variable<bool>(isDirty);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalAttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalAttendanceRecordsCompanion(
      id: Value(id),
      teacherId: Value(teacherId),
      sessionId: Value(sessionId),
      enrollmentId: Value(enrollmentId),
      status: Value(status),
      note: Value(note),
      version: Value(version),
      isDirty: Value(isDirty),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalAttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttendanceRecord(
      id: serializer.fromJson<String>(json['id']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      enrollmentId: serializer.fromJson<String>(json['enrollmentId']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String>(json['note']),
      version: serializer.fromJson<int>(json['version']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teacherId': serializer.toJson<String>(teacherId),
      'sessionId': serializer.toJson<String>(sessionId),
      'enrollmentId': serializer.toJson<String>(enrollmentId),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String>(note),
      'version': serializer.toJson<int>(version),
      'isDirty': serializer.toJson<bool>(isDirty),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalAttendanceRecord copyWith({
    String? id,
    String? teacherId,
    String? sessionId,
    String? enrollmentId,
    String? status,
    String? note,
    int? version,
    bool? isDirty,
    DateTime? updatedAt,
  }) => LocalAttendanceRecord(
    id: id ?? this.id,
    teacherId: teacherId ?? this.teacherId,
    sessionId: sessionId ?? this.sessionId,
    enrollmentId: enrollmentId ?? this.enrollmentId,
    status: status ?? this.status,
    note: note ?? this.note,
    version: version ?? this.version,
    isDirty: isDirty ?? this.isDirty,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalAttendanceRecord copyWithCompanion(
    LocalAttendanceRecordsCompanion data,
  ) {
    return LocalAttendanceRecord(
      id: data.id.present ? data.id.value : this.id,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      version: data.version.present ? data.version.value : this.version,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceRecord(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('sessionId: $sessionId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teacherId,
    sessionId,
    enrollmentId,
    status,
    note,
    version,
    isDirty,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttendanceRecord &&
          other.id == this.id &&
          other.teacherId == this.teacherId &&
          other.sessionId == this.sessionId &&
          other.enrollmentId == this.enrollmentId &&
          other.status == this.status &&
          other.note == this.note &&
          other.version == this.version &&
          other.isDirty == this.isDirty &&
          other.updatedAt == this.updatedAt);
}

class LocalAttendanceRecordsCompanion
    extends UpdateCompanion<LocalAttendanceRecord> {
  final Value<String> id;
  final Value<String> teacherId;
  final Value<String> sessionId;
  final Value<String> enrollmentId;
  final Value<String> status;
  final Value<String> note;
  final Value<int> version;
  final Value<bool> isDirty;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalAttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.version = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAttendanceRecordsCompanion.insert({
    required String id,
    required String teacherId,
    required String sessionId,
    required String enrollmentId,
    required String status,
    this.note = const Value.absent(),
    this.version = const Value.absent(),
    this.isDirty = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teacherId = Value(teacherId),
       sessionId = Value(sessionId),
       enrollmentId = Value(enrollmentId),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<LocalAttendanceRecord> custom({
    Expression<String>? id,
    Expression<String>? teacherId,
    Expression<String>? sessionId,
    Expression<String>? enrollmentId,
    Expression<String>? status,
    Expression<String>? note,
    Expression<int>? version,
    Expression<bool>? isDirty,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teacherId != null) 'teacher_id': teacherId,
      if (sessionId != null) 'session_id': sessionId,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (version != null) 'version': version,
      if (isDirty != null) 'is_dirty': isDirty,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAttendanceRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? teacherId,
    Value<String>? sessionId,
    Value<String>? enrollmentId,
    Value<String>? status,
    Value<String>? note,
    Value<int>? version,
    Value<bool>? isDirty,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalAttendanceRecordsCompanion(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      sessionId: sessionId ?? this.sessionId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      status: status ?? this.status,
      note: note ?? this.note,
      version: version ?? this.version,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('sessionId: $sessionId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStudentScoresTable extends LocalStudentScores
    with TableInfo<$LocalStudentScoresTable, LocalStudentScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStudentScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherIdMeta = const VerificationMeta(
    'teacherId',
  );
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
    'teacher_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignmentIdMeta = const VerificationMeta(
    'assignmentId',
  );
  @override
  late final GeneratedColumn<String> assignmentId = GeneratedColumn<String>(
    'assignment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enrollmentIdMeta = const VerificationMeta(
    'enrollmentId',
  );
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
    'enrollment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectClassIdMeta = const VerificationMeta(
    'subjectClassId',
  );
  @override
  late final GeneratedColumn<String> subjectClassId = GeneratedColumn<String>(
    'subject_class_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submissionStatusMeta = const VerificationMeta(
    'submissionStatus',
  );
  @override
  late final GeneratedColumn<String> submissionStatus = GeneratedColumn<String>(
    'submission_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('missing'),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teacherId,
    assignmentId,
    enrollmentId,
    subjectClassId,
    submissionStatus,
    score,
    note,
    version,
    isDirty,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_student_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStudentScore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(
        _teacherIdMeta,
        teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    if (data.containsKey('assignment_id')) {
      context.handle(
        _assignmentIdMeta,
        assignmentId.isAcceptableOrUnknown(
          data['assignment_id']!,
          _assignmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assignmentIdMeta);
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
        _enrollmentIdMeta,
        enrollmentId.isAcceptableOrUnknown(
          data['enrollment_id']!,
          _enrollmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enrollmentIdMeta);
    }
    if (data.containsKey('subject_class_id')) {
      context.handle(
        _subjectClassIdMeta,
        subjectClassId.isAcceptableOrUnknown(
          data['subject_class_id']!,
          _subjectClassIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectClassIdMeta);
    }
    if (data.containsKey('submission_status')) {
      context.handle(
        _submissionStatusMeta,
        submissionStatus.isAcceptableOrUnknown(
          data['submission_status']!,
          _submissionStatusMeta,
        ),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {assignmentId, enrollmentId},
  ];
  @override
  LocalStudentScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStudentScore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teacherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_id'],
      )!,
      assignmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignment_id'],
      )!,
      enrollmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrollment_id'],
      )!,
      subjectClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_class_id'],
      )!,
      submissionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_status'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalStudentScoresTable createAlias(String alias) {
    return $LocalStudentScoresTable(attachedDatabase, alias);
  }
}

class LocalStudentScore extends DataClass
    implements Insertable<LocalStudentScore> {
  final String id;
  final String teacherId;
  final String assignmentId;
  final String enrollmentId;
  final String subjectClassId;
  final String submissionStatus;
  final double? score;
  final String note;
  final int version;
  final bool isDirty;
  final DateTime updatedAt;
  const LocalStudentScore({
    required this.id,
    required this.teacherId,
    required this.assignmentId,
    required this.enrollmentId,
    required this.subjectClassId,
    required this.submissionStatus,
    this.score,
    required this.note,
    required this.version,
    required this.isDirty,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['teacher_id'] = Variable<String>(teacherId);
    map['assignment_id'] = Variable<String>(assignmentId);
    map['enrollment_id'] = Variable<String>(enrollmentId);
    map['subject_class_id'] = Variable<String>(subjectClassId);
    map['submission_status'] = Variable<String>(submissionStatus);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    map['note'] = Variable<String>(note);
    map['version'] = Variable<int>(version);
    map['is_dirty'] = Variable<bool>(isDirty);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalStudentScoresCompanion toCompanion(bool nullToAbsent) {
    return LocalStudentScoresCompanion(
      id: Value(id),
      teacherId: Value(teacherId),
      assignmentId: Value(assignmentId),
      enrollmentId: Value(enrollmentId),
      subjectClassId: Value(subjectClassId),
      submissionStatus: Value(submissionStatus),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      note: Value(note),
      version: Value(version),
      isDirty: Value(isDirty),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalStudentScore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStudentScore(
      id: serializer.fromJson<String>(json['id']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
      assignmentId: serializer.fromJson<String>(json['assignmentId']),
      enrollmentId: serializer.fromJson<String>(json['enrollmentId']),
      subjectClassId: serializer.fromJson<String>(json['subjectClassId']),
      submissionStatus: serializer.fromJson<String>(json['submissionStatus']),
      score: serializer.fromJson<double?>(json['score']),
      note: serializer.fromJson<String>(json['note']),
      version: serializer.fromJson<int>(json['version']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teacherId': serializer.toJson<String>(teacherId),
      'assignmentId': serializer.toJson<String>(assignmentId),
      'enrollmentId': serializer.toJson<String>(enrollmentId),
      'subjectClassId': serializer.toJson<String>(subjectClassId),
      'submissionStatus': serializer.toJson<String>(submissionStatus),
      'score': serializer.toJson<double?>(score),
      'note': serializer.toJson<String>(note),
      'version': serializer.toJson<int>(version),
      'isDirty': serializer.toJson<bool>(isDirty),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalStudentScore copyWith({
    String? id,
    String? teacherId,
    String? assignmentId,
    String? enrollmentId,
    String? subjectClassId,
    String? submissionStatus,
    Value<double?> score = const Value.absent(),
    String? note,
    int? version,
    bool? isDirty,
    DateTime? updatedAt,
  }) => LocalStudentScore(
    id: id ?? this.id,
    teacherId: teacherId ?? this.teacherId,
    assignmentId: assignmentId ?? this.assignmentId,
    enrollmentId: enrollmentId ?? this.enrollmentId,
    subjectClassId: subjectClassId ?? this.subjectClassId,
    submissionStatus: submissionStatus ?? this.submissionStatus,
    score: score.present ? score.value : this.score,
    note: note ?? this.note,
    version: version ?? this.version,
    isDirty: isDirty ?? this.isDirty,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalStudentScore copyWithCompanion(LocalStudentScoresCompanion data) {
    return LocalStudentScore(
      id: data.id.present ? data.id.value : this.id,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
      assignmentId: data.assignmentId.present
          ? data.assignmentId.value
          : this.assignmentId,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      subjectClassId: data.subjectClassId.present
          ? data.subjectClassId.value
          : this.subjectClassId,
      submissionStatus: data.submissionStatus.present
          ? data.submissionStatus.value
          : this.submissionStatus,
      score: data.score.present ? data.score.value : this.score,
      note: data.note.present ? data.note.value : this.note,
      version: data.version.present ? data.version.value : this.version,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStudentScore(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('subjectClassId: $subjectClassId, ')
          ..write('submissionStatus: $submissionStatus, ')
          ..write('score: $score, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teacherId,
    assignmentId,
    enrollmentId,
    subjectClassId,
    submissionStatus,
    score,
    note,
    version,
    isDirty,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStudentScore &&
          other.id == this.id &&
          other.teacherId == this.teacherId &&
          other.assignmentId == this.assignmentId &&
          other.enrollmentId == this.enrollmentId &&
          other.subjectClassId == this.subjectClassId &&
          other.submissionStatus == this.submissionStatus &&
          other.score == this.score &&
          other.note == this.note &&
          other.version == this.version &&
          other.isDirty == this.isDirty &&
          other.updatedAt == this.updatedAt);
}

class LocalStudentScoresCompanion extends UpdateCompanion<LocalStudentScore> {
  final Value<String> id;
  final Value<String> teacherId;
  final Value<String> assignmentId;
  final Value<String> enrollmentId;
  final Value<String> subjectClassId;
  final Value<String> submissionStatus;
  final Value<double?> score;
  final Value<String> note;
  final Value<int> version;
  final Value<bool> isDirty;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalStudentScoresCompanion({
    this.id = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.assignmentId = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.subjectClassId = const Value.absent(),
    this.submissionStatus = const Value.absent(),
    this.score = const Value.absent(),
    this.note = const Value.absent(),
    this.version = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStudentScoresCompanion.insert({
    required String id,
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    required String subjectClassId,
    this.submissionStatus = const Value.absent(),
    this.score = const Value.absent(),
    this.note = const Value.absent(),
    this.version = const Value.absent(),
    this.isDirty = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teacherId = Value(teacherId),
       assignmentId = Value(assignmentId),
       enrollmentId = Value(enrollmentId),
       subjectClassId = Value(subjectClassId),
       updatedAt = Value(updatedAt);
  static Insertable<LocalStudentScore> custom({
    Expression<String>? id,
    Expression<String>? teacherId,
    Expression<String>? assignmentId,
    Expression<String>? enrollmentId,
    Expression<String>? subjectClassId,
    Expression<String>? submissionStatus,
    Expression<double>? score,
    Expression<String>? note,
    Expression<int>? version,
    Expression<bool>? isDirty,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teacherId != null) 'teacher_id': teacherId,
      if (assignmentId != null) 'assignment_id': assignmentId,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (subjectClassId != null) 'subject_class_id': subjectClassId,
      if (submissionStatus != null) 'submission_status': submissionStatus,
      if (score != null) 'score': score,
      if (note != null) 'note': note,
      if (version != null) 'version': version,
      if (isDirty != null) 'is_dirty': isDirty,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStudentScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? teacherId,
    Value<String>? assignmentId,
    Value<String>? enrollmentId,
    Value<String>? subjectClassId,
    Value<String>? submissionStatus,
    Value<double?>? score,
    Value<String>? note,
    Value<int>? version,
    Value<bool>? isDirty,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalStudentScoresCompanion(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      assignmentId: assignmentId ?? this.assignmentId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      subjectClassId: subjectClassId ?? this.subjectClassId,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      score: score ?? this.score,
      note: note ?? this.note,
      version: version ?? this.version,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (assignmentId.present) {
      map['assignment_id'] = Variable<String>(assignmentId.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (subjectClassId.present) {
      map['subject_class_id'] = Variable<String>(subjectClassId.value);
    }
    if (submissionStatus.present) {
      map['submission_status'] = Variable<String>(submissionStatus.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStudentScoresCompanion(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('subjectClassId: $subjectClassId, ')
          ..write('submissionStatus: $submissionStatus, ')
          ..write('score: $score, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncQueueTable extends LocalSyncQueue
    with TableInfo<$LocalSyncQueueTable, LocalSyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherIdMeta = const VerificationMeta(
    'teacherId',
  );
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
    'teacher_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayLabelMeta = const VerificationMeta(
    'displayLabel',
  );
  @override
  late final GeneratedColumn<String> displayLabel = GeneratedColumn<String>(
    'display_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedVersionMeta = const VerificationMeta(
    'expectedVersion',
  );
  @override
  late final GeneratedColumn<int> expectedVersion = GeneratedColumn<int>(
    'expected_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSnapshotJsonMeta =
      const VerificationMeta('serverSnapshotJson');
  @override
  late final GeneratedColumn<String> serverSnapshotJson =
      GeneratedColumn<String>(
        'server_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teacherId,
    entityType,
    entityId,
    displayLabel,
    operation,
    payloadJson,
    expectedVersion,
    status,
    retryCount,
    nextRetryAt,
    lastError,
    serverSnapshotJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(
        _teacherIdMeta,
        teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('display_label')) {
      context.handle(
        _displayLabelMeta,
        displayLabel.isAcceptableOrUnknown(
          data['display_label']!,
          _displayLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayLabelMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('expected_version')) {
      context.handle(
        _expectedVersionMeta,
        expectedVersion.isAcceptableOrUnknown(
          data['expected_version']!,
          _expectedVersionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('server_snapshot_json')) {
      context.handle(
        _serverSnapshotJsonMeta,
        serverSnapshotJson.isAcceptableOrUnknown(
          data['server_snapshot_json']!,
          _serverSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teacherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      displayLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_label'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      expectedVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_version'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      serverSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_snapshot_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalSyncQueueTable createAlias(String alias) {
    return $LocalSyncQueueTable(attachedDatabase, alias);
  }
}

class LocalSyncQueueData extends DataClass
    implements Insertable<LocalSyncQueueData> {
  final String id;
  final String teacherId;
  final String entityType;
  final String entityId;
  final String displayLabel;
  final String operation;
  final String payloadJson;
  final int? expectedVersion;
  final String status;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final String? serverSnapshotJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalSyncQueueData({
    required this.id,
    required this.teacherId,
    required this.entityType,
    required this.entityId,
    required this.displayLabel,
    required this.operation,
    required this.payloadJson,
    this.expectedVersion,
    required this.status,
    required this.retryCount,
    this.nextRetryAt,
    this.lastError,
    this.serverSnapshotJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['teacher_id'] = Variable<String>(teacherId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['display_label'] = Variable<String>(displayLabel);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || expectedVersion != null) {
      map['expected_version'] = Variable<int>(expectedVersion);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || serverSnapshotJson != null) {
      map['server_snapshot_json'] = Variable<String>(serverSnapshotJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncQueueCompanion(
      id: Value(id),
      teacherId: Value(teacherId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      displayLabel: Value(displayLabel),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      expectedVersion: expectedVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedVersion),
      status: Value(status),
      retryCount: Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      serverSnapshotJson: serverSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSnapshotJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      displayLabel: serializer.fromJson<String>(json['displayLabel']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      expectedVersion: serializer.fromJson<int?>(json['expectedVersion']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      serverSnapshotJson: serializer.fromJson<String?>(
        json['serverSnapshotJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teacherId': serializer.toJson<String>(teacherId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'displayLabel': serializer.toJson<String>(displayLabel),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'expectedVersion': serializer.toJson<int?>(expectedVersion),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'serverSnapshotJson': serializer.toJson<String?>(serverSnapshotJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSyncQueueData copyWith({
    String? id,
    String? teacherId,
    String? entityType,
    String? entityId,
    String? displayLabel,
    String? operation,
    String? payloadJson,
    Value<int?> expectedVersion = const Value.absent(),
    String? status,
    int? retryCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> serverSnapshotJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalSyncQueueData(
    id: id ?? this.id,
    teacherId: teacherId ?? this.teacherId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    displayLabel: displayLabel ?? this.displayLabel,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    expectedVersion: expectedVersion.present
        ? expectedVersion.value
        : this.expectedVersion,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    serverSnapshotJson: serverSnapshotJson.present
        ? serverSnapshotJson.value
        : this.serverSnapshotJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalSyncQueueData copyWithCompanion(LocalSyncQueueCompanion data) {
    return LocalSyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      displayLabel: data.displayLabel.present
          ? data.displayLabel.value
          : this.displayLabel,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      expectedVersion: data.expectedVersion.present
          ? data.expectedVersion.value
          : this.expectedVersion,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      serverSnapshotJson: data.serverSnapshotJson.present
          ? data.serverSnapshotJson.value
          : this.serverSnapshotJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncQueueData(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('displayLabel: $displayLabel, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('serverSnapshotJson: $serverSnapshotJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teacherId,
    entityType,
    entityId,
    displayLabel,
    operation,
    payloadJson,
    expectedVersion,
    status,
    retryCount,
    nextRetryAt,
    lastError,
    serverSnapshotJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncQueueData &&
          other.id == this.id &&
          other.teacherId == this.teacherId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.displayLabel == this.displayLabel &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.expectedVersion == this.expectedVersion &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.serverSnapshotJson == this.serverSnapshotJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalSyncQueueCompanion extends UpdateCompanion<LocalSyncQueueData> {
  final Value<String> id;
  final Value<String> teacherId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> displayLabel;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<int?> expectedVersion;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastError;
  final Value<String?> serverSnapshotJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSyncQueueCompanion({
    this.id = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.displayLabel = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.expectedVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.serverSnapshotJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncQueueCompanion.insert({
    required String id,
    required String teacherId,
    required String entityType,
    required String entityId,
    required String displayLabel,
    required String operation,
    required String payloadJson,
    this.expectedVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.serverSnapshotJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teacherId = Value(teacherId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       displayLabel = Value(displayLabel),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalSyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? teacherId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? displayLabel,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<int>? expectedVersion,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<String>? serverSnapshotJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teacherId != null) 'teacher_id': teacherId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (displayLabel != null) 'display_label': displayLabel,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (expectedVersion != null) 'expected_version': expectedVersion,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (serverSnapshotJson != null)
        'server_snapshot_json': serverSnapshotJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? teacherId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? displayLabel,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<int?>? expectedVersion,
    Value<String>? status,
    Value<int>? retryCount,
    Value<DateTime?>? nextRetryAt,
    Value<String?>? lastError,
    Value<String?>? serverSnapshotJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalSyncQueueCompanion(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      displayLabel: displayLabel ?? this.displayLabel,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      serverSnapshotJson: serverSnapshotJson ?? this.serverSnapshotJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (displayLabel.present) {
      map['display_label'] = Variable<String>(displayLabel.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (expectedVersion.present) {
      map['expected_version'] = Variable<int>(expectedVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (serverSnapshotJson.present) {
      map['server_snapshot_json'] = Variable<String>(serverSnapshotJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('displayLabel: $displayLabel, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('serverSnapshotJson: $serverSnapshotJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalEntityCachesTable localEntityCaches =
      $LocalEntityCachesTable(this);
  late final $LocalAttendanceSessionsTable localAttendanceSessions =
      $LocalAttendanceSessionsTable(this);
  late final $LocalAttendanceRecordsTable localAttendanceRecords =
      $LocalAttendanceRecordsTable(this);
  late final $LocalStudentScoresTable localStudentScores =
      $LocalStudentScoresTable(this);
  late final $LocalSyncQueueTable localSyncQueue = $LocalSyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localEntityCaches,
    localAttendanceSessions,
    localAttendanceRecords,
    localStudentScores,
    localSyncQueue,
  ];
}

typedef $$LocalEntityCachesTableCreateCompanionBuilder =
    LocalEntityCachesCompanion Function({
      required String cacheKey,
      required String teacherId,
      required String entityGroup,
      required String payloadJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalEntityCachesTableUpdateCompanionBuilder =
    LocalEntityCachesCompanion Function({
      Value<String> cacheKey,
      Value<String> teacherId,
      Value<String> entityGroup,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalEntityCachesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalEntityCachesTable> {
  $$LocalEntityCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityGroup => $composableBuilder(
    column: $table.entityGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEntityCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalEntityCachesTable> {
  $$LocalEntityCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityGroup => $composableBuilder(
    column: $table.entityGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEntityCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalEntityCachesTable> {
  $$LocalEntityCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get teacherId =>
      $composableBuilder(column: $table.teacherId, builder: (column) => column);

  GeneratedColumn<String> get entityGroup => $composableBuilder(
    column: $table.entityGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalEntityCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEntityCachesTable,
          LocalEntityCache,
          $$LocalEntityCachesTableFilterComposer,
          $$LocalEntityCachesTableOrderingComposer,
          $$LocalEntityCachesTableAnnotationComposer,
          $$LocalEntityCachesTableCreateCompanionBuilder,
          $$LocalEntityCachesTableUpdateCompanionBuilder,
          (
            LocalEntityCache,
            BaseReferences<
              _$AppDatabase,
              $LocalEntityCachesTable,
              LocalEntityCache
            >,
          ),
          LocalEntityCache,
          PrefetchHooks Function()
        > {
  $$LocalEntityCachesTableTableManager(
    _$AppDatabase db,
    $LocalEntityCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalEntityCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalEntityCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalEntityCachesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> teacherId = const Value.absent(),
                Value<String> entityGroup = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEntityCachesCompanion(
                cacheKey: cacheKey,
                teacherId: teacherId,
                entityGroup: entityGroup,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String teacherId,
                required String entityGroup,
                required String payloadJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalEntityCachesCompanion.insert(
                cacheKey: cacheKey,
                teacherId: teacherId,
                entityGroup: entityGroup,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalEntityCachesTable, LocalEntityCache>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalEntityCachesTable,
                    LocalEntityCache
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEntityCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEntityCachesTable,
      LocalEntityCache,
      $$LocalEntityCachesTableFilterComposer,
      $$LocalEntityCachesTableOrderingComposer,
      $$LocalEntityCachesTableAnnotationComposer,
      $$LocalEntityCachesTableCreateCompanionBuilder,
      $$LocalEntityCachesTableUpdateCompanionBuilder,
      (
        LocalEntityCache,
        BaseReferences<
          _$AppDatabase,
          $LocalEntityCachesTable,
          LocalEntityCache
        >,
      ),
      LocalEntityCache,
      PrefetchHooks Function()
    >;
typedef $$LocalAttendanceSessionsTableCreateCompanionBuilder =
    LocalAttendanceSessionsCompanion Function({
      required String id,
      required String teacherId,
      required String subjectClassId,
      required String sessionDateIso,
      Value<bool> isLocked,
      Value<String> note,
      Value<int> version,
      Value<bool> isDirty,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalAttendanceSessionsTableUpdateCompanionBuilder =
    LocalAttendanceSessionsCompanion Function({
      Value<String> id,
      Value<String> teacherId,
      Value<String> subjectClassId,
      Value<String> sessionDateIso,
      Value<bool> isLocked,
      Value<String> note,
      Value<int> version,
      Value<bool> isDirty,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalAttendanceSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAttendanceSessionsTable> {
  $$LocalAttendanceSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectClassId => $composableBuilder(
    column: $table.subjectClassId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionDateIso => $composableBuilder(
    column: $table.sessionDateIso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAttendanceSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAttendanceSessionsTable> {
  $$LocalAttendanceSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectClassId => $composableBuilder(
    column: $table.subjectClassId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionDateIso => $composableBuilder(
    column: $table.sessionDateIso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAttendanceSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAttendanceSessionsTable> {
  $$LocalAttendanceSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get teacherId =>
      $composableBuilder(column: $table.teacherId, builder: (column) => column);

  GeneratedColumn<String> get subjectClassId => $composableBuilder(
    column: $table.subjectClassId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionDateIso => $composableBuilder(
    column: $table.sessionDateIso,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalAttendanceSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAttendanceSessionsTable,
          LocalAttendanceSession,
          $$LocalAttendanceSessionsTableFilterComposer,
          $$LocalAttendanceSessionsTableOrderingComposer,
          $$LocalAttendanceSessionsTableAnnotationComposer,
          $$LocalAttendanceSessionsTableCreateCompanionBuilder,
          $$LocalAttendanceSessionsTableUpdateCompanionBuilder,
          (
            LocalAttendanceSession,
            BaseReferences<
              _$AppDatabase,
              $LocalAttendanceSessionsTable,
              LocalAttendanceSession
            >,
          ),
          LocalAttendanceSession,
          PrefetchHooks Function()
        > {
  $$LocalAttendanceSessionsTableTableManager(
    _$AppDatabase db,
    $LocalAttendanceSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAttendanceSessionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalAttendanceSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalAttendanceSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teacherId = const Value.absent(),
                Value<String> subjectClassId = const Value.absent(),
                Value<String> sessionDateIso = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAttendanceSessionsCompanion(
                id: id,
                teacherId: teacherId,
                subjectClassId: subjectClassId,
                sessionDateIso: sessionDateIso,
                isLocked: isLocked,
                note: note,
                version: version,
                isDirty: isDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teacherId,
                required String subjectClassId,
                required String sessionDateIso,
                Value<bool> isLocked = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalAttendanceSessionsCompanion.insert(
                id: id,
                teacherId: teacherId,
                subjectClassId: subjectClassId,
                sessionDateIso: sessionDateIso,
                isLocked: isLocked,
                note: note,
                version: version,
                isDirty: isDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalAttendanceSessionsTable,
                    LocalAttendanceSession
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAttendanceSessionsTable,
                    LocalAttendanceSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAttendanceSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAttendanceSessionsTable,
      LocalAttendanceSession,
      $$LocalAttendanceSessionsTableFilterComposer,
      $$LocalAttendanceSessionsTableOrderingComposer,
      $$LocalAttendanceSessionsTableAnnotationComposer,
      $$LocalAttendanceSessionsTableCreateCompanionBuilder,
      $$LocalAttendanceSessionsTableUpdateCompanionBuilder,
      (
        LocalAttendanceSession,
        BaseReferences<
          _$AppDatabase,
          $LocalAttendanceSessionsTable,
          LocalAttendanceSession
        >,
      ),
      LocalAttendanceSession,
      PrefetchHooks Function()
    >;
typedef $$LocalAttendanceRecordsTableCreateCompanionBuilder =
    LocalAttendanceRecordsCompanion Function({
      required String id,
      required String teacherId,
      required String sessionId,
      required String enrollmentId,
      required String status,
      Value<String> note,
      Value<int> version,
      Value<bool> isDirty,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalAttendanceRecordsTableUpdateCompanionBuilder =
    LocalAttendanceRecordsCompanion Function({
      Value<String> id,
      Value<String> teacherId,
      Value<String> sessionId,
      Value<String> enrollmentId,
      Value<String> status,
      Value<String> note,
      Value<int> version,
      Value<bool> isDirty,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalAttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAttendanceRecordsTable> {
  $$LocalAttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enrollmentId => $composableBuilder(
    column: $table.enrollmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAttendanceRecordsTable> {
  $$LocalAttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
    column: $table.enrollmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAttendanceRecordsTable> {
  $$LocalAttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get teacherId =>
      $composableBuilder(column: $table.teacherId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
    column: $table.enrollmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalAttendanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAttendanceRecordsTable,
          LocalAttendanceRecord,
          $$LocalAttendanceRecordsTableFilterComposer,
          $$LocalAttendanceRecordsTableOrderingComposer,
          $$LocalAttendanceRecordsTableAnnotationComposer,
          $$LocalAttendanceRecordsTableCreateCompanionBuilder,
          $$LocalAttendanceRecordsTableUpdateCompanionBuilder,
          (
            LocalAttendanceRecord,
            BaseReferences<
              _$AppDatabase,
              $LocalAttendanceRecordsTable,
              LocalAttendanceRecord
            >,
          ),
          LocalAttendanceRecord,
          PrefetchHooks Function()
        > {
  $$LocalAttendanceRecordsTableTableManager(
    _$AppDatabase db,
    $LocalAttendanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAttendanceRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalAttendanceRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalAttendanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teacherId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> enrollmentId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAttendanceRecordsCompanion(
                id: id,
                teacherId: teacherId,
                sessionId: sessionId,
                enrollmentId: enrollmentId,
                status: status,
                note: note,
                version: version,
                isDirty: isDirty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teacherId,
                required String sessionId,
                required String enrollmentId,
                required String status,
                Value<String> note = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalAttendanceRecordsCompanion.insert(
                id: id,
                teacherId: teacherId,
                sessionId: sessionId,
                enrollmentId: enrollmentId,
                status: status,
                note: note,
                version: version,
                isDirty: isDirty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalAttendanceRecordsTable,
                    LocalAttendanceRecord
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAttendanceRecordsTable,
                    LocalAttendanceRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAttendanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAttendanceRecordsTable,
      LocalAttendanceRecord,
      $$LocalAttendanceRecordsTableFilterComposer,
      $$LocalAttendanceRecordsTableOrderingComposer,
      $$LocalAttendanceRecordsTableAnnotationComposer,
      $$LocalAttendanceRecordsTableCreateCompanionBuilder,
      $$LocalAttendanceRecordsTableUpdateCompanionBuilder,
      (
        LocalAttendanceRecord,
        BaseReferences<
          _$AppDatabase,
          $LocalAttendanceRecordsTable,
          LocalAttendanceRecord
        >,
      ),
      LocalAttendanceRecord,
      PrefetchHooks Function()
    >;
typedef $$LocalStudentScoresTableCreateCompanionBuilder =
    LocalStudentScoresCompanion Function({
      required String id,
      required String teacherId,
      required String assignmentId,
      required String enrollmentId,
      required String subjectClassId,
      Value<String> submissionStatus,
      Value<double?> score,
      Value<String> note,
      Value<int> version,
      Value<bool> isDirty,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalStudentScoresTableUpdateCompanionBuilder =
    LocalStudentScoresCompanion Function({
      Value<String> id,
      Value<String> teacherId,
      Value<String> assignmentId,
      Value<String> enrollmentId,
      Value<String> subjectClassId,
      Value<String> submissionStatus,
      Value<double?> score,
      Value<String> note,
      Value<int> version,
      Value<bool> isDirty,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalStudentScoresTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStudentScoresTable> {
  $$LocalStudentScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enrollmentId => $composableBuilder(
    column: $table.enrollmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectClassId => $composableBuilder(
    column: $table.subjectClassId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submissionStatus => $composableBuilder(
    column: $table.submissionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStudentScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStudentScoresTable> {
  $$LocalStudentScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
    column: $table.enrollmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectClassId => $composableBuilder(
    column: $table.subjectClassId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submissionStatus => $composableBuilder(
    column: $table.submissionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStudentScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStudentScoresTable> {
  $$LocalStudentScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get teacherId =>
      $composableBuilder(column: $table.teacherId, builder: (column) => column);

  GeneratedColumn<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
    column: $table.enrollmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectClassId => $composableBuilder(
    column: $table.subjectClassId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get submissionStatus => $composableBuilder(
    column: $table.submissionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalStudentScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStudentScoresTable,
          LocalStudentScore,
          $$LocalStudentScoresTableFilterComposer,
          $$LocalStudentScoresTableOrderingComposer,
          $$LocalStudentScoresTableAnnotationComposer,
          $$LocalStudentScoresTableCreateCompanionBuilder,
          $$LocalStudentScoresTableUpdateCompanionBuilder,
          (
            LocalStudentScore,
            BaseReferences<
              _$AppDatabase,
              $LocalStudentScoresTable,
              LocalStudentScore
            >,
          ),
          LocalStudentScore,
          PrefetchHooks Function()
        > {
  $$LocalStudentScoresTableTableManager(
    _$AppDatabase db,
    $LocalStudentScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStudentScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStudentScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStudentScoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teacherId = const Value.absent(),
                Value<String> assignmentId = const Value.absent(),
                Value<String> enrollmentId = const Value.absent(),
                Value<String> subjectClassId = const Value.absent(),
                Value<String> submissionStatus = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStudentScoresCompanion(
                id: id,
                teacherId: teacherId,
                assignmentId: assignmentId,
                enrollmentId: enrollmentId,
                subjectClassId: subjectClassId,
                submissionStatus: submissionStatus,
                score: score,
                note: note,
                version: version,
                isDirty: isDirty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teacherId,
                required String assignmentId,
                required String enrollmentId,
                required String subjectClassId,
                Value<String> submissionStatus = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalStudentScoresCompanion.insert(
                id: id,
                teacherId: teacherId,
                assignmentId: assignmentId,
                enrollmentId: enrollmentId,
                subjectClassId: subjectClassId,
                submissionStatus: submissionStatus,
                score: score,
                note: note,
                version: version,
                isDirty: isDirty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalStudentScoresTable, LocalStudentScore>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalStudentScoresTable,
                    LocalStudentScore
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStudentScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStudentScoresTable,
      LocalStudentScore,
      $$LocalStudentScoresTableFilterComposer,
      $$LocalStudentScoresTableOrderingComposer,
      $$LocalStudentScoresTableAnnotationComposer,
      $$LocalStudentScoresTableCreateCompanionBuilder,
      $$LocalStudentScoresTableUpdateCompanionBuilder,
      (
        LocalStudentScore,
        BaseReferences<
          _$AppDatabase,
          $LocalStudentScoresTable,
          LocalStudentScore
        >,
      ),
      LocalStudentScore,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncQueueTableCreateCompanionBuilder =
    LocalSyncQueueCompanion Function({
      required String id,
      required String teacherId,
      required String entityType,
      required String entityId,
      required String displayLabel,
      required String operation,
      required String payloadJson,
      Value<int?> expectedVersion,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> serverSnapshotJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalSyncQueueTableUpdateCompanionBuilder =
    LocalSyncQueueCompanion Function({
      Value<String> id,
      Value<String> teacherId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> displayLabel,
      Value<String> operation,
      Value<String> payloadJson,
      Value<int?> expectedVersion,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> serverSnapshotJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalSyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayLabel => $composableBuilder(
    column: $table.displayLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherId => $composableBuilder(
    column: $table.teacherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayLabel => $composableBuilder(
    column: $table.displayLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get teacherId =>
      $composableBuilder(column: $table.teacherId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get displayLabel => $composableBuilder(
    column: $table.displayLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSyncQueueTable,
          LocalSyncQueueData,
          $$LocalSyncQueueTableFilterComposer,
          $$LocalSyncQueueTableOrderingComposer,
          $$LocalSyncQueueTableAnnotationComposer,
          $$LocalSyncQueueTableCreateCompanionBuilder,
          $$LocalSyncQueueTableUpdateCompanionBuilder,
          (
            LocalSyncQueueData,
            BaseReferences<
              _$AppDatabase,
              $LocalSyncQueueTable,
              LocalSyncQueueData
            >,
          ),
          LocalSyncQueueData,
          PrefetchHooks Function()
        > {
  $$LocalSyncQueueTableTableManager(
    _$AppDatabase db,
    $LocalSyncQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teacherId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> displayLabel = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int?> expectedVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> serverSnapshotJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncQueueCompanion(
                id: id,
                teacherId: teacherId,
                entityType: entityType,
                entityId: entityId,
                displayLabel: displayLabel,
                operation: operation,
                payloadJson: payloadJson,
                expectedVersion: expectedVersion,
                status: status,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                serverSnapshotJson: serverSnapshotJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teacherId,
                required String entityType,
                required String entityId,
                required String displayLabel,
                required String operation,
                required String payloadJson,
                Value<int?> expectedVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> serverSnapshotJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncQueueCompanion.insert(
                id: id,
                teacherId: teacherId,
                entityType: entityType,
                entityId: entityId,
                displayLabel: displayLabel,
                operation: operation,
                payloadJson: payloadJson,
                expectedVersion: expectedVersion,
                status: status,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                serverSnapshotJson: serverSnapshotJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSyncQueueTable, LocalSyncQueueData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSyncQueueTable,
                    LocalSyncQueueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSyncQueueTable,
      LocalSyncQueueData,
      $$LocalSyncQueueTableFilterComposer,
      $$LocalSyncQueueTableOrderingComposer,
      $$LocalSyncQueueTableAnnotationComposer,
      $$LocalSyncQueueTableCreateCompanionBuilder,
      $$LocalSyncQueueTableUpdateCompanionBuilder,
      (
        LocalSyncQueueData,
        BaseReferences<_$AppDatabase, $LocalSyncQueueTable, LocalSyncQueueData>,
      ),
      LocalSyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalEntityCachesTableTableManager get localEntityCaches =>
      $$LocalEntityCachesTableTableManager(_db, _db.localEntityCaches);
  $$LocalAttendanceSessionsTableTableManager get localAttendanceSessions =>
      $$LocalAttendanceSessionsTableTableManager(
        _db,
        _db.localAttendanceSessions,
      );
  $$LocalAttendanceRecordsTableTableManager get localAttendanceRecords =>
      $$LocalAttendanceRecordsTableTableManager(
        _db,
        _db.localAttendanceRecords,
      );
  $$LocalStudentScoresTableTableManager get localStudentScores =>
      $$LocalStudentScoresTableTableManager(_db, _db.localStudentScores);
  $$LocalSyncQueueTableTableManager get localSyncQueue =>
      $$LocalSyncQueueTableTableManager(_db, _db.localSyncQueue);
}
