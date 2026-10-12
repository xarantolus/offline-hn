import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/run_history.dart';
import 'package:offline_hn/data/repository/overview_repository.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';

RunRecord run({
  SyncOutcome? outcome = SyncOutcome.succeeded,
  DateTime? started,
  DateTime? finished,
  DateTime? heartbeat,
  String? error,
  int storiesUpdated = 0,
  RunTally tally = const RunTally(),
  int prunedCopies = 0,
  int prunedStories = 0,
  int prunedBytes = 0,
  bool listsRefreshed = false,
}) {
  final start = started ?? DateTime.utc(2026, 10, 10, 5);
  return RunRecord(
    id: 1,
    trigger: SyncTrigger.scheduled,
    startedAt: start,
    heartbeatAt: heartbeat ?? start,
    finishedAt: outcome == null
        ? null
        : (finished ?? start.add(const Duration(minutes: 14))),
    outcome: outcome,
    error: error,
    storiesUpdated: storiesUpdated,
    tally: tally,
    prunedCopies: prunedCopies,
    prunedStories: prunedStories,
    prunedBytes: prunedBytes,
    listsRefreshed: listsRefreshed,
  );
}

ItemGroup items(
  SyncItemKind kind,
  SyncItemStatus status,
  int count, {
  int bytes = 0,
  bool asThread = false,
}) => ItemGroup(
  kind: kind,
  status: status,
  asThread: asThread,
  count: count,
  bytes: bytes,
);

