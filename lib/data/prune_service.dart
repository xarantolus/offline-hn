import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/policy/keep_window.dart';
import 'package:offline_hn/data/policy/prune_policy.dart';
import 'package:offline_hn/data/repository/retention_repository.dart';

/// Where the saved copies are, by paths relative to one root.
abstract interface class StoredFiles {
  Future<List<({String path, DateTime modified, int bytes})>> list();
  bool exists(String relativePath);
  Future<void> delete(String relativePath);
}

/// A file no row names is left this long first, in case it is being written.
const strayFileGrace = Duration(hours: 1);

class PruneResult {
  const PruneResult({
    required this.pages,
    required this.links,
    required this.stories,
    required this.threadStates,
    required this.snapshotFetches,
    required this.strayFiles,
    required this.lostCopies,
    required this.bytes,
  });

  final int pages;
  final int links;
  final int stories;
  final int threadStates;
  final int snapshotFetches;

  /// Files no row named, left by a crash or a capture that changed kind.
  final int strayFiles;

  /// Rows whose file or discussion was gone, now owed again.
  final int lostCopies;

  /// Weight of the saved copies and stray files removed.
  final int bytes;
}

class PruneService {
  const PruneService(this._retention);

  final RetentionRepository _retention;

  /// Rows go before files, so a crash in between leaves a stray file rather
  /// than a row pointing at nothing; the stray files go at the end. Linked
  /// pages go before article copies, and the copies of an expired story go
  /// with its text.
  Future<PruneResult> run({
    required AppSettings settings,
    required DateTime now,
    required StoredFiles files,
    UtcOffsetAt offsetAt = deviceOffsetAt,
  }) async {
    final deleteFile = files.delete;
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
      linkedFrom: await _retention.linkedDiscussions(),
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

    final named = await _retention.copyPaths();
    var strayFiles = 0;
    var strayBytes = 0;
    for (final file in await files.list()) {
      if (named.contains(file.path) ||
          now.difference(file.modified) < strayFileGrace) {
        continue;
      }
      await deleteFile(file.path);
      strayFiles++;
      strayBytes += file.bytes;
    }
    final lostCopies = await _retention.forgetMissing(files.exists);

    return PruneResult(
      pages: pages.length + expiredPages.paths.length,
      links: links.length + orphaned.paths.length,
      stories: stories.length,
      threadStates: states.length,
      snapshotFetches: fetches.length,
      strayFiles: strayFiles,
      lostCopies: lostCopies,
      bytes:
          linkFiles.bytes +
          pageFiles.bytes +
          expiredPages.bytes +
          orphaned.bytes +
          strayBytes,
    );
  }
}
