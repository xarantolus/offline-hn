import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/prune_policy.dart';

final _now = DateTime.utc(2026, 10, 10, 12);

PageCandidate _page(
  int id,
  int bytes, {
  int ageDays = 1,
  bool saved = false,
  Duration? openedAgo,
}) => PageCandidate(
  storyId: id,
  bytes: bytes,
  capturedAt: _now.subtract(Duration(days: ageDays)),
  saved: saved,
  lastOpenedAt: openedAgo == null ? null : _now.subtract(openedAgo),
);

TextCandidate _text(
  int id, {
  int ageDays = 10,
  bool saved = false,
  bool hasPage = false,
  bool onSnapshot = false,
  int? threadOpenedDaysAgo,
}) => TextCandidate(
  storyId: id,
  lastSeen: _now.subtract(Duration(days: ageDays)),
  saved: saved,
  hasPage: hasPage,
  onLatestSnapshot: onSnapshot,
  threadOpenedAt: threadOpenedDaysAgo == null
      ? null
      : _now.subtract(Duration(days: threadOpenedDaysAgo)),
);

LinkCandidate _link(
  int id,
  int bytes, {
  int ageDays = 1,
  bool saved = false,
  PageKind kind = PageKind.mhtml,
  Duration? openedAgo,
}) => LinkCandidate(
  id: id,
  kind: kind,
  bytes: bytes,
  capturedAt: _now.subtract(Duration(days: ageDays)),
  saved: saved,
  lastOpenedAt: openedAgo == null ? null : _now.subtract(openedAgo),
);

