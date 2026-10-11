import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/api/algolia_json.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/daily_time.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/filter_list_status.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/model/viewer_kind.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/data/prune_service.dart';
import 'package:offline_hn/data/repository/retention_repository.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';
import 'package:offline_hn/data/repository/thread_state_repository.dart';
import 'package:page_capture/filters.dart';

import 'fixtures.dart';

Duration _utc(DateTime utc) => Duration.zero;

RemoteStory _story(int id, {String? title, int? points, Uri? url}) =>
    RemoteStory(
      id: id,
      title: title ?? 'Story $id',
      points: points,
      url: url ?? Uri.parse('https://www.example.com/$id'),
    );

void main() {
  late AppDatabase db;
  late StoryRepository stories;
  late PageRepository pages;
  final t0 = DateTime.utc(2026, 10, 10, 6);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    stories = StoryRepository(db);
    pages = PageRepository(db);
  });
  tearDown(() => db.close());

  group('stories', () {
    test('an update keeps the user flags and first sighting', () async {
      await stories.upsertStories([_story(1, points: 10)], t0);
      await stories.setSaved(1, value: true);
      await stories.setRead(1, value: true);
      final later = t0.add(const Duration(hours: 5));
      await stories.upsertStories([_story(1, points: 99)], later);

      final row = (await stories.watchStory(1).first)!;
      expect(row.points, 99);
      expect(row.saved, isTrue);
      expect(row.read, isTrue);
      expect(row.firstSeen.toUtc(), t0);
      expect(row.lastSeen.toUtc(), later);
      expect(row.domain, 'example.com');
    });

    test('a story without a title is not stored', () async {
      await stories.upsertStories([const RemoteStory(id: 5)], t0);
      expect(await stories.watchStory(5).first, isNull);
    });

    test('missing counts in a later fetch do not erase known ones', () async {
      await stories.upsertStories([
        const RemoteStory(id: 1, title: 't', points: 5, commentCount: 7),
      ], t0);
      await stories.upsertStories([const RemoteStory(id: 1, title: 't')], t0);
      final row = (await stories.watchStory(1).first)!;
      expect(row.points, 5);
      expect(row.commentCount, 7);
    });
  });

  group('feed by day', () {
    final day = dayBoundsUtc(const LocalDay(2026, 10, 10), offsetAt: _utc);

    test('orders by the best rank reached that day', () async {
      await stories.upsertStories([_story(1), _story(2), _story(3)], t0);
      await stories.recordSnapshot(FeedKind.top, [1, 2, 3], t0);
      await stories.recordSnapshot(FeedKind.top, [
        3,
        1,
        2,
      ], t0.add(const Duration(hours: 2)));

      final feed = await stories.watchFeed(FeedKind.top, day).first;
      expect(feed.map((e) => e.story.id), [1, 3, 2]);
      expect(feed.map((e) => e.bestRank), [1, 1, 2]);
    });

    test('only the asked feed and the asked day show', () async {
      await stories.upsertStories([_story(1), _story(2), _story(3)], t0);
      await stories.recordSnapshot(FeedKind.top, [1], t0);
      await stories.recordSnapshot(FeedKind.ask, [2], t0);
      await stories.recordSnapshot(FeedKind.top, [
        3,
      ], t0.subtract(const Duration(days: 1)));

      final feed = await stories.watchFeed(FeedKind.top, day).first;
      expect(feed.map((e) => e.story.id), [1]);
    });

    test('hidden stories are left out and pages ride along', () async {
      await stories.upsertStories([_story(1), _story(2)], t0);
      await stories.recordSnapshot(FeedKind.top, [1, 2], t0);
      await stories.setHidden(2, value: true);
      await pages.recordCaptured(
        storyId: 1,
        kind: PageKind.mhtml,
        relativePath: 'p/1.mhtml',
        bytes: 10,
        now: t0,
      );

      final feed = await stories.watchFeed(FeedKind.top, day).first;
      expect(feed.map((e) => e.story.id), [1]);
      expect(feed.single.page!.bytes, 10);
    });

    test('the stream updates when a snapshot lands', () async {
      await stories.upsertStories([_story(1)], t0);
      final emissions = stories
          .watchFeed(FeedKind.top, day)
          .map((f) => f.length);
      final expectation = expectLater(emissions, emitsInOrder([0, 1]));
      await Future<void>.delayed(Duration.zero);
      await stories.recordSnapshot(FeedKind.top, [1], t0);
      await expectation;
    });

    test('stored days come from snapshots in the given offset', () async {
      await stories.upsertStories([_story(1)], t0);
      await stories.recordSnapshot(FeedKind.top, [
        1,
      ], DateTime.utc(2026, 10, 10, 23));
      await stories.recordSnapshot(FeedKind.top, [
        1,
      ], DateTime.utc(2026, 10, 8, 12));
      await stories.recordSnapshot(FeedKind.ask, [
        1,
      ], DateTime.utc(2026, 10, 1, 12));

      expect(
        await stories.watchStoredDays(FeedKind.top, offsetAt: _utc).first,
        [const LocalDay(2026, 10, 10), const LocalDay(2026, 10, 8)],
      );
      expect(
        await stories
            .watchStoredDays(
              FeedKind.top,
              offsetAt: (_) => const Duration(hours: 9),
            )
            .first,
        [const LocalDay(2026, 10, 11), const LocalDay(2026, 10, 8)],
      );
    });
  });

  group('threads', () {
    test('the stored comments come back in display order with depth', () async {
      final thread = parseThread(fixture('algolia_item.json'))!;
      await stories.replaceThread(thread, t0);

      final comments = await stories.watchComments(thread.story.id).first;
      expect(comments.length, thread.story.commentCount);
      expect(comments.first.depth, 0);
      expect(
        comments.map((c) => c.position),
        List.generate(comments.length, (i) => i),
      );
      expect(comments.any((c) => c.depth > 0), isTrue);
      final story = (await stories.watchStory(thread.story.id).first)!;
      expect(story.commentsFetchedAt!.toUtc(), t0);
    });

    test('a refresh replaces the old tree', () async {
      RemoteThread tree(List<int> ids) => RemoteThread(
        story: _story(1),
        comments: [for (final id in ids) RemoteComment(id: id, text: 'x')],
      );
      await stories.replaceThread(tree([10, 11, 12]), t0);
      await stories.replaceThread(tree([11, 13]), t0);
      final comments = await stories.watchComments(1).first;
      expect(comments.map((c) => c.id), [11, 13]);
    });

    test('an item id is found as a story or as a comment of one', () async {
      await stories.replaceThread(
        RemoteThread(
          story: _story(1),
          comments: [const RemoteComment(id: 10, text: 'x')],
        ),
        t0,
      );
      expect(await stories.locateItem(1), (storyId: 1, commentId: null));
      expect(await stories.locateItem(10), (storyId: 1, commentId: 10));
      expect(await stories.locateItem(77), isNull);
    });

    test(
      'thread state: opening advances the marker, never backwards',
      () async {
        final states = ThreadStateRepository(db);
        final seen = DateTime.utc(2026, 10, 9, 10);
        await states.markOpened(1, t0, seenUpToCommentTime: seen);
        await states.markOpened(
          1,
          t0.add(const Duration(hours: 1)),
          seenUpToCommentTime: seen.subtract(const Duration(hours: 5)),
        );
        final row = (await states.watch(1).first)!;
        expect(row.seenUpToCommentTime!.toUtc(), seen);
        expect(row.lastOpenedAt.toUtc(), t0.add(const Duration(hours: 1)));
      },
    );

    test('collapsing keeps the marker and does not count as opening', () async {
      final states = ThreadStateRepository(db);
      final seen = DateTime.utc(2026, 10, 9, 10);
      await states.markOpened(1, t0, seenUpToCommentTime: seen);
      await states.setCollapsed(1, {4, 9}, t0.add(const Duration(days: 1)));
      final row = (await states.watch(1).first)!;
      expect(row.collapsed, {4, 9});
      expect(row.seenUpToCommentTime!.toUtc(), seen);
      expect(row.lastOpenedAt.toUtc(), t0);

      await states.markOpened(1, t0.add(const Duration(days: 2)));
      expect((await states.watch(1).first)!.collapsed, {4, 9});
    });
  });

  group('page copies', () {
    test('total counts only stored pages', () async {
      await pages.recordCaptured(
        storyId: 1,
        kind: PageKind.mhtml,
        relativePath: 'a',
        bytes: 100,
        now: t0,
      );
      await pages.recordCaptured(
        storyId: 2,
        kind: PageKind.pdf,
        relativePath: 'b',
        bytes: 50,
        now: t0,
      );
      await pages.recordTooLarge(storyId: 3, kind: PageKind.mhtml, now: t0);
      await pages.recordFailed(
        storyId: 4,
        kind: PageKind.mhtml,
        error: 'timeout',
        now: t0,
      );
      expect(await pages.watchTotalBytes().first, 150);
      expect((await pages.watch(4).first)!.error, 'timeout');
      expect((await pages.watch(3).first)!.status, PageStatus.tooLarge);
    });

    test('with nothing stored the total is zero', () async {
      expect(await pages.watchTotalBytes().first, 0);
    });

    test('a retry after a failure replaces the failed record', () async {
      await pages.recordFailed(
        storyId: 1,
        kind: PageKind.mhtml,
        error: 'x',
        now: t0,
      );
      await pages.recordCaptured(
        storyId: 1,
        kind: PageKind.mhtml,
        relativePath: 'a',
        bytes: 5,
        now: t0,
      );
      final row = (await pages.watch(1).first)!;
      expect(row.status, PageStatus.ok);
      expect(row.error, isNull);
    });
  });

  group('settings', () {
    test('an empty database yields the documented defaults', () async {
      final settings = await SettingsStore(db).load();
      expect(settings.dailyTime, const DailyTime(5, 0));
      expect(settings.intervalHours, 2);
      expect(settings.wifiOnly, isTrue);
      expect(settings.pagesOnMobile, isFalse);
      expect(settings.pageBudgetBytes, 1024 * 1024 * 1024);
      expect(settings.enabledFeeds, FeedKind.values.toSet());
      expect(settings.viewer, ViewerKind.customTab);
      expect(settings.adBlocking, isTrue);
      expect(settings.rejectCookiePopups, isTrue);
      expect(settings.filterListUrls, FilterSources.defaultLists);
      expect(settings.filterListStatus, isEmpty);
      expect(settings.textRetentionDays, 3);
    });

    test(
      'values round trip, including interval off and a feed subset',
      () async {
        final store = SettingsStore(db);
        await store.set(Settings.intervalHours, null);
        await store.set(Settings.dailyTime, const DailyTime(7, 5));
        await store.set(Settings.enabledFeeds, {FeedKind.ask, FeedKind.show});
        await store.set(Settings.viewer, ViewerKind.inApp);
        await store.set(Settings.commentTextScale, 1.25);
        final updated = DateTime.utc(2026, 10, 10, 12, 30);
        await store.set(Settings.filterListUrls, ['https://x.example/l.txt']);
        await store.set(Settings.filterListStatus, {
          'https://x.example/l.txt': FilterListStatus(
            updatedAt: updated,
            networkRules: 7,
            error: 'late',
          ),
        });
        final loaded = await store.load();
        expect(loaded.filterListUrls, ['https://x.example/l.txt']);
        final status = loaded.filterListStatus['https://x.example/l.txt']!;
        expect(status.updatedAt, updated);
        expect(status.networkRules, 7);
        expect(status.error, 'late');
        expect(loaded.intervalHours, isNull);
        expect(loaded.dailyTime, const DailyTime(7, 5));
        expect(loaded.enabledFeeds, {FeedKind.ask, FeedKind.show});
        expect(loaded.viewer, ViewerKind.inApp);
        expect(loaded.commentTextScale, 1.25);
      },
    );

    test('an unreadable stored value throws instead of hiding', () async {
      final bad = {
        Settings.dailyTime.key: '99:99',
        Settings.wifiOnly.key: 'maybe',
        Settings.enabledFeeds.key: 'top,nope',
        Settings.filterListUrls.key: '[1]',
        Settings.filterListStatus.key: '{"u":{"networkRules":"7"}}',
      };
      for (final entry in bad.entries) {
        await db.delete(db.settingEntries).go();
        await db
            .into(db.settingEntries)
            .insert(
              SettingEntriesCompanion.insert(
                key: entry.key,
                value: entry.value,
              ),
            );
        await expectLater(SettingsStore(db).load(), throwsA(anything));
      }
    });

    test('a missing value is the default', () async {
      await db
          .into(db.settingEntries)
          .insert(
            SettingEntriesCompanion.insert(
              key: Settings.wifiOnly.key,
              value: 'false',
            ),
          );
      final loaded = await SettingsStore(db).load();
      expect(loaded.wifiOnly, isFalse);
      expect(loaded.dailyTime, const DailyTime(5, 0));
    });

    test('watch reports a change', () async {
      final store = SettingsStore(db);
      final seen = store.watch().map((s) => s.wifiOnly);
      final expectation = expectLater(seen, emitsInOrder([true, false]));
      await Future<void>.delayed(Duration.zero);
      await store.set(Settings.wifiOnly, false);
      await expectation;
    });
  });

  group('sync runs', () {
    late SyncRepository sync;
    setUp(() => sync = SyncRepository(db));

    test('an unfinished recent run is resumed with its queue', () async {
      final run = await sync.beginOrResume(SyncTrigger.scheduled, t0);
      await sync.enqueue(run.id, SyncItemKind.comments, [1, 2, 3]);
      await sync.markItem(
        run.id,
        SyncItemKind.comments,
        1,
        SyncItemStatus.done,
        t0,
      );

      final again = await sync.beginOrResume(
        SyncTrigger.manual,
        t0.add(const Duration(minutes: 10)),
      );
      expect(again.id, run.id);
      expect(again.trigger, SyncTrigger.scheduled);
      expect(await sync.pendingStoryIds(run.id, SyncItemKind.comments), [2, 3]);
    });

    test('a stale unfinished run is abandoned for a new one', () async {
      final old = await sync.beginOrResume(SyncTrigger.scheduled, t0);
      final fresh = await sync.beginOrResume(
        SyncTrigger.periodic,
        t0.add(const Duration(hours: 8)),
      );
      expect(fresh.id, isNot(old.id));
      expect(fresh.trigger, SyncTrigger.periodic);
      final abandoned = await (db.select(
        db.syncRuns,
      )..where((r) => r.id.equals(old.id))).getSingle();
      expect(abandoned.outcome, SyncOutcome.abandoned);
      expect(await sync.lastSuccessfulSync(), isNull);
    });

    test('enqueueing the same item twice keeps one entry', () async {
      final run = await sync.beginOrResume(SyncTrigger.manual, t0);
      await sync.enqueue(run.id, SyncItemKind.page, [7]);
      await sync.markItem(
        run.id,
        SyncItemKind.page,
        7,
        SyncItemStatus.failed,
        t0,
        error: 'x',
      );
      await sync.enqueue(run.id, SyncItemKind.page, [7]);
      expect(await sync.pendingStoryIds(run.id, SyncItemKind.page), isEmpty);
    });

    test('last successful sync ignores failed and abandoned runs', () async {
      final ok = await sync.beginOrResume(SyncTrigger.manual, t0);
      await sync.finish(
        ok.id,
        SyncOutcome.succeeded,
        t0.add(const Duration(minutes: 3)),
      );
      final bad = await sync.beginOrResume(
        SyncTrigger.manual,
        t0.add(const Duration(hours: 1)),
      );
      await sync.finish(
        bad.id,
        SyncOutcome.failed,
        t0.add(const Duration(hours: 1, minutes: 1)),
        error: 'offline',
      );
      expect(
        (await sync.lastSuccessfulSync())!.toUtc(),
        t0.add(const Duration(minutes: 3)),
      );
    });

    test('progress follows the queue and ends with the run', () async {
      final progress = sync.watchProgress();
      final values = <String>[];
      final sub = progress.listen(
        (p) => values.add(
          p == null ? 'idle' : '${p.phase.name} ${p.done}/${p.total}',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final run = await sync.beginOrResume(SyncTrigger.manual, t0);
      await sync.setPhase(run.id, SyncPhase.comments, t0);
      await sync.enqueue(run.id, SyncItemKind.comments, [1, 2]);
      await sync.markItem(
        run.id,
        SyncItemKind.comments,
        1,
        SyncItemStatus.done,
        t0,
      );
      await sync.finish(run.id, SyncOutcome.succeeded, t0);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(values.first, 'idle');
      expect(values, contains('comments 0/2'));
      expect(values, contains('comments 1/2'));
      expect(values.last, 'idle');
    });
  });

  group('what a run reads back', () {
    test(
      'the newest snapshot of each feed, in rank order, with urls',
      () async {
        await stories.upsertStories([
          _story(1),
          _story(2, url: Uri.parse('https://b.example')),
          const RemoteStory(id: 3, title: 'Ask'),
        ], t0);
        await stories.recordSnapshot(FeedKind.top, [9, 10], t0);
        await stories.recordSnapshot(FeedKind.top, [
          2,
          1,
          3,
          77,
        ], t0.add(const Duration(hours: 1)));
        await stories.setHidden(1, value: true);

        final rankings = await stories.latestRankings([
          FeedKind.top,
          FeedKind.ask,
        ]);

        expect(rankings.keys, [FeedKind.top]);
        final top = rankings[FeedKind.top]!;
        expect([for (final s in top) s.id], [2, 1, 3, 77]);
        expect(top[0].url, 'https://b.example');
        expect(top[1].url, isNull, reason: 'hidden');
        expect(top[2].url, isNull, reason: 'no link');
        expect(top[3].url, isNull, reason: 'not fetched yet');
      },
    );

    test('thread candidates carry fetch time, opening and saving', () async {
      await stories.upsertStories([_story(1), _story(2)], t0);
      await stories.replaceThread(
        RemoteThread(story: _story(1), comments: const []),
        t0,
      );
      await stories.setSaved(2, value: true);
      await ThreadStateRepository(db)
          .markOpened(1, t0.add(const Duration(hours: 2)));

      final byId = {
        for (final c in await stories.threadCandidates()) c.storyId: c,
      };
      expect(byId[1]!.commentsFetchedAt!.toUtc(), t0);
      expect(byId[1]!.lastOpenedAt!.toUtc(), t0.add(const Duration(hours: 2)));
      expect(byId[2]!.saved, isTrue);
      expect(byId[2]!.commentsFetchedAt, isNull);
    });

    test('every checkpoint is a sign of life', () async {
      final sync = SyncRepository(db);
      final run = await sync.beginOrResume(SyncTrigger.manual, t0);
      await sync.enqueue(run.id, SyncItemKind.page, [1]);
      final later = t0.add(const Duration(minutes: 7));
      await sync.markItem(
        run.id,
        SyncItemKind.page,
        1,
        SyncItemStatus.done,
        later,
      );

      final progress = (await sync.watchProgress().first)!;
      expect(progress.heartbeatAt.toUtc(), later);
      expect(progress.done, 1);
    });
  });

  group('pruning end to end', () {
    test('applies the policies and reports the files to delete', () async {
      final now = DateTime.utc(2026, 10, 20, 12);
      final old = now.subtract(const Duration(days: 10));
      await stories.upsertStories([
        _story(1),
        _story(2),
        _story(3),
        _story(4),
      ], old);
      await stories.setSaved(3, value: true);
      await stories.recordSnapshot(FeedKind.top, [4], old);
      await pages.recordCaptured(
        storyId: 1,
        kind: PageKind.mhtml,
        relativePath: 'one.mhtml',
        bytes: 600,
        now: old,
      );
      await pages.recordCaptured(
        storyId: 2,
        kind: PageKind.mhtml,
        relativePath: 'two.mhtml',
        bytes: 600,
        now: old.add(const Duration(days: 1)),
      );
      await ThreadStateRepository(db).markOpened(2, old);

      final settings = AppSettings.fromRaw({
        Settings.pageBudgetBytes.key: '700',
      });
      final deleted = <String>[];
      final result = await PruneService(RetentionRepository(db)).run(
        settings: settings,
        now: now,
        deleteFile: (path) async => deleted.add(path),
      );

      expect(deleted, ['one.mhtml']);
      expect(result.pages, 1);
      expect(await stories.watchStory(1).first, isNull);
      expect(await stories.watchStory(2).first, isNotNull);
      expect(await stories.watchStory(3).first, isNotNull);
      expect(await stories.watchStory(4).first, isNotNull);
      expect(await ThreadStateRepository(db).watch(2).first, isNotNull);
    });
  });
}
