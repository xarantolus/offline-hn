import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/sync/work_queue.dart';

class Scheduler {
  Scheduler(
    this._queue, {
    DateTime Function()? clock,
    this._offsetAt = deviceOffsetAt,
  }) : _clock = clock ?? DateTime.now;

  /// A task can wake a moment before its time; without a margin the next run
  /// would be scheduled for the minute that is just ending.
  static const _earlyWake = Duration(minutes: 1);

  final WorkQueue _queue;
  final DateTime Function() _clock;
  final UtcOffsetAt _offsetAt;

  /// Brings the scheduled work in line with [settings] and the phone's
  /// timezone as of now. Safe to repeat: app start, a settings change and a
  /// timezone change all call it.
  Future<void> apply(AppSettings settings) async {
    await scheduleDaily(settings);
    await _schedulePeriodic(settings);
  }

  Future<void> _schedulePeriodic(AppSettings settings) async {
    final hours = settings.intervalHours;
    if (hours == null) {
      await _queue.cancelPeriodic();
    } else {
      await _queue.schedulePeriodic(
        Duration(hours: hours),
        networkFor(SyncTrigger.periodic, settings),
      );
    }
  }

  Future<void> scheduleDaily(AppSettings settings, {bool afterRun = false}) {
    final now = _clock();
    final from = afterRun ? now.add(_earlyWake) : now;
    final run = nextDailyRun(settings.dailyTime, from, offsetAt: _offsetAt);
    return _queue.scheduleDaily(
      run.difference(now),
      networkFor(SyncTrigger.scheduled, settings),
      afterRun: afterRun,
    );
  }
}
