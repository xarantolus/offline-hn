import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/run_progress.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';

SyncProgress _at(
  SyncPhase phase, {
  int commentsDone = 0,
  int commentsTotal = 0,
  int pagesDone = 0,
  int pagesTotal = 0,
}) => SyncProgress(
  runId: 1,
  trigger: SyncTrigger.manual,
  phase: phase,
  commentsDone: commentsDone,
  commentsTotal: commentsTotal,
  pagesDone: pagesDone,
  pagesTotal: pagesTotal,
  heartbeatAt: DateTime(2026),
);

void main() {
  group('runPercent', () {
    test('never goes backwards through a whole run', () {
      final steps = [
        _at(SyncPhase.ranking),
        _at(SyncPhase.metadata),
        for (var i = 0; i <= 200; i += 50)
          _at(SyncPhase.comments, commentsDone: i, commentsTotal: 200),
        for (var i = 0; i <= 100; i += 20)
          _at(
            SyncPhase.pages,
            commentsDone: 200,
            commentsTotal: 200,
            pagesDone: i,
            pagesTotal: 100,
          ),
        _at(SyncPhase.done),
      ];
      final percents = [for (final s in steps) runPercent(s)];
      expect(percents, [...percents]..sort());
      expect(percents.first, 0);
      expect(percents.last, 100);
    });

    test('pages take most of the bar', () {
      final pagesHalf = runPercent(
        _at(SyncPhase.pages, pagesDone: 50, pagesTotal: 100),
      );
      final commentsDone = runPercent(
        _at(SyncPhase.comments, commentsDone: 200, commentsTotal: 200),
      );
      expect(pagesHalf, greaterThan(commentsDone));
      expect(pagesHalf, lessThan(100));
    });

    test('a resumed run starts from what is already done', () {
      final resumed = _at(
        SyncPhase.pages,
        commentsDone: 200,
        commentsTotal: 200,
        pagesDone: 80,
        pagesTotal: 100,
      );
      expect(runPercent(resumed), greaterThan(80));
    });

    test('an empty queue does not divide by zero', () {
      expect(runPercent(_at(SyncPhase.comments)), isNonNegative);
      expect(runPercent(_at(SyncPhase.pages)), isNonNegative);
    });
  });

  group('light refresh', () {
    SyncProgress light(SyncPhase phase, int done, int total) => SyncProgress(
      runId: 1,
      trigger: SyncTrigger.refresh,
      phase: phase,
      commentsDone: done,
      commentsTotal: total,
      heartbeatAt: DateTime(2026),
    );

    test('comments take the rest of the bar and it never goes back', () {
      final steps = [
        light(SyncPhase.ranking, 0, 0),
        light(SyncPhase.metadata, 0, 0),
        for (var i = 0; i <= 10; i++) light(SyncPhase.comments, i, 10),
      ];
      final percents = [for (final s in steps) runPercent(s)];
      expect(percents, [...percents]..sort());
      expect(percents.last, 100);
    });
  });

  group('NotifyPace', () {
    final t0 = DateTime(2026, 10, 11, 12);

    test('posts only when the percent rises and at most once a second', () {
      final pace = NotifyPace();
      expect(pace.allow(1, 10, t0), isTrue);
      expect(
        pace.allow(1, 11, t0.add(const Duration(milliseconds: 300))),
        isFalse,
      );
      expect(pace.allow(1, 11, t0.add(const Duration(seconds: 1))), isTrue);
      expect(pace.allow(1, 11, t0.add(const Duration(seconds: 5))), isFalse);
    });

    test('never posts a lower percent within a run', () {
      final pace = NotifyPace();
      expect(pace.allow(1, 40, t0), isTrue);
      expect(pace.allow(1, 30, t0.add(const Duration(seconds: 9))), isFalse);
    });

    test('a new run starts over', () {
      final pace = NotifyPace();
      expect(pace.allow(1, 90, t0), isTrue);
      expect(
        pace.allow(2, 3, t0.add(const Duration(milliseconds: 10))),
        isTrue,
      );
    });
  });
}
