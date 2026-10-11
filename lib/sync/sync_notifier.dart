import 'dart:async';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:offline_hn/app_name.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/policy/run_progress.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/foreground_marker.dart';
import 'package:offline_hn/sync/sync_controller.dart';
import 'package:offline_hn/sync/work_queue.dart';

/// The Stop button on the progress notification. It runs without the app on
/// screen, so it opens what it needs itself.
@pragma('vm:entry-point')
Future<void> stopSyncFromNotification(NotificationResponse response) async {
  if (response.actionId != SyncNotifier.stopAction) return;
  DartPluginRegistrant.ensureInitialized();
  final db = AppDatabase.open();
  try {
    await stopRunning(
      SyncRepository(db),
      const WorkmanagerQueue(),
      DateTime.now(),
    );
  } finally {
    await db.close();
  }
}

abstract interface class RunNotifier {
  /// Clears any earlier notification, then shows progress unless the app is
  /// on screen.
  Future<void> runStarted();

  Future<void> runEnded();

  /// For the UI going to the background in the middle of a run.
  Future<void> appLeft();

  Future<void> appOpened();
}

class SyncNotifier implements RunNotifier {
  SyncNotifier(this._plugin, this._marker, this._progress);

  static const _id = 1;
  static const _channelId = 'sync';
  static const stopAction = 'stop';

  final FlutterLocalNotificationsPlugin _plugin;
  final ForegroundMarker _marker;
  final Stream<SyncProgress?> Function() _progress;
  final _pace = NotifyPace();
  StreamSubscription<SyncProgress?>? _following;

  Future<void> initialize() => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveBackgroundNotificationResponse: stopSyncFromNotification,
  );

  /// Android 13+ asks; earlier versions have nothing to ask. A refusal leaves
  /// the app silent.
  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;

  @override
  Future<void> runStarted() async {
    await _plugin.cancel(id: _id);
    _pace.reset();
    _follow();
  }

  @override
  Future<void> runEnded() async {
    await _unfollow();
    await _plugin.cancel(id: _id);
  }

  @override
  Future<void> appLeft() async {
    _pace.reset();
    _follow();
  }

  @override
  Future<void> appOpened() async {
    await _unfollow();
    await _plugin.cancel(id: _id);
  }

  void _follow() {
    _following ??= _progress().listen(_onProgress);
  }

  Future<void> _unfollow() async {
    final following = _following;
    _following = null;
    await following?.cancel();
  }

  void _onProgress(SyncProgress? progress) {
    if (progress == null) {
      _pace.reset();
      unawaited(_plugin.cancel(id: _id));
      return;
    }
    if (_marker.isForeground) return;
    final percent = runPercent(progress);
    if (!_pace.allow(progress.runId, percent, DateTime.now())) return;
    unawaited(_show(percent, runStageText(progress.phase)));
  }

  Future<void> _show(int percent, String text) => _plugin.show(
    id: _id,
    title: appName,
    body: text,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Updating stories',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: 100,
        progress: percent,
        actions: const [AndroidNotificationAction(stopAction, 'Stop')],
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
      ),
    ),
  );
}
