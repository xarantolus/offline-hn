import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/sync_enums.dart';

/// Which staged rankings may become visible. [rankings] are the story ids per
/// feed and [threads] how this run's comment fetches stand, by story.
///
/// A feed is ready once every one of its threads has been attempted, failed
/// ones included, so one thread that never loads cannot hold a feed back. The
/// exception is a ranking where every attempt failed: that is an outage, not
/// stories without comments, and the feed keeps showing what it had.
Set<FeedKind> feedsReadyToPublish({
  required Map<FeedKind, List<int>> rankings,
  required Map<int, SyncItemStatus> threads,
}) {
  final ready = <FeedKind>{};
  for (final entry in rankings.entries) {
    final statuses = [for (final id in entry.value) ?threads[id]];
    if (statuses.contains(SyncItemStatus.pending)) continue;
    if (statuses.isNotEmpty &&
        statuses.every((status) => status == SyncItemStatus.failed)) {
      continue;
    }
    ready.add(entry.key);
  }
  return ready;
}
