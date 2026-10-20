import 'package:drift/drift.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/db/throttled_watch.dart';
import 'package:offline_hn/data/db/waiting_stories.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/store_overview.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/run_history.dart';

/// What past updates did and what is stored now, for the overview page.
class OverviewRepository {
  const OverviewRepository(this._db);

  static const _runsShown = 20;
  static const _runRefresh = Duration(seconds: 1);
  static const _storeRefresh = Duration(seconds: 3);

  final AppDatabase _db;

  /// Newest first. A sync writes every item as it finishes, so the answer is
  /// throttled like the feed's.
  Stream<List<RunRecord>> watchRuns() => throttledWatch(
    _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.syncRuns, _db.syncItems]),
    ),
    _runs,
    interval: _runRefresh,
  );

  Stream<RunRecord?> watchLatestRun() =>
      watchRuns().map((runs) => runs.firstOrNull).distinct(_sameRun);

  Future<List<RunRecord>> _runs() async {
    final rows =
        await (_db.select(_db.syncRuns)
              ..orderBy([(r) => OrderingTerm.desc(r.id)])
              ..limit(_runsShown))
            .get();
    final groups = await _db
        .customSelect(
          'SELECT run_id, kind, status, as_thread, COUNT(*) AS n, '
          'COALESCE(SUM(bytes), 0) AS bytes FROM sync_items '
          'GROUP BY run_id, kind, status, as_thread',
          readsFrom: {_db.syncItems},
        )
        .get();
    final byRun = <int, List<ItemGroup>>{};
    for (final row in groups) {
      byRun
          .putIfAbsent(row.read<int>('run_id'), () => [])
          .add(
            ItemGroup(
              kind: SyncItemKind.values.byName(row.read<String>('kind')),
              status: SyncItemStatus.values.byName(row.read<String>('status')),
              asThread: row.read<bool>('as_thread'),
              count: row.read<int>('n'),
              bytes: row.read<int>('bytes'),
            ),
          );
    }
    return [
      for (final run in rows)
        RunRecord(
          id: run.id,
          trigger: run.trigger,
          startedAt: run.startedAt,
          heartbeatAt: run.heartbeatAt ?? run.startedAt,
          finishedAt: run.finishedAt,
          outcome: run.outcome,
          error: run.error,
          connection: run.connection,
          storiesUpdated: run.storiesUpdated,
          listsRefreshed: run.listsRefreshed,
          prunedCopies: run.prunedCopies,
          prunedStories: run.prunedStories,
          prunedBytes: run.prunedBytes,
          tally: tallyItems(byRun[run.id] ?? const []),
        ),
    ];
  }

  Future<List<FailedItem>> failedItems(int runId) async {
    final rows = await _db
        .customSelect(
          'SELECT i.kind AS kind, i.story_id AS id, i.error AS error, '
          'i.as_thread AS as_thread, COALESCE(s.title, l.url) AS title '
          'FROM sync_items i '
          "LEFT JOIN stories s ON i.kind <> 'link' AND s.id = i.story_id "
          "LEFT JOIN link_copies l ON i.kind = 'link' AND l.id = i.story_id "
          "WHERE i.run_id = ?1 AND i.status = 'failed' ORDER BY i.rowid",
          variables: [Variable.withInt(runId)],
          readsFrom: {_db.syncItems, _db.stories, _db.linkCopies},
        )
        .get();
    return [
      for (final row in rows)
        FailedItem(
          kind: SyncItemKind.values.byName(row.read<String>('kind')),
          id: row.read<int>('id'),
          error: row.read<String?>('error'),
          title: row.read<String?>('title'),
          asThread: row.read<bool>('as_thread'),
        ),
    ];
  }

  Stream<StoreOverview> watchStore() => throttledWatch(
    _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.stories,
        _db.comments,
        _db.feedSnapshots,
        _db.pageCopies,
        _db.linkCopies,
      ]),
    ),
    _store,
    interval: _storeRefresh,
  );

  DateTime? _seconds(int? value) =>
      value == null ? null : DateTime.fromMillisecondsSinceEpoch(value * 1000);

  Future<StoreOverview> _store() async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS stories, MIN(time) AS oldest, MAX(time) AS newest, '
          'COUNT(comments_fetched_at) AS threads, '
          'SUM(saved) AS bookmarked, '
          '(SELECT COUNT(*) FROM comments '
          'WHERE story_id NOT IN $waitingStoryIds) AS comments, '
          '(SELECT COUNT(*) FROM $waitingStoryIds) AS waiting, '
          '(SELECT COUNT(*) FROM page_copies WHERE status = ?1) AS articles, '
          '(SELECT COALESCE(SUM(bytes), 0) FROM page_copies WHERE status = ?1) '
          'AS article_bytes, '
          '(SELECT COUNT(*) FROM link_copies WHERE status = ?2 AND kind <> ?3) '
          'AS linked, '
          '(SELECT COALESCE(SUM(bytes), 0) FROM link_copies WHERE status = ?2) '
          'AS linked_bytes, '
          '(SELECT COUNT(*) FROM link_copies WHERE status = ?2 AND kind = ?3) '
          'AS linked_threads FROM stories WHERE id NOT IN $waitingStoryIds',
          variables: [
            Variable.withString(PageStatus.ok.name),
            Variable.withString(LinkStatus.ok.name),
            Variable.withString(PageKind.thread.name),
          ],
          readsFrom: {
            _db.stories,
            _db.comments,
            _db.feedSnapshots,
            _db.pageCopies,
            _db.linkCopies,
          },
        )
        .getSingle();
    final feeds = await _db
        .customSelect(
          'SELECT feed_kind, COUNT(DISTINCT story_id) AS n '
          'FROM feed_snapshots WHERE published = 1 GROUP BY feed_kind',
          readsFrom: {_db.feedSnapshots},
        )
        .get();
    return StoreOverview(
      stories: row.read<int>('stories'),
      oldestStory: _seconds(row.read<int?>('oldest')),
      newestStory: _seconds(row.read<int?>('newest')),
      perFeed: {
        for (final feed in feeds)
          FeedKind.values.byName(feed.read<String>('feed_kind')): feed
              .read<int>('n'),
      },
      threads: row.read<int>('threads'),
      comments: row.read<int>('comments'),
      waitingStories: row.read<int>('waiting'),
      articles: row.read<int>('articles'),
      articleBytes: row.read<int>('article_bytes'),
      linkedPages: row.read<int>('linked'),
      linkedBytes: row.read<int>('linked_bytes'),
      linkedThreads: row.read<int>('linked_threads'),
      bookmarked: row.read<int?>('bookmarked') ?? 0,
    );
  }
}

bool _sameRun(RunRecord? a, RunRecord? b) =>
    a != null &&
    b != null &&
    a.id == b.id &&
    a.heartbeatAt == b.heartbeatAt &&
    a.finishedAt == b.finishedAt &&
    a.outcome == b.outcome &&
    a.storiesUpdated == b.storiesUpdated;
