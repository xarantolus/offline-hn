import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:offline_hn/app_name.dart';
import 'package:offline_hn/data/policy/run_progress.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/foreground_marker.dart';

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

  final FlutterLocalNotificationsPlugin _plugin;
  final ForegroundMarker _marker;
  final Stream<SyncProgress?> Function() _progress;
  final _pace = NotifyPace();
  StreamSubscription<SyncProgress?>? _following;

  Future<void> initialize() => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
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
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
      ),
    ),
  );
}
