import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/sync_status_text.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';

SyncProgress _progress(SyncPhase phase, {int total = 0, int done = 0}) =>
    SyncProgress(
      runId: 1,
      trigger: SyncTrigger.catchUp,
      phase: phase,
      commentsTotal: phase == SyncPhase.pages ? 0 : total,
      commentsDone: phase == SyncPhase.pages ? 0 : done,
      pagesTotal: phase == SyncPhase.pages ? total : 0,
      pagesDone: phase == SyncPhase.pages ? done : 0,
      heartbeatAt: DateTime(2026),
    );

void main() {
  test('a run in progress says what it is doing, with counts when known', () {
    expect(
      syncStatusText(
        progress: _progress(SyncPhase.comments, total: 266, done: 34),
        updatedAt: '06:12',
        connection: ConnectionKind.wifi,
      ),
      'Fetching comments 34 of 266',
    );
    expect(
      syncStatusText(
        progress: _progress(SyncPhase.ranking),
        updatedAt: null,
        connection: null,
      ),
      'Fetching rankings',
    );
  });

  test('otherwise the last update and the connection', () {
    expect(
      syncStatusText(
        progress: null,
        updatedAt: '06:12',
        connection: ConnectionKind.mobile,
      ),
      'Updated 06:12 · mobile data',
    );
    expect(
      syncStatusText(
        progress: null,
        updatedAt: '06:12',
        connection: ConnectionKind.none,
      ),
      'Updated 06:12 · offline',
    );
  });

  test('a store never synced says so', () {
    expect(
      syncStatusText(
        progress: null,
        updatedAt: null,
        connection: ConnectionKind.wifi,
      ),
      'Not updated yet · wifi',
    );
  });

  test(
    'stored rankings without a finished sync say the update is unfinished',
    () {
      expect(
        syncStatusText(
          progress: null,
          updatedAt: null,
          storedAt: '06:12',
          connection: ConnectionKind.wifi,
        ),
        'Update unfinished · stories from 06:12 · wifi',
      );
    },
  );

  test('a finished sync wins over stored rankings', () {
    expect(
      syncStatusText(
        progress: null,
        updatedAt: '07:00',
        storedAt: '06:12',
        connection: null,
      ),
      'Updated 07:00',
    );
  });
}
