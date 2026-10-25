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

/// What must hold before the system starts the work.
class WorkRequirements {
  const WorkRequirements({required this.network, required this.charging});

  final NetworkRequirement network;
  final bool charging;

  @override
  bool operator ==(Object other) =>
      other is WorkRequirements &&
      other.network == network &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(network, charging);

  @override
  String toString() => 'WorkRequirements($network, charging: $charging)';
}

/// Automatic runs follow the Wi-Fi and charging settings. A run the user asked
/// for takes whatever connection and battery state there is, and the runner
/// decides what it may fetch. The very first update has nothing on screen to
/// fall back on, so it does not wait for a charger either.
WorkRequirements requirementsFor(
  SyncTrigger trigger,
  AppSettings settings, {
  bool firstUpdate = false,
}) {
  final automatic = !trigger.userInitiated;
  return WorkRequirements(
    network: settings.wifiOnly && automatic
        ? NetworkRequirement.unmetered
        : NetworkRequirement.connected,
    charging: settings.chargingOnly && automatic && !firstUpdate,
  );
}
