// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PuzzlesTable extends Puzzles with TableInfo<$PuzzlesTable, PuzzleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fenMeta = const VerificationMeta('fen');
  @override
  late final GeneratedColumn<String> fen = GeneratedColumn<String>(
    'fen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  @override
  late final GeneratedColumn<String> moves = GeneratedColumn<String>(
    'moves',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _popularityMeta = const VerificationMeta(
    'popularity',
  );
  @override
  late final GeneratedColumn<int> popularity = GeneratedColumn<int>(
    'popularity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, fen, moves, rating, popularity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzles';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fen')) {
      context.handle(
        _fenMeta,
        fen.isAcceptableOrUnknown(data['fen']!, _fenMeta),
      );
    } else if (isInserting) {
      context.missing(_fenMeta);
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    } else if (isInserting) {
      context.missing(_movesMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('popularity')) {
      context.handle(
        _popularityMeta,
        popularity.isAcceptableOrUnknown(data['popularity']!, _popularityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PuzzleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fen'],
      )!,
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moves'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      popularity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}popularity'],
      )!,
    );
  }

  @override
  $PuzzlesTable createAlias(String alias) {
    return $PuzzlesTable(attachedDatabase, alias);
  }
}

class PuzzleRow extends DataClass implements Insertable<PuzzleRow> {
  final String id;
  final String fen;
  final String moves;
  final int rating;
  final int popularity;
  const PuzzleRow({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.popularity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fen'] = Variable<String>(fen);
    map['moves'] = Variable<String>(moves);
    map['rating'] = Variable<int>(rating);
    map['popularity'] = Variable<int>(popularity);
    return map;
  }

  PuzzlesCompanion toCompanion(bool nullToAbsent) {
    return PuzzlesCompanion(
      id: Value(id),
      fen: Value(fen),
      moves: Value(moves),
      rating: Value(rating),
      popularity: Value(popularity),
    );
  }

  factory PuzzleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleRow(
      id: serializer.fromJson<String>(json['id']),
      fen: serializer.fromJson<String>(json['fen']),
      moves: serializer.fromJson<String>(json['moves']),
      rating: serializer.fromJson<int>(json['rating']),
      popularity: serializer.fromJson<int>(json['popularity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fen': serializer.toJson<String>(fen),
      'moves': serializer.toJson<String>(moves),
      'rating': serializer.toJson<int>(rating),
      'popularity': serializer.toJson<int>(popularity),
    };
  }

  PuzzleRow copyWith({
    String? id,
    String? fen,
    String? moves,
    int? rating,
    int? popularity,
  }) => PuzzleRow(
    id: id ?? this.id,
    fen: fen ?? this.fen,
    moves: moves ?? this.moves,
    rating: rating ?? this.rating,
    popularity: popularity ?? this.popularity,
  );
  PuzzleRow copyWithCompanion(PuzzlesCompanion data) {
    return PuzzleRow(
      id: data.id.present ? data.id.value : this.id,
      fen: data.fen.present ? data.fen.value : this.fen,
      moves: data.moves.present ? data.moves.value : this.moves,
      rating: data.rating.present ? data.rating.value : this.rating,
      popularity: data.popularity.present
          ? data.popularity.value
          : this.popularity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleRow(')
          ..write('id: $id, ')
          ..write('fen: $fen, ')
          ..write('moves: $moves, ')
          ..write('rating: $rating, ')
          ..write('popularity: $popularity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fen, moves, rating, popularity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleRow &&
          other.id == this.id &&
          other.fen == this.fen &&
          other.moves == this.moves &&
          other.rating == this.rating &&
          other.popularity == this.popularity);
}

class PuzzlesCompanion extends UpdateCompanion<PuzzleRow> {
  final Value<String> id;
  final Value<String> fen;
  final Value<String> moves;
  final Value<int> rating;
  final Value<int> popularity;
  final Value<int> rowid;
  const PuzzlesCompanion({
    this.id = const Value.absent(),
    this.fen = const Value.absent(),
    this.moves = const Value.absent(),
    this.rating = const Value.absent(),
    this.popularity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzlesCompanion.insert({
    required String id,
    required String fen,
    required String moves,
    required int rating,
    this.popularity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fen = Value(fen),
       moves = Value(moves),
       rating = Value(rating);
  static Insertable<PuzzleRow> custom({
    Expression<String>? id,
    Expression<String>? fen,
    Expression<String>? moves,
    Expression<int>? rating,
    Expression<int>? popularity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fen != null) 'fen': fen,
      if (moves != null) 'moves': moves,
      if (rating != null) 'rating': rating,
      if (popularity != null) 'popularity': popularity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzlesCompanion copyWith({
    Value<String>? id,
    Value<String>? fen,
    Value<String>? moves,
    Value<int>? rating,
    Value<int>? popularity,
    Value<int>? rowid,
  }) {
    return PuzzlesCompanion(
      id: id ?? this.id,
      fen: fen ?? this.fen,
      moves: moves ?? this.moves,
      rating: rating ?? this.rating,
      popularity: popularity ?? this.popularity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fen.present) {
      map['fen'] = Variable<String>(fen.value);
    }
    if (moves.present) {
      map['moves'] = Variable<String>(moves.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (popularity.present) {
      map['popularity'] = Variable<int>(popularity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzlesCompanion(')
          ..write('id: $id, ')
          ..write('fen: $fen, ')
          ..write('moves: $moves, ')
          ..write('rating: $rating, ')
          ..write('popularity: $popularity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuzzleThemesTable extends PuzzleThemes
    with TableInfo<$PuzzleThemesTable, PuzzleThemeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleThemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES puzzles (id)',
    ),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [puzzleId, theme];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_themes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleThemeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId, theme};
  @override
  PuzzleThemeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleThemeRow(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
    );
  }

  @override
  $PuzzleThemesTable createAlias(String alias) {
    return $PuzzleThemesTable(attachedDatabase, alias);
  }
}

class PuzzleThemeRow extends DataClass implements Insertable<PuzzleThemeRow> {
  final String puzzleId;
  final String theme;
  const PuzzleThemeRow({required this.puzzleId, required this.theme});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['theme'] = Variable<String>(theme);
    return map;
  }

  PuzzleThemesCompanion toCompanion(bool nullToAbsent) {
    return PuzzleThemesCompanion(
      puzzleId: Value(puzzleId),
      theme: Value(theme),
    );
  }

  factory PuzzleThemeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleThemeRow(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      theme: serializer.fromJson<String>(json['theme']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'theme': serializer.toJson<String>(theme),
    };
  }

  PuzzleThemeRow copyWith({String? puzzleId, String? theme}) => PuzzleThemeRow(
    puzzleId: puzzleId ?? this.puzzleId,
    theme: theme ?? this.theme,
  );
  PuzzleThemeRow copyWithCompanion(PuzzleThemesCompanion data) {
    return PuzzleThemeRow(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      theme: data.theme.present ? data.theme.value : this.theme,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleThemeRow(')
          ..write('puzzleId: $puzzleId, ')
          ..write('theme: $theme')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(puzzleId, theme);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleThemeRow &&
          other.puzzleId == this.puzzleId &&
          other.theme == this.theme);
}

class PuzzleThemesCompanion extends UpdateCompanion<PuzzleThemeRow> {
  final Value<String> puzzleId;
  final Value<String> theme;
  final Value<int> rowid;
  const PuzzleThemesCompanion({
    this.puzzleId = const Value.absent(),
    this.theme = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzleThemesCompanion.insert({
    required String puzzleId,
    required String theme,
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       theme = Value(theme);
  static Insertable<PuzzleThemeRow> custom({
    Expression<String>? puzzleId,
    Expression<String>? theme,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (theme != null) 'theme': theme,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzleThemesCompanion copyWith({
    Value<String>? puzzleId,
    Value<String>? theme,
    Value<int>? rowid,
  }) {
    return PuzzleThemesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      theme: theme ?? this.theme,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleThemesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('theme: $theme, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuzzleSetsTable extends PuzzleSets
    with TableInfo<$PuzzleSetsTable, PuzzleSetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _ratingMinMeta = const VerificationMeta(
    'ratingMin',
  );
  @override
  late final GeneratedColumn<int> ratingMin = GeneratedColumn<int>(
    'rating_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMaxMeta = const VerificationMeta(
    'ratingMax',
  );
  @override
  late final GeneratedColumn<int> ratingMax = GeneratedColumn<int>(
    'rating_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themesJsonMeta = const VerificationMeta(
    'themesJson',
  );
  @override
  late final GeneratedColumn<String> themesJson = GeneratedColumn<String>(
    'themes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    ratingMin,
    ratingMax,
    themesJson,
    size,
    isSystem,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleSetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('rating_min')) {
      context.handle(
        _ratingMinMeta,
        ratingMin.isAcceptableOrUnknown(data['rating_min']!, _ratingMinMeta),
      );
    }
    if (data.containsKey('rating_max')) {
      context.handle(
        _ratingMaxMeta,
        ratingMax.isAcceptableOrUnknown(data['rating_max']!, _ratingMaxMeta),
      );
    }
    if (data.containsKey('themes_json')) {
      context.handle(
        _themesJsonMeta,
        themesJson.isAcceptableOrUnknown(data['themes_json']!, _themesJsonMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PuzzleSetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleSetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      ratingMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating_min'],
      ),
      ratingMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating_max'],
      ),
      themesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}themes_json'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $PuzzleSetsTable createAlias(String alias) {
    return $PuzzleSetsTable(attachedDatabase, alias);
  }
}

class PuzzleSetRow extends DataClass implements Insertable<PuzzleSetRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  final int? ratingMin;
  final int? ratingMax;
  final String themesJson;
  final int size;
  final bool isSystem;
  final DateTime? archivedAt;
  const PuzzleSetRow({
    required this.id,
    required this.name,
    required this.createdAt,
    this.ratingMin,
    this.ratingMax,
    required this.themesJson,
    required this.size,
    required this.isSystem,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || ratingMin != null) {
      map['rating_min'] = Variable<int>(ratingMin);
    }
    if (!nullToAbsent || ratingMax != null) {
      map['rating_max'] = Variable<int>(ratingMax);
    }
    map['themes_json'] = Variable<String>(themesJson);
    map['size'] = Variable<int>(size);
    map['is_system'] = Variable<bool>(isSystem);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  PuzzleSetsCompanion toCompanion(bool nullToAbsent) {
    return PuzzleSetsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      ratingMin: ratingMin == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingMin),
      ratingMax: ratingMax == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingMax),
      themesJson: Value(themesJson),
      size: Value(size),
      isSystem: Value(isSystem),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory PuzzleSetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleSetRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      ratingMin: serializer.fromJson<int?>(json['ratingMin']),
      ratingMax: serializer.fromJson<int?>(json['ratingMax']),
      themesJson: serializer.fromJson<String>(json['themesJson']),
      size: serializer.fromJson<int>(json['size']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'ratingMin': serializer.toJson<int?>(ratingMin),
      'ratingMax': serializer.toJson<int?>(ratingMax),
      'themesJson': serializer.toJson<String>(themesJson),
      'size': serializer.toJson<int>(size),
      'isSystem': serializer.toJson<bool>(isSystem),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  PuzzleSetRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    Value<int?> ratingMin = const Value.absent(),
    Value<int?> ratingMax = const Value.absent(),
    String? themesJson,
    int? size,
    bool? isSystem,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => PuzzleSetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    ratingMin: ratingMin.present ? ratingMin.value : this.ratingMin,
    ratingMax: ratingMax.present ? ratingMax.value : this.ratingMax,
    themesJson: themesJson ?? this.themesJson,
    size: size ?? this.size,
    isSystem: isSystem ?? this.isSystem,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  PuzzleSetRow copyWithCompanion(PuzzleSetsCompanion data) {
    return PuzzleSetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      ratingMin: data.ratingMin.present ? data.ratingMin.value : this.ratingMin,
      ratingMax: data.ratingMax.present ? data.ratingMax.value : this.ratingMax,
      themesJson: data.themesJson.present
          ? data.themesJson.value
          : this.themesJson,
      size: data.size.present ? data.size.value : this.size,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleSetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('ratingMin: $ratingMin, ')
          ..write('ratingMax: $ratingMax, ')
          ..write('themesJson: $themesJson, ')
          ..write('size: $size, ')
          ..write('isSystem: $isSystem, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    ratingMin,
    ratingMax,
    themesJson,
    size,
    isSystem,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleSetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.ratingMin == this.ratingMin &&
          other.ratingMax == this.ratingMax &&
          other.themesJson == this.themesJson &&
          other.size == this.size &&
          other.isSystem == this.isSystem &&
          other.archivedAt == this.archivedAt);
}

class PuzzleSetsCompanion extends UpdateCompanion<PuzzleSetRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int?> ratingMin;
  final Value<int?> ratingMax;
  final Value<String> themesJson;
  final Value<int> size;
  final Value<bool> isSystem;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const PuzzleSetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ratingMin = const Value.absent(),
    this.ratingMax = const Value.absent(),
    this.themesJson = const Value.absent(),
    this.size = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzleSetsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.ratingMin = const Value.absent(),
    this.ratingMax = const Value.absent(),
    this.themesJson = const Value.absent(),
    required int size,
    this.isSystem = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       size = Value(size);
  static Insertable<PuzzleSetRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? ratingMin,
    Expression<int>? ratingMax,
    Expression<String>? themesJson,
    Expression<int>? size,
    Expression<bool>? isSystem,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (ratingMin != null) 'rating_min': ratingMin,
      if (ratingMax != null) 'rating_max': ratingMax,
      if (themesJson != null) 'themes_json': themesJson,
      if (size != null) 'size': size,
      if (isSystem != null) 'is_system': isSystem,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzleSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int?>? ratingMin,
    Value<int?>? ratingMax,
    Value<String>? themesJson,
    Value<int>? size,
    Value<bool>? isSystem,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return PuzzleSetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      ratingMin: ratingMin ?? this.ratingMin,
      ratingMax: ratingMax ?? this.ratingMax,
      themesJson: themesJson ?? this.themesJson,
      size: size ?? this.size,
      isSystem: isSystem ?? this.isSystem,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (ratingMin.present) {
      map['rating_min'] = Variable<int>(ratingMin.value);
    }
    if (ratingMax.present) {
      map['rating_max'] = Variable<int>(ratingMax.value);
    }
    if (themesJson.present) {
      map['themes_json'] = Variable<String>(themesJson.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleSetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('ratingMin: $ratingMin, ')
          ..write('ratingMax: $ratingMax, ')
          ..write('themesJson: $themesJson, ')
          ..write('size: $size, ')
          ..write('isSystem: $isSystem, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuzzleSetItemsTable extends PuzzleSetItems
    with TableInfo<$PuzzleSetItemsTable, PuzzleSetItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleSetItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
    'set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES puzzle_sets (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [setId, position, puzzleId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_set_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleSetItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('set_id')) {
      context.handle(
        _setIdMeta,
        setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setId, position};
  @override
  PuzzleSetItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleSetItemRow(
      setId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
    );
  }

  @override
  $PuzzleSetItemsTable createAlias(String alias) {
    return $PuzzleSetItemsTable(attachedDatabase, alias);
  }
}

class PuzzleSetItemRow extends DataClass
    implements Insertable<PuzzleSetItemRow> {
  final String setId;
  final int position;
  final String puzzleId;
  const PuzzleSetItemRow({
    required this.setId,
    required this.position,
    required this.puzzleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['set_id'] = Variable<String>(setId);
    map['position'] = Variable<int>(position);
    map['puzzle_id'] = Variable<String>(puzzleId);
    return map;
  }

  PuzzleSetItemsCompanion toCompanion(bool nullToAbsent) {
    return PuzzleSetItemsCompanion(
      setId: Value(setId),
      position: Value(position),
      puzzleId: Value(puzzleId),
    );
  }

  factory PuzzleSetItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleSetItemRow(
      setId: serializer.fromJson<String>(json['setId']),
      position: serializer.fromJson<int>(json['position']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setId': serializer.toJson<String>(setId),
      'position': serializer.toJson<int>(position),
      'puzzleId': serializer.toJson<String>(puzzleId),
    };
  }

  PuzzleSetItemRow copyWith({String? setId, int? position, String? puzzleId}) =>
      PuzzleSetItemRow(
        setId: setId ?? this.setId,
        position: position ?? this.position,
        puzzleId: puzzleId ?? this.puzzleId,
      );
  PuzzleSetItemRow copyWithCompanion(PuzzleSetItemsCompanion data) {
    return PuzzleSetItemRow(
      setId: data.setId.present ? data.setId.value : this.setId,
      position: data.position.present ? data.position.value : this.position,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleSetItemRow(')
          ..write('setId: $setId, ')
          ..write('position: $position, ')
          ..write('puzzleId: $puzzleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(setId, position, puzzleId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleSetItemRow &&
          other.setId == this.setId &&
          other.position == this.position &&
          other.puzzleId == this.puzzleId);
}

class PuzzleSetItemsCompanion extends UpdateCompanion<PuzzleSetItemRow> {
  final Value<String> setId;
  final Value<int> position;
  final Value<String> puzzleId;
  final Value<int> rowid;
  const PuzzleSetItemsCompanion({
    this.setId = const Value.absent(),
    this.position = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzleSetItemsCompanion.insert({
    required String setId,
    required int position,
    required String puzzleId,
    this.rowid = const Value.absent(),
  }) : setId = Value(setId),
       position = Value(position),
       puzzleId = Value(puzzleId);
  static Insertable<PuzzleSetItemRow> custom({
    Expression<String>? setId,
    Expression<int>? position,
    Expression<String>? puzzleId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setId != null) 'set_id': setId,
      if (position != null) 'position': position,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzleSetItemsCompanion copyWith({
    Value<String>? setId,
    Value<int>? position,
    Value<String>? puzzleId,
    Value<int>? rowid,
  }) {
    return PuzzleSetItemsCompanion(
      setId: setId ?? this.setId,
      position: position ?? this.position,
      puzzleId: puzzleId ?? this.puzzleId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleSetItemsCompanion(')
          ..write('setId: $setId, ')
          ..write('position: $position, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoundsTable extends Rounds with TableInfo<$RoundsTable, RoundRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
    'set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES puzzle_sets (id)',
    ),
  );
  static const VerificationMeta _roundNumberMeta = const VerificationMeta(
    'roundNumber',
  );
  @override
  late final GeneratedColumn<int> roundNumber = GeneratedColumn<int>(
    'round_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPositionMeta = const VerificationMeta(
    'currentPosition',
  );
  @override
  late final GeneratedColumn<int> currentPosition = GeneratedColumn<int>(
    'current_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    setId,
    roundNumber,
    startedAt,
    completedAt,
    currentPosition,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoundRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('set_id')) {
      context.handle(
        _setIdMeta,
        setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('round_number')) {
      context.handle(
        _roundNumberMeta,
        roundNumber.isAcceptableOrUnknown(
          data['round_number']!,
          _roundNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundNumberMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('current_position')) {
      context.handle(
        _currentPositionMeta,
        currentPosition.isAcceptableOrUnknown(
          data['current_position']!,
          _currentPositionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoundRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoundRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      setId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_id'],
      )!,
      roundNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_number'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      currentPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_position'],
      )!,
    );
  }

  @override
  $RoundsTable createAlias(String alias) {
    return $RoundsTable(attachedDatabase, alias);
  }
}

class RoundRow extends DataClass implements Insertable<RoundRow> {
  final String id;
  final String setId;
  final int roundNumber;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentPosition;
  const RoundRow({
    required this.id,
    required this.setId,
    required this.roundNumber,
    required this.startedAt,
    this.completedAt,
    required this.currentPosition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_id'] = Variable<String>(setId);
    map['round_number'] = Variable<int>(roundNumber);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['current_position'] = Variable<int>(currentPosition);
    return map;
  }

  RoundsCompanion toCompanion(bool nullToAbsent) {
    return RoundsCompanion(
      id: Value(id),
      setId: Value(setId),
      roundNumber: Value(roundNumber),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      currentPosition: Value(currentPosition),
    );
  }

  factory RoundRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoundRow(
      id: serializer.fromJson<String>(json['id']),
      setId: serializer.fromJson<String>(json['setId']),
      roundNumber: serializer.fromJson<int>(json['roundNumber']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      currentPosition: serializer.fromJson<int>(json['currentPosition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setId': serializer.toJson<String>(setId),
      'roundNumber': serializer.toJson<int>(roundNumber),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'currentPosition': serializer.toJson<int>(currentPosition),
    };
  }

  RoundRow copyWith({
    String? id,
    String? setId,
    int? roundNumber,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? currentPosition,
  }) => RoundRow(
    id: id ?? this.id,
    setId: setId ?? this.setId,
    roundNumber: roundNumber ?? this.roundNumber,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    currentPosition: currentPosition ?? this.currentPosition,
  );
  RoundRow copyWithCompanion(RoundsCompanion data) {
    return RoundRow(
      id: data.id.present ? data.id.value : this.id,
      setId: data.setId.present ? data.setId.value : this.setId,
      roundNumber: data.roundNumber.present
          ? data.roundNumber.value
          : this.roundNumber,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      currentPosition: data.currentPosition.present
          ? data.currentPosition.value
          : this.currentPosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoundRow(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('currentPosition: $currentPosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    setId,
    roundNumber,
    startedAt,
    completedAt,
    currentPosition,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoundRow &&
          other.id == this.id &&
          other.setId == this.setId &&
          other.roundNumber == this.roundNumber &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.currentPosition == this.currentPosition);
}

class RoundsCompanion extends UpdateCompanion<RoundRow> {
  final Value<String> id;
  final Value<String> setId;
  final Value<int> roundNumber;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> currentPosition;
  final Value<int> rowid;
  const RoundsCompanion({
    this.id = const Value.absent(),
    this.setId = const Value.absent(),
    this.roundNumber = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.currentPosition = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoundsCompanion.insert({
    required String id,
    required String setId,
    required int roundNumber,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.currentPosition = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       setId = Value(setId),
       roundNumber = Value(roundNumber),
       startedAt = Value(startedAt);
  static Insertable<RoundRow> custom({
    Expression<String>? id,
    Expression<String>? setId,
    Expression<int>? roundNumber,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? currentPosition,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setId != null) 'set_id': setId,
      if (roundNumber != null) 'round_number': roundNumber,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (currentPosition != null) 'current_position': currentPosition,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoundsCompanion copyWith({
    Value<String>? id,
    Value<String>? setId,
    Value<int>? roundNumber,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? currentPosition,
    Value<int>? rowid,
  }) {
    return RoundsCompanion(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      roundNumber: roundNumber ?? this.roundNumber,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      currentPosition: currentPosition ?? this.currentPosition,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (roundNumber.present) {
      map['round_number'] = Variable<int>(roundNumber.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (currentPosition.present) {
      map['current_position'] = Variable<int>(currentPosition.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoundsCompanion(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('currentPosition: $currentPosition, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts
    with TableInfo<$AttemptsTable, AttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundIdMeta = const VerificationMeta(
    'roundId',
  );
  @override
  late final GeneratedColumn<String> roundId = GeneratedColumn<String>(
    'round_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rounds (id)',
    ),
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintsUsedMeta = const VerificationMeta(
    'hintsUsed',
  );
  @override
  late final GeneratedColumn<int> hintsUsed = GeneratedColumn<int>(
    'hints_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _userMoveUciMeta = const VerificationMeta(
    'userMoveUci',
  );
  @override
  late final GeneratedColumn<String> userMoveUci = GeneratedColumn<String>(
    'user_move_uci',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roundId,
    puzzleId,
    position,
    isCorrect,
    timeMs,
    finishedAt,
    hintsUsed,
    userMoveUci,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('round_id')) {
      context.handle(
        _roundIdMeta,
        roundId.isAcceptableOrUnknown(data['round_id']!, _roundIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roundIdMeta);
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMsMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedAtMeta);
    }
    if (data.containsKey('hints_used')) {
      context.handle(
        _hintsUsedMeta,
        hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta),
      );
    }
    if (data.containsKey('user_move_uci')) {
      context.handle(
        _userMoveUciMeta,
        userMoveUci.isAcceptableOrUnknown(
          data['user_move_uci']!,
          _userMoveUciMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roundId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_id'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      )!,
      hintsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_used'],
      )!,
      userMoveUci: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_move_uci'],
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  final String id;
  final String roundId;
  final String puzzleId;
  final int position;
  final bool isCorrect;
  final int timeMs;
  final DateTime finishedAt;
  final int hintsUsed;
  final String? userMoveUci;
  const AttemptRow({
    required this.id,
    required this.roundId,
    required this.puzzleId,
    required this.position,
    required this.isCorrect,
    required this.timeMs,
    required this.finishedAt,
    required this.hintsUsed,
    this.userMoveUci,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['round_id'] = Variable<String>(roundId);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['position'] = Variable<int>(position);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['time_ms'] = Variable<int>(timeMs);
    map['finished_at'] = Variable<DateTime>(finishedAt);
    map['hints_used'] = Variable<int>(hintsUsed);
    if (!nullToAbsent || userMoveUci != null) {
      map['user_move_uci'] = Variable<String>(userMoveUci);
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      roundId: Value(roundId),
      puzzleId: Value(puzzleId),
      position: Value(position),
      isCorrect: Value(isCorrect),
      timeMs: Value(timeMs),
      finishedAt: Value(finishedAt),
      hintsUsed: Value(hintsUsed),
      userMoveUci: userMoveUci == null && nullToAbsent
          ? const Value.absent()
          : Value(userMoveUci),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<String>(json['id']),
      roundId: serializer.fromJson<String>(json['roundId']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      position: serializer.fromJson<int>(json['position']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      timeMs: serializer.fromJson<int>(json['timeMs']),
      finishedAt: serializer.fromJson<DateTime>(json['finishedAt']),
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      userMoveUci: serializer.fromJson<String?>(json['userMoveUci']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roundId': serializer.toJson<String>(roundId),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'position': serializer.toJson<int>(position),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'timeMs': serializer.toJson<int>(timeMs),
      'finishedAt': serializer.toJson<DateTime>(finishedAt),
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'userMoveUci': serializer.toJson<String?>(userMoveUci),
    };
  }

  AttemptRow copyWith({
    String? id,
    String? roundId,
    String? puzzleId,
    int? position,
    bool? isCorrect,
    int? timeMs,
    DateTime? finishedAt,
    int? hintsUsed,
    Value<String?> userMoveUci = const Value.absent(),
  }) => AttemptRow(
    id: id ?? this.id,
    roundId: roundId ?? this.roundId,
    puzzleId: puzzleId ?? this.puzzleId,
    position: position ?? this.position,
    isCorrect: isCorrect ?? this.isCorrect,
    timeMs: timeMs ?? this.timeMs,
    finishedAt: finishedAt ?? this.finishedAt,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    userMoveUci: userMoveUci.present ? userMoveUci.value : this.userMoveUci,
  );
  AttemptRow copyWithCompanion(AttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      roundId: data.roundId.present ? data.roundId.value : this.roundId,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      position: data.position.present ? data.position.value : this.position,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      userMoveUci: data.userMoveUci.present
          ? data.userMoveUci.value
          : this.userMoveUci,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('roundId: $roundId, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('position: $position, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('timeMs: $timeMs, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('userMoveUci: $userMoveUci')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roundId,
    puzzleId,
    position,
    isCorrect,
    timeMs,
    finishedAt,
    hintsUsed,
    userMoveUci,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.roundId == this.roundId &&
          other.puzzleId == this.puzzleId &&
          other.position == this.position &&
          other.isCorrect == this.isCorrect &&
          other.timeMs == this.timeMs &&
          other.finishedAt == this.finishedAt &&
          other.hintsUsed == this.hintsUsed &&
          other.userMoveUci == this.userMoveUci);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<String> id;
  final Value<String> roundId;
  final Value<String> puzzleId;
  final Value<int> position;
  final Value<bool> isCorrect;
  final Value<int> timeMs;
  final Value<DateTime> finishedAt;
  final Value<int> hintsUsed;
  final Value<String?> userMoveUci;
  final Value<int> rowid;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.roundId = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.position = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.userMoveUci = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttemptsCompanion.insert({
    required String id,
    required String roundId,
    required String puzzleId,
    required int position,
    required bool isCorrect,
    required int timeMs,
    required DateTime finishedAt,
    this.hintsUsed = const Value.absent(),
    this.userMoveUci = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roundId = Value(roundId),
       puzzleId = Value(puzzleId),
       position = Value(position),
       isCorrect = Value(isCorrect),
       timeMs = Value(timeMs),
       finishedAt = Value(finishedAt);
  static Insertable<AttemptRow> custom({
    Expression<String>? id,
    Expression<String>? roundId,
    Expression<String>? puzzleId,
    Expression<int>? position,
    Expression<bool>? isCorrect,
    Expression<int>? timeMs,
    Expression<DateTime>? finishedAt,
    Expression<int>? hintsUsed,
    Expression<String>? userMoveUci,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roundId != null) 'round_id': roundId,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (position != null) 'position': position,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (timeMs != null) 'time_ms': timeMs,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (userMoveUci != null) 'user_move_uci': userMoveUci,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttemptsCompanion copyWith({
    Value<String>? id,
    Value<String>? roundId,
    Value<String>? puzzleId,
    Value<int>? position,
    Value<bool>? isCorrect,
    Value<int>? timeMs,
    Value<DateTime>? finishedAt,
    Value<int>? hintsUsed,
    Value<String?>? userMoveUci,
    Value<int>? rowid,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      puzzleId: puzzleId ?? this.puzzleId,
      position: position ?? this.position,
      isCorrect: isCorrect ?? this.isCorrect,
      timeMs: timeMs ?? this.timeMs,
      finishedAt: finishedAt ?? this.finishedAt,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      userMoveUci: userMoveUci ?? this.userMoveUci,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roundId.present) {
      map['round_id'] = Variable<String>(roundId.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (userMoveUci.present) {
      map['user_move_uci'] = Variable<String>(userMoveUci.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('roundId: $roundId, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('position: $position, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('timeMs: $timeMs, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('userMoveUci: $userMoveUci, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BotGamesTable extends BotGames
    with TableInfo<$BotGamesTable, BotGameRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BotGamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fenMeta = const VerificationMeta('fen');
  @override
  late final GeneratedColumn<String> fen = GeneratedColumn<String>(
    'fen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMoveUciMeta = const VerificationMeta(
    'lastMoveUci',
  );
  @override
  late final GeneratedColumn<String> lastMoveUci = GeneratedColumn<String>(
    'last_move_uci',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userSideMeta = const VerificationMeta(
    'userSide',
  );
  @override
  late final GeneratedColumn<String> userSide = GeneratedColumn<String>(
    'user_side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    fen,
    lastMoveUci,
    userSide,
    level,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bot_games';
  @override
  VerificationContext validateIntegrity(
    Insertable<BotGameRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fen')) {
      context.handle(
        _fenMeta,
        fen.isAcceptableOrUnknown(data['fen']!, _fenMeta),
      );
    } else if (isInserting) {
      context.missing(_fenMeta);
    }
    if (data.containsKey('last_move_uci')) {
      context.handle(
        _lastMoveUciMeta,
        lastMoveUci.isAcceptableOrUnknown(
          data['last_move_uci']!,
          _lastMoveUciMeta,
        ),
      );
    }
    if (data.containsKey('user_side')) {
      context.handle(
        _userSideMeta,
        userSide.isAcceptableOrUnknown(data['user_side']!, _userSideMeta),
      );
    } else if (isInserting) {
      context.missing(_userSideMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
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
  BotGameRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BotGameRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fen'],
      )!,
      lastMoveUci: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_move_uci'],
      ),
      userSide: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_side'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
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
  $BotGamesTable createAlias(String alias) {
    return $BotGamesTable(attachedDatabase, alias);
  }
}

class BotGameRow extends DataClass implements Insertable<BotGameRow> {
  final String id;
  final String fen;
  final String? lastMoveUci;
  final String userSide;
  final int level;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BotGameRow({
    required this.id,
    required this.fen,
    this.lastMoveUci,
    required this.userSide,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fen'] = Variable<String>(fen);
    if (!nullToAbsent || lastMoveUci != null) {
      map['last_move_uci'] = Variable<String>(lastMoveUci);
    }
    map['user_side'] = Variable<String>(userSide);
    map['level'] = Variable<int>(level);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BotGamesCompanion toCompanion(bool nullToAbsent) {
    return BotGamesCompanion(
      id: Value(id),
      fen: Value(fen),
      lastMoveUci: lastMoveUci == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMoveUci),
      userSide: Value(userSide),
      level: Value(level),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BotGameRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BotGameRow(
      id: serializer.fromJson<String>(json['id']),
      fen: serializer.fromJson<String>(json['fen']),
      lastMoveUci: serializer.fromJson<String?>(json['lastMoveUci']),
      userSide: serializer.fromJson<String>(json['userSide']),
      level: serializer.fromJson<int>(json['level']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fen': serializer.toJson<String>(fen),
      'lastMoveUci': serializer.toJson<String?>(lastMoveUci),
      'userSide': serializer.toJson<String>(userSide),
      'level': serializer.toJson<int>(level),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BotGameRow copyWith({
    String? id,
    String? fen,
    Value<String?> lastMoveUci = const Value.absent(),
    String? userSide,
    int? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BotGameRow(
    id: id ?? this.id,
    fen: fen ?? this.fen,
    lastMoveUci: lastMoveUci.present ? lastMoveUci.value : this.lastMoveUci,
    userSide: userSide ?? this.userSide,
    level: level ?? this.level,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BotGameRow copyWithCompanion(BotGamesCompanion data) {
    return BotGameRow(
      id: data.id.present ? data.id.value : this.id,
      fen: data.fen.present ? data.fen.value : this.fen,
      lastMoveUci: data.lastMoveUci.present
          ? data.lastMoveUci.value
          : this.lastMoveUci,
      userSide: data.userSide.present ? data.userSide.value : this.userSide,
      level: data.level.present ? data.level.value : this.level,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BotGameRow(')
          ..write('id: $id, ')
          ..write('fen: $fen, ')
          ..write('lastMoveUci: $lastMoveUci, ')
          ..write('userSide: $userSide, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fen, lastMoveUci, userSide, level, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BotGameRow &&
          other.id == this.id &&
          other.fen == this.fen &&
          other.lastMoveUci == this.lastMoveUci &&
          other.userSide == this.userSide &&
          other.level == this.level &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BotGamesCompanion extends UpdateCompanion<BotGameRow> {
  final Value<String> id;
  final Value<String> fen;
  final Value<String?> lastMoveUci;
  final Value<String> userSide;
  final Value<int> level;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BotGamesCompanion({
    this.id = const Value.absent(),
    this.fen = const Value.absent(),
    this.lastMoveUci = const Value.absent(),
    this.userSide = const Value.absent(),
    this.level = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BotGamesCompanion.insert({
    required String id,
    required String fen,
    this.lastMoveUci = const Value.absent(),
    required String userSide,
    required int level,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fen = Value(fen),
       userSide = Value(userSide),
       level = Value(level),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BotGameRow> custom({
    Expression<String>? id,
    Expression<String>? fen,
    Expression<String>? lastMoveUci,
    Expression<String>? userSide,
    Expression<int>? level,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fen != null) 'fen': fen,
      if (lastMoveUci != null) 'last_move_uci': lastMoveUci,
      if (userSide != null) 'user_side': userSide,
      if (level != null) 'level': level,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BotGamesCompanion copyWith({
    Value<String>? id,
    Value<String>? fen,
    Value<String?>? lastMoveUci,
    Value<String>? userSide,
    Value<int>? level,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BotGamesCompanion(
      id: id ?? this.id,
      fen: fen ?? this.fen,
      lastMoveUci: lastMoveUci ?? this.lastMoveUci,
      userSide: userSide ?? this.userSide,
      level: level ?? this.level,
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
    if (fen.present) {
      map['fen'] = Variable<String>(fen.value);
    }
    if (lastMoveUci.present) {
      map['last_move_uci'] = Variable<String>(lastMoveUci.value);
    }
    if (userSide.present) {
      map['user_side'] = Variable<String>(userSide.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
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
    return (StringBuffer('BotGamesCompanion(')
          ..write('id: $id, ')
          ..write('fen: $fen, ')
          ..write('lastMoveUci: $lastMoveUci, ')
          ..write('userSide: $userSide, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserStatesTable extends UserStates
    with TableInfo<$UserStatesTable, UserStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eloMeta = const VerificationMeta('elo');
  @override
  late final GeneratedColumn<int> elo = GeneratedColumn<int>(
    'elo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1500),
  );
  static const VerificationMeta _attemptsTotalMeta = const VerificationMeta(
    'attemptsTotal',
  );
  @override
  late final GeneratedColumn<int> attemptsTotal = GeneratedColumn<int>(
    'attempts_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _calibrationStatusMeta = const VerificationMeta(
    'calibrationStatus',
  );
  @override
  late final GeneratedColumn<String> calibrationStatus =
      GeneratedColumn<String>(
        'calibration_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
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
    elo,
    attemptsTotal,
    calibrationStatus,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('elo')) {
      context.handle(
        _eloMeta,
        elo.isAcceptableOrUnknown(data['elo']!, _eloMeta),
      );
    }
    if (data.containsKey('attempts_total')) {
      context.handle(
        _attemptsTotalMeta,
        attemptsTotal.isAcceptableOrUnknown(
          data['attempts_total']!,
          _attemptsTotalMeta,
        ),
      );
    }
    if (data.containsKey('calibration_status')) {
      context.handle(
        _calibrationStatusMeta,
        calibrationStatus.isAcceptableOrUnknown(
          data['calibration_status']!,
          _calibrationStatusMeta,
        ),
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
  UserStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      elo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elo'],
      )!,
      attemptsTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts_total'],
      )!,
      calibrationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calibration_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserStatesTable createAlias(String alias) {
    return $UserStatesTable(attachedDatabase, alias);
  }
}

class UserStateRow extends DataClass implements Insertable<UserStateRow> {
  final String id;
  final int elo;
  final int attemptsTotal;
  final String calibrationStatus;
  final DateTime updatedAt;
  const UserStateRow({
    required this.id,
    required this.elo,
    required this.attemptsTotal,
    required this.calibrationStatus,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['elo'] = Variable<int>(elo);
    map['attempts_total'] = Variable<int>(attemptsTotal);
    map['calibration_status'] = Variable<String>(calibrationStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserStatesCompanion toCompanion(bool nullToAbsent) {
    return UserStatesCompanion(
      id: Value(id),
      elo: Value(elo),
      attemptsTotal: Value(attemptsTotal),
      calibrationStatus: Value(calibrationStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserStateRow(
      id: serializer.fromJson<String>(json['id']),
      elo: serializer.fromJson<int>(json['elo']),
      attemptsTotal: serializer.fromJson<int>(json['attemptsTotal']),
      calibrationStatus: serializer.fromJson<String>(json['calibrationStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'elo': serializer.toJson<int>(elo),
      'attemptsTotal': serializer.toJson<int>(attemptsTotal),
      'calibrationStatus': serializer.toJson<String>(calibrationStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserStateRow copyWith({
    String? id,
    int? elo,
    int? attemptsTotal,
    String? calibrationStatus,
    DateTime? updatedAt,
  }) => UserStateRow(
    id: id ?? this.id,
    elo: elo ?? this.elo,
    attemptsTotal: attemptsTotal ?? this.attemptsTotal,
    calibrationStatus: calibrationStatus ?? this.calibrationStatus,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserStateRow copyWithCompanion(UserStatesCompanion data) {
    return UserStateRow(
      id: data.id.present ? data.id.value : this.id,
      elo: data.elo.present ? data.elo.value : this.elo,
      attemptsTotal: data.attemptsTotal.present
          ? data.attemptsTotal.value
          : this.attemptsTotal,
      calibrationStatus: data.calibrationStatus.present
          ? data.calibrationStatus.value
          : this.calibrationStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserStateRow(')
          ..write('id: $id, ')
          ..write('elo: $elo, ')
          ..write('attemptsTotal: $attemptsTotal, ')
          ..write('calibrationStatus: $calibrationStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, elo, attemptsTotal, calibrationStatus, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserStateRow &&
          other.id == this.id &&
          other.elo == this.elo &&
          other.attemptsTotal == this.attemptsTotal &&
          other.calibrationStatus == this.calibrationStatus &&
          other.updatedAt == this.updatedAt);
}

class UserStatesCompanion extends UpdateCompanion<UserStateRow> {
  final Value<String> id;
  final Value<int> elo;
  final Value<int> attemptsTotal;
  final Value<String> calibrationStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserStatesCompanion({
    this.id = const Value.absent(),
    this.elo = const Value.absent(),
    this.attemptsTotal = const Value.absent(),
    this.calibrationStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserStatesCompanion.insert({
    required String id,
    this.elo = const Value.absent(),
    this.attemptsTotal = const Value.absent(),
    this.calibrationStatus = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt);
  static Insertable<UserStateRow> custom({
    Expression<String>? id,
    Expression<int>? elo,
    Expression<int>? attemptsTotal,
    Expression<String>? calibrationStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (elo != null) 'elo': elo,
      if (attemptsTotal != null) 'attempts_total': attemptsTotal,
      if (calibrationStatus != null) 'calibration_status': calibrationStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserStatesCompanion copyWith({
    Value<String>? id,
    Value<int>? elo,
    Value<int>? attemptsTotal,
    Value<String>? calibrationStatus,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserStatesCompanion(
      id: id ?? this.id,
      elo: elo ?? this.elo,
      attemptsTotal: attemptsTotal ?? this.attemptsTotal,
      calibrationStatus: calibrationStatus ?? this.calibrationStatus,
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
    if (elo.present) {
      map['elo'] = Variable<int>(elo.value);
    }
    if (attemptsTotal.present) {
      map['attempts_total'] = Variable<int>(attemptsTotal.value);
    }
    if (calibrationStatus.present) {
      map['calibration_status'] = Variable<String>(calibrationStatus.value);
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
    return (StringBuffer('UserStatesCompanion(')
          ..write('id: $id, ')
          ..write('elo: $elo, ')
          ..write('attemptsTotal: $attemptsTotal, ')
          ..write('calibrationStatus: $calibrationStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EloHistoryTable extends EloHistory
    with TableInfo<$EloHistoryTable, EloHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EloHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _puzzleRatingMeta = const VerificationMeta(
    'puzzleRating',
  );
  @override
  late final GeneratedColumn<int> puzzleRating = GeneratedColumn<int>(
    'puzzle_rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eloBeforeMeta = const VerificationMeta(
    'eloBefore',
  );
  @override
  late final GeneratedColumn<int> eloBefore = GeneratedColumn<int>(
    'elo_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eloAfterMeta = const VerificationMeta(
    'eloAfter',
  );
  @override
  late final GeneratedColumn<int> eloAfter = GeneratedColumn<int>(
    'elo_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasCorrectMeta = const VerificationMeta(
    'wasCorrect',
  );
  @override
  late final GeneratedColumn<bool> wasCorrect = GeneratedColumn<bool>(
    'was_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    puzzleId,
    puzzleRating,
    eloBefore,
    eloAfter,
    wasCorrect,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'elo_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<EloHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('puzzle_rating')) {
      context.handle(
        _puzzleRatingMeta,
        puzzleRating.isAcceptableOrUnknown(
          data['puzzle_rating']!,
          _puzzleRatingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_puzzleRatingMeta);
    }
    if (data.containsKey('elo_before')) {
      context.handle(
        _eloBeforeMeta,
        eloBefore.isAcceptableOrUnknown(data['elo_before']!, _eloBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_eloBeforeMeta);
    }
    if (data.containsKey('elo_after')) {
      context.handle(
        _eloAfterMeta,
        eloAfter.isAcceptableOrUnknown(data['elo_after']!, _eloAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_eloAfterMeta);
    }
    if (data.containsKey('was_correct')) {
      context.handle(
        _wasCorrectMeta,
        wasCorrect.isAcceptableOrUnknown(data['was_correct']!, _wasCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_wasCorrectMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EloHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EloHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      puzzleRating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puzzle_rating'],
      )!,
      eloBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elo_before'],
      )!,
      eloAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elo_after'],
      )!,
      wasCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_correct'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $EloHistoryTable createAlias(String alias) {
    return $EloHistoryTable(attachedDatabase, alias);
  }
}

class EloHistoryRow extends DataClass implements Insertable<EloHistoryRow> {
  final int id;
  final String puzzleId;
  final int puzzleRating;
  final int eloBefore;
  final int eloAfter;
  final bool wasCorrect;
  final DateTime at;
  const EloHistoryRow({
    required this.id,
    required this.puzzleId,
    required this.puzzleRating,
    required this.eloBefore,
    required this.eloAfter,
    required this.wasCorrect,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['puzzle_rating'] = Variable<int>(puzzleRating);
    map['elo_before'] = Variable<int>(eloBefore);
    map['elo_after'] = Variable<int>(eloAfter);
    map['was_correct'] = Variable<bool>(wasCorrect);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  EloHistoryCompanion toCompanion(bool nullToAbsent) {
    return EloHistoryCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      puzzleRating: Value(puzzleRating),
      eloBefore: Value(eloBefore),
      eloAfter: Value(eloAfter),
      wasCorrect: Value(wasCorrect),
      at: Value(at),
    );
  }

  factory EloHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EloHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      puzzleRating: serializer.fromJson<int>(json['puzzleRating']),
      eloBefore: serializer.fromJson<int>(json['eloBefore']),
      eloAfter: serializer.fromJson<int>(json['eloAfter']),
      wasCorrect: serializer.fromJson<bool>(json['wasCorrect']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'puzzleRating': serializer.toJson<int>(puzzleRating),
      'eloBefore': serializer.toJson<int>(eloBefore),
      'eloAfter': serializer.toJson<int>(eloAfter),
      'wasCorrect': serializer.toJson<bool>(wasCorrect),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  EloHistoryRow copyWith({
    int? id,
    String? puzzleId,
    int? puzzleRating,
    int? eloBefore,
    int? eloAfter,
    bool? wasCorrect,
    DateTime? at,
  }) => EloHistoryRow(
    id: id ?? this.id,
    puzzleId: puzzleId ?? this.puzzleId,
    puzzleRating: puzzleRating ?? this.puzzleRating,
    eloBefore: eloBefore ?? this.eloBefore,
    eloAfter: eloAfter ?? this.eloAfter,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    at: at ?? this.at,
  );
  EloHistoryRow copyWithCompanion(EloHistoryCompanion data) {
    return EloHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      puzzleRating: data.puzzleRating.present
          ? data.puzzleRating.value
          : this.puzzleRating,
      eloBefore: data.eloBefore.present ? data.eloBefore.value : this.eloBefore,
      eloAfter: data.eloAfter.present ? data.eloAfter.value : this.eloAfter,
      wasCorrect: data.wasCorrect.present
          ? data.wasCorrect.value
          : this.wasCorrect,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EloHistoryRow(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('puzzleRating: $puzzleRating, ')
          ..write('eloBefore: $eloBefore, ')
          ..write('eloAfter: $eloAfter, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    puzzleId,
    puzzleRating,
    eloBefore,
    eloAfter,
    wasCorrect,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EloHistoryRow &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.puzzleRating == this.puzzleRating &&
          other.eloBefore == this.eloBefore &&
          other.eloAfter == this.eloAfter &&
          other.wasCorrect == this.wasCorrect &&
          other.at == this.at);
}

class EloHistoryCompanion extends UpdateCompanion<EloHistoryRow> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<int> puzzleRating;
  final Value<int> eloBefore;
  final Value<int> eloAfter;
  final Value<bool> wasCorrect;
  final Value<DateTime> at;
  const EloHistoryCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.puzzleRating = const Value.absent(),
    this.eloBefore = const Value.absent(),
    this.eloAfter = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.at = const Value.absent(),
  });
  EloHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required int puzzleRating,
    required int eloBefore,
    required int eloAfter,
    required bool wasCorrect,
    required DateTime at,
  }) : puzzleId = Value(puzzleId),
       puzzleRating = Value(puzzleRating),
       eloBefore = Value(eloBefore),
       eloAfter = Value(eloAfter),
       wasCorrect = Value(wasCorrect),
       at = Value(at);
  static Insertable<EloHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<int>? puzzleRating,
    Expression<int>? eloBefore,
    Expression<int>? eloAfter,
    Expression<bool>? wasCorrect,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (puzzleRating != null) 'puzzle_rating': puzzleRating,
      if (eloBefore != null) 'elo_before': eloBefore,
      if (eloAfter != null) 'elo_after': eloAfter,
      if (wasCorrect != null) 'was_correct': wasCorrect,
      if (at != null) 'at': at,
    });
  }

  EloHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? puzzleId,
    Value<int>? puzzleRating,
    Value<int>? eloBefore,
    Value<int>? eloAfter,
    Value<bool>? wasCorrect,
    Value<DateTime>? at,
  }) {
    return EloHistoryCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      puzzleRating: puzzleRating ?? this.puzzleRating,
      eloBefore: eloBefore ?? this.eloBefore,
      eloAfter: eloAfter ?? this.eloAfter,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (puzzleRating.present) {
      map['puzzle_rating'] = Variable<int>(puzzleRating.value);
    }
    if (eloBefore.present) {
      map['elo_before'] = Variable<int>(eloBefore.value);
    }
    if (eloAfter.present) {
      map['elo_after'] = Variable<int>(eloAfter.value);
    }
    if (wasCorrect.present) {
      map['was_correct'] = Variable<bool>(wasCorrect.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EloHistoryCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('puzzleRating: $puzzleRating, ')
          ..write('eloBefore: $eloBefore, ')
          ..write('eloAfter: $eloAfter, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PuzzlesTable puzzles = $PuzzlesTable(this);
  late final $PuzzleThemesTable puzzleThemes = $PuzzleThemesTable(this);
  late final $PuzzleSetsTable puzzleSets = $PuzzleSetsTable(this);
  late final $PuzzleSetItemsTable puzzleSetItems = $PuzzleSetItemsTable(this);
  late final $RoundsTable rounds = $RoundsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $BotGamesTable botGames = $BotGamesTable(this);
  late final $UserStatesTable userStates = $UserStatesTable(this);
  late final $EloHistoryTable eloHistory = $EloHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    puzzles,
    puzzleThemes,
    puzzleSets,
    puzzleSetItems,
    rounds,
    attempts,
    botGames,
    userStates,
    eloHistory,
  ];
}

typedef $$PuzzlesTableCreateCompanionBuilder =
    PuzzlesCompanion Function({
      required String id,
      required String fen,
      required String moves,
      required int rating,
      Value<int> popularity,
      Value<int> rowid,
    });
typedef $$PuzzlesTableUpdateCompanionBuilder =
    PuzzlesCompanion Function({
      Value<String> id,
      Value<String> fen,
      Value<String> moves,
      Value<int> rating,
      Value<int> popularity,
      Value<int> rowid,
    });

final class $$PuzzlesTableReferences
    extends BaseReferences<_$AppDatabase, $PuzzlesTable, PuzzleRow> {
  $$PuzzlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PuzzleThemesTable, List<PuzzleThemeRow>>
  _puzzleThemesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.puzzleThemes,
    aliasName: $_aliasNameGenerator(db.puzzles.id, db.puzzleThemes.puzzleId),
  );

  $$PuzzleThemesTableProcessedTableManager get puzzleThemesRefs {
    final manager = $$PuzzleThemesTableTableManager(
      $_db,
      $_db.puzzleThemes,
    ).filter((f) => f.puzzleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_puzzleThemesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PuzzlesTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableFilterComposer({
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

  ColumnFilters<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> puzzleThemesRefs(
    Expression<bool> Function($$PuzzleThemesTableFilterComposer f) f,
  ) {
    final $$PuzzleThemesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.puzzleThemes,
      getReferencedColumn: (t) => t.puzzleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleThemesTableFilterComposer(
            $db: $db,
            $table: $db.puzzleThemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PuzzlesTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableOrderingComposer({
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

  ColumnOrderings<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fen =>
      $composableBuilder(column: $table.fen, builder: (column) => column);

  GeneratedColumn<String> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => column,
  );

  Expression<T> puzzleThemesRefs<T extends Object>(
    Expression<T> Function($$PuzzleThemesTableAnnotationComposer a) f,
  ) {
    final $$PuzzleThemesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.puzzleThemes,
      getReferencedColumn: (t) => t.puzzleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleThemesTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzleThemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PuzzlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzlesTable,
          PuzzleRow,
          $$PuzzlesTableFilterComposer,
          $$PuzzlesTableOrderingComposer,
          $$PuzzlesTableAnnotationComposer,
          $$PuzzlesTableCreateCompanionBuilder,
          $$PuzzlesTableUpdateCompanionBuilder,
          (PuzzleRow, $$PuzzlesTableReferences),
          PuzzleRow,
          PrefetchHooks Function({bool puzzleThemesRefs})
        > {
  $$PuzzlesTableTableManager(_$AppDatabase db, $PuzzlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fen = const Value.absent(),
                Value<String> moves = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> popularity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion(
                id: id,
                fen: fen,
                moves: moves,
                rating: rating,
                popularity: popularity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fen,
                required String moves,
                required int rating,
                Value<int> popularity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion.insert(
                id: id,
                fen: fen,
                moves: moves,
                rating: rating,
                popularity: popularity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PuzzlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({puzzleThemesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (puzzleThemesRefs) db.puzzleThemes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (puzzleThemesRefs)
                    await $_getPrefetchedData<
                      PuzzleRow,
                      $PuzzlesTable,
                      PuzzleThemeRow
                    >(
                      currentTable: table,
                      referencedTable: $$PuzzlesTableReferences
                          ._puzzleThemesRefsTable(db),
                      managerFromTypedResult: (p0) => $$PuzzlesTableReferences(
                        db,
                        table,
                        p0,
                      ).puzzleThemesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.puzzleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PuzzlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzlesTable,
      PuzzleRow,
      $$PuzzlesTableFilterComposer,
      $$PuzzlesTableOrderingComposer,
      $$PuzzlesTableAnnotationComposer,
      $$PuzzlesTableCreateCompanionBuilder,
      $$PuzzlesTableUpdateCompanionBuilder,
      (PuzzleRow, $$PuzzlesTableReferences),
      PuzzleRow,
      PrefetchHooks Function({bool puzzleThemesRefs})
    >;
typedef $$PuzzleThemesTableCreateCompanionBuilder =
    PuzzleThemesCompanion Function({
      required String puzzleId,
      required String theme,
      Value<int> rowid,
    });
typedef $$PuzzleThemesTableUpdateCompanionBuilder =
    PuzzleThemesCompanion Function({
      Value<String> puzzleId,
      Value<String> theme,
      Value<int> rowid,
    });

final class $$PuzzleThemesTableReferences
    extends BaseReferences<_$AppDatabase, $PuzzleThemesTable, PuzzleThemeRow> {
  $$PuzzleThemesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PuzzlesTable _puzzleIdTable(_$AppDatabase db) =>
      db.puzzles.createAlias(
        $_aliasNameGenerator(db.puzzleThemes.puzzleId, db.puzzles.id),
      );

  $$PuzzlesTableProcessedTableManager get puzzleId {
    final $_column = $_itemColumn<String>('puzzle_id')!;

    final manager = $$PuzzlesTableTableManager(
      $_db,
      $_db.puzzles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_puzzleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PuzzleThemesTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleThemesTable> {
  $$PuzzleThemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  $$PuzzlesTableFilterComposer get puzzleId {
    final $$PuzzlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.puzzleId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableFilterComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleThemesTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleThemesTable> {
  $$PuzzleThemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  $$PuzzlesTableOrderingComposer get puzzleId {
    final $$PuzzlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.puzzleId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableOrderingComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleThemesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleThemesTable> {
  $$PuzzleThemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  $$PuzzlesTableAnnotationComposer get puzzleId {
    final $$PuzzlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.puzzleId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleThemesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzleThemesTable,
          PuzzleThemeRow,
          $$PuzzleThemesTableFilterComposer,
          $$PuzzleThemesTableOrderingComposer,
          $$PuzzleThemesTableAnnotationComposer,
          $$PuzzleThemesTableCreateCompanionBuilder,
          $$PuzzleThemesTableUpdateCompanionBuilder,
          (PuzzleThemeRow, $$PuzzleThemesTableReferences),
          PuzzleThemeRow,
          PrefetchHooks Function({bool puzzleId})
        > {
  $$PuzzleThemesTableTableManager(_$AppDatabase db, $PuzzleThemesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleThemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleThemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleThemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleThemesCompanion(
                puzzleId: puzzleId,
                theme: theme,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                required String theme,
                Value<int> rowid = const Value.absent(),
              }) => PuzzleThemesCompanion.insert(
                puzzleId: puzzleId,
                theme: theme,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PuzzleThemesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({puzzleId = false}) {
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
                    if (puzzleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.puzzleId,
                                referencedTable: $$PuzzleThemesTableReferences
                                    ._puzzleIdTable(db),
                                referencedColumn: $$PuzzleThemesTableReferences
                                    ._puzzleIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$PuzzleThemesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzleThemesTable,
      PuzzleThemeRow,
      $$PuzzleThemesTableFilterComposer,
      $$PuzzleThemesTableOrderingComposer,
      $$PuzzleThemesTableAnnotationComposer,
      $$PuzzleThemesTableCreateCompanionBuilder,
      $$PuzzleThemesTableUpdateCompanionBuilder,
      (PuzzleThemeRow, $$PuzzleThemesTableReferences),
      PuzzleThemeRow,
      PrefetchHooks Function({bool puzzleId})
    >;
typedef $$PuzzleSetsTableCreateCompanionBuilder =
    PuzzleSetsCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<int?> ratingMin,
      Value<int?> ratingMax,
      Value<String> themesJson,
      required int size,
      Value<bool> isSystem,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });
typedef $$PuzzleSetsTableUpdateCompanionBuilder =
    PuzzleSetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int?> ratingMin,
      Value<int?> ratingMax,
      Value<String> themesJson,
      Value<int> size,
      Value<bool> isSystem,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });

final class $$PuzzleSetsTableReferences
    extends BaseReferences<_$AppDatabase, $PuzzleSetsTable, PuzzleSetRow> {
  $$PuzzleSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PuzzleSetItemsTable, List<PuzzleSetItemRow>>
  _puzzleSetItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.puzzleSetItems,
    aliasName: $_aliasNameGenerator(db.puzzleSets.id, db.puzzleSetItems.setId),
  );

  $$PuzzleSetItemsTableProcessedTableManager get puzzleSetItemsRefs {
    final manager = $$PuzzleSetItemsTableTableManager(
      $_db,
      $_db.puzzleSetItems,
    ).filter((f) => f.setId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_puzzleSetItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RoundsTable, List<RoundRow>> _roundsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rounds,
    aliasName: $_aliasNameGenerator(db.puzzleSets.id, db.rounds.setId),
  );

  $$RoundsTableProcessedTableManager get roundsRefs {
    final manager = $$RoundsTableTableManager(
      $_db,
      $_db.rounds,
    ).filter((f) => f.setId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_roundsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PuzzleSetsTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleSetsTable> {
  $$PuzzleSetsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratingMin => $composableBuilder(
    column: $table.ratingMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratingMax => $composableBuilder(
    column: $table.ratingMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themesJson => $composableBuilder(
    column: $table.themesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> puzzleSetItemsRefs(
    Expression<bool> Function($$PuzzleSetItemsTableFilterComposer f) f,
  ) {
    final $$PuzzleSetItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.puzzleSetItems,
      getReferencedColumn: (t) => t.setId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetItemsTableFilterComposer(
            $db: $db,
            $table: $db.puzzleSetItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> roundsRefs(
    Expression<bool> Function($$RoundsTableFilterComposer f) f,
  ) {
    final $$RoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.setId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableFilterComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PuzzleSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleSetsTable> {
  $$PuzzleSetsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratingMin => $composableBuilder(
    column: $table.ratingMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratingMax => $composableBuilder(
    column: $table.ratingMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themesJson => $composableBuilder(
    column: $table.themesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzleSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleSetsTable> {
  $$PuzzleSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get ratingMin =>
      $composableBuilder(column: $table.ratingMin, builder: (column) => column);

  GeneratedColumn<int> get ratingMax =>
      $composableBuilder(column: $table.ratingMax, builder: (column) => column);

  GeneratedColumn<String> get themesJson => $composableBuilder(
    column: $table.themesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  Expression<T> puzzleSetItemsRefs<T extends Object>(
    Expression<T> Function($$PuzzleSetItemsTableAnnotationComposer a) f,
  ) {
    final $$PuzzleSetItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.puzzleSetItems,
      getReferencedColumn: (t) => t.setId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzleSetItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> roundsRefs<T extends Object>(
    Expression<T> Function($$RoundsTableAnnotationComposer a) f,
  ) {
    final $$RoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.setId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PuzzleSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzleSetsTable,
          PuzzleSetRow,
          $$PuzzleSetsTableFilterComposer,
          $$PuzzleSetsTableOrderingComposer,
          $$PuzzleSetsTableAnnotationComposer,
          $$PuzzleSetsTableCreateCompanionBuilder,
          $$PuzzleSetsTableUpdateCompanionBuilder,
          (PuzzleSetRow, $$PuzzleSetsTableReferences),
          PuzzleSetRow,
          PrefetchHooks Function({bool puzzleSetItemsRefs, bool roundsRefs})
        > {
  $$PuzzleSetsTableTableManager(_$AppDatabase db, $PuzzleSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> ratingMin = const Value.absent(),
                Value<int?> ratingMax = const Value.absent(),
                Value<String> themesJson = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSetsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                ratingMin: ratingMin,
                ratingMax: ratingMax,
                themesJson: themesJson,
                size: size,
                isSystem: isSystem,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<int?> ratingMin = const Value.absent(),
                Value<int?> ratingMax = const Value.absent(),
                Value<String> themesJson = const Value.absent(),
                required int size,
                Value<bool> isSystem = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSetsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                ratingMin: ratingMin,
                ratingMax: ratingMax,
                themesJson: themesJson,
                size: size,
                isSystem: isSystem,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PuzzleSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({puzzleSetItemsRefs = false, roundsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (puzzleSetItemsRefs) db.puzzleSetItems,
                    if (roundsRefs) db.rounds,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (puzzleSetItemsRefs)
                        await $_getPrefetchedData<
                          PuzzleSetRow,
                          $PuzzleSetsTable,
                          PuzzleSetItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$PuzzleSetsTableReferences
                              ._puzzleSetItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PuzzleSetsTableReferences(
                                db,
                                table,
                                p0,
                              ).puzzleSetItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.setId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (roundsRefs)
                        await $_getPrefetchedData<
                          PuzzleSetRow,
                          $PuzzleSetsTable,
                          RoundRow
                        >(
                          currentTable: table,
                          referencedTable: $$PuzzleSetsTableReferences
                              ._roundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PuzzleSetsTableReferences(
                                db,
                                table,
                                p0,
                              ).roundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.setId == item.id,
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

typedef $$PuzzleSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzleSetsTable,
      PuzzleSetRow,
      $$PuzzleSetsTableFilterComposer,
      $$PuzzleSetsTableOrderingComposer,
      $$PuzzleSetsTableAnnotationComposer,
      $$PuzzleSetsTableCreateCompanionBuilder,
      $$PuzzleSetsTableUpdateCompanionBuilder,
      (PuzzleSetRow, $$PuzzleSetsTableReferences),
      PuzzleSetRow,
      PrefetchHooks Function({bool puzzleSetItemsRefs, bool roundsRefs})
    >;
typedef $$PuzzleSetItemsTableCreateCompanionBuilder =
    PuzzleSetItemsCompanion Function({
      required String setId,
      required int position,
      required String puzzleId,
      Value<int> rowid,
    });
typedef $$PuzzleSetItemsTableUpdateCompanionBuilder =
    PuzzleSetItemsCompanion Function({
      Value<String> setId,
      Value<int> position,
      Value<String> puzzleId,
      Value<int> rowid,
    });

final class $$PuzzleSetItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PuzzleSetItemsTable, PuzzleSetItemRow> {
  $$PuzzleSetItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PuzzleSetsTable _setIdTable(_$AppDatabase db) =>
      db.puzzleSets.createAlias(
        $_aliasNameGenerator(db.puzzleSetItems.setId, db.puzzleSets.id),
      );

  $$PuzzleSetsTableProcessedTableManager get setId {
    final $_column = $_itemColumn<String>('set_id')!;

    final manager = $$PuzzleSetsTableTableManager(
      $_db,
      $_db.puzzleSets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PuzzleSetItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleSetItemsTable> {
  $$PuzzleSetItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  $$PuzzleSetsTableFilterComposer get setId {
    final $$PuzzleSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.puzzleSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetsTableFilterComposer(
            $db: $db,
            $table: $db.puzzleSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleSetItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleSetItemsTable> {
  $$PuzzleSetItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PuzzleSetsTableOrderingComposer get setId {
    final $$PuzzleSetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.puzzleSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetsTableOrderingComposer(
            $db: $db,
            $table: $db.puzzleSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleSetItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleSetItemsTable> {
  $$PuzzleSetItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  $$PuzzleSetsTableAnnotationComposer get setId {
    final $$PuzzleSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.puzzleSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzleSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleSetItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzleSetItemsTable,
          PuzzleSetItemRow,
          $$PuzzleSetItemsTableFilterComposer,
          $$PuzzleSetItemsTableOrderingComposer,
          $$PuzzleSetItemsTableAnnotationComposer,
          $$PuzzleSetItemsTableCreateCompanionBuilder,
          $$PuzzleSetItemsTableUpdateCompanionBuilder,
          (PuzzleSetItemRow, $$PuzzleSetItemsTableReferences),
          PuzzleSetItemRow,
          PrefetchHooks Function({bool setId})
        > {
  $$PuzzleSetItemsTableTableManager(
    _$AppDatabase db,
    $PuzzleSetItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleSetItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleSetItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleSetItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> setId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSetItemsCompanion(
                setId: setId,
                position: position,
                puzzleId: puzzleId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String setId,
                required int position,
                required String puzzleId,
                Value<int> rowid = const Value.absent(),
              }) => PuzzleSetItemsCompanion.insert(
                setId: setId,
                position: position,
                puzzleId: puzzleId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PuzzleSetItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setId = false}) {
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
                    if (setId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.setId,
                                referencedTable: $$PuzzleSetItemsTableReferences
                                    ._setIdTable(db),
                                referencedColumn:
                                    $$PuzzleSetItemsTableReferences
                                        ._setIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$PuzzleSetItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzleSetItemsTable,
      PuzzleSetItemRow,
      $$PuzzleSetItemsTableFilterComposer,
      $$PuzzleSetItemsTableOrderingComposer,
      $$PuzzleSetItemsTableAnnotationComposer,
      $$PuzzleSetItemsTableCreateCompanionBuilder,
      $$PuzzleSetItemsTableUpdateCompanionBuilder,
      (PuzzleSetItemRow, $$PuzzleSetItemsTableReferences),
      PuzzleSetItemRow,
      PrefetchHooks Function({bool setId})
    >;
typedef $$RoundsTableCreateCompanionBuilder =
    RoundsCompanion Function({
      required String id,
      required String setId,
      required int roundNumber,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> currentPosition,
      Value<int> rowid,
    });
typedef $$RoundsTableUpdateCompanionBuilder =
    RoundsCompanion Function({
      Value<String> id,
      Value<String> setId,
      Value<int> roundNumber,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> currentPosition,
      Value<int> rowid,
    });

final class $$RoundsTableReferences
    extends BaseReferences<_$AppDatabase, $RoundsTable, RoundRow> {
  $$RoundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PuzzleSetsTable _setIdTable(_$AppDatabase db) => db.puzzleSets
      .createAlias($_aliasNameGenerator(db.rounds.setId, db.puzzleSets.id));

  $$PuzzleSetsTableProcessedTableManager get setId {
    final $_column = $_itemColumn<String>('set_id')!;

    final manager = $$PuzzleSetsTableTableManager(
      $_db,
      $_db.puzzleSets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttemptsTable, List<AttemptRow>>
  _attemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attempts,
    aliasName: $_aliasNameGenerator(db.rounds.id, db.attempts.roundId),
  );

  $$AttemptsTableProcessedTableManager get attemptsRefs {
    final manager = $$AttemptsTableTableManager(
      $_db,
      $_db.attempts,
    ).filter((f) => f.roundId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoundsTableFilterComposer
    extends Composer<_$AppDatabase, $RoundsTable> {
  $$RoundsTableFilterComposer({
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

  ColumnFilters<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPosition => $composableBuilder(
    column: $table.currentPosition,
    builder: (column) => ColumnFilters(column),
  );

  $$PuzzleSetsTableFilterComposer get setId {
    final $$PuzzleSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.puzzleSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetsTableFilterComposer(
            $db: $db,
            $table: $db.puzzleSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attemptsRefs(
    Expression<bool> Function($$AttemptsTableFilterComposer f) f,
  ) {
    final $$AttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.roundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableFilterComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoundsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoundsTable> {
  $$RoundsTableOrderingComposer({
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

  ColumnOrderings<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPosition => $composableBuilder(
    column: $table.currentPosition,
    builder: (column) => ColumnOrderings(column),
  );

  $$PuzzleSetsTableOrderingComposer get setId {
    final $$PuzzleSetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.puzzleSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetsTableOrderingComposer(
            $db: $db,
            $table: $db.puzzleSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoundsTable> {
  $$RoundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPosition => $composableBuilder(
    column: $table.currentPosition,
    builder: (column) => column,
  );

  $$PuzzleSetsTableAnnotationComposer get setId {
    final $$PuzzleSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.puzzleSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzleSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attemptsRefs<T extends Object>(
    Expression<T> Function($$AttemptsTableAnnotationComposer a) f,
  ) {
    final $$AttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.roundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoundsTable,
          RoundRow,
          $$RoundsTableFilterComposer,
          $$RoundsTableOrderingComposer,
          $$RoundsTableAnnotationComposer,
          $$RoundsTableCreateCompanionBuilder,
          $$RoundsTableUpdateCompanionBuilder,
          (RoundRow, $$RoundsTableReferences),
          RoundRow,
          PrefetchHooks Function({bool setId, bool attemptsRefs})
        > {
  $$RoundsTableTableManager(_$AppDatabase db, $RoundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> setId = const Value.absent(),
                Value<int> roundNumber = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> currentPosition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoundsCompanion(
                id: id,
                setId: setId,
                roundNumber: roundNumber,
                startedAt: startedAt,
                completedAt: completedAt,
                currentPosition: currentPosition,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String setId,
                required int roundNumber,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> currentPosition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoundsCompanion.insert(
                id: id,
                setId: setId,
                roundNumber: roundNumber,
                startedAt: startedAt,
                completedAt: completedAt,
                currentPosition: currentPosition,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoundsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({setId = false, attemptsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attemptsRefs) db.attempts],
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
                    if (setId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.setId,
                                referencedTable: $$RoundsTableReferences
                                    ._setIdTable(db),
                                referencedColumn: $$RoundsTableReferences
                                    ._setIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attemptsRefs)
                    await $_getPrefetchedData<
                      RoundRow,
                      $RoundsTable,
                      AttemptRow
                    >(
                      currentTable: table,
                      referencedTable: $$RoundsTableReferences
                          ._attemptsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RoundsTableReferences(db, table, p0).attemptsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.roundId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoundsTable,
      RoundRow,
      $$RoundsTableFilterComposer,
      $$RoundsTableOrderingComposer,
      $$RoundsTableAnnotationComposer,
      $$RoundsTableCreateCompanionBuilder,
      $$RoundsTableUpdateCompanionBuilder,
      (RoundRow, $$RoundsTableReferences),
      RoundRow,
      PrefetchHooks Function({bool setId, bool attemptsRefs})
    >;
typedef $$AttemptsTableCreateCompanionBuilder =
    AttemptsCompanion Function({
      required String id,
      required String roundId,
      required String puzzleId,
      required int position,
      required bool isCorrect,
      required int timeMs,
      required DateTime finishedAt,
      Value<int> hintsUsed,
      Value<String?> userMoveUci,
      Value<int> rowid,
    });
typedef $$AttemptsTableUpdateCompanionBuilder =
    AttemptsCompanion Function({
      Value<String> id,
      Value<String> roundId,
      Value<String> puzzleId,
      Value<int> position,
      Value<bool> isCorrect,
      Value<int> timeMs,
      Value<DateTime> finishedAt,
      Value<int> hintsUsed,
      Value<String?> userMoveUci,
      Value<int> rowid,
    });

final class $$AttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow> {
  $$AttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoundsTable _roundIdTable(_$AppDatabase db) => db.rounds.createAlias(
    $_aliasNameGenerator(db.attempts.roundId, db.rounds.id),
  );

  $$RoundsTableProcessedTableManager get roundId {
    final $_column = $_itemColumn<String>('round_id')!;

    final manager = $$RoundsTableTableManager(
      $_db,
      $_db.rounds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
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

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userMoveUci => $composableBuilder(
    column: $table.userMoveUci,
    builder: (column) => ColumnFilters(column),
  );

  $$RoundsTableFilterComposer get roundId {
    final $$RoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundId,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableFilterComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
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

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userMoveUci => $composableBuilder(
    column: $table.userMoveUci,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoundsTableOrderingComposer get roundId {
    final $$RoundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundId,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableOrderingComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<String> get userMoveUci => $composableBuilder(
    column: $table.userMoveUci,
    builder: (column) => column,
  );

  $$RoundsTableAnnotationComposer get roundId {
    final $$RoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundId,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptsTable,
          AttemptRow,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (AttemptRow, $$AttemptsTableReferences),
          AttemptRow,
          PrefetchHooks Function({bool roundId})
        > {
  $$AttemptsTableTableManager(_$AppDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roundId = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                Value<DateTime> finishedAt = const Value.absent(),
                Value<int> hintsUsed = const Value.absent(),
                Value<String?> userMoveUci = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                roundId: roundId,
                puzzleId: puzzleId,
                position: position,
                isCorrect: isCorrect,
                timeMs: timeMs,
                finishedAt: finishedAt,
                hintsUsed: hintsUsed,
                userMoveUci: userMoveUci,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roundId,
                required String puzzleId,
                required int position,
                required bool isCorrect,
                required int timeMs,
                required DateTime finishedAt,
                Value<int> hintsUsed = const Value.absent(),
                Value<String?> userMoveUci = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                roundId: roundId,
                puzzleId: puzzleId,
                position: position,
                isCorrect: isCorrect,
                timeMs: timeMs,
                finishedAt: finishedAt,
                hintsUsed: hintsUsed,
                userMoveUci: userMoveUci,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({roundId = false}) {
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
                    if (roundId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.roundId,
                                referencedTable: $$AttemptsTableReferences
                                    ._roundIdTable(db),
                                referencedColumn: $$AttemptsTableReferences
                                    ._roundIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptsTable,
      AttemptRow,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (AttemptRow, $$AttemptsTableReferences),
      AttemptRow,
      PrefetchHooks Function({bool roundId})
    >;
typedef $$BotGamesTableCreateCompanionBuilder =
    BotGamesCompanion Function({
      required String id,
      required String fen,
      Value<String?> lastMoveUci,
      required String userSide,
      required int level,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BotGamesTableUpdateCompanionBuilder =
    BotGamesCompanion Function({
      Value<String> id,
      Value<String> fen,
      Value<String?> lastMoveUci,
      Value<String> userSide,
      Value<int> level,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BotGamesTableFilterComposer
    extends Composer<_$AppDatabase, $BotGamesTable> {
  $$BotGamesTableFilterComposer({
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

  ColumnFilters<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMoveUci => $composableBuilder(
    column: $table.lastMoveUci,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userSide => $composableBuilder(
    column: $table.userSide,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
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

class $$BotGamesTableOrderingComposer
    extends Composer<_$AppDatabase, $BotGamesTable> {
  $$BotGamesTableOrderingComposer({
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

  ColumnOrderings<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMoveUci => $composableBuilder(
    column: $table.lastMoveUci,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userSide => $composableBuilder(
    column: $table.userSide,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
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

class $$BotGamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BotGamesTable> {
  $$BotGamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fen =>
      $composableBuilder(column: $table.fen, builder: (column) => column);

  GeneratedColumn<String> get lastMoveUci => $composableBuilder(
    column: $table.lastMoveUci,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userSide =>
      $composableBuilder(column: $table.userSide, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BotGamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BotGamesTable,
          BotGameRow,
          $$BotGamesTableFilterComposer,
          $$BotGamesTableOrderingComposer,
          $$BotGamesTableAnnotationComposer,
          $$BotGamesTableCreateCompanionBuilder,
          $$BotGamesTableUpdateCompanionBuilder,
          (
            BotGameRow,
            BaseReferences<_$AppDatabase, $BotGamesTable, BotGameRow>,
          ),
          BotGameRow,
          PrefetchHooks Function()
        > {
  $$BotGamesTableTableManager(_$AppDatabase db, $BotGamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BotGamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BotGamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BotGamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fen = const Value.absent(),
                Value<String?> lastMoveUci = const Value.absent(),
                Value<String> userSide = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BotGamesCompanion(
                id: id,
                fen: fen,
                lastMoveUci: lastMoveUci,
                userSide: userSide,
                level: level,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fen,
                Value<String?> lastMoveUci = const Value.absent(),
                required String userSide,
                required int level,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BotGamesCompanion.insert(
                id: id,
                fen: fen,
                lastMoveUci: lastMoveUci,
                userSide: userSide,
                level: level,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BotGamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BotGamesTable,
      BotGameRow,
      $$BotGamesTableFilterComposer,
      $$BotGamesTableOrderingComposer,
      $$BotGamesTableAnnotationComposer,
      $$BotGamesTableCreateCompanionBuilder,
      $$BotGamesTableUpdateCompanionBuilder,
      (BotGameRow, BaseReferences<_$AppDatabase, $BotGamesTable, BotGameRow>),
      BotGameRow,
      PrefetchHooks Function()
    >;
typedef $$UserStatesTableCreateCompanionBuilder =
    UserStatesCompanion Function({
      required String id,
      Value<int> elo,
      Value<int> attemptsTotal,
      Value<String> calibrationStatus,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserStatesTableUpdateCompanionBuilder =
    UserStatesCompanion Function({
      Value<String> id,
      Value<int> elo,
      Value<int> attemptsTotal,
      Value<String> calibrationStatus,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserStatesTableFilterComposer
    extends Composer<_$AppDatabase, $UserStatesTable> {
  $$UserStatesTableFilterComposer({
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

  ColumnFilters<int> get elo => $composableBuilder(
    column: $table.elo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptsTotal => $composableBuilder(
    column: $table.attemptsTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calibrationStatus => $composableBuilder(
    column: $table.calibrationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserStatesTable> {
  $$UserStatesTableOrderingComposer({
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

  ColumnOrderings<int> get elo => $composableBuilder(
    column: $table.elo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptsTotal => $composableBuilder(
    column: $table.attemptsTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calibrationStatus => $composableBuilder(
    column: $table.calibrationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserStatesTable> {
  $$UserStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get elo =>
      $composableBuilder(column: $table.elo, builder: (column) => column);

  GeneratedColumn<int> get attemptsTotal => $composableBuilder(
    column: $table.attemptsTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calibrationStatus => $composableBuilder(
    column: $table.calibrationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserStatesTable,
          UserStateRow,
          $$UserStatesTableFilterComposer,
          $$UserStatesTableOrderingComposer,
          $$UserStatesTableAnnotationComposer,
          $$UserStatesTableCreateCompanionBuilder,
          $$UserStatesTableUpdateCompanionBuilder,
          (
            UserStateRow,
            BaseReferences<_$AppDatabase, $UserStatesTable, UserStateRow>,
          ),
          UserStateRow,
          PrefetchHooks Function()
        > {
  $$UserStatesTableTableManager(_$AppDatabase db, $UserStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> elo = const Value.absent(),
                Value<int> attemptsTotal = const Value.absent(),
                Value<String> calibrationStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserStatesCompanion(
                id: id,
                elo: elo,
                attemptsTotal: attemptsTotal,
                calibrationStatus: calibrationStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> elo = const Value.absent(),
                Value<int> attemptsTotal = const Value.absent(),
                Value<String> calibrationStatus = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserStatesCompanion.insert(
                id: id,
                elo: elo,
                attemptsTotal: attemptsTotal,
                calibrationStatus: calibrationStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserStatesTable,
      UserStateRow,
      $$UserStatesTableFilterComposer,
      $$UserStatesTableOrderingComposer,
      $$UserStatesTableAnnotationComposer,
      $$UserStatesTableCreateCompanionBuilder,
      $$UserStatesTableUpdateCompanionBuilder,
      (
        UserStateRow,
        BaseReferences<_$AppDatabase, $UserStatesTable, UserStateRow>,
      ),
      UserStateRow,
      PrefetchHooks Function()
    >;
typedef $$EloHistoryTableCreateCompanionBuilder =
    EloHistoryCompanion Function({
      Value<int> id,
      required String puzzleId,
      required int puzzleRating,
      required int eloBefore,
      required int eloAfter,
      required bool wasCorrect,
      required DateTime at,
    });
typedef $$EloHistoryTableUpdateCompanionBuilder =
    EloHistoryCompanion Function({
      Value<int> id,
      Value<String> puzzleId,
      Value<int> puzzleRating,
      Value<int> eloBefore,
      Value<int> eloAfter,
      Value<bool> wasCorrect,
      Value<DateTime> at,
    });

class $$EloHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $EloHistoryTable> {
  $$EloHistoryTableFilterComposer({
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

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get puzzleRating => $composableBuilder(
    column: $table.puzzleRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eloBefore => $composableBuilder(
    column: $table.eloBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eloAfter => $composableBuilder(
    column: $table.eloAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EloHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $EloHistoryTable> {
  $$EloHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puzzleRating => $composableBuilder(
    column: $table.puzzleRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eloBefore => $composableBuilder(
    column: $table.eloBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eloAfter => $composableBuilder(
    column: $table.eloAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EloHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $EloHistoryTable> {
  $$EloHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<int> get puzzleRating => $composableBuilder(
    column: $table.puzzleRating,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eloBefore =>
      $composableBuilder(column: $table.eloBefore, builder: (column) => column);

  GeneratedColumn<int> get eloAfter =>
      $composableBuilder(column: $table.eloAfter, builder: (column) => column);

  GeneratedColumn<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$EloHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EloHistoryTable,
          EloHistoryRow,
          $$EloHistoryTableFilterComposer,
          $$EloHistoryTableOrderingComposer,
          $$EloHistoryTableAnnotationComposer,
          $$EloHistoryTableCreateCompanionBuilder,
          $$EloHistoryTableUpdateCompanionBuilder,
          (
            EloHistoryRow,
            BaseReferences<_$AppDatabase, $EloHistoryTable, EloHistoryRow>,
          ),
          EloHistoryRow,
          PrefetchHooks Function()
        > {
  $$EloHistoryTableTableManager(_$AppDatabase db, $EloHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EloHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EloHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EloHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<int> puzzleRating = const Value.absent(),
                Value<int> eloBefore = const Value.absent(),
                Value<int> eloAfter = const Value.absent(),
                Value<bool> wasCorrect = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => EloHistoryCompanion(
                id: id,
                puzzleId: puzzleId,
                puzzleRating: puzzleRating,
                eloBefore: eloBefore,
                eloAfter: eloAfter,
                wasCorrect: wasCorrect,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String puzzleId,
                required int puzzleRating,
                required int eloBefore,
                required int eloAfter,
                required bool wasCorrect,
                required DateTime at,
              }) => EloHistoryCompanion.insert(
                id: id,
                puzzleId: puzzleId,
                puzzleRating: puzzleRating,
                eloBefore: eloBefore,
                eloAfter: eloAfter,
                wasCorrect: wasCorrect,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EloHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EloHistoryTable,
      EloHistoryRow,
      $$EloHistoryTableFilterComposer,
      $$EloHistoryTableOrderingComposer,
      $$EloHistoryTableAnnotationComposer,
      $$EloHistoryTableCreateCompanionBuilder,
      $$EloHistoryTableUpdateCompanionBuilder,
      (
        EloHistoryRow,
        BaseReferences<_$AppDatabase, $EloHistoryTable, EloHistoryRow>,
      ),
      EloHistoryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PuzzlesTableTableManager get puzzles =>
      $$PuzzlesTableTableManager(_db, _db.puzzles);
  $$PuzzleThemesTableTableManager get puzzleThemes =>
      $$PuzzleThemesTableTableManager(_db, _db.puzzleThemes);
  $$PuzzleSetsTableTableManager get puzzleSets =>
      $$PuzzleSetsTableTableManager(_db, _db.puzzleSets);
  $$PuzzleSetItemsTableTableManager get puzzleSetItems =>
      $$PuzzleSetItemsTableTableManager(_db, _db.puzzleSetItems);
  $$RoundsTableTableManager get rounds =>
      $$RoundsTableTableManager(_db, _db.rounds);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$BotGamesTableTableManager get botGames =>
      $$BotGamesTableTableManager(_db, _db.botGames);
  $$UserStatesTableTableManager get userStates =>
      $$UserStatesTableTableManager(_db, _db.userStates);
  $$EloHistoryTableTableManager get eloHistory =>
      $$EloHistoryTableTableManager(_db, _db.eloHistory);
}
