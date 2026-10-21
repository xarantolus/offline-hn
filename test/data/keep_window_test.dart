import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/keep_window.dart';

Duration _tokyo(DateTime utc) => const Duration(hours: 9);
Duration _utc(DateTime utc) => Duration.zero;

void main() {
  group('window start', () {
    final now = DateTime.utc(2026, 10, 20, 15, 30);

    test('the default is local midnight yesterday', () {
      expect(
        keepWindowStart(now, 2, offsetAt: _utc),
        DateTime.utc(2026, 10, 19),
      );
    });

    test('one day is local midnight today', () {
      expect(
        keepWindowStart(now, 1, offsetAt: _utc),
        DateTime.utc(2026, 10, 20),
      );
    });

    test('days are the viewer\'s own, not UTC', () {
      expect(
        keepWindowStart(now, 2, offsetAt: _tokyo),
        DateTime.utc(2026, 10, 19, 15),
      );
    });

    test('the window crosses a month end', () {
      expect(
        keepWindowStart(DateTime.utc(2026, 11, 1, 8), 3, offsetAt: _utc),
        DateTime.utc(2026, 10, 30),
      );
    });
  });

  group('days offered', () {
    const today = LocalDay(2026, 10, 20);
    const days = [
      LocalDay(2026, 10, 20),
      LocalDay(2026, 10, 19),
      LocalDay(2026, 10, 18),
      LocalDay(2026, 10, 16),
    ];

    test('only days inside the window', () {
      expect(daysInWindow(days, today, 2), days.take(2));
      expect(daysInWindow(days, today, 4), days.take(3));
      expect(daysInWindow(days, today, 7), days);
    });

    test('a phone offline past the window still has its newest day', () {
      expect(daysInWindow(const [LocalDay(2026, 10, 14)], today, 2), [
        const LocalDay(2026, 10, 14),
      ]);
    });

    test('nothing stored offers nothing', () {
      expect(daysInWindow(const [], today, 2), isEmpty);
    });
  });

  group('the setting', () {
    int read(Map<String, String> raw) => AppSettings.fromRaw(raw).keepDays;

    test('defaults to today and yesterday', () {
      expect(read({}), 2);
    });

    test('an install on the old default of three moves to two', () {
      expect(read({'textRetentionDays': '3'}), 2);
    });

    test('an old value the user changed is kept', () {
      expect(read({'textRetentionDays': '5'}), 5);
      expect(read({'textRetentionDays': '1'}), 1);
    });

    test('an old value outside the range is brought into it', () {
      expect(read({'textRetentionDays': '30'}), 7);
    });

    test('the new setting wins, even when it is three', () {
      expect(read({'keepDays': '3', 'textRetentionDays': '5'}), 3);
    });

    test('a value written by hand is limited to what the menu offers', () {
      expect(read({'keepDays': '0'}), 1);
      expect(read({'keepDays': '99'}), 7);
    });
  });
}
