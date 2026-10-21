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
    this.commentCount,
  });

  final int storyId;
  final bool saved;
  final DateTime? commentsFetchedAt;
  final DateTime? lastOpenedAt;
  final DateTime? storyTime;
  final int? commentCount;
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

/// Threads the user opened since [keepFrom] come first, newest first, then saved ones, then
/// the feeds in rank order. Stored threads that are on no feed and were
/// neither opened nor saved are not refreshed.
List<int> selectCommentTargets({
  required List<int> feedOrder,
  required List<ThreadCandidate> stored,
  required DateTime now,
  required DateTime keepFrom,
}) {
  final known = {for (final t in stored) t.storyId: t};
  final opened =
      stored.where((t) => t.lastOpenedAt?.isBefore(keepFrom) == false).toList()
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

/// What the light refresh fetches comments for: threads never fetched, and
/// threads whose comment count differs from what was stored before the
/// listing was refreshed. Feed order, minus anything fetched a moment ago.
List<int> selectChangedThreads({
  required List<int> feedOrder,
  required List<ThreadCandidate> before,
  required List<ThreadCandidate> after,
  required DateTime now,
}) {
  final was = {for (final t in before) t.storyId: t};
  final is_ = {for (final t in after) t.storyId: t};
  return [
    for (final id in feedOrder.toSet())
      if (is_[id] case final now_? when !_fresh(now_, now))
        if (now_.commentsFetchedAt == null ||
            was[id] == null ||
            was[id]!.commentCount != now_.commentCount)
          id,
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
