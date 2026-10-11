import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/policy/run_policy.dart';
import 'package:offline_hn/data/policy/sync_scope.dart';

final _now = DateTime.utc(2026, 10, 10, 12);

ThreadCandidate _thread(
  int id, {
  DateTime? fetched,
  DateTime? opened,
  bool saved = false,
  DateTime? posted,
}) => ThreadCandidate(
  storyId: id,
  saved: saved,
  commentsFetchedAt: fetched,
  lastOpenedAt: opened,
  storyTime: posted,
);

void main() {
  test('feeds are merged by rank without repeats', () {
    expect(
      interleavedByRank({
        FeedKind.top: [1, 2, 3],
        FeedKind.best: [2, 4],
        FeedKind.ask: [5],
      }),
      [1, 2, 5, 4, 3],
    );
  });

  test(
    'opened threads come first, newest first, then saved, then the feeds',
    () {
      final order = selectCommentTargets(
        feedOrder: [10, 11, 12],
        stored: [
          _thread(10),
          _thread(20, opened: _now.subtract(const Duration(days: 2))),
          _thread(21, opened: _now.subtract(const Duration(hours: 3))),
          _thread(
            30,
            saved: true,
            fetched: _now.subtract(const Duration(days: 1)),
            posted: _now.subtract(const Duration(days: 4)),
          ),
        ],
        now: _now,
      );
      expect(order, [21, 20, 30, 10, 11, 12]);
    },
  );

  test('a stored thread on no feed that nobody opened is left alone', () {
    final order = selectCommentTargets(
      feedOrder: [1],
      stored: [
        _thread(1),
        _thread(2, fetched: _now.subtract(const Duration(days: 1))),
      ],
      now: _now,
    );
    expect(order, [1]);
  });

  test('a thread fetched a moment ago is not fetched again', () {
    final order = selectCommentTargets(
      feedOrder: [1, 2],
      stored: [
        _thread(1, fetched: _now.subtract(const Duration(minutes: 5))),
        _thread(2, fetched: _now.subtract(const Duration(hours: 1))),
      ],
      now: _now,
    );
    expect(order, [2]);
  });

  test('a fetch time in the future does not count as fresh', () {
    final order = selectCommentTargets(
      feedOrder: [1],
      stored: [_thread(1, fetched: _now.add(const Duration(hours: 1)))],
      now: _now,
    );
    expect(order, [1]);
  });

  group('a run that went quiet', () {
    final beat = DateTime.utc(2026, 10, 10, 5);

    test('is alive while it keeps checking in', () {
      expect(runIsAlive(beat, beat.add(const Duration(minutes: 3))), isTrue);
    });

    test(
      'is dead once the process has been silent for longer than any item',
      () {
        expect(runIsAlive(beat, beat.add(const Duration(minutes: 5))), isFalse);
      },
    );

    test('is believed when the clock was set back', () {
      expect(runIsAlive(beat, beat.subtract(const Duration(hours: 1))), isTrue);
    });
  });

  group('saved threads', () {
    List<int> targets(List<ThreadCandidate> stored) =>
        selectCommentTargets(feedOrder: const [], stored: stored, now: _now);
    final old = _now.subtract(const Duration(days: 400));
    final fetched = _now.subtract(const Duration(hours: 5));

    test('a young bookmarked story is refreshed', () {
      expect(
        targets([
          _thread(
            1,
            saved: true,
            fetched: fetched,
            posted: _now.subtract(const Duration(days: 3)),
          ),
        ]),
        [1],
      );
    });

    test('a bookmark on an old story nobody opened lately is left alone', () {
      expect(
        targets([_thread(1, saved: true, fetched: fetched, posted: old)]),
        isEmpty,
      );
    });

    test('an old bookmarked story opened lately is still refreshed', () {
      expect(
        targets([
          _thread(
            1,
            saved: true,
            fetched: fetched,
            posted: old,
            opened: _now.subtract(const Duration(days: 2)),
          ),
        ]),
        [1],
      );
    });
  });
}
