import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:offline_hn/data/db/tables.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

part 'database.g.dart';

const databaseFileName = 'offline_hn.sqlite';

void configureConnection(CommonDatabase db) {
  db.execute('PRAGMA journal_mode = WAL');
  db.execute('PRAGMA busy_timeout = 5000');
  db.execute('PRAGMA synchronous = NORMAL');
}

/// Trigram index over the plain-text fields of a story, kept in step by
/// triggers so no write path has to know about it.
const storySearchIndexStatements = [
  '''CREATE VIRTUAL TABLE story_search USING fts5(
    title, domain, "by", content='stories', content_rowid='id',
    tokenize='trigram')''',
  '''CREATE TRIGGER story_search_insert AFTER INSERT ON stories BEGIN
    INSERT INTO story_search(rowid, title, domain, "by")
    VALUES (new.id, new.title, new.domain, new."by");
  END''',
  '''CREATE TRIGGER story_search_delete AFTER DELETE ON stories BEGIN
    INSERT INTO story_search(story_search, rowid, title, domain, "by")
    VALUES ('delete', old.id, old.title, old.domain, old."by");
  END''',
  '''CREATE TRIGGER story_search_update AFTER UPDATE OF title, domain, "by"
  ON stories BEGIN
    INSERT INTO story_search(story_search, rowid, title, domain, "by")
    VALUES ('delete', old.id, old.title, old.domain, old."by");
    INSERT INTO story_search(rowid, title, domain, "by")
    VALUES (new.id, new.title, new.domain, new."by");
  END''',
  "INSERT INTO story_search(story_search) VALUES ('rebuild')",
];

@DriftDatabase(
  tables: [
    Stories,
    Comments,
    FeedSnapshots,
    PageCopies,
    LinkCopies,
    LinkReferences,
    ThreadStates,
    SyncRuns,
    SyncItems,
    SettingEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.connection);

  /// Safe to call from the UI isolate and from a background isolate that has
  /// plugins registered (`DartPluginRegistrant.ensureInitialized()`).
  ///
  /// The first caller in the process spawns one database isolate that owns the
  /// only SQLite connection and registers it by name; every later caller
  /// connects to it. That is also what makes `watch()` streams in the UI see
  /// writes made by a background isolate, which separate connections would
  /// not report.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'offline_hn',
      native: DriftNativeOptions(
        databasePath: () async => p.join(
          (await getApplicationSupportDirectory()).path,
          databaseFileName,
        ),
        shareAcrossIsolates: true,
        setup: configureConnection,
      ),
    ),
  );

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createSearchIndex();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(syncRuns, syncRuns.heartbeatAt);
      if (from < 3) await m.addColumn(syncRuns, syncRuns.executing);
      if (from < 4) await m.addColumn(stories, stories.savedAt);
      if (from < 5) await _createSearchIndex();
      if (from < 6) {
        await m.createTable(linkCopies);
        await m.createTable(linkReferences);
      }
    },
  );

  Future<void> _createSearchIndex() async {
    for (final statement in storySearchIndexStatements) {
      await customStatement(statement);
    }
  }
}
