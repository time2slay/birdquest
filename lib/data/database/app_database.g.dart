// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDemoMeta = const VerificationMeta('isDemo');
  @override
  late final GeneratedColumn<bool> isDemo = GeneratedColumn<bool>(
    'is_demo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_demo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    latitude,
    longitude,
    isDemo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('is_demo')) {
      context.handle(
        _isDemoMeta,
        isDemo.isAcceptableOrUnknown(data['is_demo']!, _isDemoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      isDemo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_demo'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? latitude;
  final double? longitude;

  /// True when the session ran on the simulated demo recognizer.
  final bool isDemo;
  const SessionRow({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.latitude,
    this.longitude,
    required this.isDemo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['is_demo'] = Variable<bool>(isDemo);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      isDemo: Value(isDemo),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      isDemo: serializer.fromJson<bool>(json['isDemo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'isDemo': serializer.toJson<bool>(isDemo),
    };
  }

  SessionRow copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    bool? isDemo,
  }) => SessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    isDemo: isDemo ?? this.isDemo,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isDemo: data.isDemo.present ? data.isDemo.value : this.isDemo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isDemo: $isDemo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startedAt, endedAt, latitude, longitude, isDemo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isDemo == this.isDemo);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<bool> isDemo;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isDemo = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isDemo = const Value.absent(),
  }) : startedAt = Value(startedAt);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? isDemo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isDemo != null) 'is_demo': isDemo,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<bool>? isDemo,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (isDemo.present) {
      map['is_demo'] = Variable<bool>(isDemo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isDemo: $isDemo')
          ..write(')'))
        .toString();
  }
}

class $SightingsTable extends Sightings
    with TableInfo<$SightingsTable, SightingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SightingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _speciesIdMeta = const VerificationMeta(
    'speciesId',
  );
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
    'species_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES species (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userNotesMeta = const VerificationMeta(
    'userNotes',
  );
  @override
  late final GeneratedColumn<String> userNotes = GeneratedColumn<String>(
    'user_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelScoreMeta = const VerificationMeta(
    'modelScore',
  );
  @override
  late final GeneratedColumn<double> modelScore = GeneratedColumn<double>(
    'model_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioClipPathMeta = const VerificationMeta(
    'audioClipPath',
  );
  @override
  late final GeneratedColumn<String> audioClipPath = GeneratedColumn<String>(
    'audio_clip_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDemoMeta = const VerificationMeta('isDemo');
  @override
  late final GeneratedColumn<bool> isDemo = GeneratedColumn<bool>(
    'is_demo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_demo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
    'rarity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    speciesId,
    sessionId,
    confirmedAt,
    latitude,
    longitude,
    userNotes,
    modelScore,
    audioClipPath,
    isDemo,
    rarity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sightings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SightingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('species_id')) {
      context.handle(
        _speciesIdMeta,
        speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confirmedAtMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('user_notes')) {
      context.handle(
        _userNotesMeta,
        userNotes.isAcceptableOrUnknown(data['user_notes']!, _userNotesMeta),
      );
    }
    if (data.containsKey('model_score')) {
      context.handle(
        _modelScoreMeta,
        modelScore.isAcceptableOrUnknown(data['model_score']!, _modelScoreMeta),
      );
    }
    if (data.containsKey('audio_clip_path')) {
      context.handle(
        _audioClipPathMeta,
        audioClipPath.isAcceptableOrUnknown(
          data['audio_clip_path']!,
          _audioClipPathMeta,
        ),
      );
    }
    if (data.containsKey('is_demo')) {
      context.handle(
        _isDemoMeta,
        isDemo.isAcceptableOrUnknown(data['is_demo']!, _isDemoMeta),
      );
    }
    if (data.containsKey('rarity')) {
      context.handle(
        _rarityMeta,
        rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SightingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SightingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      speciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}species_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      userNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_notes'],
      ),
      modelScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}model_score'],
      ),
      audioClipPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_clip_path'],
      ),
      isDemo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_demo'],
      )!,
      rarity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rarity'],
      ),
    );
  }

  @override
  $SightingsTable createAlias(String alias) {
    return $SightingsTable(attachedDatabase, alias);
  }
}

class SightingRow extends DataClass implements Insertable<SightingRow> {
  final int id;
  final int speciesId;
  final int? sessionId;
  final DateTime confirmedAt;
  final double? latitude;
  final double? longitude;
  final String? userNotes;

  /// Best model score among the detections the user confirmed.
  final double? modelScore;

  /// Path (relative to the app media root) of the saved sound clip.
  final String? audioClipPath;
  final bool isDemo;

