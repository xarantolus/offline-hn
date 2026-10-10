import 'package:offline_hn/data/model/local_day.dart';

typedef UtcOffsetAt = Duration Function(DateTime utc);

Duration deviceOffsetAt(DateTime utc) => utc.toLocal().timeZoneOffset;

LocalDay localDayOf(DateTime instant, {UtcOffsetAt offsetAt = deviceOffsetAt}) {
  final utc = instant.toUtc();
  final wall = utc.add(offsetAt(utc));
  return LocalDay(wall.year, wall.month, wall.day);
}

DayBounds dayBoundsUtc(LocalDay day, {UtcOffsetAt offsetAt = deviceOffsetAt}) =>
    DayBounds(
      _localMidnightUtc(day, offsetAt),
      _localMidnightUtc(day.next(), offsetAt),
    );

/// Distinct local days of [instants], newest first.
List<LocalDay> daysWithData(
  Iterable<DateTime> instants, {
  UtcOffsetAt offsetAt = deviceOffsetAt,
}) {
  final days = {for (final t in instants) localDayOf(t, offsetAt: offsetAt)};
  return days.toList()..sort((a, b) => b.compareTo(a));
}

/// The offset at the answer can differ from the offset at the guess when a
/// transition falls between them, so the guess is refined once.
DateTime _localMidnightUtc(LocalDay day, UtcOffsetAt offsetAt) {
  final wall = day.asUtcMidnight;
  final guess = wall.subtract(offsetAt(wall));
  return wall.subtract(offsetAt(guess));
}
