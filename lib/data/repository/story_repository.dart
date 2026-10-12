import 'package:drift/drift.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/db/throttled_watch.dart';
import 'package:offline_hn/data/model/comment_tree.dart';
import 'package:offline_hn/data/model/domain.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/policy/story_search.dart';
import 'package:offline_hn/data/policy/sync_scope.dart';

class FeedEntry {
  const FeedEntry({required this.story, required this.bestRank, this.page});

  final StoryRow story;
  final int bestRank;
  final PageCopyRow? page;

  bool get hasCopy {
    final page = this.page;
    return page != null &&
        page.status == PageStatus.ok &&
        page.relativePath != null;
  }

  /// Whether a list would show this entry exactly like [other]. The times a
  /// sync stamps on every story it touches are not shown.
  bool showsSameAs(FeedEntry other) =>
      bestRank == other.bestRank &&
      hasCopy == other.hasCopy &&
      story.copyWith(
            lastSeen: other.story.lastSeen,
            commentsFetchedAt: Value(other.story.commentsFetchedAt),
          ) ==
          other.story;
}

bool showSameEntries(List<FeedEntry> a, List<FeedEntry> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!a[i].showsSameAs(b[i])) return false;
  }
  return true;
}

class StoryRepository {
  const StoryRepository(this._db);

  final AppDatabase _db;

  static const _listRefresh = Duration(milliseconds: 500);

  Stream<List<FeedEntry>> _watchList(
    List<TableInfo<Table, Object?>> tables,
    Future<List<FeedEntry>> Function() fetch,
  ) => throttledWatch(
    _db.tableUpdates(TableUpdateQuery.onAllTables(tables)),
    fetch,
    interval: _listRefresh,
  ).distinct(showSameEntries);

  /// Stories that appeared in [kind]'s snapshots within [day], best rank of
  /// the day first.
  Stream<List<FeedEntry>> watchFeed(FeedKind kind, DayBounds day) {
    final snapshots = _db.feedSnapshots;
    final bestRank = snapshots.rank.min();
    final query =
        _db.select(snapshots).join([
            innerJoin(_db.stories, _db.stories.id.equalsExp(snapshots.storyId)),
            leftOuterJoin(
              _db.pageCopies,
              _db.pageCopies.storyId.equalsExp(_db.stories.id),
            ),
          ])
          ..addColumns([bestRank])
          ..where(
            snapshots.feedKind.equalsValue(kind) &
                snapshots.fetchedAt.isBiggerOrEqualValue(day.startUtc) &
                snapshots.fetchedAt.isSmallerThanValue(day.endUtc) &
                _db.stories.hidden.equals(false),
          )
          ..groupBy([_db.stories.id])
          ..orderBy([
            OrderingTerm.asc(bestRank),
            OrderingTerm.asc(_db.stories.id),
          ]);

    return _watchList(
      [snapshots, _db.stories, _db.pageCopies],
      () async => [
        for (final row in await query.get())
          FeedEntry(
            story: row.readTable(_db.stories),
            bestRank: row.read(bestRank)!,
            page: row.readTableOrNull(_db.pageCopies),
          ),
      ],
    );
  }

  /// Bookmarked stories, the latest bookmark first. A bookmark made before
  /// the time was kept counts as made when the story was first seen.
  Stream<List<FeedEntry>> watchSaved() {
    final stories = _db.stories;
    final savedWhen = coalesce([stories.savedAt, stories.firstSeen]);
    final query =
        _db.select(stories).join([
            leftOuterJoin(
              _db.pageCopies,
              _db.pageCopies.storyId.equalsExp(stories.id),
            ),
          ])
          ..where(stories.saved.equals(true) & stories.hidden.equals(false))
          ..orderBy([
            OrderingTerm.desc(savedWhen),
            OrderingTerm.desc(stories.id),
          ]);
    return _watchList(
      [stories, _db.pageCopies],
      () async => [
        for (final row in await query.get())
          FeedEntry(
            story: row.readTable(stories),
            bestRank: 0,
            page: row.readTableOrNull(_db.pageCopies),
          ),
      ],
    );
  }

  static const _candidateLimit = 800;

