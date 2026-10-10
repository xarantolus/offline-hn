import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';

final _now = DateTime.utc(2026, 10, 10, 12);

List<RankedStory> _ranked(int count, {int from = 1}) => [
  for (var i = 0; i < count; i++)
    RankedStory(from + i, 'https://example.com/${from + i}'),
];

void main() {
  test('depth is 60 for Top and Best and 30 for Ask and Show', () {
    final chosen = selectCaptureTargets(
      rankings: {
        FeedKind.top: _ranked(100, from: 1000),
        FeedKind.best: _ranked(100, from: 2000),
        FeedKind.ask: _ranked(100, from: 3000),
        FeedKind.show: _ranked(100, from: 4000),
      },
      existing: const {},
      now: _now,
    );
    int inRange(int lo) =>
        chosen.where((id) => id >= lo && id < lo + 1000).length;
    expect(inRange(1000), 60);
    expect(inRange(2000), 60);
    expect(inRange(3000), 30);
    expect(inRange(4000), 30);
  });

  test('a story on two feeds is chosen once', () {
    final shared = [const RankedStory(1, 'https://a.example')];
    final chosen = selectCaptureTargets(
      rankings: {FeedKind.top: shared, FeedKind.best: shared},
      existing: const {},
      now: _now,
    );
    expect(chosen, [1]);
  });

  test('front pages of every feed come before the tail of any one', () {
    final chosen = selectCaptureTargets(
      rankings: {
        FeedKind.top: _ranked(3, from: 10),
        FeedKind.ask: _ranked(3, from: 20),
      },
      existing: const {},
      now: _now,
    );
    expect(chosen, [10, 20, 11, 21, 12, 22]);
  });

  test('stored and too-large pages are skipped', () {
    final chosen = selectCaptureTargets(
      rankings: {FeedKind.top: _ranked(3)},
      existing: {
        1: ExistingPage(PageStatus.ok, _now),
        2: ExistingPage(PageStatus.tooLarge, _now),
      },
      now: _now,
    );
    expect(chosen, [3]);
  });

  test('a failed capture waits before being retried', () {
    ExistingPage failed(Duration ago) =>
        ExistingPage(PageStatus.failed, _now.subtract(ago));
    final recent = selectCaptureTargets(
      rankings: {FeedKind.top: _ranked(1)},
      existing: {1: failed(const Duration(hours: 1))},
      now: _now,
    );
    final old = selectCaptureTargets(
      rankings: {FeedKind.top: _ranked(1)},
      existing: {1: failed(const Duration(hours: 7))},
      now: _now,
    );
    expect(recent, isEmpty);
    expect(old, [1]);
  });

  test('stories without a link have no page to capture', () {
    final chosen = selectCaptureTargets(
      rankings: {
        FeedKind.ask: [
          const RankedStory(1, null),
          const RankedStory(2, 'https://x.example'),
        ],
      },
      existing: const {},
      now: _now,
    );
    expect(chosen, [2]);
  });

  test('the size limit is 25 MB, inclusive of exactly 25', () {
    expect(exceedsPageLimit(25 * 1024 * 1024), isFalse);
    expect(exceedsPageLimit(25 * 1024 * 1024 + 1), isTrue);
  });
}