void main() {
  group('linked pages', () {
    List<int> prune(
      List<LinkCandidate> links, {
      int pageBytes = 0,
      int budget = 1000,
    }) => linksToPrune(
      links,
      pageBytes: pageBytes,
      budgetBytes: budget,
      textRetentionDays: 30,
      now: _now,
    );

    test('nothing goes while articles and links fit together', () {
      expect(prune([_link(1, 300)], pageBytes: 600), isEmpty);
    });

    test('oldest go first, and the articles count towards the total', () {
      expect(
        prune([
          _link(1, 300, ageDays: 1),
          _link(2, 300, ageDays: 5),
          _link(3, 300, ageDays: 3),
        ], pageBytes: 600),
        [2, 3],
      );
    });

    test('they go before any article, however old the article is', () {
      final links = [_link(1, 400)];
      final pages = [_page(1, 700, ageDays: 40)];
      final chosen = prune(links, pageBytes: 700);
      expect(chosen, [1]);
      expect(
        pagesToPrune(pages, budgetBytes: 1000, otherBytes: 0, now: _now),
        isEmpty,
      );
    });

    test('bookmarked stories keep theirs, and so does a recent open', () {
      expect(
        prune([
          _link(1, 500, ageDays: 9, saved: true),
          _link(2, 500, ageDays: 8, openedAgo: const Duration(minutes: 5)),
          _link(3, 500, ageDays: 1),
        ], budget: 1200),
        [3],
      );
    });

    test('a stored discussion goes with the text retention, not the size', () {
      expect(
        prune([
          _link(1, 0, ageDays: 31, kind: PageKind.thread),
          _link(2, 0, ageDays: 5, kind: PageKind.thread),
          _link(3, 0, ageDays: 31, kind: PageKind.thread, saved: true),
        ], budget: 1 << 30),
        [1],
      );
    });
  });

  group('pages', () {
    test('nothing goes while the total fits the budget', () {
      expect(
        pagesToPrune(
          [_page(1, 400), _page(2, 600)],
          budgetBytes: 1000,
          now: _now,
        ),
        isEmpty,
      );
    });

    test('oldest captures go first, and only as many as needed', () {
      final chosen = pagesToPrune(
        [
          _page(1, 400, ageDays: 1),
          _page(2, 400, ageDays: 5),
          _page(3, 400, ageDays: 3),
        ],
        budgetBytes: 900,
        now: _now,
      );
      expect(chosen, [2]);
    });

    test('keeps going until under budget', () {
      final chosen = pagesToPrune(
        [
          _page(1, 400, ageDays: 1),
          _page(2, 400, ageDays: 5),
          _page(3, 400, ageDays: 3),
        ],
        budgetBytes: 500,
        now: _now,
      );
      expect(chosen, [2, 3]);
    });

    test(
      'saved pages are never chosen, even when that leaves it over budget',
      () {
        final chosen = pagesToPrune(
          [_page(1, 800, ageDays: 9, saved: true), _page(2, 800, ageDays: 1)],
          budgetBytes: 100,
          now: _now,
        );
        expect(chosen, [2]);
      },
    );

    test(
      'a page opened within the hour is spared, one just outside is not',
      () {
        final chosen = pagesToPrune(
          [
            _page(1, 500, ageDays: 9, openedAgo: const Duration(minutes: 59)),
            _page(2, 500, ageDays: 8, openedAgo: const Duration(minutes: 61)),
          ],
          budgetBytes: 400,
          now: _now,
        );
        expect(chosen, [2]);
      },
    );

    test('exempt pages still count towards the total', () {
      final chosen = pagesToPrune(
        [_page(1, 900, saved: true), _page(2, 200, ageDays: 2)],
        budgetBytes: 1000,
        now: _now,
      );
      expect(chosen, [2]);
    });
  });

  group('text', () {
    List<int> prune(List<TextCandidate> c, {int days = 3}) =>
        storiesToPrune(c, retentionDays: days, now: _now);

    test('old and unprotected goes, recent stays', () {
      expect(prune([_text(1, ageDays: 10), _text(2, ageDays: 2)]), [1]);
    });

    test('retention is the setting, not a constant', () {
      expect(prune([_text(1, ageDays: 5)], days: 7), isEmpty);
      expect(prune([_text(1, ageDays: 5)], days: 3), [1]);
    });

    test(
      'saved, paged, on a latest snapshot, or recently read are each enough',
      () {
        expect(prune([_text(1, saved: true)]), isEmpty);
        expect(prune([_text(2, hasPage: true)]), isEmpty);
        expect(prune([_text(3, onSnapshot: true)]), isEmpty);
        expect(prune([_text(4, threadOpenedDaysAgo: 1)]), isEmpty);
      },
    );

    test('a thread opened long ago does not protect', () {
      expect(prune([_text(1, threadOpenedDaysAgo: 20)]), [1]);
    });
  });

  group('thread state', () {
    test('kept for 30 days from last open, saved ones kept regardless', () {
      final chosen = threadStatesToPrune([
        ThreadStateCandidate(
          storyId: 1,
          lastOpenedAt: _now.subtract(const Duration(days: 29)),
          saved: false,
        ),
        ThreadStateCandidate(
          storyId: 2,
          lastOpenedAt: _now.subtract(const Duration(days: 31)),
          saved: false,
        ),
        ThreadStateCandidate(
          storyId: 3,
          lastOpenedAt: _now.subtract(const Duration(days: 90)),
          saved: true,
        ),
      ], now: _now);
      expect(chosen, [2]);
    });
  });

  group('snapshots', () {
    SnapshotFetch fetch(int id, FeedKind kind, int ageDays) => SnapshotFetch(
      fetchId: id,
      feedKind: kind,
      fetchedAt: _now.subtract(Duration(days: ageDays)),
    );

    test('old fetches go but each feed keeps its newest', () {
      final chosen = snapshotFetchesToPrune(
        [
          fetch(1, FeedKind.top, 9),
          fetch(2, FeedKind.top, 8),
          fetch(3, FeedKind.top, 1),
          fetch(4, FeedKind.ask, 20),
        ],
        retentionDays: 3,
        now: _now,
      );
      expect(chosen, [1, 2]);
    });
  });
}