  /// Stored stories matching [query], best first, from every feed and day.
  /// Never touches the network, and follows later changes to the stories.
  Stream<List<FeedEntry>> watchSearch(String query, {DateTime? now}) {
    final words = queryWords(query);
    if (words.isEmpty) return Stream.value(const []);
    final match = ftsQueryFor(words);
    final select = match == null
        ? _db.customSelect(
            '''SELECT * FROM stories WHERE hidden = 0 AND (
              title LIKE ?1 ESCAPE '\\' OR domain LIKE ?1 ESCAPE '\\'
              OR "by" LIKE ?1 ESCAPE '\\') LIMIT $_candidateLimit''',
            variables: [Variable<String>('%${_likeEscape(words.first)}%')],
            readsFrom: {_db.stories},
          )
        : _db.customSelect(
            '''SELECT s.* FROM story_search f JOIN stories s ON s.id = f.rowid
            WHERE story_search MATCH ?1 AND s.hidden = 0
            ORDER BY bm25(story_search, 10, 3, 2) LIMIT $_candidateLimit''',
            variables: [Variable<String>(match)],
            readsFrom: {_db.stories},
          );
    return select.watch().asyncMap((rows) async {
      final stories = <int, StoryRow>{
        for (final row in rows) row.read<int>('id'): _db.stories.map(row.data),
      };
      final posts = await (_db.select(
        _db.stories,
      )..where((s) => s.body.isNotNull() & s.hidden.equals(false))).get();
      for (final post in posts) {
        stories.putIfAbsent(post.id, () => post);
      }
      final docs = [for (final story in stories.values) _searchDoc(story)];
      final ranked = rankStories(query, docs, now ?? DateTime.now());
      final ids = [for (final doc in ranked) doc.id];
      final pages = {
        for (final page in await (_db.select(
          _db.pageCopies,
        )..where((p) => p.storyId.isIn(ids))).get())
          page.storyId: page,
      };
      return [
        for (final id in ids)
          FeedEntry(story: stories[id]!, bestRank: 0, page: pages[id]),
      ];
    });
  }

  SearchDoc _searchDoc(StoryRow story) => SearchDoc(
    id: story.id,
    title: story.title,
    domain: story.domain,
    by: story.by,
    body: story.body == null ? null : parseFragment(story.body!).text,
    points: story.points,
    time: story.time,
    saved: story.saved,
    read: story.read,
  );

  String _likeEscape(String word) => word
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  /// Days are computed at query time, so a timezone change shows on the next
  /// subscription rather than on an emission.
  Stream<List<LocalDay>> watchStoredDays(
    FeedKind kind, {
    UtcOffsetAt offsetAt = deviceOffsetAt,
  }) {
    final snapshots = _db.feedSnapshots;
    final fetchedAt = snapshots.fetchedAt.min();
    final query = _db.selectOnly(snapshots)
      ..addColumns([fetchedAt])
      ..where(snapshots.feedKind.equalsValue(kind))
      ..groupBy([snapshots.fetchId]);
    return query.watch().map(
      (rows) => daysWithData([
        for (final row in rows) ?row.read(fetchedAt),
      ], offsetAt: offsetAt),
    );
  }

  /// When the newest rankings were fetched, finished run or not.
  Stream<DateTime?> watchNewestFetch() {
    final newest = _db.feedSnapshots.fetchedAt.max();
    final query = _db.selectOnly(_db.feedSnapshots)..addColumns([newest]);
    return query.watchSingle().map((row) => row.read(newest));
  }

