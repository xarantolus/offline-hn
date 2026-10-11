import 'package:offline_hn/data/model/daily_time.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';

enum NetworkRequirement { connected, unmetered }

/// The next time the wall clock reads [at] in the phone's current timezone.
/// A time that does not exist on a day the clocks go forward runs when the
/// hour has passed.
DateTime nextDailyRun(
  DailyTime at,
  DateTime now, {
  UtcOffsetAt offsetAt = deviceOffsetAt,
}) {
  final instant = now.toUtc();
  for (var day = localDayOf(instant, offsetAt: offsetAt); ; day = day.next()) {
    final wall = DateTime.utc(day.year, day.month, day.day, at.hour, at.minute);
    final guess = wall.subtract(offsetAt(wall));
    final candidate = wall.subtract(offsetAt(guess));
    if (candidate.isAfter(instant)) return candidate;
  }
}

/// Automatic runs follow the Wi-Fi setting. A run the user asked for takes
/// whatever connection there is, and the runner decides what it may fetch.
NetworkRequirement networkFor(SyncTrigger trigger, AppSettings settings) {
  return settings.wifiOnly && !trigger.userInitiated
      ? NetworkRequirement.unmetered
      : NetworkRequirement.connected;
}
