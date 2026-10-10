import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/sync/background_environment.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/sync/sync_runner.dart';
import 'package:offline_hn/sync/work_queue.dart';
import 'package:workmanager/workmanager.dart';

/// Entry point of every WorkManager task, in an isolate of its own.
@pragma('vm:entry-point')
void syncCallbackDispatcher() {
  DartPluginRegistrant.ensureInitialized();
  Workmanager().executeTask(
    SyncTaskHandler.handle,
    onTaskStopped: (task, reason) async => SyncTaskHandler.stop(),
  );
}

abstract final class SyncTaskHandler {
  static SyncRunner? _running;

  /// The platform is taking the job away: leave the run resumable.
  static void stop() => _running?.requestStop();

  /// Whether the job succeeded; false asks WorkManager to run it again after a
  /// backoff, which is how a run that ran out of time continues.
  static Future<bool> handle(String task, Map<String, dynamic>? input) async {
    final environment = await BackgroundEnvironment.open();
    try {
      switch (task) {
        case SyncTasks.sync:
          return await _sync(environment, input);
        case SyncTasks.daily:
          return await _daily(environment);
        case SyncTasks.periodic:
          return await _enqueue(environment, SyncTrigger.periodic);
        case SyncTasks.reschedule:
          await environment.scheduler.apply(await environment.settings.load());
          return true;
        default:
          throw FormatException('unknown task', task);
      }
    } finally {
      _running = null;
      await environment.close();
    }
  }

  static Future<bool> _sync(
    BackgroundEnvironment environment,
    Map<String, dynamic>? input,
  ) async {
    final trigger = SyncTrigger.values.byName(
      input?[SyncTasks.triggerKey] as String? ?? SyncTrigger.periodic.name,
    );
    _running = environment.runner;
    final result = await environment.runner.run(trigger);
    debugPrintSynchronously('sync $trigger: ${result.name}');
    return result != SyncResult.paused;
  }

  static Future<bool> _daily(BackgroundEnvironment environment) async {
    await _enqueue(environment, SyncTrigger.scheduled);
    await environment.scheduler.scheduleDaily(
      await environment.settings.load(),
      afterRun: true,
    );
    return true;
  }

  static Future<bool> _enqueue(
    BackgroundEnvironment environment,
    SyncTrigger trigger,
  ) async {
    final settings = await environment.settings.load();
    await environment.queue.enqueueSync(trigger, networkFor(trigger, settings));
    return true;
  }
}
