import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/filter_list_status.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/store_overview.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/overview_text.dart';

StoreOverview store({
  int stories = 0,
  DateTime? oldest,
  DateTime? newest,
  Map<FeedKind, int> perFeed = const {},
}) => StoreOverview(
  stories: stories,
  oldestStory: oldest,
  newestStory: newest,
  perFeed: perFeed,
  threads: 0,
  comments: 0,
  articles: 0,
  articleBytes: 0,
  linkedPages: 0,
  linkedBytes: 0,
  linkedThreads: 0,
  bookmarked: 0,
);

AppSettings settings(Map<String, String> raw) => AppSettings.fromRaw(raw);

void main() {
  String day(DateTime d) => 'D${d.day}';

  group('storiesLine', () {
    test('names the days covered, once when they are the same', () {
      expect(
        storiesLine(
          store(
            stories: 1234,
            oldest: DateTime(2026, 10, 9, 8),
            newest: DateTime(2026, 10, 12, 8),
          ),
          day,
        ),
        '1,234 stories · D9 to D12',
      );
      expect(
        storiesLine(
          store(
            stories: 1,
            oldest: DateTime(2026, 10, 9, 8),
            newest: DateTime(2026, 10, 9, 20),
          ),
          day,
        ),
        '1 story · D9',
      );
    });

    test('an empty store has no days', () {
      expect(storiesLine(store(), day), '0 stories');
    });
  });

  test('feedsLine leaves out feeds with nothing stored', () {
    expect(
      feedsLine({FeedKind.top: 1500, FeedKind.ask: 0, FeedKind.show: 20}),
      'Top 1,500 · Show 20',
    );
  });

  group('connectionNote', () {
    final strict = settings({});
    final open = settings({'wifiOnly': 'false', 'pagesOnMobile': 'true'});

    test('says what an automatic update may fetch', () {
      expect(
        connectionNote(ConnectionKind.wifi, strict),
        'Wi-Fi · stories, comments and saved pages',
      );
      expect(
        connectionNote(ConnectionKind.mobile, strict),
        'Mobile data · automatic updates wait for Wi-Fi',
      );
      expect(
        connectionNote(ConnectionKind.mobile, settings({'wifiOnly': 'false'})),
        'Mobile data · stories and comments, saved pages wait for Wi-Fi',
      );
      expect(
        connectionNote(ConnectionKind.mobile, open),
        'Mobile data · stories, comments and saved pages',
      );
      expect(
        connectionNote(ConnectionKind.none, open),
        'Offline · nothing can be fetched',
      );
    });
  });

  group('filterListSummary', () {
    test('counts lists with a good copy and finds the newest', () {
      final summary = filterListSummary(
        ['a', 'b', 'c'],
        {
          'a': FilterListStatus(updatedAt: DateTime.utc(2026, 10, 9)),
          'b': FilterListStatus(updatedAt: DateTime.utc(2026, 10, 11)),
          'c': const FilterListStatus(error: 'down'),
          'gone': FilterListStatus(updatedAt: DateTime.utc(2026, 10, 12)),
        },
      );
      expect(summary.ready, 2);
      expect(summary.total, 3);
      expect(summary.newest, DateTime.utc(2026, 10, 11));
      expect(
        filterListsLine(summary, (_) => 'Today'),
        '2 of 3 lists ready · refreshed Today',
      );
    });
  });

  group('nextUpdateText', () {
    String when(DateTime d) => '${d.toUtc().hour}:${d.toUtc().minute}';
    Duration utc(DateTime _) => Duration.zero;

    test('names the daily time and the interval when there is one', () {
      final now = DateTime.utc(2026, 10, 10, 6);
      expect(
        nextUpdateText(
          settings: settings({'intervalHours': '4'}),
          now: now,
          when: when,
          offsetAt: utc,
        ),
        '5:0 · and every 4 h',
      );
      expect(
        nextUpdateText(
          settings: settings({'intervalHours': 'off'}),
          now: now,
          when: when,
          offsetAt: utc,
        ),
        '5:0',
      );
    });
  });
}
