import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:offline_hn/comments/comment_parser.dart';
import 'package:offline_hn/data/api/hn_reader.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/comment_tree.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
import 'package:offline_hn/data/policy/link_scope.dart';
import 'package:offline_hn/data/policy/network_policy.dart';
import 'package:offline_hn/data/policy/sync_scope.dart';
import 'package:offline_hn/data/prune_service.dart';
import 'package:offline_hn/data/repository/link_repository.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/connection_probe.dart';
import 'package:offline_hn/sync/filter_list_sync.dart';
import 'package:offline_hn/sync/page_files.dart';
import 'package:offline_hn/sync/page_saver.dart';
import 'package:offline_hn/sync/run_budget.dart';
import 'package:offline_hn/sync/sync_notifier.dart';
import 'package:pool/pool.dart';

enum SyncResult {
  /// Every step ran.
  completed,

  /// Out of time; the run is open and a continuation picks it up.
  paused,

  /// Told to stop, by the platform or the user.
  stopped,

  /// The process that was working on the run died, and this start came from
  /// WorkManager's recovery, outside any job's protection. Nothing was done;
  /// a job started the normal way continues the run.
  interrupted,

  /// No usable connection for this trigger.
  skipped,

  /// Nothing could be fetched.
  failed;

  /// Whether WorkManager should run the job again to continue the run.
  bool get wantsRetry =>
      this == paused || this == stopped || this == interrupted;
}

class SyncFailure implements Exception {
  const SyncFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class _Context {
  _Context(this.run, this.trigger, this.settings, this.budget);

  final SyncRunRow run;
  final SyncTrigger trigger;
  final AppSettings settings;
  final RunBudget budget;
}

class _PageOutcome {
  const _PageOutcome(this.status, {this.error, this.bytes = 0});

  final PageStatus? status;
  final String? error;
  final int bytes;
}

class _LinkOutcome {
  const _LinkOutcome(
    this.status, {
    this.error,
    this.bytes = 0,
    this.asThread = false,
  });

