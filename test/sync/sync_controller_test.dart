import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/connection_probe.dart';
import 'package:offline_hn/sync/foreground_marker.dart';
import 'package:offline_hn/sync/live_progress.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/sync/sync_controller.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeQueue queue;
  late FakeProbe probe;
  late FakeNotifier notifier;
  late SettingsStore settings;
  late SyncRepository syncs;
  late ForegroundMarker marker;
  late SyncController controller;
  var now = DateTime.utc(2026, 10, 10, 12);

  setUp(() {
    now = DateTime.utc(2026, 10, 10, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = FakeQueue();
    probe = FakeProbe();
    notifier = FakeNotifier();
    settings = SettingsStore(db);
    syncs = SyncRepository(db);
    marker = ForegroundMarker(
      File('${Directory.systemTemp.createTempSync('marker').path}/foreground'),
      currentPid: 42,
    );
    controller = SyncController(
      syncs: syncs,
      settings: settings,
      probe: probe,
      queue: queue,
      notifier: notifier,
      marker: marker,
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  Future<void> finishedSync(DateTime at) async {
    final run = await syncs.beginOrResume(SyncTrigger.manual, at);
    await syncs.finish(run.id, SyncOutcome.succeeded, at);
  }

  group('requesting a sync', () {
    test('enqueues it with the network the trigger needs', () async {
      expect(
        await controller.requestSync(SyncTrigger.manual),
        SyncRequest.queued,
      );
      expect(queue.syncs.single, (
        SyncTrigger.manual,
        NetworkRequirement.connected,
      ));
    });

    test(
      'a manual sync on mobile data with Wi-Fi only is still queued for text',
      () async {
        probe.kind = ConnectionKind.mobile;
        expect(
          await controller.requestSync(SyncTrigger.manual),
          SyncRequest.queued,
        );
      },
    );

    test(
      'an automatic trigger on mobile data with Wi-Fi only is not',
      () async {
        probe.kind = ConnectionKind.mobile;
        expect(
          await controller.requestSync(SyncTrigger.catchUp),
          SyncRequest.noConnection,
        );
        expect(queue.syncs, isEmpty);
      },
    );

    test('nothing is queued offline', () async {
      probe.kind = ConnectionKind.none;
      expect(
        await controller.requestSync(SyncTrigger.manual),
        SyncRequest.noConnection,
      );
      expect(queue.syncs, isEmpty);
    });

    test('allowing mobile data lets the catch-up through', () async {
      probe.kind = ConnectionKind.mobile;
      await settings.set(Settings.wifiOnly, false);
      expect(
        await controller.requestSync(SyncTrigger.catchUp),
        SyncRequest.queued,
      );
      expect(queue.syncs.single.$2, NetworkRequirement.connected);
    });
  });

  group('catching up on open', () {
    test('an empty store counts as stale', () async {
      await controller.catchUpIfStale();
      expect(queue.syncs.single.$1, SyncTrigger.catchUp);
    });

    test('data from the last two hours is left alone', () async {
      await finishedSync(now.subtract(const Duration(minutes: 90)));
      await controller.catchUpIfStale();
      expect(queue.syncs, isEmpty);
    });

    test('older data triggers one', () async {
      await finishedSync(now.subtract(const Duration(hours: 3)));
      await controller.catchUpIfStale();
      expect(queue.syncs, hasLength(1));
    });

    test('a last sync in the future is not trusted', () async {
      await finishedSync(now.add(const Duration(days: 1)));
      await controller.catchUpIfStale();
      expect(queue.syncs, hasLength(1));
    });
  });

  group('leaving and returning', () {
    test(
      'opening the app clears the notification and marks it on screen',
      () async {
        await controller.appResumed();
        expect(notifier.events, ['opened']);
        expect(marker.isForeground, isTrue);
      },
    );

    test('leaving during a run shows the notification', () async {
      final run = await syncs.beginOrResume(SyncTrigger.manual, now);
      await syncs.setPhase(run.id, SyncPhase.comments, now);
      await controller.appResumed();
      await controller.appPaused();
      expect(notifier.events, ['opened', 'left']);
      expect(marker.isForeground, isFalse);
    });

    test('leaving with nothing running shows nothing', () async {
      await controller.appPaused();
      expect(notifier.events, isEmpty);
    });

    test('leaving during a run whose process died shows nothing', () async {
      await syncs.beginOrResume(SyncTrigger.manual, now);
      now = now.add(const Duration(minutes: 30));
      await controller.appPaused();
      expect(notifier.events, isEmpty);
    });
  });

  group('foreground marker', () {
    test('a marker left by another process is not believed', () async {
      final file = File(
        '${Directory.systemTemp.createTempSync('marker').path}/foreground',
      );
      await ForegroundMarker(file, currentPid: 1).setForeground(value: true);
      expect(ForegroundMarker(file, currentPid: 1).isForeground, isTrue);
      expect(ForegroundMarker(file, currentPid: 2).isForeground, isFalse);
    });

    test('no file means in the background', () {
      expect(
        ForegroundMarker(
          File('/nonexistent/foreground'),
          currentPid: 1,
        ).isForeground,
        isFalse,
      );
    });
  });

  group('progress', () {
    test('a run that stops reporting disappears from the stream', () {
      fakeAsync((async) {
        var clock = DateTime.utc(2026, 10, 10, 5);
        final source = StreamController<SyncProgress?>();
        final seen = <bool>[];
        withoutDeadRuns(
          source.stream,
          () => clock,
        ).listen((progress) => seen.add(progress != null));

        source.add(
          SyncProgress(
            runId: 1,
            trigger: SyncTrigger.manual,
            phase: SyncPhase.comments,
            total: 10,
            done: 2,
            heartbeatAt: clock,
          ),
        );
        async.flushMicrotasks();
        expect(seen, [true]);

        clock = clock.add(const Duration(minutes: 2));
        async.elapse(const Duration(minutes: 2));
        expect(seen, [true]);

        clock = clock.add(const Duration(minutes: 3));
        async.elapse(const Duration(minutes: 3));
        expect(seen, [true, false]);
      });
    });

    test('a run that finishes ends the stream value at once', () {
      fakeAsync((async) {
        final source = StreamController<SyncProgress?>();
        final seen = <bool>[];
        withoutDeadRuns(
          source.stream,
          DateTime.now,
        ).listen((progress) => seen.add(progress != null));
        source.add(
          SyncProgress(
            runId: 1,
            trigger: SyncTrigger.manual,
            phase: SyncPhase.pages,
            total: 1,
            done: 0,
            heartbeatAt: DateTime.now(),
          ),
        );
        source.add(null);
        async.flushMicrotasks();
        expect(seen, [true, false]);
      });
    });
  });

  group('connection kind', () {
    test('Wi-Fi and ethernet are not metered', () {
      expect(connectionKindOf([ConnectivityResult.wifi]), ConnectionKind.wifi);
      expect(
        connectionKindOf([ConnectivityResult.ethernet]),
        ConnectionKind.wifi,
      );
    });

    test('Wi-Fi wins over a mobile link that is also up', () {
      expect(
        connectionKindOf([ConnectivityResult.mobile, ConnectivityResult.wifi]),
        ConnectionKind.wifi,
      );
    });

    test('mobile and VPN-only count as metered, nothing as offline', () {
      expect(
        connectionKindOf([ConnectivityResult.mobile]),
        ConnectionKind.mobile,
      );
      expect(connectionKindOf([ConnectivityResult.vpn]), ConnectionKind.mobile);
      expect(connectionKindOf([ConnectivityResult.none]), ConnectionKind.none);
      expect(connectionKindOf(const []), ConnectionKind.none);
    });
  });
}
