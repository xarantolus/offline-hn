import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/throttled_watch.dart';

void main() {
  const interval = Duration(milliseconds: 500);

  ({
    List<int> seen,
    StreamController<void> changes,
    StreamSubscription<int> sub,
  })
  watch({Duration fetchTakes = Duration.zero}) {
    final changes = StreamController<void>();
    var fetches = 0;
    final seen = <int>[];
    final sub = throttledWatch(changes.stream, () async {
      fetches++;
      final n = fetches;
      if (fetchTakes > Duration.zero) await Future<void>.delayed(fetchTakes);
      return n;
    }, interval: interval).listen(seen.add);
    return (seen: seen, changes: changes, sub: sub);
  }

  test('answers at once, then a burst of changes with one fetch', () {
    fakeAsync((async) {
      final w = watch();
      async.flushMicrotasks();
      expect(w.seen, [1]);

      for (var i = 0; i < 10; i++) {
        w.changes.add(null);
        async.elapse(const Duration(milliseconds: 20));
      }
      expect(w.seen, [1]);
      async.elapse(interval);
      expect(w.seen, [1, 2]);
      async.elapse(interval * 4);
      expect(w.seen, [1, 2]);
    });
  });

  test('a change after a quiet spell is answered at once', () {
    fakeAsync((async) {
      final w = watch();
      async.elapse(interval * 3);
      w.changes.add(null);
      async.flushMicrotasks();
      expect(w.seen, [1, 2]);
    });
  });

  test('steady changes are answered once per interval', () {
    fakeAsync((async) {
      final w = watch();
      for (var i = 0; i < 100; i++) {
        w.changes.add(null);
        async.elapse(const Duration(milliseconds: 50));
      }
      async.elapse(interval);
      expect(w.seen.length, inInclusiveRange(10, 12));
    });
  });

  test('a slow fetch is never overlapped, and changes during it count', () {
    fakeAsync((async) {
      final w = watch(fetchTakes: interval * 2);
      async.elapse(const Duration(milliseconds: 100));
      w.changes.add(null);
      async.elapse(interval * 2);
      expect(w.seen, [1]);
      async.elapse(interval * 2);
      expect(w.seen, [1, 2]);
    });
  });

  test('nothing is fetched after the listener leaves', () {
    fakeAsync((async) {
      final w = watch();
      async.flushMicrotasks();
      w.changes.add(null);
      async.flushMicrotasks();
      unawaited(w.sub.cancel());
      w.changes.add(null);
      async.elapse(interval * 4);
      expect(w.seen, [1]);
    });
  });
}
