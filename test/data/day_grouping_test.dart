import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';

Duration _usEastern2026(DateTime utc) {
  final springForward = DateTime.utc(2026, 3, 8, 7);
  final fallBack = DateTime.utc(2026, 11, 1, 6);
  final summer = !utc.isBefore(springForward) && utc.isBefore(fallBack);
  return Duration(hours: summer ? -4 : -5);
}

Duration _tokyo(DateTime utc) => const Duration(hours: 9);

void main() {
  test('an evening in New York belongs to that day, not the UTC day', () {
    final instant = DateTime.utc(2026, 1, 15, 2, 30);
    expect(
      localDayOf(instant, offsetAt: _usEastern2026),
      const LocalDay(2026, 1, 14),
    );
  });

  test('the same instants group differently after a timezone change', () {
    final instants = [
      DateTime.utc(2026, 5, 1, 12),
      DateTime.utc(2026, 5, 1, 16),
    ];
    expect(daysWithData(instants, offsetAt: _usEastern2026), [
      const LocalDay(2026, 5, 1),
    ]);
    expect(daysWithData(instants, offsetAt: _tokyo), [
      const LocalDay(2026, 5, 2),
      const LocalDay(2026, 5, 1),
    ]);
  });

  test('days come out newest first and without repeats', () {
    final days = daysWithData([
      DateTime.utc(2026, 6, 1, 12),
      DateTime.utc(2026, 6, 3, 12),
      DateTime.utc(2026, 6, 3, 13),
      DateTime.utc(2026, 6, 2, 12),
    ], offsetAt: _tokyo);
    expect(days, [
      const LocalDay(2026, 6, 3),
      const LocalDay(2026, 6, 2),
      const LocalDay(2026, 6, 1),
    ]);
  });

  group('day bounds across DST', () {
    test('the spring-forward day is 23 hours long', () {
      final bounds = dayBoundsUtc(
        const LocalDay(2026, 3, 8),
        offsetAt: _usEastern2026,
      );
      expect(bounds.startUtc, DateTime.utc(2026, 3, 8, 5));
      expect(
        bounds.endUtc.difference(bounds.startUtc),
        const Duration(hours: 23),
      );
    });

    test('the fall-back day is 25 hours long', () {
      final bounds = dayBoundsUtc(
        const LocalDay(2026, 11, 1),
        offsetAt: _usEastern2026,
      );
      expect(bounds.startUtc, DateTime.utc(2026, 11, 1, 4));
      expect(
        bounds.endUtc.difference(bounds.startUtc),
        const Duration(hours: 25),
      );
    });

    test('consecutive days tile without gaps or overlap', () {
      var day = const LocalDay(2026, 3, 6);
      var previousEnd = dayBoundsUtc(day, offsetAt: _usEastern2026).startUtc;
      for (var i = 0; i < 6; i++) {
        final bounds = dayBoundsUtc(day, offsetAt: _usEastern2026);
        expect(bounds.startUtc, previousEnd);
        previousEnd = bounds.endUtc;
        day = day.next();
      }
    });

    test('every instant lands in the bounds of its own day', () {
      var instant = DateTime.utc(2026, 3, 7, 12);
      final end = DateTime.utc(2026, 3, 10);
      while (instant.isBefore(end)) {
        final day = localDayOf(instant, offsetAt: _usEastern2026);
        final bounds = dayBoundsUtc(day, offsetAt: _usEastern2026);
        expect(bounds.contains(instant), isTrue, reason: '$instant on $day');
        instant = instant.add(const Duration(minutes: 30));
      }
    });
  });

  test('LocalDay.next rolls over month and year ends', () {
    expect(const LocalDay(2026, 2, 28).next(), const LocalDay(2026, 3, 1));
    expect(const LocalDay(2026, 12, 31).next(), const LocalDay(2027, 1, 1));
  });
}