  final LinkStatus? status;
  final String? error;
  final int bytes;
  final bool asThread;
}

/// The only code that fetches. Every trigger, in the foreground or the
/// background, ends up here, and everything it learns goes to the database.
///
/// A run is a list of phases with a checkpoint per item, so it can stop
/// anywhere and the next call carries on: ranking, story details, comment
/// threads, saved pages, pages linked from top comments, pruning.
class SyncRunner {
  SyncRunner({
    required this._syncs,
    required this._stories,
    required this._pages,
    required this._links,
    required this._settings,
    required this._source,
    required this._probe,
    required this._saver,
    required this._lists,
    required this._prune,
    required this._files,
    required this._notifier,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _rankingWorstCase = Duration(seconds: 30);
  static const _metadataWorstCase = Duration(seconds: 90);
  static const _commentWorstCase = Duration(seconds: 60);
  static const _pageWorstCase = Duration(minutes: 3);
  static const _listsTimeout = Duration(minutes: 4);
  static const _pruneTimeout = Duration(minutes: 2);
  static const _searchBatch = 100;

  /// Requests in flight while the text is fetched.
  static const _textParallel = 4;

  /// Pages being captured at once; the plugin allows the same number.
  static const _captureParallel = 2;

  final SyncRepository _syncs;
  final StoryRepository _stories;
  final PageRepository _pages;
  final LinkRepository _links;
  final SettingsStore _settings;
  final HnReader _source;
  final ConnectionProbe _probe;
  final StoryPageSaver _saver;
  final FilterListSync _lists;
  final PruneService _prune;
  final PageFiles _files;
  final RunNotifier _notifier;
  final DateTime Function() _clock;

  var _stopRequested = false;
  int? _activeRun;

  /// Ends the run at the next checkpoint and abandons a page being captured.
  void requestStop() {
    _stopRequested = true;
    _saver.cancel();
  }

  /// [requestStop], and hands the run back at once for when the process is
  /// about to be torn down before the checkpoint is reached.
  Future<void> stopNow() async {
    requestStop();
    final run = _activeRun;
    if (run != null) await _syncs.setExecuting(run, value: false);
  }

  Future<SyncResult> run(SyncTrigger trigger) async {
    _stopRequested = false;
    final started = _clock();
    final settings = await _settings.load();
    if (await _allowance(trigger, settings) == SyncAllowance.nothing) {
      return SyncResult.skipped;
    }

    final run = await _syncs.beginOrResume(trigger, started);
    if (run.executing) {
      await _syncs.setExecuting(run.id, value: false);
      return SyncResult.interrupted;
    }
    await _syncs.setExecuting(run.id, value: true);
    await _syncs.recordConnection(run.id, await _probe.current());
    _activeRun = run.id;
    await _notifier.runStarted();
    try {
      final context = _Context(
        run,
        trigger,
        settings,
        RunBudget(startedAt: started),
      );
      return await _execute(context);
    } on SyncFailure catch (e) {
      await _syncs.finish(run.id, SyncOutcome.failed, _clock(), error: '$e');
      return SyncResult.failed;
    } finally {
      _activeRun = null;
      await _syncs.setExecuting(run.id, value: false);
      await _notifier.runEnded();
    }
  }

  Future<SyncResult> _execute(_Context context) async {
    final run = context.run;
    var phase = run.phase;
    if (phase == SyncPhase.ranking) {
      await _rank(context);
      await _syncs.setPhase(run.id, SyncPhase.metadata, _clock());
      phase = SyncPhase.metadata;
    }
    if (phase == SyncPhase.metadata) {
      final before = context.trigger.textOnly
          ? await _stories.threadCandidates()
          : const <ThreadCandidate>[];
      final stop = await _metadata(context);
      if (stop != null) return stop;
      await _queueComments(context, before);
      await _syncs.setPhase(run.id, SyncPhase.comments, _clock());
      phase = SyncPhase.comments;
    }
    if (phase == SyncPhase.comments) {
      final stop = await _comments(context);
      if (stop != null) return stop;
      if (context.trigger.textOnly) {
        await _syncs.finish(run.id, SyncOutcome.succeeded, _clock());
        return SyncResult.completed;
      }
      await _syncs.setPhase(run.id, SyncPhase.pages, _clock());
      phase = SyncPhase.pages;
    }
    if (phase == SyncPhase.pages) {
      final stop = await _savePages(context);
      if (stop != null) return stop;
      await _syncs.setPhase(run.id, SyncPhase.links, _clock());
    }
    final stop = await _saveLinks(context);
    if (stop != null) return stop;

    await _pruneStore(context);
    await _syncs.finish(run.id, SyncOutcome.succeeded, _clock());
    return SyncResult.completed;
  }

  Future<SyncAllowance> _allowance(
    SyncTrigger trigger,
    AppSettings settings,
  ) async => syncAllowance(
    trigger: trigger,
    connection: await _probe.current(),
    settings: settings,
  );

  SyncResult? _checkpoint(_Context context, Duration worstCase) {
    if (_stopRequested) return SyncResult.stopped;
    if (!context.budget.fits(_clock(), worstCase)) return SyncResult.paused;
    return null;
  }

  /// Runs [work] for each of [items] in order with [parallel] at a time. After
  /// the first non-null result, or a stop or a pause at a checkpoint, nothing
  /// more starts; what is already running finishes. Returns that result.
  Future<SyncResult?> _each<T>(
    _Context context,
    Iterable<T> items, {
    required int parallel,
    required Duration worstCase,
    required Future<SyncResult?> Function(T item) work,
  }) async {
    final pool = Pool(parallel);
    final running = <Future<void>>[];
    SyncResult? result;
    for (final item in items) {
      final slot = await pool.request();
      result ??= _checkpoint(context, worstCase);
      if (result != null) {
        slot.release();
        break;
      }
      running.add(
        work(item)
            .then((outcome) => result ??= outcome)
            .whenComplete(slot.release),
      );
    }
    await Future.wait(running);
    await pool.close();
    return result;
  }

  Future<void> _rank(_Context context) async {
    final feeds = context.settings.enabledFeeds.toList();
    final read = await Future.wait([
      for (final kind in feeds) _recordRanking(kind),
    ]);
    if (feeds.isNotEmpty && !read.contains(true)) {
      throw const SyncFailure('no feed could be read');
    }
  }

  Future<bool> _recordRanking(FeedKind kind) async {
    try {
      final ids = await _source.ranking(kind).timeout(_rankingWorstCase);
      await _stories.recordSnapshot(
        kind,
        ids.take(feedDepth).toList(),
        _clock(),
      );
      return true;
    } on Exception catch (e) {
      debugPrintSynchronously('ranking $kind failed: $e');
      return false;
    }
  }

  Future<Map<FeedKind, List<RankedStory>>> _rankings(AppSettings settings) =>
      _stories.latestRankings(settings.enabledFeeds);

  List<int> _idsByRank(Map<FeedKind, List<RankedStory>> rankings) =>
      interleavedByRank({
        for (final entry in rankings.entries)
          entry.key: [for (final story in entry.value) story.id],
      });

  Future<SyncResult?> _metadata(_Context context) async {
    final ids = _idsByRank(await _rankings(context.settings));
    final batches = [
      for (var i = 0; i < ids.length; i += _searchBatch)
        ids.sublist(i, (i + _searchBatch).clamp(0, ids.length)),
    ];
    var failed = 0;
    final stop = await _each(
      context,
      batches,
      parallel: _textParallel,
      worstCase: _metadataWorstCase,
      work: (batch) async {
        final closed = await _gate(context, pages: false);
        if (closed != null) return closed;
        try {
          final found = await _source
              .stories(batch)
              .timeout(_metadataWorstCase);
          await _stories.upsertStories(found, _clock());
          await _syncs.addStoriesUpdated(context.run.id, found.length);
        } on Exception catch (e) {
          failed++;
          debugPrintSynchronously('story details failed: $e');
        }
        await _syncs.heartbeat(context.run.id, _clock());
        return null;
      },
    );
    if (stop != null) return stop;
    if (batches.isNotEmpty && failed == batches.length) {
      throw const SyncFailure('story details could not be fetched');
    }
    return null;
  }

  Future<void> _queueComments(
    _Context context,
    List<ThreadCandidate> before,
  ) async {
    final feedOrder = _idsByRank(await _rankings(context.settings));
    final stored = await _stories.threadCandidates();
    final targets = context.trigger.textOnly
        ? selectChangedThreads(
            feedOrder: feedOrder,
            before: before,
            after: stored,
            now: _clock(),
          )
        : selectCommentTargets(
            feedOrder: feedOrder,
            stored: stored,
            now: _clock(),
          );
    await _syncs.enqueue(context.run.id, SyncItemKind.comments, targets);
  }

  Future<SyncResult?> _comments(_Context context) async {
    final pending = await _syncs.pendingStoryIds(
      context.run.id,
      SyncItemKind.comments,
    );
    return _each(
      context,
      pending,
      parallel: _textParallel,
      worstCase: _commentWorstCase,
      work: (id) async {
        final closed = await _gate(context, pages: false);
        if (closed != null) return closed;
        final error = await _refreshThread(id);
        await _syncs.markItem(
          context.run.id,
          SyncItemKind.comments,
          id,
          error == null ? SyncItemStatus.done : SyncItemStatus.failed,
          _clock(),
          error: error,
        );
        return null;
      },
    );
  }

  /// The error text, or null when the thread was stored.
  Future<String?> _refreshThread(int id) async {
    try {
      final thread = await _loadThread(id).timeout(_commentWorstCase);
      if (thread == null) return 'not found';
      if (thread.comments.isEmpty && (thread.story.commentCount ?? 0) > 0) {
        return 'comments not indexed yet';
      }
      await _stories.replaceThread(thread, _clock());
      return null;
    } on Exception catch (e) {
      return '$e';
    }
  }

  Future<RemoteThread?> _loadThread(int id) async {
    final thread = await _source.thread(id);
    return thread == null ? null : _inHnOrder(thread);
  }

  Future<RemoteThread> _inHnOrder(RemoteThread thread) async {
    final id = thread.story.id;
    final ranked = thread.comments.length < 2
        ? const <int>[]
        : await _rankedOrEmpty(id);
    return RemoteThread(
      story: thread.story,
      comments: orderTopLevel(thread.comments, ranked),
    );
  }

  Future<List<int>> _rankedOrEmpty(int id) async {
    try {
      return await _source.rankedTopLevel(id);
    } on Exception {
      return const [];
    }
  }

  /// Checked before every item, since the connection can change mid-run.
  /// A connection the trigger may not use, or none, pauses the run to resume
  /// on a better one. Pages additionally need more than text is allowed:
  /// without that they end and the run carries on without them.
  Future<SyncResult?> _gate(_Context context, {required bool pages}) async {
    final allowance = syncAllowance(
      trigger: context.trigger,
      connection: await _probe.current(),
      settings: context.settings,
    );
    return switch (allowance) {
      SyncAllowance.nothing => SyncResult.paused,
      SyncAllowance.textOnly when pages => SyncResult.completed,
      _ => null,
    };
  }

  Future<SyncResult?> _savePages(_Context context) async {
    final gate = await _gate(context, pages: true);
    if (gate == SyncResult.paused) return gate;
    if (gate != null) return null;
    if (await _freshenLists()) {
      await _syncs.recordListsRefreshed(context.run.id);
    }

    final rankings = await _rankings(context.settings);
    final ids = _idsByRank(rankings);
    final existing = await _pages.forStories(ids);
    final targets = selectCaptureTargets(
      rankings: rankings,
      existing: {
        for (final entry in existing.entries)
          entry.key: ExistingPage(entry.value.status, entry.value.capturedAt),
      },
      now: _clock(),
    );
    await _syncs.enqueue(context.run.id, SyncItemKind.page, targets);

    final pending = await _syncs.pendingStoryIds(
      context.run.id,
      SyncItemKind.page,
    );
    final result = await _each(
      context,
      pending,
      parallel: _captureParallel,
      worstCase: _pageWorstCase,
      work: (id) async {
        final open = await _gate(context, pages: true);
        if (open != null) return open;
        final outcome = await _savePage(id, context.settings);
        if (outcome.status == null) {
          return _stopRequested ? SyncResult.stopped : SyncResult.paused;
        }
        await _syncs.markItem(
          context.run.id,
          SyncItemKind.page,
          id,
          switch (outcome.status) {
            PageStatus.failed => SyncItemStatus.failed,
            PageStatus.tooLarge => SyncItemStatus.tooLarge,
            _ => SyncItemStatus.done,
          },
          _clock(),
          error: outcome.error,
          bytes: outcome.bytes,
        );
        return null;
      },
    );
    return result == SyncResult.completed ? null : result;
  }

  /// Pages linked from the text of every story and from the top comments of
  /// the stories at the front of the feeds and of bookmarked ones. They come after every article, so they
  /// never hold one up.
  Future<SyncResult?> _saveLinks(_Context context) async {
    final gate = await _gate(context, pages: true);
    if (gate == SyncResult.paused) return gate;
    if (gate != null) return null;

    final rankings = await _rankings(context.settings);
    final bookmarked = await _links.bookmarkedStoryIds();
    final texts = await _links.storyTexts();
    final ids = {
      for (final list in rankings.values)
        for (final story in list.take(linkedStoryDepth)) story.id,
      ...bookmarked,
      ...texts.keys,
    };
    final plan = planLinks(
      ranked: {
        for (final entry in rankings.entries)
          entry.key: [for (final story in entry.value) story.id],
      },
      bookmarked: bookmarked,
      topComments: await _links.topComments(ids),
      storyUrls: await _links.storyUrls(ids),
      storyTexts: texts,
    );
    final needed = linksNeedingCopy(
      plan.addresses,
      await _links.existing(plan.addresses),
      _clock(),
    );
    await _links.prepare(needed);
    final linkIds = await _links.idsFor(plan.addresses);
    await _links.replaceReferences({
      for (final entry in plan.byStory.entries)
        entry.key: {for (final uri in entry.value) ?linkIds[linkKey(uri)]},
    });
    await _syncs.enqueue(context.run.id, SyncItemKind.link, [
      for (final uri in needed) ?linkIds[linkKey(uri)],
    ]);

    final pending = await _syncs.pendingStoryIds(
      context.run.id,
      SyncItemKind.link,
    );
    final result = await _each(
      context,
      pending,
      parallel: _captureParallel,
      worstCase: _pageWorstCase,
      work: (id) async {
        final open = await _gate(context, pages: true);
        if (open != null) return open;
        final outcome = await _saveLink(id, context.settings);
        if (outcome.status == null) {
          return _stopRequested ? SyncResult.stopped : SyncResult.paused;
        }
        await _syncs.markItem(
          context.run.id,
          SyncItemKind.link,
          id,
          switch (outcome.status) {
            LinkStatus.failed => SyncItemStatus.failed,
            LinkStatus.tooLarge => SyncItemStatus.tooLarge,
            _ => SyncItemStatus.done,
          },
          _clock(),
          error: outcome.error,
          bytes: outcome.bytes,
          asThread: outcome.asThread,
        );
        return null;
      },
    );
    return result == SyncResult.completed ? null : result;
  }

  Future<_LinkOutcome> _saveLink(int id, AppSettings settings) async {
    try {
      final link = await _links.byId(id);
      if (link == null) {
        return const _LinkOutcome(LinkStatus.failed, error: 'unknown link');
      }
      final itemId = hnItemId(Uri.parse(link.url));
      if (itemId != null) return await _saveLinkedThread(link.id, itemId);
      final saved = await _saver.saveLink(link, settings);
      final copy = await _links.byId(id);
      return switch (saved) {
        null => const _LinkOutcome(null),
        PageStatus.ok => _LinkOutcome(LinkStatus.ok, bytes: copy?.bytes ?? 0),
        PageStatus.tooLarge => const _LinkOutcome(LinkStatus.tooLarge),
        PageStatus.failed => _LinkOutcome(
          LinkStatus.failed,
          error: copy?.error,
        ),
      };
    } on Exception catch (e) {
      await _links.recordFailed(
        id: id,
        kind: PageKind.mhtml,
        error: '$e',
        now: _clock(),
      );
      return _LinkOutcome(LinkStatus.failed, error: '$e');
    }
  }

  /// A link to a Hacker News discussion is fetched as text instead of being
  /// captured, so it opens in the app.
  Future<_LinkOutcome> _saveLinkedThread(int linkId, int itemId) async {
    Future<_LinkOutcome> failed(String error) async {
      await _links.recordFailed(
        id: linkId,
        kind: PageKind.thread,
        error: error,
        now: _clock(),
      );
      return _LinkOutcome(LinkStatus.failed, error: error, asThread: true);
    }

    if (await _stories.locateItem(itemId) == null) {
      var thread = await _source.thread(itemId).timeout(_commentWorstCase);
      final story = thread?.containingStoryId;
      if (thread != null && thread.story.type == ItemType.comment) {
        if (story == null) return failed('comment of an unknown story');
        thread = await _source.thread(story).timeout(_commentWorstCase);
      }
      if (thread == null || thread.story.title == null) {
        return failed('not found');
      }
      await _stories.replaceThread(await _inHnOrder(thread), _clock());
    }
    await _links.recordThread(id: linkId, now: _clock());
    return const _LinkOutcome(LinkStatus.ok, asThread: true);
  }

  Future<_PageOutcome> _savePage(int id, AppSettings settings) async {
    try {
      final story = await _stories.story(id);
      if (story == null) {
        return const _PageOutcome(PageStatus.failed, error: 'unknown story');
      }
      final status = await _saver.save(story, settings);
      final copy = (await _pages.forStories([id]))[id];
      return switch (status) {
        PageStatus.ok => _PageOutcome(status, bytes: copy?.bytes ?? 0),
        PageStatus.failed => _PageOutcome(status, error: copy?.error),
        _ => _PageOutcome(status),
      };
    } on Exception catch (e) {
      return _PageOutcome(PageStatus.failed, error: '$e');
    }
  }

  Future<bool> _freshenLists() async {
    try {
      return await _lists.ensureFresh().timeout(_listsTimeout);
    } on Exception catch (e) {
      debugPrintSynchronously('filter lists failed: $e');
      return false;
    }
  }

  Future<void> _pruneStore(_Context context) async {
    try {
      final result = await _prune
          .run(
            settings: context.settings,
            now: _clock(),
            deleteFile: _files.delete,
          )
          .timeout(_pruneTimeout);
      await _syncs.recordPruned(
        context.run.id,
        copies: result.pages + result.links,
        stories: result.stories,
        bytes: result.bytes,
      );
    } on Exception catch (e) {
      debugPrintSynchronously('pruning failed: $e');
    }
  }
}