  /// How rare the species is where it was found ('common', 'uncommon',
  /// 'rare', 'legendary'), fixed when saved so XP never changes later.
  /// Null when it could not be determined (no location or geo model).
  final String? rarity;
  const SightingRow({
    required this.id,
    required this.speciesId,
    this.sessionId,
    required this.confirmedAt,
    this.latitude,
    this.longitude,
    this.userNotes,
    this.modelScore,
    this.audioClipPath,
    required this.isDemo,
    this.rarity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['species_id'] = Variable<int>(speciesId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || userNotes != null) {
      map['user_notes'] = Variable<String>(userNotes);
    }
    if (!nullToAbsent || modelScore != null) {
      map['model_score'] = Variable<double>(modelScore);
    }
    if (!nullToAbsent || audioClipPath != null) {
      map['audio_clip_path'] = Variable<String>(audioClipPath);
    }
    map['is_demo'] = Variable<bool>(isDemo);
    if (!nullToAbsent || rarity != null) {
      map['rarity'] = Variable<String>(rarity);
    }
    return map;
  }

  SightingsCompanion toCompanion(bool nullToAbsent) {
    return SightingsCompanion(
      id: Value(id),
      speciesId: Value(speciesId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      confirmedAt: Value(confirmedAt),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      userNotes: userNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(userNotes),
      modelScore: modelScore == null && nullToAbsent
          ? const Value.absent()
          : Value(modelScore),
      audioClipPath: audioClipPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioClipPath),
      isDemo: Value(isDemo),
      rarity: rarity == null && nullToAbsent
          ? const Value.absent()
          : Value(rarity),
    );
  }

  factory SightingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SightingRow(
      id: serializer.fromJson<int>(json['id']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      confirmedAt: serializer.fromJson<DateTime>(json['confirmedAt']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      userNotes: serializer.fromJson<String?>(json['userNotes']),
      modelScore: serializer.fromJson<double?>(json['modelScore']),
      audioClipPath: serializer.fromJson<String?>(json['audioClipPath']),
      isDemo: serializer.fromJson<bool>(json['isDemo']),
      rarity: serializer.fromJson<String?>(json['rarity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'speciesId': serializer.toJson<int>(speciesId),
      'sessionId': serializer.toJson<int?>(sessionId),
      'confirmedAt': serializer.toJson<DateTime>(confirmedAt),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'userNotes': serializer.toJson<String?>(userNotes),
      'modelScore': serializer.toJson<double?>(modelScore),
      'audioClipPath': serializer.toJson<String?>(audioClipPath),
      'isDemo': serializer.toJson<bool>(isDemo),
      'rarity': serializer.toJson<String?>(rarity),
    };
  }

  SightingRow copyWith({
    int? id,
    int? speciesId,
    Value<int?> sessionId = const Value.absent(),
    DateTime? confirmedAt,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> userNotes = const Value.absent(),
    Value<double?> modelScore = const Value.absent(),
    Value<String?> audioClipPath = const Value.absent(),
    bool? isDemo,
    Value<String?> rarity = const Value.absent(),
  }) => SightingRow(
    id: id ?? this.id,
    speciesId: speciesId ?? this.speciesId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    userNotes: userNotes.present ? userNotes.value : this.userNotes,
    modelScore: modelScore.present ? modelScore.value : this.modelScore,
    audioClipPath: audioClipPath.present
        ? audioClipPath.value
        : this.audioClipPath,
    isDemo: isDemo ?? this.isDemo,
    rarity: rarity.present ? rarity.value : this.rarity,
  );
  SightingRow copyWithCompanion(SightingsCompanion data) {
    return SightingRow(
      id: data.id.present ? data.id.value : this.id,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      userNotes: data.userNotes.present ? data.userNotes.value : this.userNotes,
      modelScore: data.modelScore.present
          ? data.modelScore.value
          : this.modelScore,
      audioClipPath: data.audioClipPath.present
          ? data.audioClipPath.value
          : this.audioClipPath,
      isDemo: data.isDemo.present ? data.isDemo.value : this.isDemo,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SightingRow(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('sessionId: $sessionId, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('userNotes: $userNotes, ')
          ..write('modelScore: $modelScore, ')
          ..write('audioClipPath: $audioClipPath, ')
          ..write('isDemo: $isDemo, ')
          ..write('rarity: $rarity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    speciesId,
    sessionId,
    confirmedAt,
    latitude,
    longitude,
    userNotes,
    modelScore,
    audioClipPath,
    isDemo,
    rarity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SightingRow &&
          other.id == this.id &&
          other.speciesId == this.speciesId &&
          other.sessionId == this.sessionId &&
          other.confirmedAt == this.confirmedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.userNotes == this.userNotes &&
          other.modelScore == this.modelScore &&
          other.audioClipPath == this.audioClipPath &&
          other.isDemo == this.isDemo &&
          other.rarity == this.rarity);
}

class SightingsCompanion extends UpdateCompanion<SightingRow> {
  final Value<int> id;
  final Value<int> speciesId;
  final Value<int?> sessionId;
  final Value<DateTime> confirmedAt;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> userNotes;
  final Value<double?> modelScore;
  final Value<String?> audioClipPath;
  final Value<bool> isDemo;
  final Value<String?> rarity;
  const SightingsCompanion({
    this.id = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.modelScore = const Value.absent(),
    this.audioClipPath = const Value.absent(),
    this.isDemo = const Value.absent(),
    this.rarity = const Value.absent(),
  });
  SightingsCompanion.insert({
    this.id = const Value.absent(),
    required int speciesId,
    this.sessionId = const Value.absent(),
    required DateTime confirmedAt,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.modelScore = const Value.absent(),
    this.audioClipPath = const Value.absent(),
    this.isDemo = const Value.absent(),
    this.rarity = const Value.absent(),
  }) : speciesId = Value(speciesId),
       confirmedAt = Value(confirmedAt);
  static Insertable<SightingRow> custom({
    Expression<int>? id,
    Expression<int>? speciesId,
    Expression<int>? sessionId,
    Expression<DateTime>? confirmedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? userNotes,
    Expression<double>? modelScore,
    Expression<String>? audioClipPath,
    Expression<bool>? isDemo,
    Expression<String>? rarity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (speciesId != null) 'species_id': speciesId,
      if (sessionId != null) 'session_id': sessionId,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (userNotes != null) 'user_notes': userNotes,
      if (modelScore != null) 'model_score': modelScore,
      if (audioClipPath != null) 'audio_clip_path': audioClipPath,
      if (isDemo != null) 'is_demo': isDemo,
      if (rarity != null) 'rarity': rarity,
    });
  }

  SightingsCompanion copyWith({
    Value<int>? id,
    Value<int>? speciesId,
    Value<int?>? sessionId,
    Value<DateTime>? confirmedAt,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? userNotes,
    Value<double?>? modelScore,
    Value<String?>? audioClipPath,
    Value<bool>? isDemo,
    Value<String?>? rarity,
  }) {
    return SightingsCompanion(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      sessionId: sessionId ?? this.sessionId,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userNotes: userNotes ?? this.userNotes,
      modelScore: modelScore ?? this.modelScore,
      audioClipPath: audioClipPath ?? this.audioClipPath,
      isDemo: isDemo ?? this.isDemo,
      rarity: rarity ?? this.rarity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (userNotes.present) {
      map['user_notes'] = Variable<String>(userNotes.value);
    }
    if (modelScore.present) {
      map['model_score'] = Variable<double>(modelScore.value);
    }
    if (audioClipPath.present) {
      map['audio_clip_path'] = Variable<String>(audioClipPath.value);
    }
    if (isDemo.present) {
      map['is_demo'] = Variable<bool>(isDemo.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SightingsCompanion(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('sessionId: $sessionId, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('userNotes: $userNotes, ')
          ..write('modelScore: $modelScore, ')
          ..write('audioClipPath: $audioClipPath, ')
          ..write('isDemo: $isDemo, ')
          ..write('rarity: $rarity')
          ..write(')'))
        .toString();
  }
}

class $SightingPhotosTable extends SightingPhotos
    with TableInfo<$SightingPhotosTable, SightingPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SightingPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sightingIdMeta = const VerificationMeta(
    'sightingId',
  );
  @override
  late final GeneratedColumn<int> sightingId = GeneratedColumn<int>(
    'sighting_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sightings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sightingId,
    localFilePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sighting_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<SightingPhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sighting_id')) {
      context.handle(
        _sightingIdMeta,
        sightingId.isAcceptableOrUnknown(data['sighting_id']!, _sightingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sightingIdMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SightingPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SightingPhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sightingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sighting_id'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SightingPhotosTable createAlias(String alias) {
    return $SightingPhotosTable(attachedDatabase, alias);
  }
}

class SightingPhotoRow extends DataClass
    implements Insertable<SightingPhotoRow> {
  final int id;
  final int sightingId;

  /// Path relative to the app media root.
  final String localFilePath;
  final DateTime createdAt;
  const SightingPhotoRow({
    required this.id,
    required this.sightingId,
    required this.localFilePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sighting_id'] = Variable<int>(sightingId);
    map['local_file_path'] = Variable<String>(localFilePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SightingPhotosCompanion toCompanion(bool nullToAbsent) {
    return SightingPhotosCompanion(
      id: Value(id),
      sightingId: Value(sightingId),
      localFilePath: Value(localFilePath),
      createdAt: Value(createdAt),
    );
  }

  factory SightingPhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SightingPhotoRow(
      id: serializer.fromJson<int>(json['id']),
      sightingId: serializer.fromJson<int>(json['sightingId']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sightingId': serializer.toJson<int>(sightingId),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SightingPhotoRow copyWith({
    int? id,
    int? sightingId,
    String? localFilePath,
    DateTime? createdAt,
  }) => SightingPhotoRow(
    id: id ?? this.id,
    sightingId: sightingId ?? this.sightingId,
    localFilePath: localFilePath ?? this.localFilePath,
    createdAt: createdAt ?? this.createdAt,
  );
  SightingPhotoRow copyWithCompanion(SightingPhotosCompanion data) {
    return SightingPhotoRow(
      id: data.id.present ? data.id.value : this.id,
      sightingId: data.sightingId.present
          ? data.sightingId.value
          : this.sightingId,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SightingPhotoRow(')
          ..write('id: $id, ')
          ..write('sightingId: $sightingId, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sightingId, localFilePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SightingPhotoRow &&
          other.id == this.id &&
          other.sightingId == this.sightingId &&
          other.localFilePath == this.localFilePath &&
          other.createdAt == this.createdAt);
}

class SightingPhotosCompanion extends UpdateCompanion<SightingPhotoRow> {
  final Value<int> id;
  final Value<int> sightingId;
  final Value<String> localFilePath;
  final Value<DateTime> createdAt;
  const SightingPhotosCompanion({
    this.id = const Value.absent(),
    this.sightingId = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SightingPhotosCompanion.insert({
    this.id = const Value.absent(),
    required int sightingId,
    required String localFilePath,
    required DateTime createdAt,
  }) : sightingId = Value(sightingId),
       localFilePath = Value(localFilePath),
       createdAt = Value(createdAt);
  static Insertable<SightingPhotoRow> custom({
    Expression<int>? id,
    Expression<int>? sightingId,
    Expression<String>? localFilePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sightingId != null) 'sighting_id': sightingId,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SightingPhotosCompanion copyWith({
    Value<int>? id,
    Value<int>? sightingId,
    Value<String>? localFilePath,
    Value<DateTime>? createdAt,
  }) {
    return SightingPhotosCompanion(
      id: id ?? this.id,
      sightingId: sightingId ?? this.sightingId,
      localFilePath: localFilePath ?? this.localFilePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sightingId.present) {
      map['sighting_id'] = Variable<int>(sightingId.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SightingPhotosCompanion(')
          ..write('id: $id, ')
          ..write('sightingId: $sightingId, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SpeciesTable extends Species with TableInfo<$SpeciesTable, SpeciesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scientificNameMeta = const VerificationMeta(
    'scientificName',
  );
  @override
  late final GeneratedColumn<String> scientificName = GeneratedColumn<String>(
    'scientific_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _commonNameMeta = const VerificationMeta(
    'commonName',
  );
  @override
  late final GeneratedColumn<String> commonName = GeneratedColumn<String>(
    'common_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceImageMeta = const VerificationMeta(
    'referenceImage',
  );
  @override
  late final GeneratedColumn<String> referenceImage = GeneratedColumn<String>(
    'reference_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxonOrderMeta = const VerificationMeta(
    'taxonOrder',
  );
  @override
  late final GeneratedColumn<String> taxonOrder = GeneratedColumn<String>(
    'taxon_order',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelLabelIdMeta = const VerificationMeta(
    'modelLabelId',
  );
  @override
  late final GeneratedColumn<String> modelLabelId = GeneratedColumn<String>(
    'model_label_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverPhotoIdMeta = const VerificationMeta(
    'coverPhotoId',
  );
  @override
  late final GeneratedColumn<int> coverPhotoId = GeneratedColumn<int>(
    'cover_photo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sighting_photos (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scientificName,
    commonName,
    description,
    referenceImage,
    taxonOrder,
    modelLabelId,
    coverPhotoId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'species';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpeciesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scientific_name')) {
      context.handle(
        _scientificNameMeta,
        scientificName.isAcceptableOrUnknown(
          data['scientific_name']!,
          _scientificNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scientificNameMeta);
    }
    if (data.containsKey('common_name')) {
      context.handle(
        _commonNameMeta,
        commonName.isAcceptableOrUnknown(data['common_name']!, _commonNameMeta),
      );
    } else if (isInserting) {
      context.missing(_commonNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('reference_image')) {
      context.handle(
        _referenceImageMeta,
        referenceImage.isAcceptableOrUnknown(
          data['reference_image']!,
          _referenceImageMeta,
        ),
      );
    }
    if (data.containsKey('taxon_order')) {
      context.handle(
        _taxonOrderMeta,
        taxonOrder.isAcceptableOrUnknown(data['taxon_order']!, _taxonOrderMeta),
      );
    }
    if (data.containsKey('model_label_id')) {
      context.handle(
        _modelLabelIdMeta,
        modelLabelId.isAcceptableOrUnknown(
          data['model_label_id']!,
          _modelLabelIdMeta,
        ),
      );
    }
    if (data.containsKey('cover_photo_id')) {
      context.handle(
        _coverPhotoIdMeta,
        coverPhotoId.isAcceptableOrUnknown(
          data['cover_photo_id']!,
          _coverPhotoIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpeciesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeciesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scientificName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scientific_name'],
      )!,
      commonName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}common_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      referenceImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_image'],
      ),
      taxonOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_order'],
      ),
      modelLabelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_label_id'],
      ),
      coverPhotoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_photo_id'],
      ),
    );
  }

  @override
  $SpeciesTable createAlias(String alias) {
    return $SpeciesTable(attachedDatabase, alias);
  }
}

class SpeciesRow extends DataClass implements Insertable<SpeciesRow> {
  final int id;
  final String scientificName;
  final String commonName;
  final String? description;

  /// Asset path or URL of a licensed reference image. Null means the UI shows
  /// a labeled placeholder illustration.
  final String? referenceImage;

  /// Taxonomic order, e.g. "Passeriformes".
  final String? taxonOrder;

  /// Stable species id from the recognition model's label file.
  final String? modelLabelId;

  /// User-chosen cover photo for the collection card.
  final int? coverPhotoId;
  const SpeciesRow({
    required this.id,
    required this.scientificName,
    required this.commonName,
    this.description,
    this.referenceImage,
    this.taxonOrder,
    this.modelLabelId,
    this.coverPhotoId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scientific_name'] = Variable<String>(scientificName);
    map['common_name'] = Variable<String>(commonName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || referenceImage != null) {
      map['reference_image'] = Variable<String>(referenceImage);
    }
    if (!nullToAbsent || taxonOrder != null) {
      map['taxon_order'] = Variable<String>(taxonOrder);
    }
    if (!nullToAbsent || modelLabelId != null) {
      map['model_label_id'] = Variable<String>(modelLabelId);
    }
    if (!nullToAbsent || coverPhotoId != null) {
      map['cover_photo_id'] = Variable<int>(coverPhotoId);
    }
    return map;
  }

  SpeciesCompanion toCompanion(bool nullToAbsent) {
    return SpeciesCompanion(
      id: Value(id),
      scientificName: Value(scientificName),
      commonName: Value(commonName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      referenceImage: referenceImage == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceImage),
      taxonOrder: taxonOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(taxonOrder),
      modelLabelId: modelLabelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelLabelId),
      coverPhotoId: coverPhotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPhotoId),
    );
  }

  factory SpeciesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeciesRow(
      id: serializer.fromJson<int>(json['id']),
      scientificName: serializer.fromJson<String>(json['scientificName']),
      commonName: serializer.fromJson<String>(json['commonName']),
      description: serializer.fromJson<String?>(json['description']),
      referenceImage: serializer.fromJson<String?>(json['referenceImage']),
      taxonOrder: serializer.fromJson<String?>(json['taxonOrder']),
      modelLabelId: serializer.fromJson<String?>(json['modelLabelId']),
      coverPhotoId: serializer.fromJson<int?>(json['coverPhotoId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scientificName': serializer.toJson<String>(scientificName),
      'commonName': serializer.toJson<String>(commonName),
      'description': serializer.toJson<String?>(description),
      'referenceImage': serializer.toJson<String?>(referenceImage),
      'taxonOrder': serializer.toJson<String?>(taxonOrder),
      'modelLabelId': serializer.toJson<String?>(modelLabelId),
      'coverPhotoId': serializer.toJson<int?>(coverPhotoId),
    };
  }

  SpeciesRow copyWith({
    int? id,
    String? scientificName,
    String? commonName,
    Value<String?> description = const Value.absent(),
    Value<String?> referenceImage = const Value.absent(),
    Value<String?> taxonOrder = const Value.absent(),
    Value<String?> modelLabelId = const Value.absent(),
    Value<int?> coverPhotoId = const Value.absent(),
  }) => SpeciesRow(
    id: id ?? this.id,
    scientificName: scientificName ?? this.scientificName,
    commonName: commonName ?? this.commonName,
    description: description.present ? description.value : this.description,
    referenceImage: referenceImage.present
        ? referenceImage.value
        : this.referenceImage,
    taxonOrder: taxonOrder.present ? taxonOrder.value : this.taxonOrder,
    modelLabelId: modelLabelId.present ? modelLabelId.value : this.modelLabelId,
    coverPhotoId: coverPhotoId.present ? coverPhotoId.value : this.coverPhotoId,
  );
  SpeciesRow copyWithCompanion(SpeciesCompanion data) {
    return SpeciesRow(
      id: data.id.present ? data.id.value : this.id,
      scientificName: data.scientificName.present
          ? data.scientificName.value
          : this.scientificName,
      commonName: data.commonName.present
          ? data.commonName.value
          : this.commonName,
      description: data.description.present
          ? data.description.value
          : this.description,
      referenceImage: data.referenceImage.present
          ? data.referenceImage.value
          : this.referenceImage,
      taxonOrder: data.taxonOrder.present
          ? data.taxonOrder.value
          : this.taxonOrder,
      modelLabelId: data.modelLabelId.present
          ? data.modelLabelId.value
          : this.modelLabelId,
      coverPhotoId: data.coverPhotoId.present
          ? data.coverPhotoId.value
          : this.coverPhotoId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesRow(')
          ..write('id: $id, ')
          ..write('scientificName: $scientificName, ')
          ..write('commonName: $commonName, ')
          ..write('description: $description, ')
          ..write('referenceImage: $referenceImage, ')
          ..write('taxonOrder: $taxonOrder, ')
          ..write('modelLabelId: $modelLabelId, ')
          ..write('coverPhotoId: $coverPhotoId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scientificName,
    commonName,
    description,
    referenceImage,
    taxonOrder,
    modelLabelId,
    coverPhotoId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeciesRow &&
          other.id == this.id &&
          other.scientificName == this.scientificName &&
          other.commonName == this.commonName &&
          other.description == this.description &&
          other.referenceImage == this.referenceImage &&
          other.taxonOrder == this.taxonOrder &&
          other.modelLabelId == this.modelLabelId &&
          other.coverPhotoId == this.coverPhotoId);
}

class SpeciesCompanion extends UpdateCompanion<SpeciesRow> {
  final Value<int> id;
  final Value<String> scientificName;
  final Value<String> commonName;
  final Value<String?> description;
  final Value<String?> referenceImage;
  final Value<String?> taxonOrder;
  final Value<String?> modelLabelId;
  final Value<int?> coverPhotoId;
  const SpeciesCompanion({
    this.id = const Value.absent(),
    this.scientificName = const Value.absent(),
    this.commonName = const Value.absent(),
    this.description = const Value.absent(),
    this.referenceImage = const Value.absent(),
    this.taxonOrder = const Value.absent(),
    this.modelLabelId = const Value.absent(),
    this.coverPhotoId = const Value.absent(),
  });
  SpeciesCompanion.insert({
    this.id = const Value.absent(),
    required String scientificName,
    required String commonName,
    this.description = const Value.absent(),
    this.referenceImage = const Value.absent(),
    this.taxonOrder = const Value.absent(),
    this.modelLabelId = const Value.absent(),
    this.coverPhotoId = const Value.absent(),
  }) : scientificName = Value(scientificName),
       commonName = Value(commonName);
  static Insertable<SpeciesRow> custom({
    Expression<int>? id,
    Expression<String>? scientificName,
    Expression<String>? commonName,
    Expression<String>? description,
    Expression<String>? referenceImage,
    Expression<String>? taxonOrder,
    Expression<String>? modelLabelId,
    Expression<int>? coverPhotoId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scientificName != null) 'scientific_name': scientificName,
      if (commonName != null) 'common_name': commonName,
      if (description != null) 'description': description,
      if (referenceImage != null) 'reference_image': referenceImage,
      if (taxonOrder != null) 'taxon_order': taxonOrder,
      if (modelLabelId != null) 'model_label_id': modelLabelId,
      if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
    });
  }

  SpeciesCompanion copyWith({
    Value<int>? id,
    Value<String>? scientificName,
    Value<String>? commonName,
    Value<String?>? description,
    Value<String?>? referenceImage,
    Value<String?>? taxonOrder,
    Value<String?>? modelLabelId,
    Value<int?>? coverPhotoId,
  }) {
    return SpeciesCompanion(
      id: id ?? this.id,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      description: description ?? this.description,
      referenceImage: referenceImage ?? this.referenceImage,
      taxonOrder: taxonOrder ?? this.taxonOrder,
      modelLabelId: modelLabelId ?? this.modelLabelId,
      coverPhotoId: coverPhotoId ?? this.coverPhotoId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scientificName.present) {
      map['scientific_name'] = Variable<String>(scientificName.value);
    }
    if (commonName.present) {
      map['common_name'] = Variable<String>(commonName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (referenceImage.present) {
      map['reference_image'] = Variable<String>(referenceImage.value);
    }
    if (taxonOrder.present) {
      map['taxon_order'] = Variable<String>(taxonOrder.value);
    }
    if (modelLabelId.present) {
      map['model_label_id'] = Variable<String>(modelLabelId.value);
    }
    if (coverPhotoId.present) {
      map['cover_photo_id'] = Variable<int>(coverPhotoId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesCompanion(')
          ..write('id: $id, ')
          ..write('scientificName: $scientificName, ')
          ..write('commonName: $commonName, ')
          ..write('description: $description, ')
          ..write('referenceImage: $referenceImage, ')
          ..write('taxonOrder: $taxonOrder, ')
          ..write('modelLabelId: $modelLabelId, ')
          ..write('coverPhotoId: $coverPhotoId')
          ..write(')'))
        .toString();
  }
}

class $DetectionsTable extends Detections
    with TableInfo<$DetectionsTable, DetectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _speciesIdMeta = const VerificationMeta(
    'speciesId',
  );
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
    'species_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES species (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelScoreMeta = const VerificationMeta(
    'modelScore',
  );
  @override
  late final GeneratedColumn<double> modelScore = GeneratedColumn<double>(
    'model_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioClipPathMeta = const VerificationMeta(
    'audioClipPath',
  );
  @override
  late final GeneratedColumn<String> audioClipPath = GeneratedColumn<String>(
    'audio_clip_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    speciesId,
    detectedAt,
    modelScore,
    audioClipPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detections';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('species_id')) {
      context.handle(
        _speciesIdMeta,
        speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    if (data.containsKey('model_score')) {
      context.handle(
        _modelScoreMeta,
        modelScore.isAcceptableOrUnknown(data['model_score']!, _modelScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_modelScoreMeta);
    }
    if (data.containsKey('audio_clip_path')) {
      context.handle(
        _audioClipPathMeta,
        audioClipPath.isAcceptableOrUnknown(
          data['audio_clip_path']!,
          _audioClipPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DetectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      speciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}species_id'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      )!,
      modelScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}model_score'],
      )!,
      audioClipPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_clip_path'],
      ),
    );
  }

  @override
  $DetectionsTable createAlias(String alias) {
    return $DetectionsTable(attachedDatabase, alias);
  }
}

class DetectionRow extends DataClass implements Insertable<DetectionRow> {
  final int id;
  final int sessionId;
  final int speciesId;
  final DateTime detectedAt;
  final double modelScore;
  final String? audioClipPath;
  const DetectionRow({
    required this.id,
    required this.sessionId,
    required this.speciesId,
    required this.detectedAt,
    required this.modelScore,
    this.audioClipPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['species_id'] = Variable<int>(speciesId);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    map['model_score'] = Variable<double>(modelScore);
    if (!nullToAbsent || audioClipPath != null) {
      map['audio_clip_path'] = Variable<String>(audioClipPath);
    }
    return map;
  }

  DetectionsCompanion toCompanion(bool nullToAbsent) {
    return DetectionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      speciesId: Value(speciesId),
      detectedAt: Value(detectedAt),
      modelScore: Value(modelScore),
      audioClipPath: audioClipPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioClipPath),
    );
  }

  factory DetectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetectionRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      modelScore: serializer.fromJson<double>(json['modelScore']),
      audioClipPath: serializer.fromJson<String?>(json['audioClipPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'speciesId': serializer.toJson<int>(speciesId),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'modelScore': serializer.toJson<double>(modelScore),
      'audioClipPath': serializer.toJson<String?>(audioClipPath),
    };
  }

  DetectionRow copyWith({
    int? id,
    int? sessionId,
    int? speciesId,
    DateTime? detectedAt,
    double? modelScore,
    Value<String?> audioClipPath = const Value.absent(),
  }) => DetectionRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    speciesId: speciesId ?? this.speciesId,
    detectedAt: detectedAt ?? this.detectedAt,
    modelScore: modelScore ?? this.modelScore,
    audioClipPath: audioClipPath.present
        ? audioClipPath.value
        : this.audioClipPath,
  );
  DetectionRow copyWithCompanion(DetectionsCompanion data) {
    return DetectionRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      modelScore: data.modelScore.present
          ? data.modelScore.value
          : this.modelScore,
      audioClipPath: data.audioClipPath.present
          ? data.audioClipPath.value
          : this.audioClipPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetectionRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('speciesId: $speciesId, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('modelScore: $modelScore, ')
          ..write('audioClipPath: $audioClipPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    speciesId,
    detectedAt,
    modelScore,
    audioClipPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectionRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.speciesId == this.speciesId &&
          other.detectedAt == this.detectedAt &&
          other.modelScore == this.modelScore &&
          other.audioClipPath == this.audioClipPath);
}

class DetectionsCompanion extends UpdateCompanion<DetectionRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> speciesId;
  final Value<DateTime> detectedAt;
  final Value<double> modelScore;
  final Value<String?> audioClipPath;
  const DetectionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.modelScore = const Value.absent(),
    this.audioClipPath = const Value.absent(),
  });
  DetectionsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int speciesId,
    required DateTime detectedAt,
    required double modelScore,
    this.audioClipPath = const Value.absent(),
  }) : sessionId = Value(sessionId),
       speciesId = Value(speciesId),
       detectedAt = Value(detectedAt),
       modelScore = Value(modelScore);
  static Insertable<DetectionRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? speciesId,
    Expression<DateTime>? detectedAt,
    Expression<double>? modelScore,
    Expression<String>? audioClipPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (speciesId != null) 'species_id': speciesId,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (modelScore != null) 'model_score': modelScore,
      if (audioClipPath != null) 'audio_clip_path': audioClipPath,
    });
  }

  DetectionsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? speciesId,
    Value<DateTime>? detectedAt,
    Value<double>? modelScore,
    Value<String?>? audioClipPath,
  }) {
    return DetectionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      speciesId: speciesId ?? this.speciesId,
      detectedAt: detectedAt ?? this.detectedAt,
      modelScore: modelScore ?? this.modelScore,
      audioClipPath: audioClipPath ?? this.audioClipPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (modelScore.present) {
      map['model_score'] = Variable<double>(modelScore.value);
    }
    if (audioClipPath.present) {
      map['audio_clip_path'] = Variable<String>(audioClipPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetectionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('speciesId: $speciesId, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('modelScore: $modelScore, ')
          ..write('audioClipPath: $audioClipPath')
          ..write(')'))
        .toString();
  }
}

class $GuideDescriptionsTable extends GuideDescriptions
    with TableInfo<$GuideDescriptionsTable, GuideDescriptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuideDescriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scientificNameMeta = const VerificationMeta(
    'scientificName',
  );
  @override
  late final GeneratedColumn<String> scientificName = GeneratedColumn<String>(
    'scientific_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleTitleMeta = const VerificationMeta(
    'articleTitle',
  );
  @override
  late final GeneratedColumn<String> articleTitle = GeneratedColumn<String>(
    'article_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    scientificName,
    lang,
    body,
    articleTitle,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guide_descriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<GuideDescriptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scientific_name')) {
      context.handle(
        _scientificNameMeta,
        scientificName.isAcceptableOrUnknown(
          data['scientific_name']!,
          _scientificNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scientificNameMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('article_title')) {
      context.handle(
        _articleTitleMeta,
        articleTitle.isAcceptableOrUnknown(
          data['article_title']!,
          _articleTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_articleTitleMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scientificName, lang};
  @override
  GuideDescriptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuideDescriptionRow(
      scientificName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scientific_name'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      articleTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_title'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $GuideDescriptionsTable createAlias(String alias) {
    return $GuideDescriptionsTable(attachedDatabase, alias);
  }
}

class GuideDescriptionRow extends DataClass
    implements Insertable<GuideDescriptionRow> {
  final String scientificName;

  /// 'en' or 'ru'.
  final String lang;
  final String body;
  final String articleTitle;
  final DateTime fetchedAt;
  const GuideDescriptionRow({
    required this.scientificName,
    required this.lang,
    required this.body,
    required this.articleTitle,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scientific_name'] = Variable<String>(scientificName);
    map['lang'] = Variable<String>(lang);
    map['body'] = Variable<String>(body);
    map['article_title'] = Variable<String>(articleTitle);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  GuideDescriptionsCompanion toCompanion(bool nullToAbsent) {
    return GuideDescriptionsCompanion(
      scientificName: Value(scientificName),
      lang: Value(lang),
      body: Value(body),
      articleTitle: Value(articleTitle),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory GuideDescriptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuideDescriptionRow(
      scientificName: serializer.fromJson<String>(json['scientificName']),
      lang: serializer.fromJson<String>(json['lang']),
      body: serializer.fromJson<String>(json['body']),
      articleTitle: serializer.fromJson<String>(json['articleTitle']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scientificName': serializer.toJson<String>(scientificName),
      'lang': serializer.toJson<String>(lang),
      'body': serializer.toJson<String>(body),
      'articleTitle': serializer.toJson<String>(articleTitle),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  GuideDescriptionRow copyWith({
    String? scientificName,
    String? lang,
    String? body,
    String? articleTitle,
    DateTime? fetchedAt,
  }) => GuideDescriptionRow(
    scientificName: scientificName ?? this.scientificName,
    lang: lang ?? this.lang,
    body: body ?? this.body,
    articleTitle: articleTitle ?? this.articleTitle,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  GuideDescriptionRow copyWithCompanion(GuideDescriptionsCompanion data) {
    return GuideDescriptionRow(
      scientificName: data.scientificName.present
          ? data.scientificName.value
          : this.scientificName,
      lang: data.lang.present ? data.lang.value : this.lang,
      body: data.body.present ? data.body.value : this.body,
      articleTitle: data.articleTitle.present
          ? data.articleTitle.value
          : this.articleTitle,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuideDescriptionRow(')
          ..write('scientificName: $scientificName, ')
          ..write('lang: $lang, ')
          ..write('body: $body, ')
          ..write('articleTitle: $articleTitle, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(scientificName, lang, body, articleTitle, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuideDescriptionRow &&
          other.scientificName == this.scientificName &&
          other.lang == this.lang &&
          other.body == this.body &&
          other.articleTitle == this.articleTitle &&
          other.fetchedAt == this.fetchedAt);
}

class GuideDescriptionsCompanion extends UpdateCompanion<GuideDescriptionRow> {
  final Value<String> scientificName;
  final Value<String> lang;
  final Value<String> body;
  final Value<String> articleTitle;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const GuideDescriptionsCompanion({
    this.scientificName = const Value.absent(),
    this.lang = const Value.absent(),
    this.body = const Value.absent(),
    this.articleTitle = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GuideDescriptionsCompanion.insert({
    required String scientificName,
    required String lang,
    required String body,
    required String articleTitle,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : scientificName = Value(scientificName),
       lang = Value(lang),
       body = Value(body),
       articleTitle = Value(articleTitle),
       fetchedAt = Value(fetchedAt);
  static Insertable<GuideDescriptionRow> custom({
    Expression<String>? scientificName,
    Expression<String>? lang,
    Expression<String>? body,
    Expression<String>? articleTitle,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scientificName != null) 'scientific_name': scientificName,
      if (lang != null) 'lang': lang,
      if (body != null) 'body': body,
      if (articleTitle != null) 'article_title': articleTitle,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GuideDescriptionsCompanion copyWith({
    Value<String>? scientificName,
    Value<String>? lang,
    Value<String>? body,
    Value<String>? articleTitle,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return GuideDescriptionsCompanion(
      scientificName: scientificName ?? this.scientificName,
      lang: lang ?? this.lang,
      body: body ?? this.body,
      articleTitle: articleTitle ?? this.articleTitle,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scientificName.present) {
      map['scientific_name'] = Variable<String>(scientificName.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (articleTitle.present) {
      map['article_title'] = Variable<String>(articleTitle.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuideDescriptionsCompanion(')
          ..write('scientificName: $scientificName, ')
          ..write('lang: $lang, ')
          ..write('body: $body, ')
          ..write('articleTitle: $articleTitle, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EncyclopediaPacksTable extends EncyclopediaPacks
    with TableInfo<$EncyclopediaPacksTable, EncyclopediaPackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EncyclopediaPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusKmMeta = const VerificationMeta(
    'radiusKm',
  );
  @override
  late final GeneratedColumn<double> radiusKm = GeneratedColumn<double>(
    'radius_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languagesMeta = const VerificationMeta(
    'languages',
  );
  @override
  late final GeneratedColumn<String> languages = GeneratedColumn<String>(
    'languages',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _withPhotosMeta = const VerificationMeta(
    'withPhotos',
  );
  @override
  late final GeneratedColumn<bool> withPhotos = GeneratedColumn<bool>(
    'with_photos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("with_photos" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    latitude,
    longitude,
    radiusKm,
    languages,
    withPhotos,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'encyclopedia_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EncyclopediaPackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius_km')) {
      context.handle(
        _radiusKmMeta,
        radiusKm.isAcceptableOrUnknown(data['radius_km']!, _radiusKmMeta),
      );
    } else if (isInserting) {
      context.missing(_radiusKmMeta);
    }
    if (data.containsKey('languages')) {
      context.handle(
        _languagesMeta,
        languages.isAcceptableOrUnknown(data['languages']!, _languagesMeta),
      );
    } else if (isInserting) {
      context.missing(_languagesMeta);
    }
    if (data.containsKey('with_photos')) {
      context.handle(
        _withPhotosMeta,
        withPhotos.isAcceptableOrUnknown(data['with_photos']!, _withPhotosMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EncyclopediaPackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EncyclopediaPackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      radiusKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_km'],
      )!,
      languages: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}languages'],
      )!,
      withPhotos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}with_photos'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EncyclopediaPacksTable createAlias(String alias) {
    return $EncyclopediaPacksTable(attachedDatabase, alias);
  }
}

class EncyclopediaPackRow extends DataClass
    implements Insertable<EncyclopediaPackRow> {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;

  /// Comma-separated language codes, e.g. "en,ru".
  final String languages;
  final bool withPhotos;
  final DateTime createdAt;
  const EncyclopediaPackRow({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.languages,
    required this.withPhotos,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_km'] = Variable<double>(radiusKm);
    map['languages'] = Variable<String>(languages);
    map['with_photos'] = Variable<bool>(withPhotos);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EncyclopediaPacksCompanion toCompanion(bool nullToAbsent) {
    return EncyclopediaPacksCompanion(
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusKm: Value(radiusKm),
      languages: Value(languages),
      withPhotos: Value(withPhotos),
      createdAt: Value(createdAt),
    );
  }

  factory EncyclopediaPackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EncyclopediaPackRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusKm: serializer.fromJson<double>(json['radiusKm']),
      languages: serializer.fromJson<String>(json['languages']),
      withPhotos: serializer.fromJson<bool>(json['withPhotos']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusKm': serializer.toJson<double>(radiusKm),
      'languages': serializer.toJson<String>(languages),
      'withPhotos': serializer.toJson<bool>(withPhotos),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EncyclopediaPackRow copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? languages,
    bool? withPhotos,
    DateTime? createdAt,
  }) => EncyclopediaPackRow(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusKm: radiusKm ?? this.radiusKm,
    languages: languages ?? this.languages,
    withPhotos: withPhotos ?? this.withPhotos,
    createdAt: createdAt ?? this.createdAt,
  );
  EncyclopediaPackRow copyWithCompanion(EncyclopediaPacksCompanion data) {
    return EncyclopediaPackRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusKm: data.radiusKm.present ? data.radiusKm.value : this.radiusKm,
      languages: data.languages.present ? data.languages.value : this.languages,
      withPhotos: data.withPhotos.present
          ? data.withPhotos.value
          : this.withPhotos,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EncyclopediaPackRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('languages: $languages, ')
          ..write('withPhotos: $withPhotos, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    latitude,
    longitude,
    radiusKm,
    languages,
    withPhotos,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaPackRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusKm == this.radiusKm &&
          other.languages == this.languages &&
          other.withPhotos == this.withPhotos &&
          other.createdAt == this.createdAt);
}

class EncyclopediaPacksCompanion extends UpdateCompanion<EncyclopediaPackRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radiusKm;
  final Value<String> languages;
  final Value<bool> withPhotos;
  final Value<DateTime> createdAt;
  const EncyclopediaPacksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusKm = const Value.absent(),
    this.languages = const Value.absent(),
    this.withPhotos = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EncyclopediaPacksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String languages,
    this.withPhotos = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       radiusKm = Value(radiusKm),
       languages = Value(languages),
       createdAt = Value(createdAt);
  static Insertable<EncyclopediaPackRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusKm,
    Expression<String>? languages,
    Expression<bool>? withPhotos,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusKm != null) 'radius_km': radiusKm,
      if (languages != null) 'languages': languages,
      if (withPhotos != null) 'with_photos': withPhotos,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EncyclopediaPacksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? radiusKm,
    Value<String>? languages,
    Value<bool>? withPhotos,
    Value<DateTime>? createdAt,
  }) {
    return EncyclopediaPacksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      languages: languages ?? this.languages,
      withPhotos: withPhotos ?? this.withPhotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusKm.present) {
      map['radius_km'] = Variable<double>(radiusKm.value);
    }
    if (languages.present) {
      map['languages'] = Variable<String>(languages.value);
    }
    if (withPhotos.present) {
      map['with_photos'] = Variable<bool>(withPhotos.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EncyclopediaPacksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('languages: $languages, ')
          ..write('withPhotos: $withPhotos, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EncyclopediaPackSpeciesTable extends EncyclopediaPackSpecies
    with TableInfo<$EncyclopediaPackSpeciesTable, EncyclopediaPackSpeciesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EncyclopediaPackSpeciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<int> packId = GeneratedColumn<int>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES encyclopedia_packs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scientificNameMeta = const VerificationMeta(
    'scientificName',
  );
  @override
  late final GeneratedColumn<String> scientificName = GeneratedColumn<String>(
    'scientific_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commonNameMeta = const VerificationMeta(
    'commonName',
  );
  @override
  late final GeneratedColumn<String> commonName = GeneratedColumn<String>(
    'common_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [packId, scientificName, commonName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'encyclopedia_pack_species';
  @override
  VerificationContext validateIntegrity(
    Insertable<EncyclopediaPackSpeciesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('scientific_name')) {
      context.handle(
        _scientificNameMeta,
        scientificName.isAcceptableOrUnknown(
          data['scientific_name']!,
          _scientificNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scientificNameMeta);
    }
    if (data.containsKey('common_name')) {
      context.handle(
        _commonNameMeta,
        commonName.isAcceptableOrUnknown(data['common_name']!, _commonNameMeta),
      );
    } else if (isInserting) {
      context.missing(_commonNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packId, scientificName};
  @override
  EncyclopediaPackSpeciesRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EncyclopediaPackSpeciesRow(
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_id'],
      )!,
      scientificName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scientific_name'],
      )!,
      commonName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}common_name'],
      )!,
    );
  }

  @override
  $EncyclopediaPackSpeciesTable createAlias(String alias) {
    return $EncyclopediaPackSpeciesTable(attachedDatabase, alias);
  }
}

class EncyclopediaPackSpeciesRow extends DataClass
    implements Insertable<EncyclopediaPackSpeciesRow> {
  final int packId;
  final String scientificName;
  final String commonName;
  const EncyclopediaPackSpeciesRow({
    required this.packId,
    required this.scientificName,
    required this.commonName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_id'] = Variable<int>(packId);
    map['scientific_name'] = Variable<String>(scientificName);
    map['common_name'] = Variable<String>(commonName);
    return map;
  }

  EncyclopediaPackSpeciesCompanion toCompanion(bool nullToAbsent) {
    return EncyclopediaPackSpeciesCompanion(
      packId: Value(packId),
      scientificName: Value(scientificName),
      commonName: Value(commonName),
    );
  }

  factory EncyclopediaPackSpeciesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EncyclopediaPackSpeciesRow(
      packId: serializer.fromJson<int>(json['packId']),
      scientificName: serializer.fromJson<String>(json['scientificName']),
      commonName: serializer.fromJson<String>(json['commonName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packId': serializer.toJson<int>(packId),
      'scientificName': serializer.toJson<String>(scientificName),
      'commonName': serializer.toJson<String>(commonName),
    };
  }

  EncyclopediaPackSpeciesRow copyWith({
    int? packId,
    String? scientificName,
    String? commonName,
  }) => EncyclopediaPackSpeciesRow(
    packId: packId ?? this.packId,
    scientificName: scientificName ?? this.scientificName,
    commonName: commonName ?? this.commonName,
  );
  EncyclopediaPackSpeciesRow copyWithCompanion(
    EncyclopediaPackSpeciesCompanion data,
  ) {
    return EncyclopediaPackSpeciesRow(
      packId: data.packId.present ? data.packId.value : this.packId,
      scientificName: data.scientificName.present
          ? data.scientificName.value
          : this.scientificName,
      commonName: data.commonName.present
          ? data.commonName.value
          : this.commonName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EncyclopediaPackSpeciesRow(')
          ..write('packId: $packId, ')
          ..write('scientificName: $scientificName, ')
          ..write('commonName: $commonName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packId, scientificName, commonName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaPackSpeciesRow &&
          other.packId == this.packId &&
          other.scientificName == this.scientificName &&
          other.commonName == this.commonName);
}

class EncyclopediaPackSpeciesCompanion
    extends UpdateCompanion<EncyclopediaPackSpeciesRow> {
  final Value<int> packId;
  final Value<String> scientificName;
  final Value<String> commonName;
  final Value<int> rowid;
  const EncyclopediaPackSpeciesCompanion({
    this.packId = const Value.absent(),
    this.scientificName = const Value.absent(),
    this.commonName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EncyclopediaPackSpeciesCompanion.insert({
    required int packId,
    required String scientificName,
    required String commonName,
    this.rowid = const Value.absent(),
  }) : packId = Value(packId),
       scientificName = Value(scientificName),
       commonName = Value(commonName);
  static Insertable<EncyclopediaPackSpeciesRow> custom({
    Expression<int>? packId,
    Expression<String>? scientificName,
    Expression<String>? commonName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packId != null) 'pack_id': packId,
      if (scientificName != null) 'scientific_name': scientificName,
      if (commonName != null) 'common_name': commonName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EncyclopediaPackSpeciesCompanion copyWith({
    Value<int>? packId,
    Value<String>? scientificName,
    Value<String>? commonName,
    Value<int>? rowid,
  }) {
    return EncyclopediaPackSpeciesCompanion(
      packId: packId ?? this.packId,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packId.present) {
      map['pack_id'] = Variable<int>(packId.value);
    }
    if (scientificName.present) {
      map['scientific_name'] = Variable<String>(scientificName.value);
    }
    if (commonName.present) {
      map['common_name'] = Variable<String>(commonName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EncyclopediaPackSpeciesCompanion(')
          ..write('packId: $packId, ')
          ..write('scientificName: $scientificName, ')
          ..write('commonName: $commonName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestCompletionsTable extends QuestCompletions
    with TableInfo<$QuestCompletionsTable, QuestCompletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questIdMeta = const VerificationMeta(
    'questId',
  );
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, questId, xp, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestCompletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('quest_id')) {
      context.handle(
        _questIdMeta,
        questId.isAcceptableOrUnknown(data['quest_id']!, _questIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questIdMeta);
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    } else if (isInserting) {
      context.missing(_xpMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, questId};
  @override
  QuestCompletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestCompletionRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $QuestCompletionsTable createAlias(String alias) {
    return $QuestCompletionsTable(attachedDatabase, alias);
  }
}

class QuestCompletionRow extends DataClass
    implements Insertable<QuestCompletionRow> {
  /// Local date, 'yyyy-mm-dd'.
  final String day;
  final String questId;
  final int xp;
  final DateTime completedAt;
  const QuestCompletionRow({
    required this.day,
    required this.questId,
    required this.xp,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['quest_id'] = Variable<String>(questId);
    map['xp'] = Variable<int>(xp);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  QuestCompletionsCompanion toCompanion(bool nullToAbsent) {
    return QuestCompletionsCompanion(
      day: Value(day),
      questId: Value(questId),
      xp: Value(xp),
      completedAt: Value(completedAt),
    );
  }

  factory QuestCompletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestCompletionRow(
      day: serializer.fromJson<String>(json['day']),
      questId: serializer.fromJson<String>(json['questId']),
      xp: serializer.fromJson<int>(json['xp']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'questId': serializer.toJson<String>(questId),
      'xp': serializer.toJson<int>(xp),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  QuestCompletionRow copyWith({
    String? day,
    String? questId,
    int? xp,
    DateTime? completedAt,
  }) => QuestCompletionRow(
    day: day ?? this.day,
    questId: questId ?? this.questId,
    xp: xp ?? this.xp,
    completedAt: completedAt ?? this.completedAt,
  );
  QuestCompletionRow copyWithCompanion(QuestCompletionsCompanion data) {
    return QuestCompletionRow(
      day: data.day.present ? data.day.value : this.day,
      questId: data.questId.present ? data.questId.value : this.questId,
      xp: data.xp.present ? data.xp.value : this.xp,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestCompletionRow(')
          ..write('day: $day, ')
          ..write('questId: $questId, ')
          ..write('xp: $xp, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, questId, xp, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestCompletionRow &&
          other.day == this.day &&
          other.questId == this.questId &&
          other.xp == this.xp &&
          other.completedAt == this.completedAt);
}

class QuestCompletionsCompanion extends UpdateCompanion<QuestCompletionRow> {
  final Value<String> day;
  final Value<String> questId;
  final Value<int> xp;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const QuestCompletionsCompanion({
    this.day = const Value.absent(),
    this.questId = const Value.absent(),
    this.xp = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestCompletionsCompanion.insert({
    required String day,
    required String questId,
    required int xp,
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       questId = Value(questId),
       xp = Value(xp),
       completedAt = Value(completedAt);
  static Insertable<QuestCompletionRow> custom({
    Expression<String>? day,
    Expression<String>? questId,
    Expression<int>? xp,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (questId != null) 'quest_id': questId,
      if (xp != null) 'xp': xp,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestCompletionsCompanion copyWith({
    Value<String>? day,
    Value<String>? questId,
    Value<int>? xp,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return QuestCompletionsCompanion(
      day: day ?? this.day,
      questId: questId ?? this.questId,
      xp: xp ?? this.xp,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestCompletionsCompanion(')
          ..write('day: $day, ')
          ..write('questId: $questId, ')
          ..write('xp: $xp, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SightingsTable sightings = $SightingsTable(this);
  late final $SightingPhotosTable sightingPhotos = $SightingPhotosTable(this);
  late final $SpeciesTable species = $SpeciesTable(this);
  late final $DetectionsTable detections = $DetectionsTable(this);
  late final $GuideDescriptionsTable guideDescriptions =
      $GuideDescriptionsTable(this);
  late final $EncyclopediaPacksTable encyclopediaPacks =
      $EncyclopediaPacksTable(this);
  late final $EncyclopediaPackSpeciesTable encyclopediaPackSpecies =
      $EncyclopediaPackSpeciesTable(this);
  late final $QuestCompletionsTable questCompletions = $QuestCompletionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    sightings,
    sightingPhotos,
    species,
    detections,
    guideDescriptions,
    encyclopediaPacks,
    encyclopediaPackSpecies,
    questCompletions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'species',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sightings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sightings', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sightings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sighting_photos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sighting_photos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('species', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('detections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'species',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('detections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'encyclopedia_packs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('encyclopedia_pack_species', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<bool> isDemo,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<bool> isDemo,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SightingsTable, List<SightingRow>>
  _sightingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sightings,
    aliasName: 'sessions__id__sightings__session_id',
  );

  $$SightingsTableProcessedTableManager get sightingsRefs {
    final manager = $$SightingsTableTableManager(
      $_db,
      $_db.sightings,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sightingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DetectionsTable, List<DetectionRow>>
  _detectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.detections,
    aliasName: 'sessions__id__detections__session_id',
  );

  $$DetectionsTableProcessedTableManager get detectionsRefs {
    final manager = $$DetectionsTableTableManager(
      $_db,
      $_db.detections,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_detectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDemo => $composableBuilder(
    column: $table.isDemo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sightingsRefs(
    Expression<bool> Function($$SightingsTableFilterComposer f) f,
  ) {
    final $$SightingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sightings,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingsTableFilterComposer(
            $db: $db,
            $table: $db.sightings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> detectionsRefs(
    Expression<bool> Function($$DetectionsTableFilterComposer f) f,
  ) {
    final $$DetectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detections,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectionsTableFilterComposer(
            $db: $db,
            $table: $db.detections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDemo => $composableBuilder(
    column: $table.isDemo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get isDemo =>
      $composableBuilder(column: $table.isDemo, builder: (column) => column);

  Expression<T> sightingsRefs<T extends Object>(
    Expression<T> Function($$SightingsTableAnnotationComposer a) f,
  ) {
    final $$SightingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sightings,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingsTableAnnotationComposer(
            $db: $db,
            $table: $db.sightings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> detectionsRefs<T extends Object>(
    Expression<T> Function($$DetectionsTableAnnotationComposer a) f,
  ) {
    final $$DetectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detections,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.detections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool sightingsRefs, bool detectionsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isDemo = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                latitude: latitude,
                longitude: longitude,
                isDemo: isDemo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isDemo = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                latitude: latitude,
                longitude: longitude,
                isDemo: isDemo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sightingsRefs = false, detectionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sightingsRefs) db.sightings,
                    if (detectionsRefs) db.detections,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sightingsRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          SightingRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._sightingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sightingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (detectionsRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          DetectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._detectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).detectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool sightingsRefs, bool detectionsRefs})
    >;
typedef $$SightingsTableCreateCompanionBuilder = SightingsCompanion Function({
  Value<int> id,
  required int speciesId,
  Value<int?> sessionId,
  required DateTime confirmedAt,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> userNotes,
  Value<double?> modelScore,
  Value<String?> audioClipPath,
  Value<bool> isDemo,
  Value<String?> rarity,
});
typedef $$SightingsTableUpdateCompanionBuilder = SightingsCompanion Function({
  Value<int> id,
  Value<int> speciesId,
  Value<int?> sessionId,
  Value<DateTime> confirmedAt,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> userNotes,
  Value<double?> modelScore,
  Value<String?> audioClipPath,
  Value<bool> isDemo,
  Value<String?> rarity,
});

final class $$SightingsTableReferences
    extends BaseReferences<_$AppDatabase, $SightingsTable, SightingRow> {
  $$SightingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SpeciesTable _speciesIdTable(_$AppDatabase db) =>
      db.species.createAlias('sightings__species_id__species__id');

  $$SpeciesTableProcessedTableManager get speciesId {
    final $_column = $_itemColumn<int>('species_id')!;

    final manager = $$SpeciesTableTableManager(
      $_db,
      $_db.species,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_speciesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('sightings__session_id__sessions__id');

  $$SessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<int>('session_id');
    if ($_column == null) return null;
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SightingPhotosTable, List<SightingPhotoRow>>
  _sightingPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sightingPhotos,
    aliasName: 'sightings__id__sighting_photos__sighting_id',
  );

  $$SightingPhotosTableProcessedTableManager get sightingPhotosRefs {
    final manager = $$SightingPhotosTableTableManager(
      $_db,
      $_db.sightingPhotos,
    ).filter((f) => f.sightingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sightingPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SightingsTableFilterComposer
    extends Composer<_$AppDatabase, $SightingsTable> {
  $$SightingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userNotes => $composableBuilder(
    column: $table.userNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get modelScore => $composableBuilder(
    column: $table.modelScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioClipPath => $composableBuilder(
    column: $table.audioClipPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDemo => $composableBuilder(
    column: $table.isDemo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnFilters(column),
  );

  $$SpeciesTableFilterComposer get speciesId {
    final $$SpeciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.speciesId,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableFilterComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sightingPhotosRefs(
    Expression<bool> Function($$SightingPhotosTableFilterComposer f) f,
  ) {
    final $$SightingPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sightingPhotos,
      getReferencedColumn: (t) => t.sightingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingPhotosTableFilterComposer(
            $db: $db,
            $table: $db.sightingPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SightingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SightingsTable> {
  $$SightingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userNotes => $composableBuilder(
    column: $table.userNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get modelScore => $composableBuilder(
    column: $table.modelScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioClipPath => $composableBuilder(
    column: $table.audioClipPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDemo => $composableBuilder(
    column: $table.isDemo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnOrderings(column),
  );

  $$SpeciesTableOrderingComposer get speciesId {
    final $$SpeciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.speciesId,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableOrderingComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SightingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SightingsTable> {
  $$SightingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get userNotes =>
      $composableBuilder(column: $table.userNotes, builder: (column) => column);

  GeneratedColumn<double> get modelScore => $composableBuilder(
    column: $table.modelScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioClipPath => $composableBuilder(
    column: $table.audioClipPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDemo =>
      $composableBuilder(column: $table.isDemo, builder: (column) => column);

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  $$SpeciesTableAnnotationComposer get speciesId {
    final $$SpeciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.speciesId,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableAnnotationComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sightingPhotosRefs<T extends Object>(
    Expression<T> Function($$SightingPhotosTableAnnotationComposer a) f,
  ) {
    final $$SightingPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sightingPhotos,
      getReferencedColumn: (t) => t.sightingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.sightingPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SightingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SightingsTable,
          SightingRow,
          $$SightingsTableFilterComposer,
          $$SightingsTableOrderingComposer,
          $$SightingsTableAnnotationComposer,
          $$SightingsTableCreateCompanionBuilder,
          $$SightingsTableUpdateCompanionBuilder,
          (SightingRow, $$SightingsTableReferences),
          SightingRow,
          PrefetchHooks Function({
            bool speciesId,
            bool sessionId,
            bool sightingPhotosRefs,
          })
        > {
  $$SightingsTableTableManager(_$AppDatabase db, $SightingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SightingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SightingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SightingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> speciesId = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<DateTime> confirmedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> userNotes = const Value.absent(),
                Value<double?> modelScore = const Value.absent(),
                Value<String?> audioClipPath = const Value.absent(),
                Value<bool> isDemo = const Value.absent(),
                Value<String?> rarity = const Value.absent(),
              }) => SightingsCompanion(
                id: id,
                speciesId: speciesId,
                sessionId: sessionId,
                confirmedAt: confirmedAt,
                latitude: latitude,
                longitude: longitude,
                userNotes: userNotes,
                modelScore: modelScore,
                audioClipPath: audioClipPath,
                isDemo: isDemo,
                rarity: rarity,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int speciesId,
                Value<int?> sessionId = const Value.absent(),
                required DateTime confirmedAt,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> userNotes = const Value.absent(),
                Value<double?> modelScore = const Value.absent(),
                Value<String?> audioClipPath = const Value.absent(),
                Value<bool> isDemo = const Value.absent(),
                Value<String?> rarity = const Value.absent(),
              }) => SightingsCompanion.insert(
                id: id,
                speciesId: speciesId,
                sessionId: sessionId,
                confirmedAt: confirmedAt,
                latitude: latitude,
                longitude: longitude,
                userNotes: userNotes,
                modelScore: modelScore,
                audioClipPath: audioClipPath,
                isDemo: isDemo,
                rarity: rarity,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SightingsTable, SightingRow>(table),
                  $$SightingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                speciesId = false,
                sessionId = false,
                sightingPhotosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sightingPhotosRefs) db.sightingPhotos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (speciesId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.speciesId,
                            referencedTable: $$SightingsTableReferences
                                ._speciesIdTable(db),
                            referencedColumn: $$SightingsTableReferences
                                ._speciesIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (sessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$SightingsTableReferences
                                ._sessionIdTable(db),
                            referencedColumn: $$SightingsTableReferences
                                ._sessionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sightingPhotosRefs)
                        await $_getPrefetchedData<
                          SightingRow,
                          $SightingsTable,
                          SightingPhotoRow
                        >(
                          currentTable: table,
                          referencedTable: $$SightingsTableReferences
                              ._sightingPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SightingsTableReferences(
                                db,
                                table,
                                p0,
                              ).sightingPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sightingId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SightingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SightingsTable,
      SightingRow,
      $$SightingsTableFilterComposer,
      $$SightingsTableOrderingComposer,
      $$SightingsTableAnnotationComposer,
      $$SightingsTableCreateCompanionBuilder,
      $$SightingsTableUpdateCompanionBuilder,
      (SightingRow, $$SightingsTableReferences),
      SightingRow,
      PrefetchHooks Function({
        bool speciesId,
        bool sessionId,
        bool sightingPhotosRefs,
      })
    >;
typedef $$SightingPhotosTableCreateCompanionBuilder =
    SightingPhotosCompanion Function({
      Value<int> id,
      required int sightingId,
      required String localFilePath,
      required DateTime createdAt,
    });
typedef $$SightingPhotosTableUpdateCompanionBuilder =
    SightingPhotosCompanion Function({
      Value<int> id,
      Value<int> sightingId,
      Value<String> localFilePath,
      Value<DateTime> createdAt,
    });

final class $$SightingPhotosTableReferences
    extends
        BaseReferences<_$AppDatabase, $SightingPhotosTable, SightingPhotoRow> {
  $$SightingPhotosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SightingsTable _sightingIdTable(_$AppDatabase db) =>
      db.sightings.createAlias('sighting_photos__sighting_id__sightings__id');

  $$SightingsTableProcessedTableManager get sightingId {
    final $_column = $_itemColumn<int>('sighting_id')!;

    final manager = $$SightingsTableTableManager(
      $_db,
      $_db.sightings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sightingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SpeciesTable, List<SpeciesRow>> _speciesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.species,
    aliasName: 'sighting_photos__id__species__cover_photo_id',
  );

  $$SpeciesTableProcessedTableManager get speciesRefs {
    final manager = $$SpeciesTableTableManager(
      $_db,
      $_db.species,
    ).filter((f) => f.coverPhotoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_speciesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SightingPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $SightingPhotosTable> {
  $$SightingPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SightingsTableFilterComposer get sightingId {
    final $$SightingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sightingId,
      referencedTable: $db.sightings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingsTableFilterComposer(
            $db: $db,
            $table: $db.sightings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> speciesRefs(
    Expression<bool> Function($$SpeciesTableFilterComposer f) f,
  ) {
    final $$SpeciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.coverPhotoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableFilterComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SightingPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $SightingPhotosTable> {
  $$SightingPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SightingsTableOrderingComposer get sightingId {
    final $$SightingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sightingId,
      referencedTable: $db.sightings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingsTableOrderingComposer(
            $db: $db,
            $table: $db.sightings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SightingPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $SightingPhotosTable> {
  $$SightingPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SightingsTableAnnotationComposer get sightingId {
    final $$SightingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sightingId,
      referencedTable: $db.sightings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingsTableAnnotationComposer(
            $db: $db,
            $table: $db.sightings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> speciesRefs<T extends Object>(
    Expression<T> Function($$SpeciesTableAnnotationComposer a) f,
  ) {
    final $$SpeciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.coverPhotoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableAnnotationComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SightingPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SightingPhotosTable,
          SightingPhotoRow,
          $$SightingPhotosTableFilterComposer,
          $$SightingPhotosTableOrderingComposer,
          $$SightingPhotosTableAnnotationComposer,
          $$SightingPhotosTableCreateCompanionBuilder,
          $$SightingPhotosTableUpdateCompanionBuilder,
          (SightingPhotoRow, $$SightingPhotosTableReferences),
          SightingPhotoRow,
          PrefetchHooks Function({bool sightingId, bool speciesRefs})
        > {
  $$SightingPhotosTableTableManager(
    _$AppDatabase db,
    $SightingPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SightingPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SightingPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SightingPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sightingId = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SightingPhotosCompanion(
                id: id,
                sightingId: sightingId,
                localFilePath: localFilePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sightingId,
                required String localFilePath,
                required DateTime createdAt,
              }) => SightingPhotosCompanion.insert(
                id: id,
                sightingId: sightingId,
                localFilePath: localFilePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SightingPhotosTable, SightingPhotoRow>(table),
                  $$SightingPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sightingId = false, speciesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (speciesRefs) db.species],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sightingId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sightingId,
                        referencedTable: $$SightingPhotosTableReferences
                            ._sightingIdTable(db),
                        referencedColumn: $$SightingPhotosTableReferences
                            ._sightingIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (speciesRefs)
                    await $_getPrefetchedData<
                      SightingPhotoRow,
                      $SightingPhotosTable,
                      SpeciesRow
                    >(
                      currentTable: table,
                      referencedTable: $$SightingPhotosTableReferences
                          ._speciesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SightingPhotosTableReferences(
                            db,
                            table,
                            p0,
                          ).speciesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.coverPhotoId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SightingPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SightingPhotosTable,
      SightingPhotoRow,
      $$SightingPhotosTableFilterComposer,
      $$SightingPhotosTableOrderingComposer,
      $$SightingPhotosTableAnnotationComposer,
      $$SightingPhotosTableCreateCompanionBuilder,
      $$SightingPhotosTableUpdateCompanionBuilder,
      (SightingPhotoRow, $$SightingPhotosTableReferences),
      SightingPhotoRow,
      PrefetchHooks Function({bool sightingId, bool speciesRefs})
    >;
typedef $$SpeciesTableCreateCompanionBuilder = SpeciesCompanion Function({
  Value<int> id,
  required String scientificName,
  required String commonName,
  Value<String?> description,
  Value<String?> referenceImage,
  Value<String?> taxonOrder,
  Value<String?> modelLabelId,
  Value<int?> coverPhotoId,
});
typedef $$SpeciesTableUpdateCompanionBuilder = SpeciesCompanion Function({
  Value<int> id,
  Value<String> scientificName,
  Value<String> commonName,
  Value<String?> description,
  Value<String?> referenceImage,
  Value<String?> taxonOrder,
  Value<String?> modelLabelId,
  Value<int?> coverPhotoId,
});

final class $$SpeciesTableReferences
    extends BaseReferences<_$AppDatabase, $SpeciesTable, SpeciesRow> {
  $$SpeciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SightingPhotosTable _coverPhotoIdTable(_$AppDatabase db) => db
      .sightingPhotos
      .createAlias('species__cover_photo_id__sighting_photos__id');

  $$SightingPhotosTableProcessedTableManager? get coverPhotoId {
    final $_column = $_itemColumn<int>('cover_photo_id');
    if ($_column == null) return null;
    final manager = $$SightingPhotosTableTableManager(
      $_db,
      $_db.sightingPhotos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coverPhotoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SightingsTable, List<SightingRow>>
  _sightingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sightings,
    aliasName: 'species__id__sightings__species_id',
  );

  $$SightingsTableProcessedTableManager get sightingsRefs {
    final manager = $$SightingsTableTableManager(
      $_db,
      $_db.sightings,
    ).filter((f) => f.speciesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sightingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DetectionsTable, List<DetectionRow>>
  _detectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.detections,
    aliasName: 'species__id__detections__species_id',
  );

  $$DetectionsTableProcessedTableManager get detectionsRefs {
    final manager = $$DetectionsTableTableManager(
      $_db,
      $_db.detections,
    ).filter((f) => f.speciesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_detectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SpeciesTableFilterComposer
    extends Composer<_$AppDatabase, $SpeciesTable> {
  $$SpeciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceImage => $composableBuilder(
    column: $table.referenceImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonOrder => $composableBuilder(
    column: $table.taxonOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelLabelId => $composableBuilder(
    column: $table.modelLabelId,
    builder: (column) => ColumnFilters(column),
  );

  $$SightingPhotosTableFilterComposer get coverPhotoId {
    final $$SightingPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverPhotoId,
      referencedTable: $db.sightingPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingPhotosTableFilterComposer(
            $db: $db,
            $table: $db.sightingPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sightingsRefs(
    Expression<bool> Function($$SightingsTableFilterComposer f) f,
  ) {
    final $$SightingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sightings,
      getReferencedColumn: (t) => t.speciesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingsTableFilterComposer(
            $db: $db,
            $table: $db.sightings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> detectionsRefs(
    Expression<bool> Function($$DetectionsTableFilterComposer f) f,
  ) {
    final $$DetectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detections,
      getReferencedColumn: (t) => t.speciesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectionsTableFilterComposer(
            $db: $db,
            $table: $db.detections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SpeciesTableOrderingComposer
    extends Composer<_$AppDatabase, $SpeciesTable> {
  $$SpeciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceImage => $composableBuilder(
    column: $table.referenceImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonOrder => $composableBuilder(
    column: $table.taxonOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelLabelId => $composableBuilder(
    column: $table.modelLabelId,
    builder: (column) => ColumnOrderings(column),
  );

  $$SightingPhotosTableOrderingComposer get coverPhotoId {
    final $$SightingPhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverPhotoId,
      referencedTable: $db.sightingPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingPhotosTableOrderingComposer(
            $db: $db,
            $table: $db.sightingPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpeciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpeciesTable> {
  $$SpeciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceImage => $composableBuilder(
    column: $table.referenceImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxonOrder => $composableBuilder(
    column: $table.taxonOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelLabelId => $composableBuilder(
    column: $table.modelLabelId,
    builder: (column) => column,
  );

  $$SightingPhotosTableAnnotationComposer get coverPhotoId {
    final $$SightingPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverPhotoId,
      referencedTable: $db.sightingPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.sightingPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sightingsRefs<T extends Object>(
    Expression<T> Function($$SightingsTableAnnotationComposer a) f,
  ) {
    final $$SightingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sightings,
      getReferencedColumn: (t) => t.speciesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SightingsTableAnnotationComposer(
            $db: $db,
            $table: $db.sightings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> detectionsRefs<T extends Object>(
    Expression<T> Function($$DetectionsTableAnnotationComposer a) f,
  ) {
    final $$DetectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detections,
      getReferencedColumn: (t) => t.speciesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.detections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SpeciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpeciesTable,
          SpeciesRow,
          $$SpeciesTableFilterComposer,
          $$SpeciesTableOrderingComposer,
          $$SpeciesTableAnnotationComposer,
          $$SpeciesTableCreateCompanionBuilder,
          $$SpeciesTableUpdateCompanionBuilder,
          (SpeciesRow, $$SpeciesTableReferences),
          SpeciesRow,
          PrefetchHooks Function({
            bool coverPhotoId,
            bool sightingsRefs,
            bool detectionsRefs,
          })
        > {
  $$SpeciesTableTableManager(_$AppDatabase db, $SpeciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scientificName = const Value.absent(),
                Value<String> commonName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> referenceImage = const Value.absent(),
                Value<String?> taxonOrder = const Value.absent(),
                Value<String?> modelLabelId = const Value.absent(),
                Value<int?> coverPhotoId = const Value.absent(),
              }) => SpeciesCompanion(
                id: id,
                scientificName: scientificName,
                commonName: commonName,
                description: description,
                referenceImage: referenceImage,
                taxonOrder: taxonOrder,
                modelLabelId: modelLabelId,
                coverPhotoId: coverPhotoId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String scientificName,
                required String commonName,
                Value<String?> description = const Value.absent(),
                Value<String?> referenceImage = const Value.absent(),
                Value<String?> taxonOrder = const Value.absent(),
                Value<String?> modelLabelId = const Value.absent(),
                Value<int?> coverPhotoId = const Value.absent(),
              }) => SpeciesCompanion.insert(
                id: id,
                scientificName: scientificName,
                commonName: commonName,
                description: description,
                referenceImage: referenceImage,
                taxonOrder: taxonOrder,
                modelLabelId: modelLabelId,
                coverPhotoId: coverPhotoId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpeciesTable, SpeciesRow>(table),
                  $$SpeciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                coverPhotoId = false,
                sightingsRefs = false,
                detectionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sightingsRefs) db.sightings,
                    if (detectionsRefs) db.detections,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (coverPhotoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.coverPhotoId,
                            referencedTable: $$SpeciesTableReferences
                                ._coverPhotoIdTable(db),
                            referencedColumn: $$SpeciesTableReferences
                                ._coverPhotoIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sightingsRefs)
                        await $_getPrefetchedData<
                          SpeciesRow,
                          $SpeciesTable,
                          SightingRow
                        >(
                          currentTable: table,
                          referencedTable: $$SpeciesTableReferences
                              ._sightingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SpeciesTableReferences(
                                db,
                                table,
                                p0,
                              ).sightingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.speciesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (detectionsRefs)
                        await $_getPrefetchedData<
                          SpeciesRow,
                          $SpeciesTable,
                          DetectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$SpeciesTableReferences
                              ._detectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SpeciesTableReferences(
                                db,
                                table,
                                p0,
                              ).detectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.speciesId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SpeciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpeciesTable,
      SpeciesRow,
      $$SpeciesTableFilterComposer,
      $$SpeciesTableOrderingComposer,
      $$SpeciesTableAnnotationComposer,
      $$SpeciesTableCreateCompanionBuilder,
      $$SpeciesTableUpdateCompanionBuilder,
      (SpeciesRow, $$SpeciesTableReferences),
      SpeciesRow,
      PrefetchHooks Function({
        bool coverPhotoId,
        bool sightingsRefs,
        bool detectionsRefs,
      })
    >;
typedef $$DetectionsTableCreateCompanionBuilder = DetectionsCompanion Function({
  Value<int> id,
  required int sessionId,
  required int speciesId,
  required DateTime detectedAt,
  required double modelScore,
  Value<String?> audioClipPath,
});
typedef $$DetectionsTableUpdateCompanionBuilder = DetectionsCompanion Function({
  Value<int> id,
  Value<int> sessionId,
  Value<int> speciesId,
  Value<DateTime> detectedAt,
  Value<double> modelScore,
  Value<String?> audioClipPath,
});

final class $$DetectionsTableReferences
    extends BaseReferences<_$AppDatabase, $DetectionsTable, DetectionRow> {
  $$DetectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('detections__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SpeciesTable _speciesIdTable(_$AppDatabase db) =>
      db.species.createAlias('detections__species_id__species__id');

  $$SpeciesTableProcessedTableManager get speciesId {
    final $_column = $_itemColumn<int>('species_id')!;

    final manager = $$SpeciesTableTableManager(
      $_db,
      $_db.species,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_speciesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DetectionsTableFilterComposer
    extends Composer<_$AppDatabase, $DetectionsTable> {
  $$DetectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get modelScore => $composableBuilder(
    column: $table.modelScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioClipPath => $composableBuilder(
    column: $table.audioClipPath,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SpeciesTableFilterComposer get speciesId {
    final $$SpeciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.speciesId,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableFilterComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DetectionsTable> {
  $$DetectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get modelScore => $composableBuilder(
    column: $table.modelScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioClipPath => $composableBuilder(
    column: $table.audioClipPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SpeciesTableOrderingComposer get speciesId {
    final $$SpeciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.speciesId,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableOrderingComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DetectionsTable> {
  $$DetectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get modelScore => $composableBuilder(
    column: $table.modelScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioClipPath => $composableBuilder(
    column: $table.audioClipPath,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SpeciesTableAnnotationComposer get speciesId {
    final $$SpeciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.speciesId,
      referencedTable: $db.species,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeciesTableAnnotationComposer(
            $db: $db,
            $table: $db.species,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DetectionsTable,
          DetectionRow,
          $$DetectionsTableFilterComposer,
          $$DetectionsTableOrderingComposer,
          $$DetectionsTableAnnotationComposer,
          $$DetectionsTableCreateCompanionBuilder,
          $$DetectionsTableUpdateCompanionBuilder,
          (DetectionRow, $$DetectionsTableReferences),
          DetectionRow,
          PrefetchHooks Function({bool sessionId, bool speciesId})
        > {
  $$DetectionsTableTableManager(_$AppDatabase db, $DetectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> speciesId = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<double> modelScore = const Value.absent(),
                Value<String?> audioClipPath = const Value.absent(),
              }) => DetectionsCompanion(
                id: id,
                sessionId: sessionId,
                speciesId: speciesId,
                detectedAt: detectedAt,
                modelScore: modelScore,
                audioClipPath: audioClipPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int speciesId,
                required DateTime detectedAt,
                required double modelScore,
                Value<String?> audioClipPath = const Value.absent(),
              }) => DetectionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                speciesId: speciesId,
                detectedAt: detectedAt,
                modelScore: modelScore,
                audioClipPath: audioClipPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DetectionsTable, DetectionRow>(table),
                  $$DetectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, speciesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$DetectionsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$DetectionsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (speciesId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.speciesId,
                        referencedTable: $$DetectionsTableReferences
                            ._speciesIdTable(db),
                        referencedColumn: $$DetectionsTableReferences
                            ._speciesIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DetectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DetectionsTable,
      DetectionRow,
      $$DetectionsTableFilterComposer,
      $$DetectionsTableOrderingComposer,
      $$DetectionsTableAnnotationComposer,
      $$DetectionsTableCreateCompanionBuilder,
      $$DetectionsTableUpdateCompanionBuilder,
      (DetectionRow, $$DetectionsTableReferences),
      DetectionRow,
      PrefetchHooks Function({bool sessionId, bool speciesId})
    >;
typedef $$GuideDescriptionsTableCreateCompanionBuilder =
    GuideDescriptionsCompanion Function({
      required String scientificName,
      required String lang,
      required String body,
      required String articleTitle,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$GuideDescriptionsTableUpdateCompanionBuilder =
    GuideDescriptionsCompanion Function({
      Value<String> scientificName,
      Value<String> lang,
      Value<String> body,
      Value<String> articleTitle,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$GuideDescriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $GuideDescriptionsTable> {
  $$GuideDescriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get articleTitle => $composableBuilder(
    column: $table.articleTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GuideDescriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $GuideDescriptionsTable> {
  $$GuideDescriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get articleTitle => $composableBuilder(
    column: $table.articleTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GuideDescriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuideDescriptionsTable> {
  $$GuideDescriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get articleTitle => $composableBuilder(
    column: $table.articleTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$GuideDescriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GuideDescriptionsTable,
          GuideDescriptionRow,
          $$GuideDescriptionsTableFilterComposer,
          $$GuideDescriptionsTableOrderingComposer,
          $$GuideDescriptionsTableAnnotationComposer,
          $$GuideDescriptionsTableCreateCompanionBuilder,
          $$GuideDescriptionsTableUpdateCompanionBuilder,
          (
            GuideDescriptionRow,
            BaseReferences<
              _$AppDatabase,
              $GuideDescriptionsTable,
              GuideDescriptionRow
            >,
          ),
          GuideDescriptionRow,
          PrefetchHooks Function()
        > {
  $$GuideDescriptionsTableTableManager(
    _$AppDatabase db,
    $GuideDescriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuideDescriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuideDescriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuideDescriptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scientificName = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> articleTitle = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GuideDescriptionsCompanion(
                scientificName: scientificName,
                lang: lang,
                body: body,
                articleTitle: articleTitle,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scientificName,
                required String lang,
                required String body,
                required String articleTitle,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => GuideDescriptionsCompanion.insert(
                scientificName: scientificName,
                lang: lang,
                body: body,
                articleTitle: articleTitle,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GuideDescriptionsTable, GuideDescriptionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $GuideDescriptionsTable,
                    GuideDescriptionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GuideDescriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GuideDescriptionsTable,
      GuideDescriptionRow,
      $$GuideDescriptionsTableFilterComposer,
      $$GuideDescriptionsTableOrderingComposer,
      $$GuideDescriptionsTableAnnotationComposer,
      $$GuideDescriptionsTableCreateCompanionBuilder,
      $$GuideDescriptionsTableUpdateCompanionBuilder,
      (
        GuideDescriptionRow,
        BaseReferences<
          _$AppDatabase,
          $GuideDescriptionsTable,
          GuideDescriptionRow
        >,
      ),
      GuideDescriptionRow,
      PrefetchHooks Function()
    >;
typedef $$EncyclopediaPacksTableCreateCompanionBuilder =
    EncyclopediaPacksCompanion Function({
      Value<int> id,
      required String name,
      required double latitude,
      required double longitude,
      required double radiusKm,
      required String languages,
      Value<bool> withPhotos,
      required DateTime createdAt,
    });
typedef $$EncyclopediaPacksTableUpdateCompanionBuilder =
    EncyclopediaPacksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> radiusKm,
      Value<String> languages,
      Value<bool> withPhotos,
      Value<DateTime> createdAt,
    });

final class $$EncyclopediaPacksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EncyclopediaPacksTable,
          EncyclopediaPackRow
        > {
  $$EncyclopediaPacksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $EncyclopediaPackSpeciesTable,
    List<EncyclopediaPackSpeciesRow>
  >
  _encyclopediaPackSpeciesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.encyclopediaPackSpecies,
        aliasName: 'encyclopedia_packs__id__encyclopedia_pack_species__pack_id',
      );

  $$EncyclopediaPackSpeciesTableProcessedTableManager
  get encyclopediaPackSpeciesRefs {
    final manager = $$EncyclopediaPackSpeciesTableTableManager(
      $_db,
      $_db.encyclopediaPackSpecies,
    ).filter((f) => f.packId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _encyclopediaPackSpeciesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EncyclopediaPacksTableFilterComposer
    extends Composer<_$AppDatabase, $EncyclopediaPacksTable> {
  $$EncyclopediaPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusKm => $composableBuilder(
    column: $table.radiusKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languages => $composableBuilder(
    column: $table.languages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get withPhotos => $composableBuilder(
    column: $table.withPhotos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> encyclopediaPackSpeciesRefs(
    Expression<bool> Function($$EncyclopediaPackSpeciesTableFilterComposer f) f,
  ) {
    final $$EncyclopediaPackSpeciesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.encyclopediaPackSpecies,
          getReferencedColumn: (t) => t.packId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EncyclopediaPackSpeciesTableFilterComposer(
                $db: $db,
                $table: $db.encyclopediaPackSpecies,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EncyclopediaPacksTableOrderingComposer
    extends Composer<_$AppDatabase, $EncyclopediaPacksTable> {
  $$EncyclopediaPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusKm => $composableBuilder(
    column: $table.radiusKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languages => $composableBuilder(
    column: $table.languages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get withPhotos => $composableBuilder(
    column: $table.withPhotos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EncyclopediaPacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $EncyclopediaPacksTable> {
  $$EncyclopediaPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusKm =>
      $composableBuilder(column: $table.radiusKm, builder: (column) => column);

  GeneratedColumn<String> get languages =>
      $composableBuilder(column: $table.languages, builder: (column) => column);

  GeneratedColumn<bool> get withPhotos => $composableBuilder(
    column: $table.withPhotos,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> encyclopediaPackSpeciesRefs<T extends Object>(
    Expression<T> Function($$EncyclopediaPackSpeciesTableAnnotationComposer a)
    f,
  ) {
    final $$EncyclopediaPackSpeciesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.encyclopediaPackSpecies,
          getReferencedColumn: (t) => t.packId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EncyclopediaPackSpeciesTableAnnotationComposer(
                $db: $db,
                $table: $db.encyclopediaPackSpecies,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EncyclopediaPacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EncyclopediaPacksTable,
          EncyclopediaPackRow,
          $$EncyclopediaPacksTableFilterComposer,
          $$EncyclopediaPacksTableOrderingComposer,
          $$EncyclopediaPacksTableAnnotationComposer,
          $$EncyclopediaPacksTableCreateCompanionBuilder,
          $$EncyclopediaPacksTableUpdateCompanionBuilder,
          (EncyclopediaPackRow, $$EncyclopediaPacksTableReferences),
          EncyclopediaPackRow,
          PrefetchHooks Function({bool encyclopediaPackSpeciesRefs})
        > {
  $$EncyclopediaPacksTableTableManager(
    _$AppDatabase db,
    $EncyclopediaPacksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EncyclopediaPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EncyclopediaPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EncyclopediaPacksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> radiusKm = const Value.absent(),
                Value<String> languages = const Value.absent(),
                Value<bool> withPhotos = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EncyclopediaPacksCompanion(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm,
                languages: languages,
                withPhotos: withPhotos,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double latitude,
                required double longitude,
                required double radiusKm,
                required String languages,
                Value<bool> withPhotos = const Value.absent(),
                required DateTime createdAt,
              }) => EncyclopediaPacksCompanion.insert(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm,
                languages: languages,
                withPhotos: withPhotos,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EncyclopediaPacksTable, EncyclopediaPackRow>(
                    table,
                  ),
                  $$EncyclopediaPacksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({encyclopediaPackSpeciesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (encyclopediaPackSpeciesRefs) db.encyclopediaPackSpecies,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (encyclopediaPackSpeciesRefs)
                    await $_getPrefetchedData<
                      EncyclopediaPackRow,
                      $EncyclopediaPacksTable,
                      EncyclopediaPackSpeciesRow
                    >(
                      currentTable: table,
                      referencedTable: $$EncyclopediaPacksTableReferences
                          ._encyclopediaPackSpeciesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$EncyclopediaPacksTableReferences(
                            db,
                            table,
                            p0,
                          ).encyclopediaPackSpeciesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.packId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EncyclopediaPacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EncyclopediaPacksTable,
      EncyclopediaPackRow,
      $$EncyclopediaPacksTableFilterComposer,
      $$EncyclopediaPacksTableOrderingComposer,
      $$EncyclopediaPacksTableAnnotationComposer,
      $$EncyclopediaPacksTableCreateCompanionBuilder,
      $$EncyclopediaPacksTableUpdateCompanionBuilder,
      (EncyclopediaPackRow, $$EncyclopediaPacksTableReferences),
      EncyclopediaPackRow,
      PrefetchHooks Function({bool encyclopediaPackSpeciesRefs})
    >;
typedef $$EncyclopediaPackSpeciesTableCreateCompanionBuilder =
    EncyclopediaPackSpeciesCompanion Function({
      required int packId,
      required String scientificName,
      required String commonName,
      Value<int> rowid,
    });
typedef $$EncyclopediaPackSpeciesTableUpdateCompanionBuilder =
    EncyclopediaPackSpeciesCompanion Function({
      Value<int> packId,
      Value<String> scientificName,
      Value<String> commonName,
      Value<int> rowid,
    });

final class $$EncyclopediaPackSpeciesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EncyclopediaPackSpeciesTable,
          EncyclopediaPackSpeciesRow
        > {
  $$EncyclopediaPackSpeciesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EncyclopediaPacksTable _packIdTable(_$AppDatabase db) =>
      db.encyclopediaPacks.createAlias(
        'encyclopedia_pack_species__pack_id__encyclopedia_packs__id',
      );

  $$EncyclopediaPacksTableProcessedTableManager get packId {
    final $_column = $_itemColumn<int>('pack_id')!;

    final manager = $$EncyclopediaPacksTableTableManager(
      $_db,
      $_db.encyclopediaPacks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EncyclopediaPackSpeciesTableFilterComposer
    extends Composer<_$AppDatabase, $EncyclopediaPackSpeciesTable> {
  $$EncyclopediaPackSpeciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnFilters(column),
  );

  $$EncyclopediaPacksTableFilterComposer get packId {
    final $$EncyclopediaPacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.encyclopediaPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EncyclopediaPacksTableFilterComposer(
            $db: $db,
            $table: $db.encyclopediaPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EncyclopediaPackSpeciesTableOrderingComposer
    extends Composer<_$AppDatabase, $EncyclopediaPackSpeciesTable> {
  $$EncyclopediaPackSpeciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnOrderings(column),
  );

  $$EncyclopediaPacksTableOrderingComposer get packId {
    final $$EncyclopediaPacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.encyclopediaPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EncyclopediaPacksTableOrderingComposer(
            $db: $db,
            $table: $db.encyclopediaPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EncyclopediaPackSpeciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EncyclopediaPackSpeciesTable> {
  $$EncyclopediaPackSpeciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => column,
  );

  $$EncyclopediaPacksTableAnnotationComposer get packId {
    final $$EncyclopediaPacksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.packId,
          referencedTable: $db.encyclopediaPacks,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EncyclopediaPacksTableAnnotationComposer(
                $db: $db,
                $table: $db.encyclopediaPacks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$EncyclopediaPackSpeciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EncyclopediaPackSpeciesTable,
          EncyclopediaPackSpeciesRow,
          $$EncyclopediaPackSpeciesTableFilterComposer,
          $$EncyclopediaPackSpeciesTableOrderingComposer,
          $$EncyclopediaPackSpeciesTableAnnotationComposer,
          $$EncyclopediaPackSpeciesTableCreateCompanionBuilder,
          $$EncyclopediaPackSpeciesTableUpdateCompanionBuilder,
          (
            EncyclopediaPackSpeciesRow,
            $$EncyclopediaPackSpeciesTableReferences,
          ),
          EncyclopediaPackSpeciesRow,
          PrefetchHooks Function({bool packId})
        > {
  $$EncyclopediaPackSpeciesTableTableManager(
    _$AppDatabase db,
    $EncyclopediaPackSpeciesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EncyclopediaPackSpeciesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EncyclopediaPackSpeciesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EncyclopediaPackSpeciesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> packId = const Value.absent(),
                Value<String> scientificName = const Value.absent(),
                Value<String> commonName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EncyclopediaPackSpeciesCompanion(
                packId: packId,
                scientificName: scientificName,
                commonName: commonName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int packId,
                required String scientificName,
                required String commonName,
                Value<int> rowid = const Value.absent(),
              }) => EncyclopediaPackSpeciesCompanion.insert(
                packId: packId,
                scientificName: scientificName,
                commonName: commonName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $EncyclopediaPackSpeciesTable,
                    EncyclopediaPackSpeciesRow
                  >(table),
                  $$EncyclopediaPackSpeciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({packId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (packId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.packId,
                        referencedTable:
                            $$EncyclopediaPackSpeciesTableReferences
                                ._packIdTable(db),
                        referencedColumn:
                            $$EncyclopediaPackSpeciesTableReferences
                                ._packIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EncyclopediaPackSpeciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EncyclopediaPackSpeciesTable,
      EncyclopediaPackSpeciesRow,
      $$EncyclopediaPackSpeciesTableFilterComposer,
      $$EncyclopediaPackSpeciesTableOrderingComposer,
      $$EncyclopediaPackSpeciesTableAnnotationComposer,
      $$EncyclopediaPackSpeciesTableCreateCompanionBuilder,
      $$EncyclopediaPackSpeciesTableUpdateCompanionBuilder,
      (EncyclopediaPackSpeciesRow, $$EncyclopediaPackSpeciesTableReferences),
      EncyclopediaPackSpeciesRow,
      PrefetchHooks Function({bool packId})
    >;
typedef $$QuestCompletionsTableCreateCompanionBuilder =
    QuestCompletionsCompanion Function({
      required String day,
      required String questId,
      required int xp,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$QuestCompletionsTableUpdateCompanionBuilder =
    QuestCompletionsCompanion Function({
      Value<String> day,
      Value<String> questId,
      Value<int> xp,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

class $$QuestCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestCompletionsTable> {
  $$QuestCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questId => $composableBuilder(
    column: $table.questId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestCompletionsTable> {
  $$QuestCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questId => $composableBuilder(
    column: $table.questId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestCompletionsTable> {
  $$QuestCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get questId =>
      $composableBuilder(column: $table.questId, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$QuestCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestCompletionsTable,
          QuestCompletionRow,
          $$QuestCompletionsTableFilterComposer,
          $$QuestCompletionsTableOrderingComposer,
          $$QuestCompletionsTableAnnotationComposer,
          $$QuestCompletionsTableCreateCompanionBuilder,
          $$QuestCompletionsTableUpdateCompanionBuilder,
          (
            QuestCompletionRow,
            BaseReferences<
              _$AppDatabase,
              $QuestCompletionsTable,
              QuestCompletionRow
            >,
          ),
          QuestCompletionRow,
          PrefetchHooks Function()
        > {
  $$QuestCompletionsTableTableManager(
    _$AppDatabase db,
    $QuestCompletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<String> questId = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestCompletionsCompanion(
                day: day,
                questId: questId,
                xp: xp,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required String questId,
                required int xp,
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuestCompletionsCompanion.insert(
                day: day,
                questId: questId,
                xp: xp,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestCompletionsTable, QuestCompletionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $QuestCompletionsTable,
                    QuestCompletionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestCompletionsTable,
      QuestCompletionRow,
      $$QuestCompletionsTableFilterComposer,
      $$QuestCompletionsTableOrderingComposer,
      $$QuestCompletionsTableAnnotationComposer,
      $$QuestCompletionsTableCreateCompanionBuilder,
      $$QuestCompletionsTableUpdateCompanionBuilder,
      (
        QuestCompletionRow,
        BaseReferences<
          _$AppDatabase,
          $QuestCompletionsTable,
          QuestCompletionRow
        >,
      ),
      QuestCompletionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SightingsTableTableManager get sightings =>
      $$SightingsTableTableManager(_db, _db.sightings);
  $$SightingPhotosTableTableManager get sightingPhotos =>
      $$SightingPhotosTableTableManager(_db, _db.sightingPhotos);
  $$SpeciesTableTableManager get species =>
      $$SpeciesTableTableManager(_db, _db.species);
  $$DetectionsTableTableManager get detections =>
      $$DetectionsTableTableManager(_db, _db.detections);
  $$GuideDescriptionsTableTableManager get guideDescriptions =>
      $$GuideDescriptionsTableTableManager(_db, _db.guideDescriptions);
  $$EncyclopediaPacksTableTableManager get encyclopediaPacks =>
      $$EncyclopediaPacksTableTableManager(_db, _db.encyclopediaPacks);
  $$EncyclopediaPackSpeciesTableTableManager get encyclopediaPackSpecies =>
      $$EncyclopediaPackSpeciesTableTableManager(
        _db,
        _db.encyclopediaPackSpecies,
      );
  $$QuestCompletionsTableTableManager get questCompletions =>
      $$QuestCompletionsTableTableManager(_db, _db.questCompletions);
}
