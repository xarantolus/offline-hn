import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/publish_policy.dart';

void main() {
  const done = SyncItemStatus.done;
  const failed = SyncItemStatus.failed;
  const pending = SyncItemStatus.pending;

  Set<FeedKind> ready(
    Map<FeedKind, List<int>> rankings,
    Map<int, SyncItemStatus> threads,
  ) => feedsReadyToPublish(rankings: rankings, threads: threads);

  test('a feed waits while any of its threads is still pending', () {
    expect(
      ready(
        {
          FeedKind.top: [1, 2, 3],
        },
        {1: done, 2: pending, 3: done},
      ),
      isEmpty,
    );
  });

  test('each feed is judged on its own threads', () {
    expect(
      ready(
        {
          FeedKind.top: [1, 2],
          FeedKind.ask: [3],
        },
        {1: done, 2: pending, 3: done},
      ),
      {FeedKind.ask},
    );
  });

  test('a failed thread does not hold the feed back', () {
    expect(
      ready(
        {
          FeedKind.top: [1, 2, 3],
        },
        {1: done, 2: failed, 3: done},
      ),
      {FeedKind.top},
    );
  });

  test('every thread failing is an outage and keeps the old feed', () {
    expect(
      ready(
        {
          FeedKind.top: [1, 2],
        },
        {1: failed, 2: failed},
      ),
      isEmpty,
    );
  });

  test('stories with nothing to fetch count as ready', () {
    expect(
      ready({
        FeedKind.top: [1, 2],
        FeedKind.best: [],
      }, {}),
      {FeedKind.top, FeedKind.best},
    );
    expect(
      ready(
        {
          FeedKind.top: [1, 2],
        },
        {2: done},
      ),
      {FeedKind.top},
    );
  });
}
