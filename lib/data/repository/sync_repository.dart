import 'package:drift/drift.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/run_policy.dart';

class SyncProgress {
  const SyncProgress({
    required this.runId,
    required this.trigger,
    required this.phase,
    required this.total,
    required this.done,
  });

  final int runId;
  final SyncTrigger trigger;
  final SyncPhase phase;
  final int total;
  final int done;
}

class SyncRepository {
  const SyncRepository(this._db);

  static const _runsKept = 20;

  final AppDatabase _db;

  /// Continues the unfinished run when it is recent enough, which is how a run
  /// cut off by the system picks up where it stopped. An older one is
  /// abandoned and a fresh run starts.
  Future<SyncRunRow> beginOrResume(SyncTrigger trigger, DateTime now) =>
      _db.transaction(() async {
        final open = await _openRun();
        if (open != null) {
          if (canResumeRun(open.startedAt, now)) return open;
          await finish(open.id, SyncOutcome.abandoned, now);
        }
        final id = await _db
            .into(_db.syncRuns)
            .insert(
              SyncRunsCompanion.insert(
                trigger: trigger,
                phase: SyncPhase.ranking,
                startedAt: now,
              ),
            );
        await _trimHistory(id);
        return (_db.select(
          _db.syncRuns,
        )..where((r) => r.id.equals(id))).getSingle();
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

  Future<void> setPhase(int runId, SyncPhase phase) =>
      (_db.update(_db.syncRuns)..where((r) => r.id.equals(runId))).write(
        SyncRunsCompanion(phase: Value(phase)),
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
    SyncItemStatus status, {
    String? error,
  }) =>
      (_db.update(_db.syncItems)..where(
            (i) =>
                i.runId.equals(runId) &
                i.kind.equalsValue(kind) &
                i.storyId.equals(storyId),
          ))
          .write(
            SyncItemsCompanion(status: Value(status), error: Value(error)),
          );

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
        '(SELECT COUNT(*) FROM sync_items i WHERE i.run_id = r.id) AS total, '
        "(SELECT COUNT(*) FROM sync_items i WHERE i.run_id = r.id AND i.status <> 'pending') AS done "
        'FROM sync_runs r WHERE r.finished_at IS NULL ORDER BY r.id DESC LIMIT 1',
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
          total: row.read<int>('total'),
          done: row.read<int>('done'),
        );
      });
}
