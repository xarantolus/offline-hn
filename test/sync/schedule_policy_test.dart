import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/daily_time.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/sync/scheduler.dart';

import 'fakes.dart';

/// Central Europe: UTC+1, UTC+2 between the last Sundays of March and
/// October, switching at 01:00 UTC.
Duration berlin(DateTime utc) {
  DateTime lastSunday(int month) {
    var day = DateTime.utc(utc.year, month + 1, 0);
    while (day.weekday != DateTime.sunday) {
      day = day.subtract(const Duration(days: 1));
    }
    return DateTime.utc(day.year, day.month, day.day, 1);
  }

  final summer = !utc.isBefore(lastSunday(3)) && utc.isBefore(lastSunday(10));
  return Duration(hours: summer ? 2 : 1);
}

Duration newYork(DateTime utc) => const Duration(hours: -5);

void main() {
  const five = DailyTime(5, 0);

  group('next daily run', () {
    test('later today when the time has not come yet', () {
      final next = nextDailyRun(
        five,
        DateTime.utc(2026, 10, 10, 3),
        offsetAt: (utc) => Duration.zero,
      );
      expect(next, DateTime.utc(2026, 10, 10, 5));
    });

    test('tomorrow once it has passed, and at exactly the time', () {
      expect(
        nextDailyRun(
          five,
          DateTime.utc(2026, 10, 10, 6),
          offsetAt: (utc) => Duration.zero,
        ),
        DateTime.utc(2026, 10, 11, 5),
      );
      expect(
        nextDailyRun(
          five,
          DateTime.utc(2026, 10, 10, 5),
          offsetAt: (utc) => Duration.zero,
        ),
        DateTime.utc(2026, 10, 11, 5),
      );
    });

    test('is read in the phone timezone', () {
      final now = DateTime.utc(2026, 1, 15, 12);
      expect(
        nextDailyRun(five, now, offsetAt: berlin),
        DateTime.utc(2026, 1, 16, 4),
      );
      expect(
        nextDailyRun(five, now, offsetAt: (u) => const Duration(hours: -8)),
        DateTime.utc(2026, 1, 15, 13),
      );
    });

    test('the night the clocks go forward lands an hour earlier in UTC', () {
      final friday = DateTime.utc(2026, 3, 27, 12);
      final saturday = DateTime.utc(2026, 3, 28, 12);
      expect(
        nextDailyRun(five, friday, offsetAt: berlin),
        DateTime.utc(2026, 3, 28, 4),
      );
      expect(
        nextDailyRun(five, saturday, offsetAt: berlin),
        DateTime.utc(2026, 3, 29, 3),
      );
    });

    test('the night the clocks go back lands an hour later in UTC', () {
      final friday = DateTime.utc(2026, 10, 23, 12);
      final saturday = DateTime.utc(2026, 10, 24, 12);
      expect(
        nextDailyRun(five, friday, offsetAt: berlin),
        DateTime.utc(2026, 10, 24, 3),
      );
      expect(
        nextDailyRun(five, saturday, offsetAt: berlin),
        DateTime.utc(2026, 10, 25, 4),
      );
    });

    test('a time that does not exist runs when the hour has passed', () {
      final next = nextDailyRun(
        const DailyTime(2, 30),
        DateTime.utc(2026, 3, 28, 12),
        offsetAt: berlin,
      );
      expect(next, DateTime.utc(2026, 3, 29, 1, 30));
      expect(next.add(berlin(next)).hour, 3);
    });

    test('a time that happens twice runs once, on a day that exists', () {
      final next = nextDailyRun(
        const DailyTime(2, 30),
        DateTime.utc(2026, 10, 24, 12),
        offsetAt: berlin,
      );
      expect(next.add(berlin(next)).hour, 2);
      expect(next.add(berlin(next)).minute, 30);
    });

    test('changing timezone moves the next run', () {
      final now = DateTime.utc(2026, 10, 10, 12);
      final home = nextDailyRun(five, now, offsetAt: berlin);
      final away = nextDailyRun(five, now, offsetAt: newYork);
      expect(home, DateTime.utc(2026, 10, 11, 3));
      expect(away, DateTime.utc(2026, 10, 11, 10));
    });
  });

  group('work requirements', () {
    final defaults = AppSettings.defaults();
    final anyNetwork = AppSettings.fromRaw({Settings.wifiOnly.key: 'false'});
    final unplugged = AppSettings.fromRaw({Settings.chargingOnly.key: 'false'});
    const automatic = [
      SyncTrigger.scheduled,
      SyncTrigger.periodic,
      SyncTrigger.catchUp,
    ];

    test('automatic runs follow the Wi-Fi setting', () {
      for (final trigger in automatic) {
        expect(
          requirementsFor(trigger, defaults).network,
          NetworkRequirement.unmetered,
        );
        expect(
          requirementsFor(trigger, anyNetwork).network,
          NetworkRequirement.connected,
        );
      }
    });

    test('automatic runs wait for a charger unless the setting is off', () {
      for (final trigger in automatic) {
        expect(requirementsFor(trigger, defaults).charging, isTrue);
        expect(requirementsFor(trigger, unplugged).charging, isFalse);
      }
    });

    test('a run the user asked for needs neither Wi-Fi nor a charger', () {
      for (final trigger in [SyncTrigger.manual, SyncTrigger.refresh]) {
        expect(
          requirementsFor(trigger, defaults),
          const WorkRequirements(
            network: NetworkRequirement.connected,
            charging: false,
          ),
        );
      }
    });

    test('the first update ever does not wait for a charger', () {
      expect(
        requirementsFor(SyncTrigger.catchUp, defaults, firstUpdate: true),
        const WorkRequirements(
          network: NetworkRequirement.unmetered,
          charging: false,
        ),
      );
    });
  });

  group('scheduler', () {
    final now = DateTime.utc(2026, 10, 10, 12);

    test('schedules the daily run with the delay to the next time', () async {
      final queue = FakeQueue();
      await Scheduler(
        queue,
        clock: () => now,
        offsetAt: berlin,
      ).apply(AppSettings.defaults());
      expect(queue.daily.single.$1, const Duration(hours: 15));
      expect(queue.daily.single.$2.network, NetworkRequirement.unmetered);
    });

    test('the interval setting sets or cancels the periodic run', () async {
      final queue = FakeQueue();
      final scheduler = Scheduler(queue, clock: () => now, offsetAt: berlin);
      await scheduler.apply(
        AppSettings.fromRaw({Settings.intervalHours.key: '6'}),
      );
      expect(queue.periodic.single.$1, const Duration(hours: 6));

      await scheduler.apply(
        AppSettings.fromRaw({Settings.intervalHours.key: 'off'}),
      );
      expect(queue.periodicCancelled, 1);
      expect(queue.periodic, hasLength(1));
    });

    test('the charging setting reaches both triggers', () async {
      final queue = FakeQueue();
      final scheduler = Scheduler(queue, clock: () => now, offsetAt: berlin);
      await scheduler.apply(AppSettings.defaults());
      await scheduler.apply(
        AppSettings.fromRaw({Settings.chargingOnly.key: 'false'}),
      );
      expect(queue.daily.map((d) => d.$2.charging), [true, false]);
      expect(queue.periodic.map((p) => p.$2.charging), [true, false]);
    });

    test('the Wi-Fi setting reaches both triggers', () async {
      final queue = FakeQueue();
      await Scheduler(
        queue,
        clock: () => now,
        offsetAt: berlin,
      ).apply(AppSettings.fromRaw({Settings.wifiOnly.key: 'false'}));
      expect(queue.daily.single.$2.network, NetworkRequirement.connected);
      expect(queue.periodic.single.$2.network, NetworkRequirement.connected);
    });

    test(
      'a daily run woken just early schedules tomorrow, not seconds ahead',
      () async {
        final queue = FakeQueue();
        final early = DateTime.utc(2026, 10, 11, 4, 59, 59);
        await Scheduler(
          queue,
          clock: () => early,
          offsetAt: (u) => Duration.zero,
        ).scheduleDaily(AppSettings.defaults(), afterRun: true);
        expect(queue.daily.single.$1, const Duration(hours: 24, seconds: 1));
      },
    );

    test('a different daily time changes the delay', () async {
      final queue = FakeQueue();
      await Scheduler(
        queue,
        clock: () => now,
        offsetAt: berlin,
      ).apply(AppSettings.fromRaw({Settings.dailyTime.key: '23:30'}));
      expect(queue.daily.single.$1, const Duration(hours: 9, minutes: 30));
    });
  });
}
