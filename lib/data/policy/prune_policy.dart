import 'package:offline_hn/data/model/feed_kind.dart';

const recentlyOpenedGrace = Duration(hours: 1);
const threadStateKeep = Duration(days: 30);

class PageCandidate {
  const PageCandidate({
    required this.storyId,
    required this.bytes,
    required this.capturedAt,
    required this.saved,
    this.lastOpenedAt,
  });

  final int storyId;
  final int bytes;
  final DateTime capturedAt;
  final bool saved;
  final DateTime? lastOpenedAt;
}

/// Oldest captures go first until the total fits. Saved pages and pages
/// opened within the last hour still count towards the total but are never
/// chosen.
List<int> pagesToPrune(
  List<PageCandidate> pages, {
  required int budgetBytes,
  required DateTime now,
}) {
  var total = pages.fold(0, (sum, page) => sum + page.bytes);
  if (total <= budgetBytes) return const [];

  final evictable =
      pages.where((page) => !page.saved && !_openedRecently(page, now)).toList()
        ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

  final chosen = <int>[];
  for (final page in evictable) {
    if (total <= budgetBytes) break;
    chosen.add(page.storyId);
    total -= page.bytes;
  }
  return chosen;
}

bool _openedRecently(PageCandidate page, DateTime now) {
  final opened = page.lastOpenedAt;
  return opened != null && now.difference(opened) < recentlyOpenedGrace;
}

class TextCandidate {
  const TextCandidate({
    required this.storyId,
    required this.lastSeen,
    required this.saved,
    required this.hasPage,
    required this.onLatestSnapshot,
    this.threadOpenedAt,
  });

  final int storyId;
  final DateTime lastSeen;
  final bool saved;
  final bool hasPage;
  final bool onLatestSnapshot;
  final DateTime? threadOpenedAt;
}

List<int> storiesToPrune(
  List<TextCandidate> stories, {
  required int retentionDays,
  required DateTime now,
}) {
  final cutoff = now.subtract(Duration(days: retentionDays));
  return [
    for (final story in stories)
      if (!story.saved &&
          !story.hasPage &&
          !story.onLatestSnapshot &&
          !_within(story.lastSeen, cutoff) &&
          !_within(story.threadOpenedAt, cutoff))
        story.storyId,
  ];
}

bool _within(DateTime? instant, DateTime cutoff) =>
    instant != null && !instant.isBefore(cutoff);

class ThreadStateCandidate {
  const ThreadStateCandidate({
    required this.storyId,
    required this.lastOpenedAt,
    required this.saved,
  });

  final int storyId;
  final DateTime lastOpenedAt;
  final bool saved;
}

List<int> threadStatesToPrune(
  List<ThreadStateCandidate> states, {
  required DateTime now,
}) => [
  for (final state in states)
    if (!state.saved && now.difference(state.lastOpenedAt) > threadStateKeep)
      state.storyId,
];

class SnapshotFetch {
  const SnapshotFetch({
    required this.fetchId,
    required this.feedKind,
    required this.fetchedAt,
  });

  final int fetchId;
  final FeedKind feedKind;
  final DateTime fetchedAt;
}

Map<FeedKind, SnapshotFetch> newestFetchPerFeed(List<SnapshotFetch> fetches) {
  final newest = <FeedKind, SnapshotFetch>{};
  for (final fetch in fetches) {
    final current = newest[fetch.feedKind];
    if (current == null || fetch.fetchedAt.isAfter(current.fetchedAt)) {
      newest[fetch.feedKind] = fetch;
    }
  }
  return newest;
}

/// Each feed's newest fetch always stays, so a phone offline for a week
/// still has a front page to show.
List<int> snapshotFetchesToPrune(
  List<SnapshotFetch> fetches, {
  required int retentionDays,
  required DateTime now,
}) {
  final cutoff = now.subtract(Duration(days: retentionDays));
  final keep = {for (final f in newestFetchPerFeed(fetches).values) f.fetchId};
  return [
    for (final fetch in fetches)
      if (!keep.contains(fetch.fetchId) && fetch.fetchedAt.isBefore(cutoff))
        fetch.fetchId,
  ];
}
