import 'dart:io';

import 'package:offline_hn/data/api/hn_reader.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/repository/link_repository.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/sync/connection_probe.dart';
import 'package:offline_hn/sync/filter_list_sync.dart';
import 'package:offline_hn/sync/page_files.dart';
import 'package:offline_hn/sync/page_saver.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/sync/sync_notifier.dart';
import 'package:offline_hn/sync/work_queue.dart';

class FakeHn implements HnReader {
  final rankings = <FeedKind, List<int>>{};
  final failingFeeds = <FeedKind>{};
  final failingThreads = <int>{};
  final unindexedThreads = <int>{};
  final kids = <int, List<int>>{};

  /// Replaces the text of the story's first comment in HN order.
  final firstCommentHtml = <int, String>{};
  var failStories = false;
  var rankingCalls = 0;
  final threadCalls = <int>[];
  void Function(int id)? onThread;
  var latency = Duration.zero;
  var _threadsInFlight = 0;
  var maxThreadsInFlight = 0;

  @override
  Future<List<int>> ranking(FeedKind kind) async {
    rankingCalls++;
    if (failingFeeds.contains(kind)) throw Exception('feed down');
    return rankings[kind] ?? const [];
  }

  @override
  Future<List<RemoteStory>> stories(List<int> ids) async {
    if (failStories) throw Exception('search down');
    return [
      for (final id in ids)
        RemoteStory(
          id: id,
          title: 'Story $id',
          url: id % 5 == 0 ? null : Uri.parse('https://example.com/$id'),
          points: id,
        ),
    ];
  }

  @override
  Future<RemoteThread?> thread(int id) async {
    threadCalls.add(id);
    onThread?.call(id);
    _threadsInFlight++;
    if (_threadsInFlight > maxThreadsInFlight) {
      maxThreadsInFlight = _threadsInFlight;
    }
    try {
      await Future<void>.delayed(latency);
    } finally {
      _threadsInFlight--;
    }
    if (failingThreads.contains(id)) throw Exception('thread down');
    final story = RemoteStory(
      id: id,
      title: 'Story $id',
      url: id % 5 == 0 ? null : Uri.parse('https://example.com/$id'),
      commentCount: 2,
    );
    if (unindexedThreads.contains(id)) {
      return RemoteThread(story: story, comments: const []);
    }
    return RemoteThread(
      story: story,
      comments: [
        RemoteComment(id: id * 100 + 1, parentId: id, text: 'older'),
        RemoteComment(
          id: id * 100 + 2,
          parentId: id,
          text: firstCommentHtml[id] ?? 'newer',
        ),
      ],
    );
  }

  @override
  Future<List<int>> rankedTopLevel(int storyId) async {
    final ranked = kids[storyId];
    if (ranked != null) return ranked;
    return [storyId * 100 + 2, storyId * 100 + 1];
  }
}

class FakeProbe implements ConnectionProbe {
  FakeProbe([this.kind = ConnectionKind.wifi]);

  ConnectionKind kind;

  @override
  Future<ConnectionKind> current() async => kind;

  @override
  Stream<ConnectionKind> get changes => const Stream.empty();
}

class FakeNotifier implements RunNotifier {
  final events = <String>[];

  @override
  Future<void> appLeft() async => events.add('left');

  @override
  Future<void> appOpened() async => events.add('opened');

  @override
  Future<void> runEnded() async => events.add('ended');

  @override
  Future<void> runStarted() async => events.add('started');
}

class FakeLists implements FilterListSync {
  var ensured = 0;

  @override
  String get directoryPath => '/lists';

  @override
  Future<bool> ensureFresh() async {
    ensured++;
    return true;
  }
}

/// Records pages the way the real saver does, without a WebView.
class FakeSaver implements StoryPageSaver {
  FakeSaver(this.pages, this.clock, this.links);

  final PageRepository pages;
  final LinkRepository links;
  final savedLinks = <String>[];
  final failingLinks = <String>{};
  final DateTime Function() clock;
  final saved = <int>[];
  final failing = <int>{};
  final unreachable = <int>{};
  void Function(int id)? onSave;
  var cancelled = false;
  var latency = Duration.zero;
  var _inFlight = 0;
  var maxInFlight = 0;

  @override
  void cancel() => cancelled = true;

  @override
  Future<PageStatus?> save(StoryRow story, AppSettings settings) async {
    saved.add(story.id);
    onSave?.call(story.id);
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    try {
      await Future<void>.delayed(latency);
    } finally {
      _inFlight--;
    }
    if (cancelled && latency > Duration.zero) return null;
    if (unreachable.contains(story.id)) return null;
    if (failing.contains(story.id)) {
      await pages.recordFailed(
        storyId: story.id,
        kind: PageKind.mhtml,
        error: 'boom',
        now: clock(),
      );
      return PageStatus.failed;
    }
    await pages.recordCaptured(
      storyId: story.id,
      kind: PageKind.mhtml,
      relativePath: 'pages/${story.id}.mhtml',
      bytes: 1000,
      now: clock(),
    );
    return PageStatus.ok;
  }

  @override
  Future<PageStatus?> saveLink(LinkCopyRow link, AppSettings settings) async {
    savedLinks.add(link.url);
    if (failingLinks.contains(link.url)) {
      await links.recordFailed(
        id: link.id,
        kind: PageKind.mhtml,
        error: 'boom',
        now: clock(),
      );
      return PageStatus.failed;
    }
    await links.recordCaptured(
      id: link.id,
      kind: PageKind.mhtml,
      relativePath: 'pages/links/${link.id}.mhtml',
      bytes: 1000,
      now: clock(),
    );
    return PageStatus.ok;
  }
}

class FakeQueue implements WorkQueue {
  final syncs = <(SyncTrigger, NetworkRequirement)>[];
  final daily = <(Duration, NetworkRequirement)>[];
  final periodic = <(Duration, NetworkRequirement)>[];
  var periodicCancelled = 0;
  var syncCancelled = 0;

  @override
  Future<void> cancelSync() async => syncCancelled++;

  @override
  Future<void> cancelPeriodic() async => periodicCancelled++;

  @override
  Future<void> enqueueSync(
    SyncTrigger trigger,
    NetworkRequirement network,
  ) async => syncs.add((trigger, network));

  @override
  Future<void> scheduleDaily(
    Duration delay,
    NetworkRequirement network, {
    bool afterRun = false,
  }) async => daily.add((delay, network));

  @override
  Future<void> schedulePeriodic(
    Duration every,
    NetworkRequirement network,
  ) async => periodic.add((every, network));
}

PageFiles tempPageFiles() =>
    PageFiles(Directory.systemTemp.createTempSync('offline_hn_pages'));
