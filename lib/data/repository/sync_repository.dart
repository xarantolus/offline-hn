import 'package:drift/drift.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/run_policy.dart';

class SyncProgress {
  const SyncProgress({
    required this.runId,
    required this.trigger,
    required this.phase,
    this.commentsTotal = 0,
    this.commentsDone = 0,
    this.pagesTotal = 0,
    this.pagesDone = 0,
    required this.heartbeatAt,
  });

  final int runId;
  final SyncTrigger trigger;
  final SyncPhase phase;
  final int commentsTotal;
  final int commentsDone;
  final int pagesTotal;
  final int pagesDone;

  /// Of the items the current phase works through.
  int get total => phase == SyncPhase.pages ? pagesTotal : commentsTotal;
  int get done => phase == SyncPhase.pages ? pagesDone : commentsDone;

  /// Last sign of life from whoever is running it.
  final DateTime heartbeatAt;
}

class SyncRepository {
  const SyncRepository(this._db);

  static const _runsKept = 20;

  final AppDatabase _db;

  /// Continues the unfinished run when it is recent enough, which is how a run
  /// cut off by the system picks up where it stopped. An older one is
  /// abandoned and a fresh run starts.
  ///
  /// A light refresh never resumes: it is asked for to get fresh text, so an
  /// unfinished run is abandoned, unless a process is still working on it.
  Future<SyncRunRow> beginOrResume(SyncTrigger trigger, DateTime now) =>
      _db.transaction(() async {
        final open = await _openRun();
        if (open != null) {
          final resumable =
              !trigger.textOnly && canResumeRun(open.startedAt, now);
          if (resumable || open.executing) return open;
          await finish(open.id, SyncOutcome.abandoned, now);
        }
        final id = await _db
            .into(_db.syncRuns)
            .insert(
              SyncRunsCompanion.insert(
                trigger: trigger,
                phase: SyncPhase.ranking,
                startedAt: now,
                heartbeatAt: Value(now),
              ),
            );
        await _trimHistory(id);
        return (_db.select(
          _db.syncRuns,
        )..where((r) => r.id.equals(id))).getSingle();
      });

  /// Ends the run in progress for good: the next one starts afresh.
  Future<void> abandonOpen(DateTime now) => _db.transaction(() async {
    final open = await _openRun();
    if (open != null) await finish(open.id, SyncOutcome.abandoned, now);
  });

