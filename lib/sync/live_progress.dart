import 'dart:async';

import 'package:offline_hn/data/policy/run_policy.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';

/// [source] with runs whose heartbeat has gone quiet reported as finished,
/// re-checked on a timer because nothing in the database changes when a
/// process dies.
Stream<SyncProgress?> withoutDeadRuns(
  Stream<SyncProgress?> source,
  DateTime Function() clock, {
  Duration recheckEvery = const Duration(seconds: 30),
}) {
  late final StreamController<SyncProgress?> out;
  StreamSubscription<SyncProgress?>? subscription;
  Timer? timer;
  SyncProgress? latest;

  SyncProgress? alive() {
    final progress = latest;
    return progress != null && runIsAlive(progress.heartbeatAt, clock())
        ? progress
        : null;
  }

  void recheck() {
    if (latest != null && alive() == null) {
      latest = null;
      timer?.cancel();
      out.add(null);
    }
  }

  out = StreamController<SyncProgress?>(
    onListen: () {
      subscription = source.listen(
        (progress) {
          latest = progress;
          out.add(alive());
          timer?.cancel();
          if (progress != null) {
            timer = Timer.periodic(recheckEvery, (_) => recheck());
          }
        },
        onError: out.addError,
        onDone: out.close,
      );
    },
    onCancel: () async {
      timer?.cancel();
      await subscription?.cancel();
    },
  );
  return out.stream;
}
