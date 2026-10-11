import 'package:offline_hn/data/model/feed_kind.dart';

/// How far down each feed a run goes. A feed's list has 500 ids; a thread
/// each for four of them would be most of a gigabyte a day.
const feedDepth = 100;

/// A thread fetched more recently than this is left alone, so a two-hour
/// schedule does not download every thread twelve times a day.
const commentsFreshFor = Duration(minutes: 30);

/// A bookmarked thread is only kept current while its story is this young or
/// it was opened this recently; older ones have stopped moving.
const savedRefreshWindow = Duration(days: 14);

class ThreadCandidate {
  const ThreadCandidate({
    required this.storyId,
    required this.saved,
    this.commentsFetchedAt,
    this.lastOpenedAt,
    this.storyTime,
  });

  final int storyId;
  final bool saved;
  final DateTime? commentsFetchedAt;
  final DateTime? lastOpenedAt;
  final DateTime? storyTime;
}

/// One id list with the feeds merged by rank, so every feed's front page comes
/// before the tail of any one.
List<int> interleavedByRank(Map<FeedKind, List<int>> rankings) {
  final chosen = <int>{};
  final deepest = rankings.values.fold(
    0,
    (m, l) => l.length > m ? l.length : m,
  );
  for (var rank = 0; rank < deepest; rank++) {
    for (final kind in FeedKind.values) {
      final list = rankings[kind];
      if (list != null && rank < list.length) chosen.add(list[rank]);
    }
  }
  return chosen.toList();
}

/// Threads the user opened come first, newest first, then saved ones, then
/// the feeds in rank order. Stored threads that are on no feed and were
/// neither opened nor saved are not refreshed.
List<int> selectCommentTargets({
  required List<int> feedOrder,
  required List<ThreadCandidate> stored,
  required DateTime now,
}) {
  final known = {for (final t in stored) t.storyId: t};
  final opened = stored.where((t) => t.lastOpenedAt != null).toList()
    ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
  final saved = stored.where(
    (t) => t.saved && t.commentsFetchedAt != null && _stillMoving(t, now),
  );

  final ordered = <int>{
    for (final t in opened) t.storyId,
    for (final t in saved) t.storyId,
    ...feedOrder,
  };
  return [
    for (final id in ordered)
      if (!_fresh(known[id], now)) id,
  ];
}

bool _stillMoving(ThreadCandidate thread, DateTime now) {
  bool recent(DateTime? at) =>
      at != null && now.difference(at) < savedRefreshWindow;
  return recent(thread.storyTime) || recent(thread.lastOpenedAt);
}

bool _fresh(ThreadCandidate? thread, DateTime now) {
  final fetched = thread?.commentsFetchedAt;
  if (fetched == null) return false;
  final age = now.difference(fetched);
  return !age.isNegative && age < commentsFreshFor;
}