  Future<SyncRunRow?> _openRun() =>
      (_db.select(_db.syncRuns)
            ..where((r) => r.finishedAt.isNull())
            ..orderBy([(r) => OrderingTerm.desc(r.id)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> _trimHistory(int newestId) async {
    final cutoff = newestId - _runsKept;
    await (_db.delete(
      _db.syncRuns,
    )..where((r) => r.id.isSmallerOrEqualValue(cutoff))).go();
    await (_db.delete(
      _db.syncItems,
    )..where((i) => i.runId.isSmallerOrEqualValue(cutoff))).go();
  }

  Future<void> setPhase(int runId, SyncPhase phase, DateTime now) =>
      (_db.update(_db.syncRuns)..where((r) => r.id.equals(runId))).write(
        SyncRunsCompanion(phase: Value(phase), heartbeatAt: Value(now)),
      );

  Future<void> setExecuting(int runId, {required bool value}) =>
      (_db.update(_db.syncRuns)..where((r) => r.id.equals(runId))).write(
        SyncRunsCompanion(executing: Value(value)),
      );

  Future<void> heartbeat(int runId, DateTime now) =>
      (_db.update(_db.syncRuns)..where((r) => r.id.equals(runId))).write(
        SyncRunsCompanion(heartbeatAt: Value(now)),
      );

  Future<void> finish(
    int runId,
    SyncOutcome outcome,
    DateTime now, {
    String? error,
  }) => (_db.update(_db.syncRuns)..where((r) => r.id.equals(runId))).write(
    SyncRunsCompanion(
      phase: Value(
        outcome == SyncOutcome.succeeded ? SyncPhase.done : SyncPhase.ranking,
      ),
      finishedAt: Value(now),
      outcome: Value(outcome),
      error: Value(error),
    ),
  );

  Future<void> enqueue(int runId, SyncItemKind kind, Iterable<int> storyIds) =>
      _db.batch((batch) {
        batch.insertAll(_db.syncItems, [
          for (final id in storyIds)
            SyncItemsCompanion.insert(runId: runId, kind: kind, storyId: id),
        ], mode: InsertMode.insertOrIgnore);
      });

  Future<List<int>> pendingStoryIds(int runId, SyncItemKind kind) async {
    final rows =
        await (_db.select(_db.syncItems)
              ..where(
                (i) =>
                    i.runId.equals(runId) &
                    i.kind.equalsValue(kind) &
                    i.status.equalsValue(SyncItemStatus.pending),
              )
              ..orderBy([(i) => OrderingTerm.asc(i.rowId)]))
            .get();
    return [for (final row in rows) row.storyId];
  }

  Future<void> markItem(
    int runId,
    SyncItemKind kind,
    int storyId,
    SyncItemStatus status,
    DateTime now, {
    String? error,
  }) => _db.transaction(() async {
    await (_db.update(_db.syncItems)..where(
          (i) =>
              i.runId.equals(runId) &
              i.kind.equalsValue(kind) &
              i.storyId.equals(storyId),
        ))
        .write(SyncItemsCompanion(status: Value(status), error: Value(error)));
    await heartbeat(runId, now);
  });

  Future<DateTime?> lastSuccessfulSync() async {
    final row = await _lastSuccess().getSingleOrNull();
    return row?.finishedAt;
  }

  Stream<DateTime?> watchLastSuccessfulSync() =>
      _lastSuccess().watchSingleOrNull().map((row) => row?.finishedAt);

  SimpleSelectStatement<$SyncRunsTable, SyncRunRow> _lastSuccess() =>
      _db.select(_db.syncRuns)
        ..where((r) => r.outcome.equalsValue(SyncOutcome.succeeded))
        ..orderBy([(r) => OrderingTerm.desc(r.finishedAt)])
        ..limit(1);

  /// Null when no run is in progress.
  Stream<SyncProgress?> watchProgress() => _db
      .customSelect(
        'SELECT r.id AS id, r."trigger" AS trigger, r.phase AS phase, '
        'COALESCE(r.heartbeat_at, r.started_at) AS heartbeat_at, '
        '(SELECT COUNT(*) FROM sync_items i WHERE i.run_id = r.id AND i.kind = ?1) AS comments_total, '
        "(SELECT COUNT(*) FROM sync_items i WHERE i.run_id = r.id AND i.kind = ?1 AND i.status <> 'pending') AS comments_done, "
        '(SELECT COUNT(*) FROM sync_items i WHERE i.run_id = r.id AND i.kind = ?2) AS pages_total, '
        "(SELECT COUNT(*) FROM sync_items i WHERE i.run_id = r.id AND i.kind = ?2 AND i.status <> 'pending') AS pages_done "
        'FROM sync_runs r WHERE r.finished_at IS NULL ORDER BY r.id DESC LIMIT 1',
        variables: [
          Variable.withString(SyncItemKind.comments.name),
          Variable.withString(SyncItemKind.page.name),
        ],
        readsFrom: {_db.syncRuns, _db.syncItems},
      )
      .watch()
      .map((rows) {
        if (rows.isEmpty) return null;
        final row = rows.first;
        return SyncProgress(
          runId: row.read<int>('id'),
          trigger: SyncTrigger.values.byName(row.read<String>('trigger')),
          phase: SyncPhase.values.byName(row.read<String>('phase')),
          commentsTotal: row.read<int>('comments_total'),
          commentsDone: row.read<int>('comments_done'),
          pagesTotal: row.read<int>('pages_total'),
          pagesDone: row.read<int>('pages_done'),
          heartbeatAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('heartbeat_at') * 1000,
          ),
        );
      });
}
