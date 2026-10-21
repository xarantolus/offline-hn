import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/policy/keep_window.dart';
import 'package:offline_hn/data/policy/prune_policy.dart';
import 'package:offline_hn/data/repository/retention_repository.dart';

class PruneResult {
  const PruneResult({
    required this.pages,
    required this.links,
    required this.stories,
    required this.threadStates,
    required this.snapshotFetches,
    required this.bytes,
  });

  final int pages;
  final int links;
  final int stories;
  final int threadStates;
  final int snapshotFetches;

  /// Weight of the saved copies removed.
  final int bytes;
}

class PruneService {
  const PruneService(this._retention);

  final RetentionRepository _retention;

  /// Rows go before files, so a crash in between leaves an orphan file rather
  /// than a row pointing at nothing. Linked pages go before article copies,
  /// and the copies of an expired story go with its text.
  Future<PruneResult> run({
    required AppSettings settings,
    required DateTime now,
    required Future<void> Function(String relativePath) deleteFile,
    UtcOffsetAt offsetAt = deviceOffsetAt,
  }) async {
    final keepFrom = keepWindowStart(
      now,
      settings.keepDays,
      offsetAt: offsetAt,
    );
    final pageCandidates = await _retention.pageCandidates();
    final linkCandidates = await _retention.linkCandidates();
    final links = linksToPrune(
      linkCandidates,
      pageBytes: pageCandidates.fold(0, (sum, page) => sum + page.bytes),
      budgetBytes: settings.pageBudgetBytes,
      keepFrom: keepFrom,
      now: now,
    );
    final linkFiles = await _retention.deleteLinks(links);
    final pages = pagesToPrune(
      pageCandidates,
      budgetBytes: settings.pageBudgetBytes,
      otherBytes: linkCandidates
          .where((link) => !links.contains(link.id))
          .fold(0, (sum, link) => sum + link.bytes),
      now: now,
    );
    final pageFiles = await _retention.deletePages(pages);
    for (final path in [...linkFiles.paths, ...pageFiles.paths]) {
      await deleteFile(path);
    }

    final stories = storiesToPrune(
      await _retention.textCandidates(),
      keepFrom: keepFrom,
    );
    final expiredPages = await _retention.deletePages(stories);
    await _retention.deleteStories(stories);
    final orphaned = await _retention.deleteUnreferencedLinks();
    for (final path in [...expiredPages.paths, ...orphaned.paths]) {
      await deleteFile(path);
    }

    final states = threadStatesToPrune(
      await _retention.threadStateCandidates(),
      now: now,
    );
    await _retention.deleteThreadStates(states);

    final fetches = snapshotFetchesToPrune(
      await _retention.snapshotFetches(),
      keepFrom: keepFrom,
    );
    await _retention.deleteSnapshotFetches(fetches);

    return PruneResult(
      pages: pages.length + expiredPages.paths.length,
      links: links.length + orphaned.paths.length,
      stories: stories.length,
      threadStates: states.length,
      snapshotFetches: fetches.length,
      bytes:
          linkFiles.bytes +
          pageFiles.bytes +
          expiredPages.bytes +
          orphaned.bytes,
    );
  }
}
