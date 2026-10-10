import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/daily_time.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/data/repository/thread_state_repository.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/sync/connection_probe.dart';
import 'package:offline_hn/sync/foreground_marker.dart';
import 'package:offline_hn/sync/scheduler.dart';
import 'package:offline_hn/sync/sync_controller.dart';
import 'package:offline_hn/sync/sync_notifier.dart';
import 'package:offline_hn/sync/sync_task_handler.dart';
import 'package:offline_hn/sync/work_queue.dart';
import 'package:workmanager/workmanager.dart';

typedef ScheduleSettings = ({
  DailyTime dailyTime,
  int? intervalHours,
  bool wifiOnly,
});

/// What the UI reads and calls. Built once in `main`.
class AppServices {
  AppServices._({
    required this.db,
    required this.settings,
    required this.stories,
    required this.pages,
    required this.threadStates,
    required this.sync,
    required this.scheduler,
    required this.notifier,
  });

  static const _askedForNotifications = Setting<bool>(
    'askedForNotifications',
    false,
    bool.parse,
    _encodeBool,
  );

  final AppDatabase db;
  final SettingsStore settings;
  final StoryRepository stories;
  final PageRepository pages;
  final ThreadStateRepository threadStates;
  final SyncController sync;
  final Scheduler scheduler;
  final SyncNotifier notifier;

  static String _encodeBool(bool value) => value.toString();

  static Future<AppServices> open() async {
    await Workmanager().initialize(syncCallbackDispatcher);
    final db = AppDatabase.open();
    final settings = SettingsStore(db);
    final marker = await ForegroundMarker.locate();
    final notifier = SyncNotifier(FlutterLocalNotificationsPlugin(), marker);
    await notifier.initialize();
    const queue = WorkmanagerQueue();
    return AppServices._(
      db: db,
      settings: settings,
      stories: StoryRepository(db),
      pages: PageRepository(db),
      threadStates: ThreadStateRepository(db),
      scheduler: Scheduler(queue),
      notifier: notifier,
      sync: SyncController(
        syncs: SyncRepository(db),
        settings: settings,
        probe: PluginConnectionProbe(),
        queue: queue,
        notifier: notifier,
        marker: marker,
      ),
    );
  }

  StreamSubscription<ScheduleSettings>? _scheduleWatch;

  /// Keeps the schedule in line with the settings, now and whenever they
  /// change, and fetches if the data is old. Call on start.
  Future<void> start() async {
    _scheduleWatch ??= settings
        .watch()
        .map(
          (s) => (
            dailyTime: s.dailyTime,
            intervalHours: s.intervalHours,
            wifiOnly: s.wifiOnly,
          ),
        )
        .distinct()
        .listen((_) async => scheduler.apply(await settings.load()));
    await sync.appResumed();
    await sync.catchUpIfStale();
  }

  /// Asks for notification permission the first time only. A refusal is final
  /// and the app stays silent.
  Future<void> askForNotificationsOnce() async {
    if (await settings.read(_askedForNotifications)) return;
    await settings.set(_askedForNotifications, true);
    await notifier.requestPermission();
  }
}
