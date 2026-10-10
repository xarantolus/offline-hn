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

@DriftDatabase(
  tables: [
    Stories,
    Comments,
    FeedSnapshots,
    PageCopies,
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
  int get schemaVersion => 1;
}