void main() {
  group('tallyItems', () {
    test('counts each kind by how it ended and ignores what is pending', () {
      final tally = tallyItems([
        items(SyncItemKind.comments, SyncItemStatus.done, 30),
        items(SyncItemKind.comments, SyncItemStatus.failed, 2),
        items(SyncItemKind.comments, SyncItemStatus.pending, 9),
        items(SyncItemKind.page, SyncItemStatus.done, 20, bytes: 5000),
        items(SyncItemKind.page, SyncItemStatus.failed, 6),
        items(SyncItemKind.page, SyncItemStatus.tooLarge, 1),
        items(SyncItemKind.link, SyncItemStatus.done, 4, bytes: 700),
        items(SyncItemKind.link, SyncItemStatus.done, 3, asThread: true),
        items(SyncItemKind.link, SyncItemStatus.failed, 1),
      ]);
      expect(tally.threads, 30);
      expect(tally.threadsFailed, 2);
      expect(tally.articles, 20);
      expect(tally.articlesFailed, 6);
      expect(tally.articlesTooLarge, 1);
      expect(tally.links, 4);
      expect(tally.linkedThreads, 3);
      expect(tally.linksFailed, 1);
      expect(tally.bytes, 5700);
    });
  });

  group('runState', () {
    final now = DateTime.utc(2026, 10, 10, 6);

    test('an open run with a recent heartbeat is running', () {
      final open = run(outcome: null, heartbeat: now);
      expect(runState(open, now), RunState.running);
    });

    test('an open run that went quiet is waiting to continue', () {
      final open = run(
        outcome: null,
        heartbeat: now.subtract(const Duration(minutes: 30)),
      );
      expect(runState(open, now), RunState.paused);
    });

    test('finished runs report how they ended', () {
      expect(runState(run(), now), RunState.completed);
      expect(
        runState(run(outcome: SyncOutcome.abandoned), now),
        RunState.stopped,
      );
      expect(runState(run(outcome: SyncOutcome.failed), now), RunState.failed);
    });
  });

  group('durationLabel', () {
    test('says the two largest units', () {
      expect(durationLabel(const Duration(seconds: 20)), 'under a minute');
      expect(durationLabel(const Duration(minutes: 14, seconds: 40)), '14 min');
      expect(durationLabel(const Duration(hours: 2)), '2 h');
      expect(durationLabel(const Duration(hours: 1, minutes: 5)), '1 h 5 min');
      expect(durationLabel(const Duration(days: 1, hours: 3)), '1 d 3 h');
    });
  });

  group('whenLabel', () {
    Duration utcPlusTwo(DateTime _) => const Duration(hours: 2);
    String date(DateTime d) => 'D${d.day}';
    final now = DateTime.utc(2026, 10, 10, 12);

    String label(DateTime at) => whenLabel(
      at: at,
      now: now,
      clock: '05:03',
      date: date,
      offsetAt: utcPlusTwo,
    );

    test('names today, yesterday and tomorrow in the phone local day', () {
      expect(label(DateTime.utc(2026, 10, 10, 3)), 'Today 05:03');
      expect(label(DateTime.utc(2026, 10, 9, 23)), 'Today 05:03');
      expect(label(DateTime.utc(2026, 10, 9, 21)), 'Yesterday 05:03');
      expect(label(DateTime.utc(2026, 10, 11, 3)), 'Tomorrow 05:03');
    });

    test('a further day is written out', () {
      expect(label(DateTime.utc(2026, 10, 5, 3)).endsWith(' 05:03'), isTrue);
      expect(label(DateTime.utc(2026, 10, 5, 3)).startsWith('Today'), isFalse);
    });
  });

  group('runHeadline', () {
    final now = DateTime.utc(2026, 10, 10, 6);

    test('joins when, how long and how it ended', () {
      expect(
        runHeadline(run(), now: now, when: 'Today 05:03'),
        'Today 05:03 · 14 min · Completed',
      );
    });

    test('a running run measures up to now', () {
      final open = run(outcome: null, heartbeat: now);
      expect(
        runHeadline(open, now: now, when: 'Today 05:00'),
        'Today 05:00 · 1 h · Running',
      );
    });

    test('a failure carries its reason', () {
      final failed = run(
        outcome: SyncOutcome.failed,
        error: 'no feed could be read',
      );
      expect(
        runHeadline(failed, now: now, when: 'Today 05:03'),
        endsWith('Failed: no feed could be read'),
      );
    });
  });

  group('runOverview', () {
    test('leaves out what did not happen', () {
      expect(runOverview(run()), isEmpty);
      expect(runOverview(run(storiesUpdated: 1)), ['1 story updated']);
    });

    test('lists each part of a full update', () {
      final lines = runOverview(
        run(
          storiesUpdated: 412,
          listsRefreshed: true,
          prunedCopies: 12,
          prunedStories: 3,
          prunedBytes: 80 * 1024 * 1024,
          tally: const RunTally(
            threads: 37,
            threadsFailed: 2,
            articles: 20,
            articlesFailed: 6,
            articlesTooLarge: 1,
            links: 5,
            linksFailed: 1,
            linkedThreads: 2,
            bytes: 45 * 1024 * 1024,
          ),
        ),
      );
      expect(lines, [
        '412 stories updated',
        '37 threads with comments fetched · 2 failed',
        'Article pages: 20 saved · 6 failed · 1 too large',
        'Linked pages: 5 saved · 1 failed',
        '2 discussions from comment links saved',
        '45.0 MB of pages added',
        'Removed 12 saved copies and 3 old stories (80.0 MB)',
        'Filter lists refreshed',
      ]);
    });
  });

  group('failureReason', () {
    test('turns what the runner stored into plain words', () {
      expect(failureReason('http: HTTP 403'), '403 Forbidden');
      expect(failureReason('http: HTTP 503'), '503 Server error');
      expect(failureReason('http: HTTP 418'), 'HTTP 418');
      expect(failureReason('timeout: over 70 s'), 'Took too long');
      expect(
        failureReason('network: net::ERR_NAME_NOT_RESOLVED'),
        'Could not connect',
      );
      expect(failureReason('ssl: bad cert'), 'Certificate problem');
      expect(failureReason('not a PDF'), 'Not a valid PDF');
      expect(
        failureReason('comments not indexed yet'),
        'Comments not indexed yet',
      );
      expect(failureReason(null), 'Unknown reason');
    });

    test('an unknown text is kept, cut to one line', () {
      expect(failureReason('odd\nsecond line'), 'odd');
      expect(failureReason('x' * 200), hasLength(80));
    });
  });

  group('groupFailures', () {
    FailedItem item(int id, String? error) => FailedItem(
      kind: SyncItemKind.page,
      id: id,
      error: error,
      title: 'Story $id',
      asThread: false,
    );

    test('groups by reason, the most frequent first', () {
      final groups = groupFailures([
        item(1, 'http: HTTP 401'),
        item(2, 'http: HTTP 403'),
        item(3, 'http: HTTP 403'),
        item(4, 'http: HTTP 403'),
      ]);
      expect(
        [for (final g in groups) g.reason],
        ['403 Forbidden', '401 Unauthorized'],
      );
      expect([for (final i in groups.first.items) i.id], [2, 3, 4]);
    });

    test('a linked page has no story to open', () {
      const link = FailedItem(
        kind: SyncItemKind.link,
        id: 9,
        error: null,
        title: null,
        asThread: false,
      );
      expect(link.storyId, isNull);
      expect(item(5, null).storyId, 5);
    });
  });

  group('OverviewRepository', () {
    late AppDatabase db;
    late SyncRepository syncs;
    late OverviewRepository overview;
    final t0 = DateTime.utc(2026, 10, 10, 5);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      syncs = SyncRepository(db);
      overview = OverviewRepository(db);
    });
    tearDown(() => db.close());

    test('summarises a run from its items, newest run first', () async {
      final first = await syncs.beginOrResume(SyncTrigger.scheduled, t0);
      await syncs.finish(first.id, SyncOutcome.succeeded, t0);
      final second = await syncs.beginOrResume(SyncTrigger.manual, t0);
      await syncs.addStoriesUpdated(second.id, 40);
      await syncs.addStoriesUpdated(second.id, 2);
      await syncs.recordConnection(second.id, ConnectionKind.mobile);
      await syncs.recordListsRefreshed(second.id);
      await syncs.recordPruned(second.id, copies: 3, stories: 1, bytes: 900);
      await syncs.enqueue(second.id, SyncItemKind.page, [1, 2, 3]);
      await syncs.markItem(
        second.id,
        SyncItemKind.page,
        1,
        SyncItemStatus.done,
        t0,
        bytes: 500,
      );
      await syncs.markItem(
        second.id,
        SyncItemKind.page,
        2,
        SyncItemStatus.failed,
        t0,
        error: 'http: HTTP 403',
      );
      await syncs.markItem(
        second.id,
        SyncItemKind.page,
        3,
        SyncItemStatus.tooLarge,
        t0,
      );

      final runs = await overview.watchRuns().first;
      expect(runs.map((r) => r.id), [second.id, first.id]);
      final latest = runs.first;
      expect(latest.storiesUpdated, 42);
      expect(latest.connection, ConnectionKind.mobile);
      expect(latest.listsRefreshed, isTrue);
      expect(latest.prunedCopies, 3);
      expect(latest.prunedBytes, 900);
      expect(latest.tally.articles, 1);
      expect(latest.tally.articlesFailed, 1);
      expect(latest.tally.articlesTooLarge, 1);
      expect(latest.tally.bytes, 500);

      final failed = await overview.failedItems(second.id);
      expect(failed.single.id, 2);
      expect(failed.single.error, 'http: HTTP 403');
    });

    test('an empty store has nothing to show', () async {
      final store = await overview.watchStore().first;
      expect(store.stories, 0);
      expect(store.oldestStory, isNull);
      expect(store.perFeed, isEmpty);
      expect(store.copyBytes, 0);
    });
  });
}
