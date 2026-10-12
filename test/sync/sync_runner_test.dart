import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/prune_service.dart';
import 'package:offline_hn/data/repository/link_repository.dart';
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
    saver = FakeSaver(pages, clock, LinkRepository(db));
    runner = SyncRunner(
      syncs: syncs,
      stories: stories,
      pages: pages,
      links: LinkRepository(db),
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

  group('pages linked from comments', () {
    const article = 'https://a.example/post';

    setUp(() {
      hn.firstCommentHtml[1] =
          '<a href="$article">post</a> '
          '<a href="https://www.youtube.com/watch?v=1">video</a> '
          '<a href="https://news.ycombinator.com/item?id=777">talk</a>';
      hn.firstCommentHtml[2] = '<a href="$article">again</a>';
    });

    test(
      'are saved once, after the articles, and discussions as text',
      () async {
        expect(await runner.run(SyncTrigger.manual), SyncResult.completed);

        expect(saver.savedLinks, [article]);
        expect(hn.threadCalls, contains(777));
        expect((await stories.story(777))!.title, 'Story 777');
        final links = LinkRepository(db);
        expect(
          (await links.copyFor(Uri.parse(article)))!.status,
          LinkStatus.ok,
        );
        expect(
          (await links.copyFor(
            Uri.parse('https://news.ycombinator.com/item?id=777'),
          ))!.kind,
          PageKind.thread,
        );
        final done = await items(SyncItemKind.link);
        expect(done, hasLength(2));
        expect(done.every((i) => i.status == SyncItemStatus.done), isTrue);
      },
    );

    test('a second run leaves what is saved alone', () async {
      await runner.run(SyncTrigger.manual);
      saver.savedLinks.clear();
      hn.threadCalls.clear();
      now = now.add(const Duration(days: 1));

      await runner.run(SyncTrigger.manual);

      expect(saver.savedLinks, isEmpty);
      expect(hn.threadCalls, isNot(contains(777)));
    });

    test('a failed one is recorded and retried only after a while', () async {
      saver.failingLinks.add(article);
      await runner.run(SyncTrigger.manual);
      expect(
        (await LinkRepository(db).copyFor(Uri.parse(article)))!.status,
        LinkStatus.failed,
      );

      saver.savedLinks.clear();
      now = now.add(const Duration(hours: 1));
      await runner.run(SyncTrigger.manual);
      expect(saver.savedLinks, isEmpty);

      saver.failingLinks.clear();
      now = now.add(const Duration(hours: 7));
      await runner.run(SyncTrigger.manual);
      expect(saver.savedLinks, [article]);
    });

    test('a light refresh saves none', () async {
      await runner.run(SyncTrigger.refresh);
      expect(saver.savedLinks, isEmpty);
    });
  });

  group('light refresh', () {
    test(
      'fetches text for new threads only and never captures a page',
      () async {
        expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
        hn.threadCalls.clear();
        saver.saved.clear();
        now = now.add(const Duration(hours: 2));

        expect(await runner.run(SyncTrigger.refresh), SyncResult.completed);

        expect(hn.threadCalls, isEmpty, reason: 'nothing changed');
        expect(saver.saved, isEmpty);
      },
    );

    test('a story with a new comment count is refetched', () async {
      expect(await runner.run(SyncTrigger.refresh), SyncResult.completed);
      expect(hn.threadCalls.toSet(), {1, 2, 3, 4, 5});
      expect(saver.saved, isEmpty);
      expect((await runs()).single.outcome, SyncOutcome.succeeded);
    });

    test('it does not resume an unfinished full run', () async {
      final open = await syncs.beginOrResume(SyncTrigger.manual, now);
      await syncs.setPhase(open.id, SyncPhase.pages, now);

      expect(await runner.run(SyncTrigger.refresh), SyncResult.completed);

      final all = await runs();
      expect(all, hasLength(2));
      expect(all.first.outcome, SyncOutcome.abandoned);
      expect(saver.saved, isEmpty);
    });
  });

  group('concurrency', () {
    setUp(() {
      hn.rankings[FeedKind.top] = [for (var i = 1; i <= 40; i++) i];
      hn.rankings[FeedKind.best] = [];
      hn.rankings[FeedKind.ask] = [];
    });

    test('threads are fetched four at a time and all stored', () async {
      hn.latency = const Duration(milliseconds: 5);
      await runner.run(SyncTrigger.manual);

      expect(hn.maxThreadsInFlight, 4);
      expect(
        await items(SyncItemKind.comments),
        everyElement(
          isA<SyncItemRow>().having(
            (i) => i.status,
            'status',
            SyncItemStatus.done,
          ),
        ),
      );
      expect(hn.threadCalls.toSet(), hasLength(hn.threadCalls.length));
    });

    test('pages are captured two at a time, best-ranked first', () async {
      saver.latency = const Duration(milliseconds: 5);
      await runner.run(SyncTrigger.manual);

      expect(saver.maxInFlight, 2);
      final linked = [
        for (var i = 1; i <= 40; i++)
          if (i % 5 != 0) i,
      ];
      expect(saver.saved, linked.take(60).toList());
    });

    test('a stop in the middle leaves a clean cut and resumes', () async {
      saver.latency = const Duration(milliseconds: 5);
      saver.onSave = (id) {
        if (id == 9) runner.requestStop();
      };
      expect(await runner.run(SyncTrigger.manual), SyncResult.stopped);

      final done = {
        for (final item in await items(SyncItemKind.page))
          if (item.status == SyncItemStatus.done) item.storyId,
      };
      expect(done, isNotEmpty);
      expect(done.length, lessThan(32));
      expect(
        done.every((id) => id <= 10),
        isTrue,
        reason: 'nothing past the cut was started',
      );

      saver.onSave = null;
      saver.cancelled = false;
      expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
      for (final id in done) {
        expect(saver.saved.where((s) => s == id), hasLength(1));
      }
      expect((await items(SyncItemKind.page)).map((i) => i.status).toSet(), {
        SyncItemStatus.done,
      });
    });
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
    expect(saver.saved.length, inInclusiveRange(1, 2));
    expect(saver.cancelled, isTrue);

    saver.onSave = null;
    expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
    expect(saver.saved.toSet(), {1, 2, 3, 4});
    expect(saver.saved, hasLength(4));
  });

  test(
    'a start after the working process died does nothing but ask for a retry',
    () async {
      saver.onSave = (_) => runner.requestStop();
      await runner.run(SyncTrigger.manual);
      final run = (await runs()).single;
      await syncs.setExecuting(run.id, value: true);
      final fetched = saver.saved.length;
      final rankings = hn.rankingCalls;
      notifier.events.clear();

      saver.onSave = null;
      expect(await runner.run(SyncTrigger.manual), SyncResult.interrupted);
      expect(SyncResult.interrupted.wantsRetry, isTrue);
      expect(saver.saved, hasLength(fetched));
      expect(hn.rankingCalls, rankings);
      expect(
        notifier.events,
        isEmpty,
        reason: 'no notification flashes for it',
      );

      expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
      expect(saver.saved.toSet(), {1, 2, 3, 4});
      expect((await runs()).single.outcome, SyncOutcome.succeeded);
    },
  );

  test('stopping now hands the run back before the checkpoint', () async {
    late Future<void> stopped;
    saver.onSave = (_) => stopped = runner.stopNow();
    expect(await runner.run(SyncTrigger.manual), SyncResult.stopped);
    await stopped;
    final run = (await runs()).single;
    expect(run.executing, isFalse);
    expect(run.finishedAt, isNull);
  });

  test('only a finished run is not retried', () {
    final retried = [
      for (final result in SyncResult.values)
        if (result.wantsRetry) result,
    ];
    expect(retried, [
      SyncResult.paused,
      SyncResult.stopped,
      SyncResult.interrupted,
    ]);
  });

  test('a run that pauses or stops is not left marked as running', () async {
    saver.onSave = (_) => runner.requestStop();
    await runner.run(SyncTrigger.manual);
    expect((await runs()).single.executing, isFalse);
  });

  test('losing Wi-Fi in the middle of the pages ends them early', () async {
    saver.onSave = (_) => probe.kind = ConnectionKind.mobile;
    expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
    expect(saver.saved.length, inInclusiveRange(1, 2));
    expect(
      (await items(SyncItemKind.page))
          .where((i) => i.status == SyncItemStatus.pending),
      isNotEmpty,
    );
  });

  test(
    'no connection at all in the pages phase pauses the run to be retried',
    () async {
      saver.onSave = (_) => probe.kind = ConnectionKind.none;
      expect(await runner.run(SyncTrigger.manual), SyncResult.paused);
      expect((await runs()).single.finishedAt, isNull);

      probe.kind = ConnectionKind.wifi;
      saver.onSave = null;
      expect(await runner.run(SyncTrigger.manual), SyncResult.completed);
      expect(saver.saved.toSet(), {1, 2, 3, 4});
    },
  );

  test(
    'a page the saver could not attempt for want of a network pauses',
    () async {
      saver.unreachable.add(2);
      expect(await runner.run(SyncTrigger.manual), SyncResult.paused);
      expect(
        (await items(SyncItemKind.page))
            .where((i) => i.storyId == 2)
            .single
            .status,
        SyncItemStatus.pending,
      );
    },
  );

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

  test('turned-off feeds are not fetched', () async {
    await settings.set(Settings.enabledFeeds, {FeedKind.ask});
    await runner.run(SyncTrigger.manual);
    expect(hn.rankingCalls, 1);
    expect(await stories.story(1), isNull);
    expect(await stories.story(5), isNotNull);
  });
}
