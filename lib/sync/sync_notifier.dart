import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:offline_hn/app_name.dart';
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
  SyncNotifier(this._plugin, this._marker);

  static const _id = 1;
  static const _channelId = 'sync';

  final FlutterLocalNotificationsPlugin _plugin;
  final ForegroundMarker _marker;

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
    if (!_marker.isForeground) await _show();
  }

  @override
  Future<void> runEnded() => _plugin.cancel(id: _id);

  @override
  Future<void> appLeft() => _show();

  @override
  Future<void> appOpened() => _plugin.cancel(id: _id);

  Future<void> _show() => _plugin.show(
    id: _id,
    title: appName,
    body: 'Updating stories',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Updating stories',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showProgress: true,
        indeterminate: true,
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
      ),
    ),
  );
}
