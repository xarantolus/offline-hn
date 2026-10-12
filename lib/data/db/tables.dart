import 'package:drift/drift.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/sync_enums.dart';

@DataClassName('StoryRow')
class Stories extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get url => text().nullable()();
  TextColumn get domain => text().nullable()();
  TextColumn get by => text().nullable()();
  IntColumn get points => integer().nullable()();
  IntColumn get commentCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get time => dateTime().nullable()();
  TextColumn get type => text().withDefault(const Constant('story'))();
  TextColumn get body => text().nullable()();
  DateTimeColumn get firstSeen => dateTime()();
  DateTimeColumn get lastSeen => dateTime()();
  DateTimeColumn get commentsFetchedAt => dateTime().nullable()();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
  BoolColumn get saved => boolean().withDefault(const Constant(false))();
  DateTimeColumn get savedAt => dateTime().nullable()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CommentRow')
@TableIndex(name: 'comments_by_story', columns: {#storyId, #position})
class Comments extends Table {
  IntColumn get id => integer()();
  IntColumn get storyId => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get html => text().nullable()();
  DateTimeColumn get time => dateTime().nullable()();
  IntColumn get position => integer()();
  IntColumn get depth => integer()();
  BoolColumn get dead => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SnapshotRow')
@TableIndex(name: 'snapshots_by_time', columns: {#feedKind, #fetchedAt})
class FeedSnapshots extends Table {
  IntColumn get fetchId => integer()();
  TextColumn get feedKind => textEnum<FeedKind>()();
  IntColumn get storyId => integer()();
  IntColumn get rank => integer()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {fetchId, storyId};
}

@DataClassName('PageCopyRow')
class PageCopies extends Table {
  IntColumn get storyId => integer()();
  TextColumn get kind => textEnum<PageKind>()();
  TextColumn get relativePath => text().nullable()();
  IntColumn get bytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get status => textEnum<PageStatus>()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {storyId};
}

/// A page linked from a top comment. One copy per address, however many
/// stories link to it.
@DataClassName('LinkCopyRow')
class LinkCopies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().unique()();
  TextColumn get kind =>
      textEnum<PageKind>().withDefault(Constant(PageKind.mhtml.name))();
  TextColumn get relativePath => text().nullable()();
  IntColumn get bytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get capturedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status =>
      textEnum<LinkStatus>().withDefault(Constant(LinkStatus.pending.name))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
}

@DataClassName('LinkReferenceRow')
class LinkReferences extends Table {
  IntColumn get storyId => integer()();
  IntColumn get linkId => integer()();

  @override
  Set<Column<Object>> get primaryKey => {storyId, linkId};
}

@DataClassName('ThreadStateRow')
class ThreadStates extends Table {
  IntColumn get storyId => integer()();
  DateTimeColumn get lastOpenedAt => dateTime()();
  DateTimeColumn get seenUpToCommentTime => dateTime().nullable()();
  TextColumn get collapsedIds => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {storyId};
}

@DataClassName('SyncRunRow')
class SyncRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trigger => textEnum<SyncTrigger>()();
  TextColumn get phase => textEnum<SyncPhase>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get heartbeatAt => dateTime().nullable()();

  /// Set while a process is working on the run; still set when a new process
  /// finds the run, it means the previous one died.
  BoolColumn get executing => boolean().withDefault(const Constant(false))();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get outcome => textEnum<SyncOutcome>().nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get connection => textEnum<ConnectionKind>().nullable()();
  IntColumn get storiesUpdated => integer().withDefault(const Constant(0))();
  BoolColumn get listsRefreshed =>
      boolean().withDefault(const Constant(false))();
  IntColumn get prunedCopies => integer().withDefault(const Constant(0))();
  IntColumn get prunedStories => integer().withDefault(const Constant(0))();
  IntColumn get prunedBytes => integer().withDefault(const Constant(0))();
}

@DataClassName('SyncItemRow')
class SyncItems extends Table {
  IntColumn get runId => integer()();
  TextColumn get kind => textEnum<SyncItemKind>()();
  IntColumn get storyId => integer()();
  TextColumn get status =>
      textEnum<SyncItemStatus>().withDefault(const Constant('pending'))();
  TextColumn get error => text().nullable()();
  IntColumn get bytes => integer().withDefault(const Constant(0))();

  /// A linked Hacker News discussion fetched as text instead of a page.
  BoolColumn get asThread => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {runId, kind, storyId};
}

@DataClassName('SettingRow')
class SettingEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
