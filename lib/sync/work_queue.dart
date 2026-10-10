import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:workmanager/workmanager.dart';

/// What the app asks of the operating system's job scheduler. The tasks it
/// registers only ever enqueue [syncWork]; fetching happens there and nowhere
/// else.
abstract interface class WorkQueue {
  /// Joins a sync that is already waiting or running.
  Future<void> enqueueSync(SyncTrigger trigger, NetworkRequirement network);

  /// Replaces the pending daily trigger, or with [afterRun] queues the next
  /// one behind the daily task that is running: replacing a running task
  /// cancels it.
  Future<void> scheduleDaily(
    Duration delay,
    NetworkRequirement network, {
    bool afterRun = false,
  });

  Future<void> schedulePeriodic(Duration every, NetworkRequirement network);

  Future<void> cancelPeriodic();
}

abstract final class SyncTasks {
  static const syncWork = 'sync';
  static const dailyWork = 'sync:daily';
  static const periodicWork = 'sync:periodic';

  /// The native time-change receiver enqueues this one under [rescheduleWork];
  /// both strings are repeated in `TimeChangeReceiver.kt`.
  static const rescheduleWork = 'sync:reschedule';

  static const sync = 'sync';
  static const daily = 'daily';
  static const periodic = 'periodic';
  static const reschedule = 'reschedule';

  static const triggerKey = 'trigger';
}

class WorkmanagerQueue implements WorkQueue {
  const WorkmanagerQueue();

  static const _backoff = Duration(seconds: 10);

  @override
  Future<void> enqueueSync(SyncTrigger trigger, NetworkRequirement network) =>
      Workmanager().registerOneOffTask(
        SyncTasks.syncWork,
        SyncTasks.sync,
        inputData: {SyncTasks.triggerKey: trigger.name},
        constraints: _constraints(network),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: _backoff,
      );

  @override
  Future<void> scheduleDaily(
    Duration delay,
    NetworkRequirement network, {
    bool afterRun = false,
  }) => Workmanager().registerOneOffTask(
    SyncTasks.dailyWork,
    SyncTasks.daily,
    initialDelay: delay,
    constraints: _constraints(network),
    existingWorkPolicy: afterRun
        ? ExistingWorkPolicy.update
        : ExistingWorkPolicy.replace,
  );

  @override
  Future<void> schedulePeriodic(Duration every, NetworkRequirement network) =>
      Workmanager().registerPeriodicTask(
        SyncTasks.periodicWork,
        SyncTasks.periodic,
        frequency: every,
        constraints: _constraints(network),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

  @override
  Future<void> cancelPeriodic() =>
      Workmanager().cancelByUniqueName(SyncTasks.periodicWork);

  Constraints _constraints(NetworkRequirement network) => Constraints(
    networkType: network == NetworkRequirement.unmetered
        ? NetworkType.unmetered
        : NetworkType.connected,
  );
}
