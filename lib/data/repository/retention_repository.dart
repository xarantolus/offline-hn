import 'package:drift/drift.dart';
import 'package:offline_hn/comments/comment_parser.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/prune_policy.dart';
import 'package:offline_hn/data/repository/story_repository.dart';

/// Files a deletion left behind to remove, and what they weighed.
class RemovedFiles {
  const RemovedFiles(this.paths, this.bytes);

  final List<String> paths;
  final int bytes;
}

class RetentionRepository {
  const RetentionRepository(this._db);

  final AppDatabase _db;

  /// For each stored discussion saved as a link, the stories that link to it.
  Future<Map<int, Set<int>>> linkedDiscussions() async {
    final rows =
        await (_db.select(_db.linkCopies).join([
              innerJoin(
                _db.linkReferences,
                _db.linkReferences.linkId.equalsExp(_db.linkCopies.id),
              ),
            ])..where(
              _db.linkCopies.kind.equalsValue(PageKind.thread) &
                  _db.linkCopies.status.equalsValue(LinkStatus.ok),
            ))
            .get();
    final linked = <int, Set<int>>{};
    for (final row in rows) {
      final story = await _discussionOf(row.readTable(_db.linkCopies).url);
      if (story == null) continue;
      linked
          .putIfAbsent(story, () => {})
          .add(row.readTable(_db.linkReferences).storyId);
    }
    return linked;
  }

  /// The paths every copy row names, whatever its status.
  Future<Set<String>> copyPaths() async => {
    for (final row in await _db.select(_db.pageCopies).get()) ?row.relativePath,
    for (final row in await _db.select(_db.linkCopies).get()) ?row.relativePath,
  };

  /// Copies whose file is gone, and discussions saved as links whose thread
  /// is gone, become owed again so the next update fetches them. Returns how
  /// many.
  Future<int> forgetMissing(bool Function(String relativePath) exists) =>
      _db.transaction(() async {
        final pages = await (_db.select(
          _db.pageCopies,
        )..where((p) => p.status.equalsValue(PageStatus.ok))).get();
        final lostPages = [
          for (final page in pages)
            if (!_present(page.relativePath, exists)) page.storyId,
        ];
        await (_db.delete(
          _db.pageCopies,
        )..where((p) => p.storyId.isIn(lostPages))).go();

        final links = await (_db.select(
          _db.linkCopies,
        )..where((l) => l.status.equalsValue(LinkStatus.ok))).get();
        final lostLinks = <int>[];
        for (final link in links) {
          final present = link.kind == PageKind.thread
              ? await _discussionOf(link.url) != null
              : _present(link.relativePath, exists);
          if (!present) lostLinks.add(link.id);
        }
        await (_db.update(
          _db.linkCopies,
        )..where((l) => l.id.isIn(lostLinks))).write(
          const LinkCopiesCompanion(
            status: Value(LinkStatus.pending),
            relativePath: Value(null),
            bytes: Value(0),
          ),
        );
        return lostPages.length + lostLinks.length;
      });

  bool _present(String? path, bool Function(String) exists) =>
      path != null && exists(path);

  /// The stored story a link to an HN item opens, if it is stored.
  Future<int?> _discussionOf(String url) async {
    final item = hnItemId(Uri.parse(url));
    if (item == null) return null;
    return (await StoryRepository(_db).locateItem(item))?.storyId;
  }

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

  /// Removes the rows and returns the files they named.
  Future<RemovedFiles> deleteLinks(List<int> ids) => _db.transaction(() async {
    final rows = await (_db.select(
      _db.linkCopies,
    )..where((l) => l.id.isIn(ids))).get();
    await (_db.delete(_db.linkCopies)..where((l) => l.id.isIn(ids))).go();
    return RemovedFiles([
      for (final row in rows) ?row.relativePath,
    ], rows.fold(0, (sum, row) => sum + row.bytes));
  });

  /// Copies no remaining story links to.
  Future<RemovedFiles> deleteUnreferencedLinks() async {
    final referenced = _db.selectOnly(_db.linkReferences, distinct: true)
      ..addColumns([_db.linkReferences.linkId]);
    final orphans = await (_db.select(
      _db.linkCopies,
    )..where((l) => l.id.isNotInQuery(referenced))).get();
    return deleteLinks([for (final row in orphans) row.id]);
  }

  Future<List<TextCandidate>> textCandidates() async {
    final onFeed = await _latestSnapshotStoryIds();
    final pageOpened = {
      for (final row in await _db.select(_db.pageCopies).get())
        row.storyId: ?row.lastOpenedAt,
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
          pageOpenedAt: pageOpened[story.id],
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
              ..where(_db.feedSnapshots.published.equals(true))
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

  /// Removes the rows and returns the files they named.
  Future<RemovedFiles> deletePages(List<int> storyIds) =>
      _db.transaction(() async {
        final rows = await (_db.select(
          _db.pageCopies,
        )..where((p) => p.storyId.isIn(storyIds))).get();
        await (_db.delete(
          _db.pageCopies,
        )..where((p) => p.storyId.isIn(storyIds))).go();
        return RemovedFiles([
          for (final row in rows) ?row.relativePath,
        ], rows.fold(0, (sum, row) => sum + row.bytes));
      });

  /// Comments, copies, link references and thread state go with their story.
  Future<void> deleteStories(List<int> storyIds) => _db.transaction(() async {
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
