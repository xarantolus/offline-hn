import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:offline_hn/data/api/hn_reader.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/comment_tree.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
import 'package:offline_hn/data/policy/network_policy.dart';
import 'package:offline_hn/data/policy/sync_scope.dart';
import 'package:offline_hn/data/prune_service.dart';
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

enum SyncResult {
  /// Every step ran.
  completed,

  /// Out of time; the run is open and a continuation picks it up.
  paused,

  /// Told to stop; the run is open and the next one resumes it.
  stopped,

  /// No usable connection for this trigger.
  skipped,

  /// Nothing could be fetched.
  failed,
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

/// The only code that fetches. Every trigger, in the foreground or the
/// background, ends up here, and everything it learns goes to the database.
///
/// A run is a list of phases with a checkpoint per item, so it can stop
/// anywhere and the next call carries on: ranking, story details, comment
/// threads, saved pages, pruning.
class SyncRunner {
  SyncRunner({
    required this._syncs,
    required this._stories,
    required this._pages,
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

  final SyncRepository _syncs;
  final StoryRepository _stories;
  final PageRepository _pages;
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

  /// Ends the run at the next checkpoint and abandons a page being captured.
  void requestStop() {
    _stopRequested = true;
    _saver.cancel();
  }

  Future<SyncResult> run(SyncTrigger trigger) async {
    _stopRequested = false;
    final started = _clock();
    final settings = await _settings.load();
    if (await _allowance(trigger, settings) == SyncAllowance.nothing) {
      return SyncResult.skipped;
    }
    if (trigger == SyncTrigger.filterLists) await _updateLists();

    final run = await _syncs.beginOrResume(trigger, started);
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
      await _notifier.runEnded();
    }
  }

  Future<SyncResult> _execute(_Context context) async {
    final run = context.run;
    if (run.trigger == SyncTrigger.filterLists) {
      await _syncs.finish(run.id, SyncOutcome.succeeded, _clock());
      return SyncResult.completed;
    }

    var phase = run.phase;
    if (phase == SyncPhase.ranking) {
      await _rank(context);
      await _syncs.setPhase(run.id, SyncPhase.metadata, _clock());
      phase = SyncPhase.metadata;
    }
    if (phase == SyncPhase.metadata) {
      final stop = await _metadata(context);
      if (stop != null) return stop;
      await _queueComments(context);
      await _syncs.setPhase(run.id, SyncPhase.comments, _clock());
      phase = SyncPhase.comments;
    }
    if (phase == SyncPhase.comments) {
      final stop = await _comments(context);
      if (stop != null) return stop;
      await _syncs.setPhase(run.id, SyncPhase.pages, _clock());
    }
    final stop = await _savePages(context);
    if (stop != null) return stop;

    await _pruneStore(context.settings);
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
    var batches = 0;
    var failed = 0;
    for (var i = 0; i < ids.length; i += _searchBatch) {
      final stop = _checkpoint(context, _metadataWorstCase);
      if (stop != null) return stop;
      batches++;
      final batch = ids.sublist(i, (i + _searchBatch).clamp(0, ids.length));
      try {
        final found = await _source.stories(batch).timeout(_metadataWorstCase);
        await _stories.upsertStories(found, _clock());
      } on Exception catch (e) {
        failed++;
        debugPrintSynchronously('story details failed: $e');
      }
      await _syncs.heartbeat(context.run.id, _clock());
    }
    if (batches > 0 && failed == batches) {
      throw const SyncFailure('story details could not be fetched');
    }
    return null;
  }

  Future<void> _queueComments(_Context context) async {
    final targets = selectCommentTargets(
      feedOrder: _idsByRank(await _rankings(context.settings)),
      stored: await _stories.threadCandidates(),
      now: _clock(),
    );
    await _syncs.enqueue(context.run.id, SyncItemKind.comments, targets);
  }

  Future<SyncResult?> _comments(_Context context) async {
    final pending = await _syncs.pendingStoryIds(
      context.run.id,
      SyncItemKind.comments,
    );
    for (final id in pending) {
      final stop = _checkpoint(context, _commentWorstCase);
      if (stop != null) return stop;
      final error = await _refreshThread(id);
      await _syncs.markItem(
        context.run.id,
        SyncItemKind.comments,
        id,
        error == null ? SyncItemStatus.done : SyncItemStatus.failed,
        _clock(),
        error: error,
      );
    }
    return null;
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
    if (thread == null) return null;
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

  Future<SyncResult?> _savePages(_Context context) async {
    if (await _allowance(context.trigger, context.settings) !=
        SyncAllowance.textAndPages) {
      return null;
    }
    await _freshenLists();

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
    for (final id in pending) {
      final stop = _checkpoint(context, _pageWorstCase);
      if (stop != null) return stop;
      if (await _allowance(context.trigger, context.settings) !=
          SyncAllowance.textAndPages) {
        return null;
      }
      final outcome = await _savePage(id, context.settings);
      if (outcome.status == null) return SyncResult.stopped;
      await _syncs.markItem(
        context.run.id,
        SyncItemKind.page,
        id,
        outcome.status == PageStatus.failed
            ? SyncItemStatus.failed
            : SyncItemStatus.done,
        _clock(),
        error: outcome.error,
      );
    }
    return null;
  }

  Future<({PageStatus? status, String? error})> _savePage(
    int id,
    AppSettings settings,
  ) async {
    try {
      final story = await _stories.story(id);
      if (story == null) {
        return (status: PageStatus.failed, error: 'unknown story');
      }
      return (status: await _saver.save(story, settings), error: null);
    } on Exception catch (e) {
      return (status: PageStatus.failed, error: '$e');
    }
  }

  Future<void> _freshenLists() async {
    try {
      await _lists.ensureFresh().timeout(_listsTimeout);
    } on Exception catch (e) {
      debugPrintSynchronously('filter lists failed: $e');
    }
  }

  Future<void> _updateLists() async {
    try {
      await _lists.updateNow().timeout(_listsTimeout);
    } on Exception catch (e) {
      debugPrintSynchronously('filter lists failed: $e');
    }
  }

  Future<void> _pruneStore(AppSettings settings) async {
    try {
      await _prune
          .run(settings: settings, now: _clock(), deleteFile: _files.delete)
          .timeout(_pruneTimeout);
    } on Exception catch (e) {
      debugPrintSynchronously('pruning failed: $e');
    }
  }
}
