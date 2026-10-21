import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';

const minKeepDays = 1;
const maxKeepDays = 7;
const defaultKeepDays = 2;
const _legacyDefaultDays = 3;

/// The window counts today as the first day, so 2 is today and yesterday.
DateTime keepWindowStart(
  DateTime now,
  int keepDays, {
  UtcOffsetAt offsetAt = deviceOffsetAt,
}) {
  final first = localDayOf(now, offsetAt: offsetAt).minus(keepDays - 1);
  return dayBoundsUtc(first, offsetAt: offsetAt).startUtc;
}

/// The days of [days] inside the window, or just the newest when none are,
/// so a phone offline for a week still shows its last front page.
List<LocalDay> daysInWindow(List<LocalDay> days, LocalDay today, int keepDays) {
  final first = today.minus(keepDays - 1);
  final inside = [
    for (final day in days)
      if (day.compareTo(first) >= 0) day,
  ];
  return inside.isEmpty ? days.take(1).toList() : inside;
}

/// An install still on the old default of three days moves to the new one; a
/// value the user chose is kept.
int readKeepDays(Map<String, String> raw) {
  final current = int.tryParse(raw[keepDaysKey] ?? '');
  if (current != null) return current.clamp(minKeepDays, maxKeepDays);
  final legacy = int.tryParse(raw[legacyKeepDaysKey] ?? '');
  if (legacy == null || legacy == _legacyDefaultDays) return defaultKeepDays;
  return legacy.clamp(minKeepDays, maxKeepDays);
}

const keepDaysKey = 'keepDays';
const legacyKeepDaysKey = 'textRetentionDays';
