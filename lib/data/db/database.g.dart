// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StoriesTable extends Stories with TableInfo<$StoriesTable, StoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _byMeta = const VerificationMeta('by');
  @override
  late final GeneratedColumn<String> by = GeneratedColumn<String>(
    'by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commentCountMeta = const VerificationMeta(
    'commentCount',
  );
  @override
  late final GeneratedColumn<int> commentCount = GeneratedColumn<int>(
    'comment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('story'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeen = GeneratedColumn<DateTime>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentsFetchedAtMeta = const VerificationMeta(
    'commentsFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> commentsFetchedAt =
      GeneratedColumn<DateTime>(
        'comments_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _readMeta = const VerificationMeta('read');
  @override
  late final GeneratedColumn<bool> read = GeneratedColumn<bool>(
    'read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _savedMeta = const VerificationMeta('saved');
  @override
  late final GeneratedColumn<bool> saved = GeneratedColumn<bool>(
    'saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    url,
    domain,
    by,
    points,
    commentCount,
    time,
    type,
    body,
    firstSeen,
    lastSeen,
    commentsFetchedAt,
    read,
    saved,
    savedAt,
    hidden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('by')) {
      context.handle(_byMeta, by.isAcceptableOrUnknown(data['by']!, _byMeta));
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('comment_count')) {
      context.handle(
        _commentCountMeta,
        commentCount.isAcceptableOrUnknown(
          data['comment_count']!,
          _commentCountMeta,
        ),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('comments_fetched_at')) {
      context.handle(
        _commentsFetchedAtMeta,
        commentsFetchedAt.isAcceptableOrUnknown(
          data['comments_fetched_at']!,
          _commentsFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('read')) {
      context.handle(
        _readMeta,
        read.isAcceptableOrUnknown(data['read']!, _readMeta),
      );
    }
    if (data.containsKey('saved')) {
      context.handle(
        _savedMeta,
        saved.isAcceptableOrUnknown(data['saved']!, _savedMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
      by: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by'],
      ),
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      ),
      commentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comment_count'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}time'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      firstSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
      commentsFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}comments_fetched_at'],
      ),
      read: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read'],
      )!,
      saved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}saved'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class StoryRow extends DataClass implements Insertable<StoryRow> {
  final int id;
  final String title;
  final String? url;
  final String? domain;
  final String? by;
  final int? points;
  final int commentCount;
  final DateTime? time;
  final String type;
  final String? body;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final DateTime? commentsFetchedAt;
  final bool read;
  final bool saved;
  final DateTime? savedAt;
  final bool hidden;
  const StoryRow({
    required this.id,
    required this.title,
    this.url,
    this.domain,
    this.by,
    this.points,
    required this.commentCount,
    this.time,
    required this.type,
    this.body,
    required this.firstSeen,
    required this.lastSeen,
    this.commentsFetchedAt,
    required this.read,
    required this.saved,
    this.savedAt,
    required this.hidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    if (!nullToAbsent || by != null) {
      map['by'] = Variable<String>(by);
    }
    if (!nullToAbsent || points != null) {
      map['points'] = Variable<int>(points);
    }
    map['comment_count'] = Variable<int>(commentCount);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<DateTime>(time);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['first_seen'] = Variable<DateTime>(firstSeen);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    if (!nullToAbsent || commentsFetchedAt != null) {
      map['comments_fetched_at'] = Variable<DateTime>(commentsFetchedAt);
    }
    map['read'] = Variable<bool>(read);
    map['saved'] = Variable<bool>(saved);
    if (!nullToAbsent || savedAt != null) {
      map['saved_at'] = Variable<DateTime>(savedAt);
    }
    map['hidden'] = Variable<bool>(hidden);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      id: Value(id),
      title: Value(title),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
      by: by == null && nullToAbsent ? const Value.absent() : Value(by),
      points: points == null && nullToAbsent
          ? const Value.absent()
          : Value(points),
      commentCount: Value(commentCount),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      type: Value(type),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      firstSeen: Value(firstSeen),
      lastSeen: Value(lastSeen),
      commentsFetchedAt: commentsFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(commentsFetchedAt),
      read: Value(read),
      saved: Value(saved),
      savedAt: savedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(savedAt),
      hidden: Value(hidden),
    );
  }

  factory StoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String?>(json['url']),
      domain: serializer.fromJson<String?>(json['domain']),
      by: serializer.fromJson<String?>(json['by']),
      points: serializer.fromJson<int?>(json['points']),
      commentCount: serializer.fromJson<int>(json['commentCount']),
      time: serializer.fromJson<DateTime?>(json['time']),
      type: serializer.fromJson<String>(json['type']),
      body: serializer.fromJson<String?>(json['body']),
      firstSeen: serializer.fromJson<DateTime>(json['firstSeen']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      commentsFetchedAt: serializer.fromJson<DateTime?>(
        json['commentsFetchedAt'],
      ),
      read: serializer.fromJson<bool>(json['read']),
      saved: serializer.fromJson<bool>(json['saved']),
      savedAt: serializer.fromJson<DateTime?>(json['savedAt']),
      hidden: serializer.fromJson<bool>(json['hidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String?>(url),
      'domain': serializer.toJson<String?>(domain),
      'by': serializer.toJson<String?>(by),
      'points': serializer.toJson<int?>(points),
      'commentCount': serializer.toJson<int>(commentCount),
      'time': serializer.toJson<DateTime?>(time),
      'type': serializer.toJson<String>(type),
      'body': serializer.toJson<String?>(body),
      'firstSeen': serializer.toJson<DateTime>(firstSeen),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'commentsFetchedAt': serializer.toJson<DateTime?>(commentsFetchedAt),
      'read': serializer.toJson<bool>(read),
      'saved': serializer.toJson<bool>(saved),
      'savedAt': serializer.toJson<DateTime?>(savedAt),
      'hidden': serializer.toJson<bool>(hidden),
    };
  }

  StoryRow copyWith({
    int? id,
    String? title,
    Value<String?> url = const Value.absent(),
    Value<String?> domain = const Value.absent(),
    Value<String?> by = const Value.absent(),
    Value<int?> points = const Value.absent(),
    int? commentCount,
    Value<DateTime?> time = const Value.absent(),
    String? type,
    Value<String?> body = const Value.absent(),
    DateTime? firstSeen,
    DateTime? lastSeen,
    Value<DateTime?> commentsFetchedAt = const Value.absent(),
    bool? read,
    bool? saved,
    Value<DateTime?> savedAt = const Value.absent(),
    bool? hidden,
  }) => StoryRow(
    id: id ?? this.id,
    title: title ?? this.title,
    url: url.present ? url.value : this.url,
    domain: domain.present ? domain.value : this.domain,
    by: by.present ? by.value : this.by,
    points: points.present ? points.value : this.points,
    commentCount: commentCount ?? this.commentCount,
    time: time.present ? time.value : this.time,
    type: type ?? this.type,
    body: body.present ? body.value : this.body,
    firstSeen: firstSeen ?? this.firstSeen,
    lastSeen: lastSeen ?? this.lastSeen,
    commentsFetchedAt: commentsFetchedAt.present
        ? commentsFetchedAt.value
        : this.commentsFetchedAt,
    read: read ?? this.read,
    saved: saved ?? this.saved,
    savedAt: savedAt.present ? savedAt.value : this.savedAt,
    hidden: hidden ?? this.hidden,
  );
  StoryRow copyWithCompanion(StoriesCompanion data) {
    return StoryRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      domain: data.domain.present ? data.domain.value : this.domain,
      by: data.by.present ? data.by.value : this.by,
      points: data.points.present ? data.points.value : this.points,
      commentCount: data.commentCount.present
          ? data.commentCount.value
          : this.commentCount,
      time: data.time.present ? data.time.value : this.time,
      type: data.type.present ? data.type.value : this.type,
      body: data.body.present ? data.body.value : this.body,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      commentsFetchedAt: data.commentsFetchedAt.present
          ? data.commentsFetchedAt.value
          : this.commentsFetchedAt,
      read: data.read.present ? data.read.value : this.read,
      saved: data.saved.present ? data.saved.value : this.saved,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('domain: $domain, ')
          ..write('by: $by, ')
          ..write('points: $points, ')
          ..write('commentCount: $commentCount, ')
          ..write('time: $time, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('commentsFetchedAt: $commentsFetchedAt, ')
          ..write('read: $read, ')
          ..write('saved: $saved, ')
          ..write('savedAt: $savedAt, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    url,
    domain,
    by,
    points,
    commentCount,
    time,
    type,
    body,
    firstSeen,
    lastSeen,
    commentsFetchedAt,
    read,
    saved,
    savedAt,
    hidden,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.url == this.url &&
          other.domain == this.domain &&
          other.by == this.by &&
          other.points == this.points &&
          other.commentCount == this.commentCount &&
          other.time == this.time &&
          other.type == this.type &&
          other.body == this.body &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen &&
          other.commentsFetchedAt == this.commentsFetchedAt &&
          other.read == this.read &&
          other.saved == this.saved &&
          other.savedAt == this.savedAt &&
          other.hidden == this.hidden);
}

class StoriesCompanion extends UpdateCompanion<StoryRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> url;
  final Value<String?> domain;
  final Value<String?> by;
  final Value<int?> points;
  final Value<int> commentCount;
  final Value<DateTime?> time;
  final Value<String> type;
  final Value<String?> body;
  final Value<DateTime> firstSeen;
  final Value<DateTime> lastSeen;
  final Value<DateTime?> commentsFetchedAt;
  final Value<bool> read;
  final Value<bool> saved;
  final Value<DateTime?> savedAt;
  final Value<bool> hidden;
  const StoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.domain = const Value.absent(),
    this.by = const Value.absent(),
    this.points = const Value.absent(),
    this.commentCount = const Value.absent(),
    this.time = const Value.absent(),
    this.type = const Value.absent(),
    this.body = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.commentsFetchedAt = const Value.absent(),
    this.read = const Value.absent(),
    this.saved = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.hidden = const Value.absent(),
  });
  StoriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.url = const Value.absent(),
    this.domain = const Value.absent(),
    this.by = const Value.absent(),
    this.points = const Value.absent(),
    this.commentCount = const Value.absent(),
    this.time = const Value.absent(),
    this.type = const Value.absent(),
    this.body = const Value.absent(),
    required DateTime firstSeen,
    required DateTime lastSeen,
    this.commentsFetchedAt = const Value.absent(),
    this.read = const Value.absent(),
    this.saved = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.hidden = const Value.absent(),
  }) : title = Value(title),
       firstSeen = Value(firstSeen),
       lastSeen = Value(lastSeen);
  static Insertable<StoryRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? domain,
    Expression<String>? by,
    Expression<int>? points,
    Expression<int>? commentCount,
    Expression<DateTime>? time,
    Expression<String>? type,
    Expression<String>? body,
    Expression<DateTime>? firstSeen,
    Expression<DateTime>? lastSeen,
    Expression<DateTime>? commentsFetchedAt,
    Expression<bool>? read,
    Expression<bool>? saved,
    Expression<DateTime>? savedAt,
    Expression<bool>? hidden,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (domain != null) 'domain': domain,
      if (by != null) 'by': by,
      if (points != null) 'points': points,
      if (commentCount != null) 'comment_count': commentCount,
      if (time != null) 'time': time,
      if (type != null) 'type': type,
      if (body != null) 'body': body,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (commentsFetchedAt != null) 'comments_fetched_at': commentsFetchedAt,
      if (read != null) 'read': read,
      if (saved != null) 'saved': saved,
      if (savedAt != null) 'saved_at': savedAt,
      if (hidden != null) 'hidden': hidden,
    });
  }

  StoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? url,
    Value<String?>? domain,
    Value<String?>? by,
    Value<int?>? points,
    Value<int>? commentCount,
    Value<DateTime?>? time,
    Value<String>? type,
    Value<String?>? body,
    Value<DateTime>? firstSeen,
    Value<DateTime>? lastSeen,
    Value<DateTime?>? commentsFetchedAt,
    Value<bool>? read,
    Value<bool>? saved,
    Value<DateTime?>? savedAt,
    Value<bool>? hidden,
  }) {
    return StoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      domain: domain ?? this.domain,
      by: by ?? this.by,
      points: points ?? this.points,
      commentCount: commentCount ?? this.commentCount,
      time: time ?? this.time,
      type: type ?? this.type,
      body: body ?? this.body,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      commentsFetchedAt: commentsFetchedAt ?? this.commentsFetchedAt,
      read: read ?? this.read,
      saved: saved ?? this.saved,
      savedAt: savedAt ?? this.savedAt,
      hidden: hidden ?? this.hidden,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (by.present) {
      map['by'] = Variable<String>(by.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (commentCount.present) {
      map['comment_count'] = Variable<int>(commentCount.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<DateTime>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (commentsFetchedAt.present) {
      map['comments_fetched_at'] = Variable<DateTime>(commentsFetchedAt.value);
    }
    if (read.present) {
      map['read'] = Variable<bool>(read.value);
    }
    if (saved.present) {
      map['saved'] = Variable<bool>(saved.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('domain: $domain, ')
          ..write('by: $by, ')
          ..write('points: $points, ')
          ..write('commentCount: $commentCount, ')
          ..write('time: $time, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('commentsFetchedAt: $commentsFetchedAt, ')
          ..write('read: $read, ')
          ..write('saved: $saved, ')
          ..write('savedAt: $savedAt, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }
}

class $CommentsTable extends Comments
    with TableInfo<$CommentsTable, CommentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _htmlMeta = const VerificationMeta('html');
  @override
  late final GeneratedColumn<String> html = GeneratedColumn<String>(
    'html',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<int> depth = GeneratedColumn<int>(
    'depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadMeta = const VerificationMeta('dead');
  @override
  late final GeneratedColumn<bool> dead = GeneratedColumn<bool>(
    'dead',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dead" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storyId,
    parentId,
    author,
    html,
    time,
    position,
    depth,
    dead,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('html')) {
      context.handle(
        _htmlMeta,
        html.isAcceptableOrUnknown(data['html']!, _htmlMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('depth')) {
      context.handle(
        _depthMeta,
        depth.isAcceptableOrUnknown(data['depth']!, _depthMeta),
      );
    } else if (isInserting) {
      context.missing(_depthMeta);
    }
    if (data.containsKey('dead')) {
      context.handle(
        _deadMeta,
        dead.isAcceptableOrUnknown(data['dead']!, _deadMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      html: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}html'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}time'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      depth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}depth'],
      )!,
      dead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dead'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $CommentsTable createAlias(String alias) {
    return $CommentsTable(attachedDatabase, alias);
  }
}

class CommentRow extends DataClass implements Insertable<CommentRow> {
  final int id;
  final int storyId;
  final int? parentId;
  final String? author;
  final String? html;
  final DateTime? time;
  final int position;
  final int depth;
  final bool dead;
  final bool deleted;
  const CommentRow({
    required this.id,
    required this.storyId,
    this.parentId,
    this.author,
    this.html,
    this.time,
    required this.position,
    required this.depth,
    required this.dead,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['story_id'] = Variable<int>(storyId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || html != null) {
      map['html'] = Variable<String>(html);
    }
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<DateTime>(time);
    }
    map['position'] = Variable<int>(position);
    map['depth'] = Variable<int>(depth);
    map['dead'] = Variable<bool>(dead);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  CommentsCompanion toCompanion(bool nullToAbsent) {
    return CommentsCompanion(
      id: Value(id),
      storyId: Value(storyId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      html: html == null && nullToAbsent ? const Value.absent() : Value(html),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      position: Value(position),
      depth: Value(depth),
      dead: Value(dead),
      deleted: Value(deleted),
    );
  }

  factory CommentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommentRow(
      id: serializer.fromJson<int>(json['id']),
      storyId: serializer.fromJson<int>(json['storyId']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      author: serializer.fromJson<String?>(json['author']),
      html: serializer.fromJson<String?>(json['html']),
      time: serializer.fromJson<DateTime?>(json['time']),
      position: serializer.fromJson<int>(json['position']),
      depth: serializer.fromJson<int>(json['depth']),
      dead: serializer.fromJson<bool>(json['dead']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storyId': serializer.toJson<int>(storyId),
      'parentId': serializer.toJson<int?>(parentId),
      'author': serializer.toJson<String?>(author),
      'html': serializer.toJson<String?>(html),
      'time': serializer.toJson<DateTime?>(time),
      'position': serializer.toJson<int>(position),
      'depth': serializer.toJson<int>(depth),
      'dead': serializer.toJson<bool>(dead),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  CommentRow copyWith({
    int? id,
    int? storyId,
    Value<int?> parentId = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> html = const Value.absent(),
    Value<DateTime?> time = const Value.absent(),
    int? position,
    int? depth,
    bool? dead,
    bool? deleted,
  }) => CommentRow(
    id: id ?? this.id,
    storyId: storyId ?? this.storyId,
    parentId: parentId.present ? parentId.value : this.parentId,
    author: author.present ? author.value : this.author,
    html: html.present ? html.value : this.html,
    time: time.present ? time.value : this.time,
    position: position ?? this.position,
    depth: depth ?? this.depth,
    dead: dead ?? this.dead,
    deleted: deleted ?? this.deleted,
  );
  CommentRow copyWithCompanion(CommentsCompanion data) {
    return CommentRow(
      id: data.id.present ? data.id.value : this.id,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      author: data.author.present ? data.author.value : this.author,
      html: data.html.present ? data.html.value : this.html,
      time: data.time.present ? data.time.value : this.time,
      position: data.position.present ? data.position.value : this.position,
      depth: data.depth.present ? data.depth.value : this.depth,
      dead: data.dead.present ? data.dead.value : this.dead,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommentRow(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('parentId: $parentId, ')
          ..write('author: $author, ')
          ..write('html: $html, ')
          ..write('time: $time, ')
          ..write('position: $position, ')
          ..write('depth: $depth, ')
          ..write('dead: $dead, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storyId,
    parentId,
    author,
    html,
    time,
    position,
    depth,
    dead,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommentRow &&
          other.id == this.id &&
          other.storyId == this.storyId &&
          other.parentId == this.parentId &&
          other.author == this.author &&
          other.html == this.html &&
          other.time == this.time &&
          other.position == this.position &&
          other.depth == this.depth &&
          other.dead == this.dead &&
          other.deleted == this.deleted);
}

class CommentsCompanion extends UpdateCompanion<CommentRow> {
  final Value<int> id;
  final Value<int> storyId;
  final Value<int?> parentId;
  final Value<String?> author;
  final Value<String?> html;
  final Value<DateTime?> time;
  final Value<int> position;
  final Value<int> depth;
  final Value<bool> dead;
  final Value<bool> deleted;
  const CommentsCompanion({
    this.id = const Value.absent(),
    this.storyId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.author = const Value.absent(),
    this.html = const Value.absent(),
    this.time = const Value.absent(),
    this.position = const Value.absent(),
    this.depth = const Value.absent(),
    this.dead = const Value.absent(),
    this.deleted = const Value.absent(),
  });
  CommentsCompanion.insert({
    this.id = const Value.absent(),
    required int storyId,
    this.parentId = const Value.absent(),
    this.author = const Value.absent(),
    this.html = const Value.absent(),
    this.time = const Value.absent(),
    required int position,
    required int depth,
    this.dead = const Value.absent(),
    this.deleted = const Value.absent(),
  }) : storyId = Value(storyId),
       position = Value(position),
       depth = Value(depth);
  static Insertable<CommentRow> custom({
    Expression<int>? id,
    Expression<int>? storyId,
    Expression<int>? parentId,
    Expression<String>? author,
    Expression<String>? html,
    Expression<DateTime>? time,
    Expression<int>? position,
    Expression<int>? depth,
    Expression<bool>? dead,
    Expression<bool>? deleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storyId != null) 'story_id': storyId,
      if (parentId != null) 'parent_id': parentId,
      if (author != null) 'author': author,
      if (html != null) 'html': html,
      if (time != null) 'time': time,
      if (position != null) 'position': position,
      if (depth != null) 'depth': depth,
      if (dead != null) 'dead': dead,
      if (deleted != null) 'deleted': deleted,
    });
  }

  CommentsCompanion copyWith({
    Value<int>? id,
    Value<int>? storyId,
    Value<int?>? parentId,
    Value<String?>? author,
    Value<String?>? html,
    Value<DateTime?>? time,
    Value<int>? position,
    Value<int>? depth,
    Value<bool>? dead,
    Value<bool>? deleted,
  }) {
    return CommentsCompanion(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      parentId: parentId ?? this.parentId,
      author: author ?? this.author,
      html: html ?? this.html,
      time: time ?? this.time,
      position: position ?? this.position,
      depth: depth ?? this.depth,
      dead: dead ?? this.dead,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (html.present) {
      map['html'] = Variable<String>(html.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (depth.present) {
      map['depth'] = Variable<int>(depth.value);
    }
    if (dead.present) {
      map['dead'] = Variable<bool>(dead.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentsCompanion(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('parentId: $parentId, ')
          ..write('author: $author, ')
          ..write('html: $html, ')
          ..write('time: $time, ')
          ..write('position: $position, ')
          ..write('depth: $depth, ')
          ..write('dead: $dead, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }
}

class $FeedSnapshotsTable extends FeedSnapshots
    with TableInfo<$FeedSnapshotsTable, SnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fetchIdMeta = const VerificationMeta(
    'fetchId',
  );
  @override
  late final GeneratedColumn<int> fetchId = GeneratedColumn<int>(
    'fetch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FeedKind, String> feedKind =
      GeneratedColumn<String>(
        'feed_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FeedKind>($FeedSnapshotsTable.$converterfeedKind);
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    fetchId,
    feedKind,
    storyId,
    rank,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fetch_id')) {
      context.handle(
        _fetchIdMeta,
        fetchId.isAcceptableOrUnknown(data['fetch_id']!, _fetchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchIdMeta);
    }
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
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
  Set<GeneratedColumn> get $primaryKey => {fetchId, storyId};
  @override
  SnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotRow(
      fetchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetch_id'],
      )!,
      feedKind: $FeedSnapshotsTable.$converterfeedKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}feed_kind'],
        )!,
      ),
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_id'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FeedSnapshotsTable createAlias(String alias) {
    return $FeedSnapshotsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FeedKind, String, String> $converterfeedKind =
      const EnumNameConverter<FeedKind>(FeedKind.values);
}

class SnapshotRow extends DataClass implements Insertable<SnapshotRow> {
  final int fetchId;
  final FeedKind feedKind;
  final int storyId;
  final int rank;
  final DateTime fetchedAt;
  const SnapshotRow({
    required this.fetchId,
    required this.feedKind,
    required this.storyId,
    required this.rank,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fetch_id'] = Variable<int>(fetchId);
    {
      map['feed_kind'] = Variable<String>(
        $FeedSnapshotsTable.$converterfeedKind.toSql(feedKind),
      );
    }
    map['story_id'] = Variable<int>(storyId);
    map['rank'] = Variable<int>(rank);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  FeedSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return FeedSnapshotsCompanion(
      fetchId: Value(fetchId),
      feedKind: Value(feedKind),
      storyId: Value(storyId),
      rank: Value(rank),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory SnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotRow(
      fetchId: serializer.fromJson<int>(json['fetchId']),
      feedKind: $FeedSnapshotsTable.$converterfeedKind.fromJson(
        serializer.fromJson<String>(json['feedKind']),
      ),
      storyId: serializer.fromJson<int>(json['storyId']),
      rank: serializer.fromJson<int>(json['rank']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fetchId': serializer.toJson<int>(fetchId),
      'feedKind': serializer.toJson<String>(
        $FeedSnapshotsTable.$converterfeedKind.toJson(feedKind),
      ),
      'storyId': serializer.toJson<int>(storyId),
      'rank': serializer.toJson<int>(rank),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  SnapshotRow copyWith({
    int? fetchId,
    FeedKind? feedKind,
    int? storyId,
    int? rank,
    DateTime? fetchedAt,
  }) => SnapshotRow(
    fetchId: fetchId ?? this.fetchId,
    feedKind: feedKind ?? this.feedKind,
    storyId: storyId ?? this.storyId,
    rank: rank ?? this.rank,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  SnapshotRow copyWithCompanion(FeedSnapshotsCompanion data) {
    return SnapshotRow(
      fetchId: data.fetchId.present ? data.fetchId.value : this.fetchId,
      feedKind: data.feedKind.present ? data.feedKind.value : this.feedKind,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      rank: data.rank.present ? data.rank.value : this.rank,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotRow(')
          ..write('fetchId: $fetchId, ')
          ..write('feedKind: $feedKind, ')
          ..write('storyId: $storyId, ')
          ..write('rank: $rank, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fetchId, feedKind, storyId, rank, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotRow &&
          other.fetchId == this.fetchId &&
          other.feedKind == this.feedKind &&
          other.storyId == this.storyId &&
          other.rank == this.rank &&
          other.fetchedAt == this.fetchedAt);
}

class FeedSnapshotsCompanion extends UpdateCompanion<SnapshotRow> {
  final Value<int> fetchId;
  final Value<FeedKind> feedKind;
  final Value<int> storyId;
  final Value<int> rank;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const FeedSnapshotsCompanion({
    this.fetchId = const Value.absent(),
    this.feedKind = const Value.absent(),
    this.storyId = const Value.absent(),
    this.rank = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedSnapshotsCompanion.insert({
    required int fetchId,
    required FeedKind feedKind,
    required int storyId,
    required int rank,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : fetchId = Value(fetchId),
       feedKind = Value(feedKind),
       storyId = Value(storyId),
       rank = Value(rank),
       fetchedAt = Value(fetchedAt);
  static Insertable<SnapshotRow> custom({
    Expression<int>? fetchId,
    Expression<String>? feedKind,
    Expression<int>? storyId,
    Expression<int>? rank,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fetchId != null) 'fetch_id': fetchId,
      if (feedKind != null) 'feed_kind': feedKind,
      if (storyId != null) 'story_id': storyId,
      if (rank != null) 'rank': rank,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedSnapshotsCompanion copyWith({
    Value<int>? fetchId,
    Value<FeedKind>? feedKind,
    Value<int>? storyId,
    Value<int>? rank,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FeedSnapshotsCompanion(
      fetchId: fetchId ?? this.fetchId,
      feedKind: feedKind ?? this.feedKind,
      storyId: storyId ?? this.storyId,
      rank: rank ?? this.rank,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fetchId.present) {
      map['fetch_id'] = Variable<int>(fetchId.value);
    }
    if (feedKind.present) {
      map['feed_kind'] = Variable<String>(
        $FeedSnapshotsTable.$converterfeedKind.toSql(feedKind.value),
      );
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
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
    return (StringBuffer('FeedSnapshotsCompanion(')
          ..write('fetchId: $fetchId, ')
          ..write('feedKind: $feedKind, ')
          ..write('storyId: $storyId, ')
          ..write('rank: $rank, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageCopiesTable extends PageCopies
    with TableInfo<$PageCopiesTable, PageCopyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageCopiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PageKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PageKind>($PageCopiesTable.$converterkind);
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PageStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PageStatus>($PageCopiesTable.$converterstatus);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    storyId,
    kind,
    relativePath,
    bytes,
    capturedAt,
    status,
    error,
    lastOpenedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_copies';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageCopyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {storyId};
  @override
  PageCopyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageCopyRow(
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_id'],
      )!,
      kind: $PageCopiesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      ),
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      status: $PageCopiesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
    );
  }

  @override
  $PageCopiesTable createAlias(String alias) {
    return $PageCopiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PageKind, String, String> $converterkind =
      const EnumNameConverter<PageKind>(PageKind.values);
  static JsonTypeConverter2<PageStatus, String, String> $converterstatus =
      const EnumNameConverter<PageStatus>(PageStatus.values);
}

class PageCopyRow extends DataClass implements Insertable<PageCopyRow> {
  final int storyId;
  final PageKind kind;
  final String? relativePath;
  final int bytes;
  final DateTime capturedAt;
  final PageStatus status;
  final String? error;
  final DateTime? lastOpenedAt;
  const PageCopyRow({
    required this.storyId,
    required this.kind,
    this.relativePath,
    required this.bytes,
    required this.capturedAt,
    required this.status,
    this.error,
    this.lastOpenedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['story_id'] = Variable<int>(storyId);
    {
      map['kind'] = Variable<String>(
        $PageCopiesTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || relativePath != null) {
      map['relative_path'] = Variable<String>(relativePath);
    }
    map['bytes'] = Variable<int>(bytes);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    {
      map['status'] = Variable<String>(
        $PageCopiesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    return map;
  }

  PageCopiesCompanion toCompanion(bool nullToAbsent) {
    return PageCopiesCompanion(
      storyId: Value(storyId),
      kind: Value(kind),
      relativePath: relativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(relativePath),
      bytes: Value(bytes),
      capturedAt: Value(capturedAt),
      status: Value(status),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
    );
  }

  factory PageCopyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageCopyRow(
      storyId: serializer.fromJson<int>(json['storyId']),
      kind: $PageCopiesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      relativePath: serializer.fromJson<String?>(json['relativePath']),
      bytes: serializer.fromJson<int>(json['bytes']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      status: $PageCopiesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      error: serializer.fromJson<String?>(json['error']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'storyId': serializer.toJson<int>(storyId),
      'kind': serializer.toJson<String>(
        $PageCopiesTable.$converterkind.toJson(kind),
      ),
      'relativePath': serializer.toJson<String?>(relativePath),
      'bytes': serializer.toJson<int>(bytes),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'status': serializer.toJson<String>(
        $PageCopiesTable.$converterstatus.toJson(status),
      ),
      'error': serializer.toJson<String?>(error),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
    };
  }

  PageCopyRow copyWith({
    int? storyId,
    PageKind? kind,
    Value<String?> relativePath = const Value.absent(),
    int? bytes,
    DateTime? capturedAt,
    PageStatus? status,
    Value<String?> error = const Value.absent(),
    Value<DateTime?> lastOpenedAt = const Value.absent(),
  }) => PageCopyRow(
    storyId: storyId ?? this.storyId,
    kind: kind ?? this.kind,
    relativePath: relativePath.present ? relativePath.value : this.relativePath,
    bytes: bytes ?? this.bytes,
    capturedAt: capturedAt ?? this.capturedAt,
    status: status ?? this.status,
    error: error.present ? error.value : this.error,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
  );
  PageCopyRow copyWithCompanion(PageCopiesCompanion data) {
    return PageCopyRow(
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      kind: data.kind.present ? data.kind.value : this.kind,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageCopyRow(')
          ..write('storyId: $storyId, ')
          ..write('kind: $kind, ')
          ..write('relativePath: $relativePath, ')
          ..write('bytes: $bytes, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    storyId,
    kind,
    relativePath,
    bytes,
    capturedAt,
    status,
    error,
    lastOpenedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageCopyRow &&
          other.storyId == this.storyId &&
          other.kind == this.kind &&
          other.relativePath == this.relativePath &&
          other.bytes == this.bytes &&
          other.capturedAt == this.capturedAt &&
          other.status == this.status &&
          other.error == this.error &&
          other.lastOpenedAt == this.lastOpenedAt);
}

class PageCopiesCompanion extends UpdateCompanion<PageCopyRow> {
  final Value<int> storyId;
  final Value<PageKind> kind;
  final Value<String?> relativePath;
  final Value<int> bytes;
  final Value<DateTime> capturedAt;
  final Value<PageStatus> status;
  final Value<String?> error;
  final Value<DateTime?> lastOpenedAt;
  const PageCopiesCompanion({
    this.storyId = const Value.absent(),
    this.kind = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.bytes = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
  });
  PageCopiesCompanion.insert({
    this.storyId = const Value.absent(),
    required PageKind kind,
    this.relativePath = const Value.absent(),
    this.bytes = const Value.absent(),
    required DateTime capturedAt,
    required PageStatus status,
    this.error = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
  }) : kind = Value(kind),
       capturedAt = Value(capturedAt),
       status = Value(status);
  static Insertable<PageCopyRow> custom({
    Expression<int>? storyId,
    Expression<String>? kind,
    Expression<String>? relativePath,
    Expression<int>? bytes,
    Expression<DateTime>? capturedAt,
    Expression<String>? status,
    Expression<String>? error,
    Expression<DateTime>? lastOpenedAt,
  }) {
    return RawValuesInsertable({
      if (storyId != null) 'story_id': storyId,
      if (kind != null) 'kind': kind,
      if (relativePath != null) 'relative_path': relativePath,
      if (bytes != null) 'bytes': bytes,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
    });
  }

  PageCopiesCompanion copyWith({
    Value<int>? storyId,
    Value<PageKind>? kind,
    Value<String?>? relativePath,
    Value<int>? bytes,
    Value<DateTime>? capturedAt,
    Value<PageStatus>? status,
    Value<String?>? error,
    Value<DateTime?>? lastOpenedAt,
  }) {
    return PageCopiesCompanion(
      storyId: storyId ?? this.storyId,
      kind: kind ?? this.kind,
      relativePath: relativePath ?? this.relativePath,
      bytes: bytes ?? this.bytes,
      capturedAt: capturedAt ?? this.capturedAt,
      status: status ?? this.status,
      error: error ?? this.error,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PageCopiesTable.$converterkind.toSql(kind.value),
      );
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PageCopiesTable.$converterstatus.toSql(status.value),
      );
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageCopiesCompanion(')
          ..write('storyId: $storyId, ')
          ..write('kind: $kind, ')
          ..write('relativePath: $relativePath, ')
          ..write('bytes: $bytes, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }
}

class $ThreadStatesTable extends ThreadStates
    with TableInfo<$ThreadStatesTable, ThreadStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThreadStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenUpToCommentTimeMeta =
      const VerificationMeta('seenUpToCommentTime');
  @override
  late final GeneratedColumn<DateTime> seenUpToCommentTime =
      GeneratedColumn<DateTime>(
        'seen_up_to_comment_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _collapsedIdsMeta = const VerificationMeta(
    'collapsedIds',
  );
  @override
  late final GeneratedColumn<String> collapsedIds = GeneratedColumn<String>(
    'collapsed_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    storyId,
    lastOpenedAt,
    seenUpToCommentTime,
    collapsedIds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thread_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThreadStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastOpenedAtMeta);
    }
    if (data.containsKey('seen_up_to_comment_time')) {
      context.handle(
        _seenUpToCommentTimeMeta,
        seenUpToCommentTime.isAcceptableOrUnknown(
          data['seen_up_to_comment_time']!,
          _seenUpToCommentTimeMeta,
        ),
      );
    }
    if (data.containsKey('collapsed_ids')) {
      context.handle(
        _collapsedIdsMeta,
        collapsedIds.isAcceptableOrUnknown(
          data['collapsed_ids']!,
          _collapsedIdsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {storyId};
  @override
  ThreadStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThreadStateRow(
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_id'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      )!,
      seenUpToCommentTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}seen_up_to_comment_time'],
      ),
      collapsedIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collapsed_ids'],
      )!,
    );
  }

  @override
  $ThreadStatesTable createAlias(String alias) {
    return $ThreadStatesTable(attachedDatabase, alias);
  }
}

class ThreadStateRow extends DataClass implements Insertable<ThreadStateRow> {
  final int storyId;
  final DateTime lastOpenedAt;
  final DateTime? seenUpToCommentTime;
  final String collapsedIds;
  const ThreadStateRow({
    required this.storyId,
    required this.lastOpenedAt,
    this.seenUpToCommentTime,
    required this.collapsedIds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['story_id'] = Variable<int>(storyId);
    map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    if (!nullToAbsent || seenUpToCommentTime != null) {
      map['seen_up_to_comment_time'] = Variable<DateTime>(seenUpToCommentTime);
    }
    map['collapsed_ids'] = Variable<String>(collapsedIds);
    return map;
  }

  ThreadStatesCompanion toCompanion(bool nullToAbsent) {
    return ThreadStatesCompanion(
      storyId: Value(storyId),
      lastOpenedAt: Value(lastOpenedAt),
      seenUpToCommentTime: seenUpToCommentTime == null && nullToAbsent
          ? const Value.absent()
          : Value(seenUpToCommentTime),
      collapsedIds: Value(collapsedIds),
    );
  }

  factory ThreadStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThreadStateRow(
      storyId: serializer.fromJson<int>(json['storyId']),
      lastOpenedAt: serializer.fromJson<DateTime>(json['lastOpenedAt']),
      seenUpToCommentTime: serializer.fromJson<DateTime?>(
        json['seenUpToCommentTime'],
      ),
      collapsedIds: serializer.fromJson<String>(json['collapsedIds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'storyId': serializer.toJson<int>(storyId),
      'lastOpenedAt': serializer.toJson<DateTime>(lastOpenedAt),
      'seenUpToCommentTime': serializer.toJson<DateTime?>(seenUpToCommentTime),
      'collapsedIds': serializer.toJson<String>(collapsedIds),
    };
  }

  ThreadStateRow copyWith({
    int? storyId,
    DateTime? lastOpenedAt,
    Value<DateTime?> seenUpToCommentTime = const Value.absent(),
    String? collapsedIds,
  }) => ThreadStateRow(
    storyId: storyId ?? this.storyId,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    seenUpToCommentTime: seenUpToCommentTime.present
        ? seenUpToCommentTime.value
        : this.seenUpToCommentTime,
    collapsedIds: collapsedIds ?? this.collapsedIds,
  );
  ThreadStateRow copyWithCompanion(ThreadStatesCompanion data) {
    return ThreadStateRow(
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      seenUpToCommentTime: data.seenUpToCommentTime.present
          ? data.seenUpToCommentTime.value
          : this.seenUpToCommentTime,
      collapsedIds: data.collapsedIds.present
          ? data.collapsedIds.value
          : this.collapsedIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThreadStateRow(')
          ..write('storyId: $storyId, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('seenUpToCommentTime: $seenUpToCommentTime, ')
          ..write('collapsedIds: $collapsedIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(storyId, lastOpenedAt, seenUpToCommentTime, collapsedIds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThreadStateRow &&
          other.storyId == this.storyId &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.seenUpToCommentTime == this.seenUpToCommentTime &&
          other.collapsedIds == this.collapsedIds);
}

class ThreadStatesCompanion extends UpdateCompanion<ThreadStateRow> {
  final Value<int> storyId;
  final Value<DateTime> lastOpenedAt;
  final Value<DateTime?> seenUpToCommentTime;
  final Value<String> collapsedIds;
  const ThreadStatesCompanion({
    this.storyId = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.seenUpToCommentTime = const Value.absent(),
    this.collapsedIds = const Value.absent(),
  });
  ThreadStatesCompanion.insert({
    this.storyId = const Value.absent(),
    required DateTime lastOpenedAt,
    this.seenUpToCommentTime = const Value.absent(),
    this.collapsedIds = const Value.absent(),
  }) : lastOpenedAt = Value(lastOpenedAt);
  static Insertable<ThreadStateRow> custom({
    Expression<int>? storyId,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? seenUpToCommentTime,
    Expression<String>? collapsedIds,
  }) {
    return RawValuesInsertable({
      if (storyId != null) 'story_id': storyId,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (seenUpToCommentTime != null)
        'seen_up_to_comment_time': seenUpToCommentTime,
      if (collapsedIds != null) 'collapsed_ids': collapsedIds,
    });
  }

  ThreadStatesCompanion copyWith({
    Value<int>? storyId,
    Value<DateTime>? lastOpenedAt,
    Value<DateTime?>? seenUpToCommentTime,
    Value<String>? collapsedIds,
  }) {
    return ThreadStatesCompanion(
      storyId: storyId ?? this.storyId,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      seenUpToCommentTime: seenUpToCommentTime ?? this.seenUpToCommentTime,
      collapsedIds: collapsedIds ?? this.collapsedIds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (seenUpToCommentTime.present) {
      map['seen_up_to_comment_time'] = Variable<DateTime>(
        seenUpToCommentTime.value,
      );
    }
    if (collapsedIds.present) {
      map['collapsed_ids'] = Variable<String>(collapsedIds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThreadStatesCompanion(')
          ..write('storyId: $storyId, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('seenUpToCommentTime: $seenUpToCommentTime, ')
          ..write('collapsedIds: $collapsedIds')
          ..write(')'))
        .toString();
  }
}

class $SyncRunsTable extends SyncRuns
    with TableInfo<$SyncRunsTable, SyncRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRunsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncTrigger, String> trigger =
      GeneratedColumn<String>(
        'trigger',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncTrigger>($SyncRunsTable.$convertertrigger);
  @override
  late final GeneratedColumnWithTypeConverter<SyncPhase, String> phase =
      GeneratedColumn<String>(
        'phase',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncPhase>($SyncRunsTable.$converterphase);
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
  static const VerificationMeta _heartbeatAtMeta = const VerificationMeta(
    'heartbeatAt',
  );
  @override
  late final GeneratedColumn<DateTime> heartbeatAt = GeneratedColumn<DateTime>(
    'heartbeat_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _executingMeta = const VerificationMeta(
    'executing',
  );
  @override
  late final GeneratedColumn<bool> executing = GeneratedColumn<bool>(
    'executing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("executing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncOutcome?, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SyncOutcome?>($SyncRunsTable.$converteroutcomen);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trigger,
    phase,
    startedAt,
    heartbeatAt,
    executing,
    finishedAt,
    outcome,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRunRow> instance, {
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
    if (data.containsKey('heartbeat_at')) {
      context.handle(
        _heartbeatAtMeta,
        heartbeatAt.isAcceptableOrUnknown(
          data['heartbeat_at']!,
          _heartbeatAtMeta,
        ),
      );
    }
    if (data.containsKey('executing')) {
      context.handle(
        _executingMeta,
        executing.isAcceptableOrUnknown(data['executing']!, _executingMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trigger: $SyncRunsTable.$convertertrigger.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}trigger'],
        )!,
      ),
      phase: $SyncRunsTable.$converterphase.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}phase'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      heartbeatAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}heartbeat_at'],
      ),
      executing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}executing'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      outcome: $SyncRunsTable.$converteroutcomen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        ),
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $SyncRunsTable createAlias(String alias) {
    return $SyncRunsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncTrigger, String, String> $convertertrigger =
      const EnumNameConverter<SyncTrigger>(SyncTrigger.values);
  static JsonTypeConverter2<SyncPhase, String, String> $converterphase =
      const EnumNameConverter<SyncPhase>(SyncPhase.values);
  static JsonTypeConverter2<SyncOutcome, String, String> $converteroutcome =
      const EnumNameConverter<SyncOutcome>(SyncOutcome.values);
  static JsonTypeConverter2<SyncOutcome?, String?, String?> $converteroutcomen =
      JsonTypeConverter2.asNullable($converteroutcome);
}

class SyncRunRow extends DataClass implements Insertable<SyncRunRow> {
  final int id;
  final SyncTrigger trigger;
  final SyncPhase phase;
  final DateTime startedAt;
  final DateTime? heartbeatAt;

  /// Set while a process is working on the run; still set when a new process
  /// finds the run, it means the previous one died.
  final bool executing;
  final DateTime? finishedAt;
  final SyncOutcome? outcome;
  final String? error;
  const SyncRunRow({
    required this.id,
    required this.trigger,
    required this.phase,
    required this.startedAt,
    this.heartbeatAt,
    required this.executing,
    this.finishedAt,
    this.outcome,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['trigger'] = Variable<String>(
        $SyncRunsTable.$convertertrigger.toSql(trigger),
      );
    }
    {
      map['phase'] = Variable<String>(
        $SyncRunsTable.$converterphase.toSql(phase),
      );
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || heartbeatAt != null) {
      map['heartbeat_at'] = Variable<DateTime>(heartbeatAt);
    }
    map['executing'] = Variable<bool>(executing);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(
        $SyncRunsTable.$converteroutcomen.toSql(outcome),
      );
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SyncRunsCompanion toCompanion(bool nullToAbsent) {
    return SyncRunsCompanion(
      id: Value(id),
      trigger: Value(trigger),
      phase: Value(phase),
      startedAt: Value(startedAt),
      heartbeatAt: heartbeatAt == null && nullToAbsent
          ? const Value.absent()
          : Value(heartbeatAt),
      executing: Value(executing),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory SyncRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRunRow(
      id: serializer.fromJson<int>(json['id']),
      trigger: $SyncRunsTable.$convertertrigger.fromJson(
        serializer.fromJson<String>(json['trigger']),
      ),
      phase: $SyncRunsTable.$converterphase.fromJson(
        serializer.fromJson<String>(json['phase']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      heartbeatAt: serializer.fromJson<DateTime?>(json['heartbeatAt']),
      executing: serializer.fromJson<bool>(json['executing']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      outcome: $SyncRunsTable.$converteroutcomen.fromJson(
        serializer.fromJson<String?>(json['outcome']),
      ),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trigger': serializer.toJson<String>(
        $SyncRunsTable.$convertertrigger.toJson(trigger),
      ),
      'phase': serializer.toJson<String>(
        $SyncRunsTable.$converterphase.toJson(phase),
      ),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'heartbeatAt': serializer.toJson<DateTime?>(heartbeatAt),
      'executing': serializer.toJson<bool>(executing),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'outcome': serializer.toJson<String?>(
        $SyncRunsTable.$converteroutcomen.toJson(outcome),
      ),
      'error': serializer.toJson<String?>(error),
    };
  }

  SyncRunRow copyWith({
    int? id,
    SyncTrigger? trigger,
    SyncPhase? phase,
    DateTime? startedAt,
    Value<DateTime?> heartbeatAt = const Value.absent(),
    bool? executing,
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<SyncOutcome?> outcome = const Value.absent(),
    Value<String?> error = const Value.absent(),
  }) => SyncRunRow(
    id: id ?? this.id,
    trigger: trigger ?? this.trigger,
    phase: phase ?? this.phase,
    startedAt: startedAt ?? this.startedAt,
    heartbeatAt: heartbeatAt.present ? heartbeatAt.value : this.heartbeatAt,
    executing: executing ?? this.executing,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    outcome: outcome.present ? outcome.value : this.outcome,
    error: error.present ? error.value : this.error,
  );
  SyncRunRow copyWithCompanion(SyncRunsCompanion data) {
    return SyncRunRow(
      id: data.id.present ? data.id.value : this.id,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      phase: data.phase.present ? data.phase.value : this.phase,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      heartbeatAt: data.heartbeatAt.present
          ? data.heartbeatAt.value
          : this.heartbeatAt,
      executing: data.executing.present ? data.executing.value : this.executing,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRunRow(')
          ..write('id: $id, ')
          ..write('trigger: $trigger, ')
          ..write('phase: $phase, ')
          ..write('startedAt: $startedAt, ')
          ..write('heartbeatAt: $heartbeatAt, ')
          ..write('executing: $executing, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('outcome: $outcome, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trigger,
    phase,
    startedAt,
    heartbeatAt,
    executing,
    finishedAt,
    outcome,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRunRow &&
          other.id == this.id &&
          other.trigger == this.trigger &&
          other.phase == this.phase &&
          other.startedAt == this.startedAt &&
          other.heartbeatAt == this.heartbeatAt &&
          other.executing == this.executing &&
          other.finishedAt == this.finishedAt &&
          other.outcome == this.outcome &&
          other.error == this.error);
}

class SyncRunsCompanion extends UpdateCompanion<SyncRunRow> {
  final Value<int> id;
  final Value<SyncTrigger> trigger;
  final Value<SyncPhase> phase;
  final Value<DateTime> startedAt;
  final Value<DateTime?> heartbeatAt;
  final Value<bool> executing;
  final Value<DateTime?> finishedAt;
  final Value<SyncOutcome?> outcome;
  final Value<String?> error;
  const SyncRunsCompanion({
    this.id = const Value.absent(),
    this.trigger = const Value.absent(),
    this.phase = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.heartbeatAt = const Value.absent(),
    this.executing = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.error = const Value.absent(),
  });
  SyncRunsCompanion.insert({
    this.id = const Value.absent(),
    required SyncTrigger trigger,
    required SyncPhase phase,
    required DateTime startedAt,
    this.heartbeatAt = const Value.absent(),
    this.executing = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.error = const Value.absent(),
  }) : trigger = Value(trigger),
       phase = Value(phase),
       startedAt = Value(startedAt);
  static Insertable<SyncRunRow> custom({
    Expression<int>? id,
    Expression<String>? trigger,
    Expression<String>? phase,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? heartbeatAt,
    Expression<bool>? executing,
    Expression<DateTime>? finishedAt,
    Expression<String>? outcome,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trigger != null) 'trigger': trigger,
      if (phase != null) 'phase': phase,
      if (startedAt != null) 'started_at': startedAt,
      if (heartbeatAt != null) 'heartbeat_at': heartbeatAt,
      if (executing != null) 'executing': executing,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (outcome != null) 'outcome': outcome,
      if (error != null) 'error': error,
    });
  }

  SyncRunsCompanion copyWith({
    Value<int>? id,
    Value<SyncTrigger>? trigger,
    Value<SyncPhase>? phase,
    Value<DateTime>? startedAt,
    Value<DateTime?>? heartbeatAt,
    Value<bool>? executing,
    Value<DateTime?>? finishedAt,
    Value<SyncOutcome?>? outcome,
    Value<String?>? error,
  }) {
    return SyncRunsCompanion(
      id: id ?? this.id,
      trigger: trigger ?? this.trigger,
      phase: phase ?? this.phase,
      startedAt: startedAt ?? this.startedAt,
      heartbeatAt: heartbeatAt ?? this.heartbeatAt,
      executing: executing ?? this.executing,
      finishedAt: finishedAt ?? this.finishedAt,
      outcome: outcome ?? this.outcome,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(
        $SyncRunsTable.$convertertrigger.toSql(trigger.value),
      );
    }
    if (phase.present) {
      map['phase'] = Variable<String>(
        $SyncRunsTable.$converterphase.toSql(phase.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (heartbeatAt.present) {
      map['heartbeat_at'] = Variable<DateTime>(heartbeatAt.value);
    }
    if (executing.present) {
      map['executing'] = Variable<bool>(executing.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $SyncRunsTable.$converteroutcomen.toSql(outcome.value),
      );
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRunsCompanion(')
          ..write('id: $id, ')
          ..write('trigger: $trigger, ')
          ..write('phase: $phase, ')
          ..write('startedAt: $startedAt, ')
          ..write('heartbeatAt: $heartbeatAt, ')
          ..write('executing: $executing, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('outcome: $outcome, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $SyncItemsTable extends SyncItems
    with TableInfo<$SyncItemsTable, SyncItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<int> runId = GeneratedColumn<int>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncItemKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncItemKind>($SyncItemsTable.$converterkind);
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncItemStatus>($SyncItemsTable.$converterstatus);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [runId, kind, storyId, status, error];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId, kind, storyId};
  @override
  SyncItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncItemRow(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_id'],
      )!,
      kind: $SyncItemsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_id'],
      )!,
      status: $SyncItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $SyncItemsTable createAlias(String alias) {
    return $SyncItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncItemKind, String, String> $converterkind =
      const EnumNameConverter<SyncItemKind>(SyncItemKind.values);
  static JsonTypeConverter2<SyncItemStatus, String, String> $converterstatus =
      const EnumNameConverter<SyncItemStatus>(SyncItemStatus.values);
}

class SyncItemRow extends DataClass implements Insertable<SyncItemRow> {
  final int runId;
  final SyncItemKind kind;
  final int storyId;
  final SyncItemStatus status;
  final String? error;
  const SyncItemRow({
    required this.runId,
    required this.kind,
    required this.storyId,
    required this.status,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<int>(runId);
    {
      map['kind'] = Variable<String>(
        $SyncItemsTable.$converterkind.toSql(kind),
      );
    }
    map['story_id'] = Variable<int>(storyId);
    {
      map['status'] = Variable<String>(
        $SyncItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SyncItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncItemsCompanion(
      runId: Value(runId),
      kind: Value(kind),
      storyId: Value(storyId),
      status: Value(status),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory SyncItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncItemRow(
      runId: serializer.fromJson<int>(json['runId']),
      kind: $SyncItemsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      storyId: serializer.fromJson<int>(json['storyId']),
      status: $SyncItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<int>(runId),
      'kind': serializer.toJson<String>(
        $SyncItemsTable.$converterkind.toJson(kind),
      ),
      'storyId': serializer.toJson<int>(storyId),
      'status': serializer.toJson<String>(
        $SyncItemsTable.$converterstatus.toJson(status),
      ),
      'error': serializer.toJson<String?>(error),
    };
  }

  SyncItemRow copyWith({
    int? runId,
    SyncItemKind? kind,
    int? storyId,
    SyncItemStatus? status,
    Value<String?> error = const Value.absent(),
  }) => SyncItemRow(
    runId: runId ?? this.runId,
    kind: kind ?? this.kind,
    storyId: storyId ?? this.storyId,
    status: status ?? this.status,
    error: error.present ? error.value : this.error,
  );
  SyncItemRow copyWithCompanion(SyncItemsCompanion data) {
    return SyncItemRow(
      runId: data.runId.present ? data.runId.value : this.runId,
      kind: data.kind.present ? data.kind.value : this.kind,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncItemRow(')
          ..write('runId: $runId, ')
          ..write('kind: $kind, ')
          ..write('storyId: $storyId, ')
          ..write('status: $status, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(runId, kind, storyId, status, error);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncItemRow &&
          other.runId == this.runId &&
          other.kind == this.kind &&
          other.storyId == this.storyId &&
          other.status == this.status &&
          other.error == this.error);
}

class SyncItemsCompanion extends UpdateCompanion<SyncItemRow> {
  final Value<int> runId;
  final Value<SyncItemKind> kind;
  final Value<int> storyId;
  final Value<SyncItemStatus> status;
  final Value<String?> error;
  final Value<int> rowid;
  const SyncItemsCompanion({
    this.runId = const Value.absent(),
    this.kind = const Value.absent(),
    this.storyId = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncItemsCompanion.insert({
    required int runId,
    required SyncItemKind kind,
    required int storyId,
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       kind = Value(kind),
       storyId = Value(storyId);
  static Insertable<SyncItemRow> custom({
    Expression<int>? runId,
    Expression<String>? kind,
    Expression<int>? storyId,
    Expression<String>? status,
    Expression<String>? error,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (kind != null) 'kind': kind,
      if (storyId != null) 'story_id': storyId,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncItemsCompanion copyWith({
    Value<int>? runId,
    Value<SyncItemKind>? kind,
    Value<int>? storyId,
    Value<SyncItemStatus>? status,
    Value<String?>? error,
    Value<int>? rowid,
  }) {
    return SyncItemsCompanion(
      runId: runId ?? this.runId,
      kind: kind ?? this.kind,
      storyId: storyId ?? this.storyId,
      status: status ?? this.status,
      error: error ?? this.error,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<int>(runId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SyncItemsTable.$converterkind.toSql(kind.value),
      );
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SyncItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncItemsCompanion(')
          ..write('runId: $runId, ')
          ..write('kind: $kind, ')
          ..write('storyId: $storyId, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingEntriesTable extends SettingEntries
    with TableInfo<$SettingEntriesTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingEntriesTable createAlias(String alias) {
    return $SettingEntriesTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingEntriesCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingEntriesCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final $CommentsTable comments = $CommentsTable(this);
  late final $FeedSnapshotsTable feedSnapshots = $FeedSnapshotsTable(this);
  late final $PageCopiesTable pageCopies = $PageCopiesTable(this);
  late final $ThreadStatesTable threadStates = $ThreadStatesTable(this);
  late final $SyncRunsTable syncRuns = $SyncRunsTable(this);
  late final $SyncItemsTable syncItems = $SyncItemsTable(this);
  late final $SettingEntriesTable settingEntries = $SettingEntriesTable(this);
  late final Index commentsByStory = Index(
    'comments_by_story',
    'CREATE INDEX comments_by_story ON comments (story_id, position)',
  );
  late final Index snapshotsByTime = Index(
    'snapshots_by_time',
    'CREATE INDEX snapshots_by_time ON feed_snapshots (feed_kind, fetched_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stories,
    comments,
    feedSnapshots,
    pageCopies,
    threadStates,
    syncRuns,
    syncItems,
    settingEntries,
    commentsByStory,
    snapshotsByTime,
  ];
}

typedef $$StoriesTableCreateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> url,
  Value<String?> domain,
  Value<String?> by,
  Value<int?> points,
  Value<int> commentCount,
  Value<DateTime?> time,
  Value<String> type,
  Value<String?> body,
  required DateTime firstSeen,
  required DateTime lastSeen,
  Value<DateTime?> commentsFetchedAt,
  Value<bool> read,
  Value<bool> saved,
  Value<DateTime?> savedAt,
  Value<bool> hidden,
});
typedef $$StoriesTableUpdateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> url,
  Value<String?> domain,
  Value<String?> by,
  Value<int?> points,
  Value<int> commentCount,
  Value<DateTime?> time,
  Value<String> type,
  Value<String?> body,
  Value<DateTime> firstSeen,
  Value<DateTime> lastSeen,
  Value<DateTime?> commentsFetchedAt,
  Value<bool> read,
  Value<bool> saved,
  Value<DateTime?> savedAt,
  Value<bool> hidden,
});

class $$StoriesTableFilterComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get by => $composableBuilder(
    column: $table.by,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commentCount => $composableBuilder(
    column: $table.commentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get commentsFetchedAt => $composableBuilder(
    column: $table.commentsFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get by => $composableBuilder(
    column: $table.by,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commentCount => $composableBuilder(
    column: $table.commentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get commentsFetchedAt => $composableBuilder(
    column: $table.commentsFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get by =>
      $composableBuilder(column: $table.by, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<int> get commentCount => $composableBuilder(
    column: $table.commentCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get commentsFetchedAt => $composableBuilder(
    column: $table.commentsFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get read =>
      $composableBuilder(column: $table.read, builder: (column) => column);

  GeneratedColumn<bool> get saved =>
      $composableBuilder(column: $table.saved, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);
}

class $$StoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoriesTable,
          StoryRow,
          $$StoriesTableFilterComposer,
          $$StoriesTableOrderingComposer,
          $$StoriesTableAnnotationComposer,
          $$StoriesTableCreateCompanionBuilder,
          $$StoriesTableUpdateCompanionBuilder,
          (StoryRow, BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>),
          StoryRow,
          PrefetchHooks Function()
        > {
  $$StoriesTableTableManager(_$AppDatabase db, $StoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<String?> by = const Value.absent(),
                Value<int?> points = const Value.absent(),
                Value<int> commentCount = const Value.absent(),
                Value<DateTime?> time = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<DateTime> firstSeen = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                Value<DateTime?> commentsFetchedAt = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<DateTime?> savedAt = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
              }) => StoriesCompanion(
                id: id,
                title: title,
                url: url,
                domain: domain,
                by: by,
                points: points,
                commentCount: commentCount,
                time: time,
                type: type,
                body: body,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
                commentsFetchedAt: commentsFetchedAt,
                read: read,
                saved: saved,
                savedAt: savedAt,
                hidden: hidden,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> url = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<String?> by = const Value.absent(),
                Value<int?> points = const Value.absent(),
                Value<int> commentCount = const Value.absent(),
                Value<DateTime?> time = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> body = const Value.absent(),
                required DateTime firstSeen,
                required DateTime lastSeen,
                Value<DateTime?> commentsFetchedAt = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<DateTime?> savedAt = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
              }) => StoriesCompanion.insert(
                id: id,
                title: title,
                url: url,
                domain: domain,
                by: by,
                points: points,
                commentCount: commentCount,
                time: time,
                type: type,
                body: body,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
                commentsFetchedAt: commentsFetchedAt,
                read: read,
                saved: saved,
                savedAt: savedAt,
                hidden: hidden,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoriesTable, StoryRow>(table),
                  BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoriesTable,
      StoryRow,
      $$StoriesTableFilterComposer,
      $$StoriesTableOrderingComposer,
      $$StoriesTableAnnotationComposer,
      $$StoriesTableCreateCompanionBuilder,
      $$StoriesTableUpdateCompanionBuilder,
      (StoryRow, BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>),
      StoryRow,
      PrefetchHooks Function()
    >;
typedef $$CommentsTableCreateCompanionBuilder = CommentsCompanion Function({
  Value<int> id,
  required int storyId,
  Value<int?> parentId,
  Value<String?> author,
  Value<String?> html,
  Value<DateTime?> time,
  required int position,
  required int depth,
  Value<bool> dead,
  Value<bool> deleted,
});
typedef $$CommentsTableUpdateCompanionBuilder = CommentsCompanion Function({
  Value<int> id,
  Value<int> storyId,
  Value<int?> parentId,
  Value<String?> author,
  Value<String?> html,
  Value<DateTime?> time,
  Value<int> position,
  Value<int> depth,
  Value<bool> dead,
  Value<bool> deleted,
});

class $$CommentsTableFilterComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableFilterComposer({
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

  ColumnFilters<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get html => $composableBuilder(
    column: $table.html,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dead => $composableBuilder(
    column: $table.dead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableOrderingComposer({
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

  ColumnOrderings<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get html => $composableBuilder(
    column: $table.html,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dead => $composableBuilder(
    column: $table.dead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get html =>
      $composableBuilder(column: $table.html, builder: (column) => column);

  GeneratedColumn<DateTime> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<bool> get dead =>
      $composableBuilder(column: $table.dead, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$CommentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommentsTable,
          CommentRow,
          $$CommentsTableFilterComposer,
          $$CommentsTableOrderingComposer,
          $$CommentsTableAnnotationComposer,
          $$CommentsTableCreateCompanionBuilder,
          $$CommentsTableUpdateCompanionBuilder,
          (
            CommentRow,
            BaseReferences<_$AppDatabase, $CommentsTable, CommentRow>,
          ),
          CommentRow,
          PrefetchHooks Function()
        > {
  $$CommentsTableTableManager(_$AppDatabase db, $CommentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storyId = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> html = const Value.absent(),
                Value<DateTime?> time = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> depth = const Value.absent(),
                Value<bool> dead = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
              }) => CommentsCompanion(
                id: id,
                storyId: storyId,
                parentId: parentId,
                author: author,
                html: html,
                time: time,
                position: position,
                depth: depth,
                dead: dead,
                deleted: deleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storyId,
                Value<int?> parentId = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> html = const Value.absent(),
                Value<DateTime?> time = const Value.absent(),
                required int position,
                required int depth,
                Value<bool> dead = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
              }) => CommentsCompanion.insert(
                id: id,
                storyId: storyId,
                parentId: parentId,
                author: author,
                html: html,
                time: time,
                position: position,
                depth: depth,
                dead: dead,
                deleted: deleted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommentsTable, CommentRow>(table),
                  BaseReferences<_$AppDatabase, $CommentsTable, CommentRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommentsTable,
      CommentRow,
      $$CommentsTableFilterComposer,
      $$CommentsTableOrderingComposer,
      $$CommentsTableAnnotationComposer,
      $$CommentsTableCreateCompanionBuilder,
      $$CommentsTableUpdateCompanionBuilder,
      (CommentRow, BaseReferences<_$AppDatabase, $CommentsTable, CommentRow>),
      CommentRow,
      PrefetchHooks Function()
    >;
typedef $$FeedSnapshotsTableCreateCompanionBuilder =
    FeedSnapshotsCompanion Function({
      required int fetchId,
      required FeedKind feedKind,
      required int storyId,
      required int rank,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$FeedSnapshotsTableUpdateCompanionBuilder =
    FeedSnapshotsCompanion Function({
      Value<int> fetchId,
      Value<FeedKind> feedKind,
      Value<int> storyId,
      Value<int> rank,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$FeedSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $FeedSnapshotsTable> {
  $$FeedSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get fetchId => $composableBuilder(
    column: $table.fetchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FeedKind, FeedKind, String> get feedKind =>
      $composableBuilder(
        column: $table.feedKind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeedSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedSnapshotsTable> {
  $$FeedSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get fetchId => $composableBuilder(
    column: $table.fetchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedKind => $composableBuilder(
    column: $table.feedKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeedSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedSnapshotsTable> {
  $$FeedSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get fetchId =>
      $composableBuilder(column: $table.fetchId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FeedKind, String> get feedKind =>
      $composableBuilder(column: $table.feedKind, builder: (column) => column);

  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FeedSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedSnapshotsTable,
          SnapshotRow,
          $$FeedSnapshotsTableFilterComposer,
          $$FeedSnapshotsTableOrderingComposer,
          $$FeedSnapshotsTableAnnotationComposer,
          $$FeedSnapshotsTableCreateCompanionBuilder,
          $$FeedSnapshotsTableUpdateCompanionBuilder,
          (
            SnapshotRow,
            BaseReferences<_$AppDatabase, $FeedSnapshotsTable, SnapshotRow>,
          ),
          SnapshotRow,
          PrefetchHooks Function()
        > {
  $$FeedSnapshotsTableTableManager(_$AppDatabase db, $FeedSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> fetchId = const Value.absent(),
                Value<FeedKind> feedKind = const Value.absent(),
                Value<int> storyId = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedSnapshotsCompanion(
                fetchId: fetchId,
                feedKind: feedKind,
                storyId: storyId,
                rank: rank,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int fetchId,
                required FeedKind feedKind,
                required int storyId,
                required int rank,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FeedSnapshotsCompanion.insert(
                fetchId: fetchId,
                feedKind: feedKind,
                storyId: storyId,
                rank: rank,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeedSnapshotsTable, SnapshotRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FeedSnapshotsTable,
                    SnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedSnapshotsTable,
      SnapshotRow,
      $$FeedSnapshotsTableFilterComposer,
      $$FeedSnapshotsTableOrderingComposer,
      $$FeedSnapshotsTableAnnotationComposer,
      $$FeedSnapshotsTableCreateCompanionBuilder,
      $$FeedSnapshotsTableUpdateCompanionBuilder,
      (
        SnapshotRow,
        BaseReferences<_$AppDatabase, $FeedSnapshotsTable, SnapshotRow>,
      ),
      SnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$PageCopiesTableCreateCompanionBuilder = PageCopiesCompanion Function({
  Value<int> storyId,
  required PageKind kind,
  Value<String?> relativePath,
  Value<int> bytes,
  required DateTime capturedAt,
  required PageStatus status,
  Value<String?> error,
  Value<DateTime?> lastOpenedAt,
});
typedef $$PageCopiesTableUpdateCompanionBuilder = PageCopiesCompanion Function({
  Value<int> storyId,
  Value<PageKind> kind,
  Value<String?> relativePath,
  Value<int> bytes,
  Value<DateTime> capturedAt,
  Value<PageStatus> status,
  Value<String?> error,
  Value<DateTime?> lastOpenedAt,
});

class $$PageCopiesTableFilterComposer
    extends Composer<_$AppDatabase, $PageCopiesTable> {
  $$PageCopiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PageKind, PageKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PageStatus, PageStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PageCopiesTableOrderingComposer
    extends Composer<_$AppDatabase, $PageCopiesTable> {
  $$PageCopiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PageCopiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageCopiesTable> {
  $$PageCopiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PageKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PageStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );
}

class $$PageCopiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PageCopiesTable,
          PageCopyRow,
          $$PageCopiesTableFilterComposer,
          $$PageCopiesTableOrderingComposer,
          $$PageCopiesTableAnnotationComposer,
          $$PageCopiesTableCreateCompanionBuilder,
          $$PageCopiesTableUpdateCompanionBuilder,
          (
            PageCopyRow,
            BaseReferences<_$AppDatabase, $PageCopiesTable, PageCopyRow>,
          ),
          PageCopyRow,
          PrefetchHooks Function()
        > {
  $$PageCopiesTableTableManager(_$AppDatabase db, $PageCopiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageCopiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageCopiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageCopiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> storyId = const Value.absent(),
                Value<PageKind> kind = const Value.absent(),
                Value<String?> relativePath = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<PageStatus> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
              }) => PageCopiesCompanion(
                storyId: storyId,
                kind: kind,
                relativePath: relativePath,
                bytes: bytes,
                capturedAt: capturedAt,
                status: status,
                error: error,
                lastOpenedAt: lastOpenedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> storyId = const Value.absent(),
                required PageKind kind,
                Value<String?> relativePath = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                required DateTime capturedAt,
                required PageStatus status,
                Value<String?> error = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
              }) => PageCopiesCompanion.insert(
                storyId: storyId,
                kind: kind,
                relativePath: relativePath,
                bytes: bytes,
                capturedAt: capturedAt,
                status: status,
                error: error,
                lastOpenedAt: lastOpenedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PageCopiesTable, PageCopyRow>(table),
                  BaseReferences<_$AppDatabase, $PageCopiesTable, PageCopyRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PageCopiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PageCopiesTable,
      PageCopyRow,
      $$PageCopiesTableFilterComposer,
      $$PageCopiesTableOrderingComposer,
      $$PageCopiesTableAnnotationComposer,
      $$PageCopiesTableCreateCompanionBuilder,
      $$PageCopiesTableUpdateCompanionBuilder,
      (
        PageCopyRow,
        BaseReferences<_$AppDatabase, $PageCopiesTable, PageCopyRow>,
      ),
      PageCopyRow,
      PrefetchHooks Function()
    >;
typedef $$ThreadStatesTableCreateCompanionBuilder =
    ThreadStatesCompanion Function({
      Value<int> storyId,
      required DateTime lastOpenedAt,
      Value<DateTime?> seenUpToCommentTime,
      Value<String> collapsedIds,
    });
typedef $$ThreadStatesTableUpdateCompanionBuilder =
    ThreadStatesCompanion Function({
      Value<int> storyId,
      Value<DateTime> lastOpenedAt,
      Value<DateTime?> seenUpToCommentTime,
      Value<String> collapsedIds,
    });

class $$ThreadStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ThreadStatesTable> {
  $$ThreadStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get seenUpToCommentTime => $composableBuilder(
    column: $table.seenUpToCommentTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collapsedIds => $composableBuilder(
    column: $table.collapsedIds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ThreadStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ThreadStatesTable> {
  $$ThreadStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get seenUpToCommentTime => $composableBuilder(
    column: $table.seenUpToCommentTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collapsedIds => $composableBuilder(
    column: $table.collapsedIds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThreadStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThreadStatesTable> {
  $$ThreadStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get seenUpToCommentTime => $composableBuilder(
    column: $table.seenUpToCommentTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collapsedIds => $composableBuilder(
    column: $table.collapsedIds,
    builder: (column) => column,
  );
}

class $$ThreadStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThreadStatesTable,
          ThreadStateRow,
          $$ThreadStatesTableFilterComposer,
          $$ThreadStatesTableOrderingComposer,
          $$ThreadStatesTableAnnotationComposer,
          $$ThreadStatesTableCreateCompanionBuilder,
          $$ThreadStatesTableUpdateCompanionBuilder,
          (
            ThreadStateRow,
            BaseReferences<_$AppDatabase, $ThreadStatesTable, ThreadStateRow>,
          ),
          ThreadStateRow,
          PrefetchHooks Function()
        > {
  $$ThreadStatesTableTableManager(_$AppDatabase db, $ThreadStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThreadStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThreadStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThreadStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> storyId = const Value.absent(),
                Value<DateTime> lastOpenedAt = const Value.absent(),
                Value<DateTime?> seenUpToCommentTime = const Value.absent(),
                Value<String> collapsedIds = const Value.absent(),
              }) => ThreadStatesCompanion(
                storyId: storyId,
                lastOpenedAt: lastOpenedAt,
                seenUpToCommentTime: seenUpToCommentTime,
                collapsedIds: collapsedIds,
              ),
          createCompanionCallback:
              ({
                Value<int> storyId = const Value.absent(),
                required DateTime lastOpenedAt,
                Value<DateTime?> seenUpToCommentTime = const Value.absent(),
                Value<String> collapsedIds = const Value.absent(),
              }) => ThreadStatesCompanion.insert(
                storyId: storyId,
                lastOpenedAt: lastOpenedAt,
                seenUpToCommentTime: seenUpToCommentTime,
                collapsedIds: collapsedIds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ThreadStatesTable, ThreadStateRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ThreadStatesTable,
                    ThreadStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ThreadStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThreadStatesTable,
      ThreadStateRow,
      $$ThreadStatesTableFilterComposer,
      $$ThreadStatesTableOrderingComposer,
      $$ThreadStatesTableAnnotationComposer,
      $$ThreadStatesTableCreateCompanionBuilder,
      $$ThreadStatesTableUpdateCompanionBuilder,
      (
        ThreadStateRow,
        BaseReferences<_$AppDatabase, $ThreadStatesTable, ThreadStateRow>,
      ),
      ThreadStateRow,
      PrefetchHooks Function()
    >;
typedef $$SyncRunsTableCreateCompanionBuilder = SyncRunsCompanion Function({
  Value<int> id,
  required SyncTrigger trigger,
  required SyncPhase phase,
  required DateTime startedAt,
  Value<DateTime?> heartbeatAt,
  Value<bool> executing,
  Value<DateTime?> finishedAt,
  Value<SyncOutcome?> outcome,
  Value<String?> error,
});
typedef $$SyncRunsTableUpdateCompanionBuilder = SyncRunsCompanion Function({
  Value<int> id,
  Value<SyncTrigger> trigger,
  Value<SyncPhase> phase,
  Value<DateTime> startedAt,
  Value<DateTime?> heartbeatAt,
  Value<bool> executing,
  Value<DateTime?> finishedAt,
  Value<SyncOutcome?> outcome,
  Value<String?> error,
});

class $$SyncRunsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncRunsTable> {
  $$SyncRunsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncTrigger, SyncTrigger, String>
  get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncPhase, SyncPhase, String> get phase =>
      $composableBuilder(
        column: $table.phase,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get heartbeatAt => $composableBuilder(
    column: $table.heartbeatAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get executing => $composableBuilder(
    column: $table.executing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncOutcome?, SyncOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncRunsTable> {
  $$SyncRunsTableOrderingComposer({
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

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get heartbeatAt => $composableBuilder(
    column: $table.heartbeatAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get executing => $composableBuilder(
    column: $table.executing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncRunsTable> {
  $$SyncRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncTrigger, String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncPhase, String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get heartbeatAt => $composableBuilder(
    column: $table.heartbeatAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get executing =>
      $composableBuilder(column: $table.executing, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncOutcome?, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SyncRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncRunsTable,
          SyncRunRow,
          $$SyncRunsTableFilterComposer,
          $$SyncRunsTableOrderingComposer,
          $$SyncRunsTableAnnotationComposer,
          $$SyncRunsTableCreateCompanionBuilder,
          $$SyncRunsTableUpdateCompanionBuilder,
          (
            SyncRunRow,
            BaseReferences<_$AppDatabase, $SyncRunsTable, SyncRunRow>,
          ),
          SyncRunRow,
          PrefetchHooks Function()
        > {
  $$SyncRunsTableTableManager(_$AppDatabase db, $SyncRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<SyncTrigger> trigger = const Value.absent(),
                Value<SyncPhase> phase = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> heartbeatAt = const Value.absent(),
                Value<bool> executing = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<SyncOutcome?> outcome = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SyncRunsCompanion(
                id: id,
                trigger: trigger,
                phase: phase,
                startedAt: startedAt,
                heartbeatAt: heartbeatAt,
                executing: executing,
                finishedAt: finishedAt,
                outcome: outcome,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required SyncTrigger trigger,
                required SyncPhase phase,
                required DateTime startedAt,
                Value<DateTime?> heartbeatAt = const Value.absent(),
                Value<bool> executing = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<SyncOutcome?> outcome = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SyncRunsCompanion.insert(
                id: id,
                trigger: trigger,
                phase: phase,
                startedAt: startedAt,
                heartbeatAt: heartbeatAt,
                executing: executing,
                finishedAt: finishedAt,
                outcome: outcome,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncRunsTable, SyncRunRow>(table),
                  BaseReferences<_$AppDatabase, $SyncRunsTable, SyncRunRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncRunsTable,
      SyncRunRow,
      $$SyncRunsTableFilterComposer,
      $$SyncRunsTableOrderingComposer,
      $$SyncRunsTableAnnotationComposer,
      $$SyncRunsTableCreateCompanionBuilder,
      $$SyncRunsTableUpdateCompanionBuilder,
      (SyncRunRow, BaseReferences<_$AppDatabase, $SyncRunsTable, SyncRunRow>),
      SyncRunRow,
      PrefetchHooks Function()
    >;
typedef $$SyncItemsTableCreateCompanionBuilder = SyncItemsCompanion Function({
  required int runId,
  required SyncItemKind kind,
  required int storyId,
  Value<SyncItemStatus> status,
  Value<String?> error,
  Value<int> rowid,
});
typedef $$SyncItemsTableUpdateCompanionBuilder = SyncItemsCompanion Function({
  Value<int> runId,
  Value<SyncItemKind> kind,
  Value<int> storyId,
  Value<SyncItemStatus> status,
  Value<String?> error,
  Value<int> rowid,
});

class $$SyncItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncItemKind, SyncItemKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncItemStatus, SyncItemStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncItemKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SyncItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncItemsTable,
          SyncItemRow,
          $$SyncItemsTableFilterComposer,
          $$SyncItemsTableOrderingComposer,
          $$SyncItemsTableAnnotationComposer,
          $$SyncItemsTableCreateCompanionBuilder,
          $$SyncItemsTableUpdateCompanionBuilder,
          (
            SyncItemRow,
            BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItemRow>,
          ),
          SyncItemRow,
          PrefetchHooks Function()
        > {
  $$SyncItemsTableTableManager(_$AppDatabase db, $SyncItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> runId = const Value.absent(),
                Value<SyncItemKind> kind = const Value.absent(),
                Value<int> storyId = const Value.absent(),
                Value<SyncItemStatus> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncItemsCompanion(
                runId: runId,
                kind: kind,
                storyId: storyId,
                status: status,
                error: error,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int runId,
                required SyncItemKind kind,
                required int storyId,
                Value<SyncItemStatus> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncItemsCompanion.insert(
                runId: runId,
                kind: kind,
                storyId: storyId,
                status: status,
                error: error,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncItemsTable, SyncItemRow>(table),
                  BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItemRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncItemsTable,
      SyncItemRow,
      $$SyncItemsTableFilterComposer,
      $$SyncItemsTableOrderingComposer,
      $$SyncItemsTableAnnotationComposer,
      $$SyncItemsTableCreateCompanionBuilder,
      $$SyncItemsTableUpdateCompanionBuilder,
      (
        SyncItemRow,
        BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItemRow>,
      ),
      SyncItemRow,
      PrefetchHooks Function()
    >;
typedef $$SettingEntriesTableCreateCompanionBuilder =
    SettingEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingEntriesTableUpdateCompanionBuilder =
    SettingEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingEntriesTable,
          SettingRow,
          $$SettingEntriesTableFilterComposer,
          $$SettingEntriesTableOrderingComposer,
          $$SettingEntriesTableAnnotationComposer,
          $$SettingEntriesTableCreateCompanionBuilder,
          $$SettingEntriesTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingEntriesTableTableManager(
    _$AppDatabase db,
    $SettingEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingEntriesTable, SettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingEntriesTable,
                    SettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingEntriesTable,
      SettingRow,
      $$SettingEntriesTableFilterComposer,
      $$SettingEntriesTableOrderingComposer,
      $$SettingEntriesTableAnnotationComposer,
      $$SettingEntriesTableCreateCompanionBuilder,
      $$SettingEntriesTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
  $$CommentsTableTableManager get comments =>
      $$CommentsTableTableManager(_db, _db.comments);
  $$FeedSnapshotsTableTableManager get feedSnapshots =>
      $$FeedSnapshotsTableTableManager(_db, _db.feedSnapshots);
  $$PageCopiesTableTableManager get pageCopies =>
      $$PageCopiesTableTableManager(_db, _db.pageCopies);
  $$ThreadStatesTableTableManager get threadStates =>
      $$ThreadStatesTableTableManager(_db, _db.threadStates);
  $$SyncRunsTableTableManager get syncRuns =>
      $$SyncRunsTableTableManager(_db, _db.syncRuns);
  $$SyncItemsTableTableManager get syncItems =>
      $$SyncItemsTableTableManager(_db, _db.syncItems);
  $$SettingEntriesTableTableManager get settingEntries =>
      $$SettingEntriesTableTableManager(_db, _db.settingEntries);
}
