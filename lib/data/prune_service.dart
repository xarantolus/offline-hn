import 'package:offline_hn/data/model/settings.dart';
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
  /// than a row pointing at nothing. Linked pages go before article copies, and pages are pruned before text because a story
  /// with a page is exempt from text pruning.
  Future<PruneResult> run({
    required AppSettings settings,
    required DateTime now,
    required Future<void> Function(String relativePath) deleteFile,
  }) async {
    final pageCandidates = await _retention.pageCandidates();
    final linkCandidates = await _retention.linkCandidates();
    final links = linksToPrune(
      linkCandidates,
      pageBytes: pageCandidates.fold(0, (sum, page) => sum + page.bytes),
      budgetBytes: settings.pageBudgetBytes,
      textRetentionDays: settings.textRetentionDays,
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
      retentionDays: settings.textRetentionDays,
      now: now,
    );
    await _retention.deleteStories(stories);
    final orphaned = await _retention.deleteUnreferencedLinks();
    for (final path in orphaned.paths) {
      await deleteFile(path);
    }

    final states = threadStatesToPrune(
      await _retention.threadStateCandidates(),
      now: now,
    );
    await _retention.deleteThreadStates(states);

    final fetches = snapshotFetchesToPrune(
      await _retention.snapshotFetches(),
      retentionDays: settings.textRetentionDays,
      now: now,
    );
    await _retention.deleteSnapshotFetches(fetches);

    return PruneResult(
      pages: pages.length,
      links: links.length + orphaned.paths.length,
      stories: stories.length,
      threadStates: states.length,
      snapshotFetches: fetches.length,
      bytes: linkFiles.bytes + pageFiles.bytes + orphaned.bytes,
    );
  }
}
