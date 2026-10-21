import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';

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
  int otherBytes = 0,
}) {
  var total = otherBytes + pages.fold(0, (sum, page) => sum + page.bytes);
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

class LinkCandidate {
  const LinkCandidate({
    required this.id,
    required this.kind,
    required this.bytes,
    required this.capturedAt,
    required this.saved,
    this.lastOpenedAt,
  });

  final int id;
  final PageKind kind;
  final int bytes;
  final DateTime capturedAt;

  /// Linked from a bookmarked story.
  final bool saved;
  final DateTime? lastOpenedAt;
}

/// Linked pages go before any article copy, whatever the budget says about
/// the rest. Oldest first until the pages and links together fit; copies of
/// bookmarked stories' links and ones opened within the last hour are never
/// chosen. A linked discussion lives in the text store, so it goes with the
/// keep window rather than with the size.
List<int> linksToPrune(
  List<LinkCandidate> links, {
  required int pageBytes,
  required int budgetBytes,
  required DateTime keepFrom,
  required DateTime now,
}) {
  bool kept(LinkCandidate link) =>
      link.saved || _recently(link.lastOpenedAt, now);
  final chosen = [
    for (final link in links)
      if (link.kind == PageKind.thread &&
          !link.saved &&
          link.capturedAt.isBefore(keepFrom))
        link.id,
  ];
  var total =
      pageBytes +
      links
          .where((link) => !chosen.contains(link.id))
          .fold(0, (sum, link) => sum + link.bytes);
  final evictable =
      links.where((link) => !chosen.contains(link.id) && !kept(link)).toList()
        ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  for (final link in evictable) {
    if (total <= budgetBytes) break;
    chosen.add(link.id);
    total -= link.bytes;
  }
  return chosen;
}

bool _recently(DateTime? opened, DateTime now) =>
    opened != null && now.difference(opened) < recentlyOpenedGrace;

bool _openedRecently(PageCandidate page, DateTime now) =>
    _recently(page.lastOpenedAt, now);

class TextCandidate {
  const TextCandidate({
    required this.storyId,
    required this.lastSeen,
    required this.saved,
    this.pageOpenedAt,
    required this.onLatestSnapshot,
    this.threadOpenedAt,
  });

  final int storyId;
  final DateTime lastSeen;
  final bool saved;
  final DateTime? pageOpenedAt;
  final bool onLatestSnapshot;
  final DateTime? threadOpenedAt;
}

/// Stories last seen before the window start go, with their comments and
/// saved copies, unless bookmarked, still on a feed's newest ranking or opened
/// since the window start.
List<int> storiesToPrune(
  List<TextCandidate> stories, {
  required DateTime keepFrom,
}) {
  return [
    for (final story in stories)
      if (!story.saved &&
          !story.onLatestSnapshot &&
          !_within(story.lastSeen, keepFrom) &&
          !_within(story.threadOpenedAt, keepFrom) &&
          !_within(story.pageOpenedAt, keepFrom))
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
  required DateTime keepFrom,
}) {
  final keep = {for (final f in newestFetchPerFeed(fetches).values) f.fetchId};
  return [
    for (final fetch in fetches)
      if (!keep.contains(fetch.fetchId) && fetch.fetchedAt.isBefore(keepFrom))
        fetch.fetchId,
  ];
}
