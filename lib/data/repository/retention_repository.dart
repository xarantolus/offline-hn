import 'package:drift/drift.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/prune_policy.dart';

class RetentionRepository {
  const RetentionRepository(this._db);

  final AppDatabase _db;

  Future<List<PageCandidate>> pageCandidates() async {
    final rows = await (_db.select(_db.pageCopies).join([
      leftOuterJoin(
        _db.stories,
        _db.stories.id.equalsExp(_db.pageCopies.storyId),
      ),
    ])..where(_db.pageCopies.status.equalsValue(PageStatus.ok))).get();
    return [
      for (final row in rows)
        PageCandidate(
          storyId: row.readTable(_db.pageCopies).storyId,
          bytes: row.readTable(_db.pageCopies).bytes,
          capturedAt: row.readTable(_db.pageCopies).capturedAt,
          lastOpenedAt: row.readTable(_db.pageCopies).lastOpenedAt,
          saved: row.readTableOrNull(_db.stories)?.saved ?? false,
        ),
    ];
  }

  Future<List<LinkCandidate>> linkCandidates() async {
    final saved = {
      for (final row in await (_db.select(_db.linkReferences).join([
        innerJoin(
          _db.stories,
          _db.stories.id.equalsExp(_db.linkReferences.storyId),
        ),
      ])..where(_db.stories.saved.equals(true))).get())
        row.readTable(_db.linkReferences).linkId,
    };
    return [
      for (final row in await (_db.select(
        _db.linkCopies,
      )..where((l) => l.status.equalsValue(LinkStatus.ok))).get())
        LinkCandidate(
          id: row.id,
          kind: row.kind,
          bytes: row.bytes,
          capturedAt: row.capturedAt,
          lastOpenedAt: row.lastOpenedAt,
          saved: saved.contains(row.id),
        ),
    ];
  }

  /// Removes the rows and returns the relative paths of the files they named.
  Future<List<String>> deleteLinks(List<int> ids) => _db.transaction(() async {
    final rows = await (_db.select(
      _db.linkCopies,
    )..where((l) => l.id.isIn(ids))).get();
    await (_db.delete(
      _db.linkReferences,
    )..where((r) => r.linkId.isIn(ids))).go();
    await (_db.delete(_db.linkCopies)..where((l) => l.id.isIn(ids))).go();
    return [for (final row in rows) ?row.relativePath];
  });

  /// Copies no remaining story links to.
  Future<List<String>> deleteUnreferencedLinks() async {
    final referenced = _db.selectOnly(_db.linkReferences, distinct: true)
      ..addColumns([_db.linkReferences.linkId]);
    final orphans = await (_db.select(
      _db.linkCopies,
    )..where((l) => l.id.isNotInQuery(referenced))).get();
    return deleteLinks([for (final row in orphans) row.id]);
  }

  Future<List<TextCandidate>> textCandidates() async {
    final onFeed = await _latestSnapshotStoryIds();
    final withPage = {
      for (final row in await (_db.select(
        _db.pageCopies,
      )..where((p) => p.status.equalsValue(PageStatus.ok))).get())
        row.storyId,
    };
    final opened = {
      for (final row in await _db.select(_db.threadStates).get())
        row.storyId: row.lastOpenedAt,
    };
    return [
      for (final story in await _db.select(_db.stories).get())
        TextCandidate(
          storyId: story.id,
          lastSeen: story.lastSeen,
          saved: story.saved,
          hasPage: withPage.contains(story.id),
          onLatestSnapshot: onFeed.contains(story.id),
          threadOpenedAt: opened[story.id],
        ),
    ];
  }

  Future<List<ThreadStateCandidate>> threadStateCandidates() async {
    final saved = {
      for (final row in await (_db.select(
        _db.stories,
      )..where((s) => s.saved.equals(true))).get())
        row.id,
    };
    return [
      for (final state in await _db.select(_db.threadStates).get())
        ThreadStateCandidate(
          storyId: state.storyId,
          lastOpenedAt: state.lastOpenedAt,
          saved: saved.contains(state.storyId),
        ),
    ];
  }

  Future<List<SnapshotFetch>> snapshotFetches() async {
    final fetchId = _db.feedSnapshots.fetchId;
    final kind = _db.feedSnapshots.feedKind;
    final at = _db.feedSnapshots.fetchedAt.min();
    final rows =
        await (_db.selectOnly(_db.feedSnapshots)
              ..addColumns([fetchId, kind, at])
              ..groupBy([fetchId]))
            .get();
    return [
      for (final row in rows)
        SnapshotFetch(
          fetchId: row.read(fetchId)!,
          feedKind: FeedKind.values.byName(row.read(kind)!),
          fetchedAt: row.read(at)!,
        ),
    ];
  }

  /// Removes the rows and returns the relative paths of the files they named.
  Future<List<String>> deletePages(List<int> storyIds) =>
      _db.transaction(() async {
        final rows = await (_db.select(
          _db.pageCopies,
        )..where((p) => p.storyId.isIn(storyIds))).get();
        await (_db.delete(
          _db.pageCopies,
        )..where((p) => p.storyId.isIn(storyIds))).go();
        return [for (final row in rows) ?row.relativePath];
      });

  Future<void> deleteStories(List<int> storyIds) => _db.transaction(() async {
    await (_db.delete(
      _db.comments,
    )..where((c) => c.storyId.isIn(storyIds))).go();
    await (_db.delete(
      _db.pageCopies,
    )..where((p) => p.storyId.isIn(storyIds))).go();
    await (_db.delete(
      _db.linkReferences,
    )..where((r) => r.storyId.isIn(storyIds))).go();
    await (_db.delete(
      _db.feedSnapshots,
    )..where((s) => s.storyId.isIn(storyIds))).go();
    await (_db.delete(_db.stories)..where((s) => s.id.isIn(storyIds))).go();
  });

  Future<void> deleteThreadStates(List<int> storyIds) => (_db.delete(
    _db.threadStates,
  )..where((t) => t.storyId.isIn(storyIds))).go();

  Future<void> deleteSnapshotFetches(List<int> fetchIds) => (_db.delete(
    _db.feedSnapshots,
  )..where((s) => s.fetchId.isIn(fetchIds))).go();

  Future<Set<int>> _latestSnapshotStoryIds() async {
    final newest = newestFetchPerFeed(await snapshotFetches());
    final rows =
        await (_db.select(_db.feedSnapshots)..where(
              (s) => s.fetchId.isIn([for (final f in newest.values) f.fetchId]),
            ))
            .get();
    return {for (final row in rows) row.storyId};
  }
}
