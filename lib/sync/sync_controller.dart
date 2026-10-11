import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/network_policy.dart';
import 'package:offline_hn/data/policy/run_policy.dart';
import 'package:offline_hn/data/policy/staleness.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/connection_probe.dart';
import 'package:offline_hn/sync/foreground_marker.dart';
import 'package:offline_hn/sync/live_progress.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/sync/sync_notifier.dart';
import 'package:offline_hn/sync/work_queue.dart';

enum SyncRequest {
  /// A sync is queued, or the one already waiting or running will serve.
  queued,

  /// Nothing could be fetched over the current connection.
  noConnection,
}

/// What the screens use. They never fetch: they ask here, and watch the
/// database through [progress] and [lastSync].
class SyncController {
  SyncController({
    required this._syncs,
    required this._settings,
    required this._probe,
    required this._queue,
    required this._notifier,
    required this._marker,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SyncRepository _syncs;
  final SettingsStore _settings;
  final ConnectionProbe _probe;
  final WorkQueue _queue;
  final RunNotifier _notifier;
  final ForegroundMarker _marker;
  final DateTime Function() _clock;

  /// Null when no run is in progress.
  Stream<SyncProgress?> get progress =>
      withoutDeadRuns(_syncs.watchProgress(), _clock);

  Stream<DateTime?> get lastSync => _syncs.watchLastSuccessfulSync();

  /// The connection now, then every change.
  Stream<ConnectionKind> get connection async* {
    yield await _probe.current();
    yield* _probe.changes;
  }

  /// Whether the catch-up on open can run over the current connection. When it
  /// cannot, the empty screen offers the fetch itself.
  Future<bool> canFetchAutomatically() async =>
      syncAllowance(
        trigger: SyncTrigger.catchUp,
        connection: await _probe.current(),
        settings: await _settings.load(),
      ) !=
      SyncAllowance.nothing;

  Future<SyncRequest> requestSync(SyncTrigger trigger) async {
    final settings = await _settings.load();
    final allowance = syncAllowance(
      trigger: trigger,
      connection: await _probe.current(),
      settings: settings,
    );
    if (allowance == SyncAllowance.nothing) return SyncRequest.noConnection;
    await _queue.enqueueSync(trigger, networkFor(trigger, settings));
    return SyncRequest.queued;
  }

  /// An empty store counts as stale.
  Future<void> catchUpIfStale() async {
    if (isStale(await _syncs.lastSuccessfulSync(), _clock())) {
      await requestSync(SyncTrigger.catchUp);
    }
  }

  Future<void> appResumed() async {
    await _marker.setForeground(value: true);
    await _notifier.appOpened();
  }

  Future<void> appPaused() async {
    await _marker.setForeground(value: false);
    final running = await _syncs.watchProgress().first;
    if (running != null && runIsAlive(running.heartbeatAt, _clock())) {
      await _notifier.appLeft();
    }
  }
}