  Future<StoryRow?> story(int id) => (_db.select(
    _db.stories,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Each feed's newest snapshot in rank order. A story with no metadata yet,
  /// or hidden by the user, has no url to capture.
  Future<Map<FeedKind, List<RankedStory>>> latestRankings(
    Iterable<FeedKind> kinds,
  ) async {
    final snapshots = _db.feedSnapshots;
    final highest = snapshots.fetchId.max();
    final result = <FeedKind, List<RankedStory>>{};
    for (final kind in kinds) {
      final newest =
          await (_db.selectOnly(snapshots)
                ..addColumns([highest])
                ..where(snapshots.feedKind.equalsValue(kind)))
              .map((row) => row.read(highest))
              .getSingle();
      if (newest == null) continue;
      final rows =
          await (_db.select(snapshots).join([
                  leftOuterJoin(
                    _db.stories,
                    _db.stories.id.equalsExp(snapshots.storyId),
                  ),
                ])
                ..where(snapshots.fetchId.equals(newest))
                ..orderBy([OrderingTerm.asc(snapshots.rank)]))
              .get();
      result[kind] = [
        for (final row in rows)
          RankedStory(
            row.readTable(snapshots).storyId,
            _capturableUrl(row.readTableOrNull(_db.stories)),
          ),
      ];
    }
    return result;
  }

  String? _capturableUrl(StoryRow? story) =>
      story == null || story.hidden ? null : story.url;

  Future<List<ThreadCandidate>> threadCandidates() async {
    final rows = await _db.select(_db.stories).join([
      leftOuterJoin(
        _db.threadStates,
        _db.threadStates.storyId.equalsExp(_db.stories.id),
      ),
    ]).get();
    return [
      for (final row in rows)
        ThreadCandidate(
          storyId: row.readTable(_db.stories).id,
          saved: row.readTable(_db.stories).saved,
          commentsFetchedAt: row.readTable(_db.stories).commentsFetchedAt,
          lastOpenedAt: row.readTableOrNull(_db.threadStates)?.lastOpenedAt,
          storyTime: row.readTable(_db.stories).time,
          commentCount: row.readTable(_db.stories).commentCount,
        ),
    ];
  }

  /// Where an HN item id lives in the store: a story, or a comment of one.
  /// Null when the item is not stored.
  Future<({int storyId, int? commentId})?> locateItem(int itemId) async {
    if (await story(itemId) != null) return (storyId: itemId, commentId: null);
    final comment = await (_db.select(
      _db.comments,
    )..where((c) => c.id.equals(itemId))).getSingleOrNull();
    if (comment == null || await story(comment.storyId) == null) return null;
    return (storyId: comment.storyId, commentId: itemId);
  }

  Stream<StoryRow?> watchStory(int id) => (_db.select(
    _db.stories,
  )..where((s) => s.id.equals(id))).watchSingleOrNull();

  Stream<List<CommentRow>> watchComments(int storyId) =>
      (_db.select(_db.comments)
            ..where((c) => c.storyId.equals(storyId))
            ..orderBy([(c) => OrderingTerm.asc(c.position)]))
          .watch();

  /// Stories without a title are skipped: they are deleted or not yet
  /// readable. The user's flags and `firstSeen` survive an update.
  Future<void> upsertStories(List<RemoteStory> stories, DateTime now) =>
      _db.batch((batch) {
        for (final story in stories) {
          final title = story.title;
          if (title == null) continue;
          batch.insert(
            _db.stories,
            StoriesCompanion.insert(
              id: Value(story.id),
              title: title,
              url: Value(story.url?.toString()),
              domain: Value(domainOf(story.url)),
              by: Value(story.by),
              points: Value(story.points),
              commentCount: Value.absentIfNull(story.commentCount),
              time: Value(story.time),
              type: Value(story.type.name),
              body: Value(story.text),
              firstSeen: now,
              lastSeen: now,
            ),
            onConflict: DoUpdate(
              (_) => StoriesCompanion(
                title: Value(title),
                url: Value(story.url?.toString()),
                domain: Value(domainOf(story.url)),
                by: Value(story.by),
                points: Value.absentIfNull(story.points),
                commentCount: Value.absentIfNull(story.commentCount),
                time: Value.absentIfNull(story.time),
                type: Value(story.type.name),
                body: Value.absentIfNull(story.text),
                lastSeen: Value(now),
              ),
            ),
          );
        }
      });

  /// Ranks are 1-based. Returns the new fetch id.
  Future<int> recordSnapshot(
    FeedKind kind,
    List<int> rankedIds,
    DateTime fetchedAt,
  ) => _db.transaction(() async {
    final highest = _db.feedSnapshots.fetchId.max();
    final current = await (_db.selectOnly(
      _db.feedSnapshots,
    )..addColumns([highest])).map((r) => r.read(highest)).getSingle();
    final fetchId = (current ?? 0) + 1;
    await _db.batch((batch) {
      batch.insertAll(_db.feedSnapshots, [
        for (var i = 0; i < rankedIds.length; i++)
          FeedSnapshotsCompanion.insert(
            fetchId: fetchId,
            feedKind: kind,
            storyId: rankedIds[i],
            rank: i + 1,
            fetchedAt: fetchedAt,
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
    return fetchId;
  });

  /// The old tree is replaced in one transaction, so a reader never sees a
  /// half-written thread.
  Future<void> replaceThread(RemoteThread thread, DateTime now) async {
    if (thread.story.title == null) return;
    final flat = flattenComments(thread.comments);
    await _db.transaction(() async {
      await upsertStories([thread.story], now);
      await (_db.delete(
        _db.comments,
      )..where((c) => c.storyId.equals(thread.story.id))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.comments, [
          for (final entry in flat)
            CommentsCompanion.insert(
              id: Value(entry.comment.id),
              storyId: thread.story.id,
              parentId: Value(entry.comment.parentId),
              author: Value(entry.comment.by),
              html: Value(entry.comment.text),
              time: Value(entry.comment.time),
              position: entry.position,
              depth: entry.depth,
              dead: Value(entry.comment.dead),
              deleted: Value(entry.comment.deleted),
            ),
        ], mode: InsertMode.insertOrReplace);
      });
      await (_db.update(_db.stories)
            ..where((s) => s.id.equals(thread.story.id)))
          .write(StoriesCompanion(commentsFetchedAt: Value(now)));
    });
  }

  Future<void> setRead(int id, {required bool value}) =>
      _write(id, StoriesCompanion(read: Value(value)));

  Future<void> setSaved(int id, {required bool value, DateTime? now}) => _write(
    id,
    StoriesCompanion(
      saved: Value(value),
      savedAt: Value(value ? (now ?? DateTime.now()) : null),
    ),
  );

  Future<void> setHidden(int id, {required bool value}) =>
      _write(id, StoriesCompanion(hidden: Value(value)));

  Future<void> _write(int id, StoriesCompanion change) =>
      (_db.update(_db.stories)..where((s) => s.id.equals(id))).write(change);
}
