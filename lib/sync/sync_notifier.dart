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

  /// A killed process cannot take its notification down, and Android keeps an
  /// ongoing one up for good: it would sit there, stuck, until the app is next
  /// opened. So it expires unless posted again, and a living run posts it
  /// again well before that.
  static const _expiresAfter = Duration(minutes: 3);
  static const _repostEvery = Duration(minutes: 1);

  final FlutterLocalNotificationsPlugin _plugin;
  final ForegroundMarker _marker;
  final Stream<SyncProgress?> Function() _progress;
  final _pace = NotifyPace();
  StreamSubscription<SyncProgress?>? _following;
  Timer? _keepAlive;
  ({int percent, String text})? _shown;

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
    _follow(keepAlive: true);
  }

  @override
  Future<void> runEnded() async {
    await _unfollow();
    await _plugin.cancel(id: _id);
  }

  @override
  Future<void> appLeft() async {
    _pace.reset();
    _follow(keepAlive: false);
  }

  @override
  Future<void> appOpened() async {
    await _unfollow();
    await _plugin.cancel(id: _id);
  }

  /// Only the process doing the run keeps the notification alive. The app's
  /// own copy would carry on posting a run that was stopped under it.
  void _follow({required bool keepAlive}) {
    _following ??= _progress().listen(_onProgress);
    if (!keepAlive) return;
    _keepAlive ??= Timer.periodic(_repostEvery, (_) {
      final shown = _shown;
      if (shown == null || _marker.isForeground) return;
      unawaited(_show(shown.percent, shown.text));
    });
  }

  Future<void> _unfollow() async {
    final following = _following;
    _following = null;
    _keepAlive?.cancel();
    _keepAlive = null;
    _shown = null;
    await following?.cancel();
  }

  void _onProgress(SyncProgress? progress) {
    if (progress == null) {
      _pace.reset();
      _shown = null;
      unawaited(_plugin.cancel(id: _id));
      return;
    }
    if (_marker.isForeground) return;
    final percent = runPercent(progress);
    if (!_pace.allow(progress.runId, percent, DateTime.now())) return;
    unawaited(_show(percent, runStageText(progress.phase)));
  }

  Future<void> _show(int percent, String text) {
    _shown = (percent: percent, text: text);
    return _plugin.show(
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
          timeoutAfter: _expiresAfter.inMilliseconds,
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
}
