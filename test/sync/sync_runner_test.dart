import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/prune_service.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/data/repository/retention_repository.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/sync/sync_runner.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeHn hn;
  late FakeProbe probe;
  late FakeNotifier notifier;
  late FakeLists lists;
  late FakeSaver saver;
  late SyncRunner runner;
  late StoryRepository stories;
  late SyncRepository syncs;
  late SettingsStore settings;
  late PageRepository pages;
  var now = DateTime.utc(2026, 10, 10, 5);
  var tick = Duration.zero;

  DateTime clock() => now = now.add(tick);

  setUp(() {
    now = DateTime.utc(2026, 10, 10, 5);
    tick = Duration.zero;
    db = AppDatabase(NativeDatabase.memory());
    stories = StoryRepository(db);
    syncs = SyncRepository(db);
    pages = PageRepository(db);
    settings = SettingsStore(db);
    hn = FakeHn()
      ..rankings[FeedKind.top] = [1, 2, 3]
      ..rankings[FeedKind.best] = [2, 4]
      ..rankings[FeedKind.ask] = [5]
      ..rankings[FeedKind.show] = [];
    probe = FakeProbe();
    notifier = FakeNotifier();
    lists = FakeLists();
    saver = FakeSaver(pages, clock);
    runner = SyncRunner(
      syncs: syncs,
      stories: stories,
      pages: pages,
      settings: settings,
      source: hn,
      probe: probe,
      saver: saver,
      lists: lists,
      prune: PruneService(RetentionRepository(db)),
      files: tempPageFiles(),
      notifier: notifier,
      clock: clock,
    );
  });
  tearDown(() => db.close());

  Future<List<SyncItemRow>> items(SyncItemKind kind) =>
      (db.select(db.syncItems)..where((i) => i.kind.equalsValue(kind))).get();

  Future<List<SyncRunRow>> runs() => db.select(db.syncRuns).get();

  test('a run fills the store: rankings, stories, threads and pages', () async {
    expect(await runner.run(SyncTrigger.manual), SyncResult.completed);

    final rankings = await stories.latestRankings(FeedKind.values);
    expect([for (final s in rankings[FeedKind.top]!) s.id], [1, 2, 3]);
    expect([for (final s in rankings[FeedKind.best]!) s.id], [2, 4]);
    expect((await stories.story(3))!.title, 'Story 3');
    for (final id in [1, 2, 3, 4, 5]) {
      expect(
        await stories.watchComments(id).first,
        hasLength(2),
        reason: '$id',
      );
    }
    expect(saver.saved.toSet(), {1, 2, 3, 4});
    expect(await syncs.lastSuccessfulSync(), isNotNull);
    expect(notifier.events, ['started', 'ended']);
    expect(lists.ensured, 1);
  });

  test('top-level comments are stored in HN order', () async {
    hn.kids[1] = [102, 101];
    await runner.run(SyncTrigger.manual);
    final comments = await stories.watchComments(1).first;
    expect([for (final c in comments) c.id], [102, 101]);
    expect([for (final c in comments) c.position], [0, 1]);
  });

  test(
    'on mobile data with pages off a manual run fetches text only',
    () async {
      probe.kind = ConnectionKind.mobile;
      expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
      expect(await stories.watchComments(1).first, isNotEmpty);
      expect(saver.saved, isEmpty);
      expect(lists.ensured, 0);
    },
  );

  test(
    'an automatic run on mobile data with Wi-Fi only does nothing',
    () async {
      probe.kind = ConnectionKind.mobile;
      expect(await runner.run(SyncTrigger.scheduled), SyncResult.skipped);
      expect(await runs(), isEmpty);
      expect(hn.rankingCalls, 0);
      expect(notifier.events, isEmpty);
    },
  );

  test('offline does nothing', () async {
    probe.kind = ConnectionKind.none;
    expect(await runner.run(SyncTrigger.manual), SyncResult.skipped);
    expect(await runs(), isEmpty);
  });

  test('a failing thread or page is recorded and the run carries on', () async {
    hn.failingThreads.add(3);
    saver.failing.add(2);
    expect(await runner.run(SyncTrigger.manual), SyncResult.completed);

    final threads = await items(SyncItemKind.comments);
    expect(
      threads
          .where((i) => i.status == SyncItemStatus.failed)
          .map((i) => i.storyId),
      [3],
    );
    final pageItems = await items(SyncItemKind.page);
    expect(
      pageItems
          .where((i) => i.status == SyncItemStatus.failed)
          .map((i) => i.storyId),
      [2],
    );
    expect(pageItems.where((i) => i.status == SyncItemStatus.pending), isEmpty);
    expect((await runs()).single.outcome, SyncOutcome.succeeded);
  });

  test(
    'a thread the index has not caught up with keeps its comments',
    () async {
      await runner.run(SyncTrigger.manual);
      now = now.add(const Duration(hours: 1));
      hn.unindexedThreads.add(1);
      await runner.run(SyncTrigger.manual);

      expect(await stories.watchComments(1).first, hasLength(2));
      final failed = (await items(SyncItemKind.comments))
          .where((i) => i.status == SyncItemStatus.failed);
      expect(failed.single.error, contains('not indexed'));
    },
  );

  test('one dead feed does not stop the others', () async {
    hn.failingFeeds.add(FeedKind.top);
    expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
    final rankings = await stories.latestRankings(FeedKind.values);
    expect(rankings.containsKey(FeedKind.top), isFalse);
    expect(rankings[FeedKind.best], isNotEmpty);
  });

  test('every feed failing fails the run and records why', () async {
    hn.failingFeeds.addAll(FeedKind.values);
    expect(await runner.run(SyncTrigger.manual), SyncResult.failed);
    final run = (await runs()).single;
    expect(run.outcome, SyncOutcome.failed);
    expect(run.error, 'no feed could be read');
    expect(await syncs.lastSuccessfulSync(), isNull);
    expect(notifier.events.last, 'ended');
  });

  test('story details failing everywhere fails the run', () async {
    hn.failStories = true;
    expect(await runner.run(SyncTrigger.manual), SyncResult.failed);
  });

  test('a run out of time pauses and a later one resumes it', () async {
    tick = const Duration(seconds: 30);
    final results = <SyncResult>[];
    do {
      results.add(await runner.run(SyncTrigger.manual));
    } while (results.last == SyncResult.paused && results.length < 40);

    expect(results, contains(SyncResult.paused));
    expect(results.last, SyncResult.completed);
    expect((await runs()).single.outcome, SyncOutcome.succeeded);
    expect(
      hn.rankingCalls,
      FeedKind.values.length,
      reason: 'ranking is not repeated on resume',
    );
    expect(hn.threadCalls.toSet(), hn.threadCalls.toList().toSet());
    expect(saver.saved.toSet(), {1, 2, 3, 4});
    expect(saver.saved, hasLength(4));
  });

  test('a stop request leaves the run open for the next one', () async {
    saver.onSave = (_) => runner.requestStop();
    expect(await runner.run(SyncTrigger.manual), SyncResult.stopped);
    expect((await runs()).single.finishedAt, isNull);
    expect(saver.saved, hasLength(1));
    expect(saver.cancelled, isTrue);

    saver.onSave = null;
    expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
    expect(saver.saved.toSet(), {1, 2, 3, 4});
    expect(saver.saved, hasLength(4));
  });

  test('losing Wi-Fi in the middle of the pages ends them early', () async {
    saver.onSave = (_) => probe.kind = ConnectionKind.mobile;
    expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
    expect(saver.saved, hasLength(1));
    expect(
      (await items(SyncItemKind.page))
          .where((i) => i.status == SyncItemStatus.pending),
      isNotEmpty,
    );
  });

  test('a page that is already saved is not captured again', () async {
    await pages.recordCaptured(
      storyId: 1,
      kind: PageKind.mhtml,
      relativePath: 'pages/1.mhtml',
      bytes: 5,
      now: now,
    );
    await runner.run(SyncTrigger.manual);
    expect(saver.saved, isNot(contains(1)));
  });

  test(
    'threads the user opened are refreshed although off every feed',
    () async {
      await stories.replaceThread((await hn.thread(99))!, now);
      await db
          .into(db.threadStates)
          .insert(
            ThreadStatesCompanion.insert(
              storyId: const Value(99),
              lastOpenedAt: now,
            ),
          );
      hn.threadCalls.clear();
      now = now.add(const Duration(hours: 5));
      await runner.run(SyncTrigger.manual);
      expect(hn.threadCalls, contains(99));
    },
  );

  test('the filter list trigger updates the lists and nothing else', () async {
    expect(await runner.run(SyncTrigger.filterLists), SyncResult.completed);
    expect(lists.updated, 1);
    expect(hn.rankingCalls, 0);
    expect((await runs()).single.outcome, SyncOutcome.succeeded);
  });

  test('turned-off feeds are not fetched', () async {
    await settings.set(Settings.enabledFeeds, {FeedKind.ask});
    await runner.run(SyncTrigger.manual);
    expect(hn.rankingCalls, 1);
    expect(await stories.story(1), isNull);
    expect(await stories.story(5), isNotNull);
  });
}
