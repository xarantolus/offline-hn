import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:offline_hn/capture/filter_lists.dart';
import 'package:offline_hn/data/api/hn_source.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/prune_service.dart';
import 'package:offline_hn/data/repository/link_repository.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/data/repository/retention_repository.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/connection_probe.dart';
import 'package:offline_hn/sync/filter_list_sync.dart';
import 'package:offline_hn/sync/foreground_marker.dart';
import 'package:offline_hn/sync/live_progress.dart';
import 'package:offline_hn/sync/page_files.dart';
import 'package:offline_hn/sync/page_saver.dart';
import 'package:offline_hn/sync/pdf_downloader.dart';
import 'package:offline_hn/sync/scheduler.dart';
import 'package:offline_hn/sync/sync_notifier.dart';
import 'package:offline_hn/sync/sync_runner.dart';
import 'package:offline_hn/sync/work_queue.dart';

/// Everything a WorkManager task needs, opened for the length of one task.
class BackgroundEnvironment {
  BackgroundEnvironment._({
    required this.db,
    required this.settings,
    required this.runner,
    required this.scheduler,
    required this.queue,
  });

  final AppDatabase db;
  final SettingsStore settings;
  final SyncRunner runner;
  final Scheduler scheduler;
  final WorkQueue queue;

  static Future<BackgroundEnvironment> open() async {
    final db = AppDatabase.open();
    final settings = SettingsStore(db);
    final files = await PageFiles.locate();
    final lists = FilterListsSync(
      FilterLists(directory: await FilterLists.locate(), settings: settings),
    );
    final syncs = SyncRepository(db);
    final notifier = SyncNotifier(
      FlutterLocalNotificationsPlugin(),
      await ForegroundMarker.locate(),
      () => withoutDeadRuns(syncs.watchProgress(), DateTime.now),
    );
    await notifier.initialize();
    final pages = PageRepository(db);
    final links = LinkRepository(db);
    const queue = WorkmanagerQueue();
    final probe = PluginConnectionProbe();

    return BackgroundEnvironment._(
      db: db,
      settings: settings,
      queue: queue,
      scheduler: Scheduler(queue),
      runner: SyncRunner(
        syncs: syncs,
        stories: StoryRepository(db),
        pages: pages,
        links: links,
        settings: settings,
        source: HnSource.create(),
        probe: probe,
        saver: PageSaver(
          files: files,
          pages: pages,
          links: links,
          capture: captureWithPlugin,
          pdf: PdfDownloader(),
          probe: probe,
          filterListsDirectory: lists.directoryPath,
        ),
        lists: lists,
        prune: PruneService(RetentionRepository(db)),
        files: files,
        notifier: notifier,
      ),
    );
  }

  Future<void> close() => db.close();
}
