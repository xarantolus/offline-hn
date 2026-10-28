import 'package:offline_hn/data/model/daily_time.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/policy/network_policy.dart';

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
/// decides what it may fetch.
WorkRequirements requirementsFor(SyncTrigger trigger, AppSettings settings) {
  final automatic = !trigger.userInitiated;
  return WorkRequirements(
    network: settings.wifiOnly && automatic
        ? NetworkRequirement.unmetered
        : NetworkRequirement.connected,
    charging: settings.chargingOnly && automatic,
  );
}

/// What an automatic update may be waiting for.
enum AutomaticHold { connection, charger }

/// Empty when the catch-up can start right away. The charger is a requirement
/// rather than a known battery state: on a phone that is already charging the
/// run starts anyway, and its progress takes over the screen.
Set<AutomaticHold> automaticHolds(
  SyncAllowance allowance,
  AppSettings settings,
) => {
  if (allowance == SyncAllowance.nothing) AutomaticHold.connection,
  if (settings.chargingOnly) AutomaticHold.charger,
};
