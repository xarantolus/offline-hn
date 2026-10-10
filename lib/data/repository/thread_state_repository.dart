import 'package:drift/drift.dart';
import 'package:offline_hn/data/db/database.dart';

extension ThreadStateCollapsed on ThreadStateRow {
  Set<int> get collapsed => decodeIds(collapsedIds);
}

Set<int> decodeIds(String raw) => {
  for (final part in raw.split(',')) ?int.tryParse(part),
};

String encodeIds(Set<int> ids) => ids.join(',');

class ThreadStateRepository {
  const ThreadStateRepository(this._db);

  final AppDatabase _db;

  Stream<ThreadStateRow?> watch(int storyId) => (_db.select(
    _db.threadStates,
  )..where((t) => t.storyId.equals(storyId))).watchSingleOrNull();

  /// The seen marker only moves forward, and only here: a background refresh
  /// never calls this.
  Future<void> markOpened(
    int storyId,
    DateTime now, {
    DateTime? seenUpToCommentTime,
  }) => _db.transaction(() async {
    final existing = await (_db.select(
      _db.threadStates,
    )..where((t) => t.storyId.equals(storyId))).getSingleOrNull();
    final previous = existing?.seenUpToCommentTime;
    final seen = switch ((previous, seenUpToCommentTime)) {
      (final a?, final b?) => a.isAfter(b) ? a : b,
      (final a?, null) => a,
      (null, final b) => b,
    };
    await _db
        .into(_db.threadStates)
        .insertOnConflictUpdate(
          ThreadStatesCompanion(
            storyId: Value(storyId),
            lastOpenedAt: Value(now),
            seenUpToCommentTime: Value(seen),
            collapsedIds: Value(existing?.collapsedIds ?? ''),
          ),
        );
  });

  /// Does not count as opening the thread.
  Future<void> setCollapsed(int storyId, Set<int> ids, DateTime now) =>
      _db.transaction(() async {
        final existing = await (_db.select(
          _db.threadStates,
        )..where((t) => t.storyId.equals(storyId))).getSingleOrNull();
        await _db
            .into(_db.threadStates)
            .insertOnConflictUpdate(
              ThreadStatesCompanion(
                storyId: Value(storyId),
                lastOpenedAt: Value(existing?.lastOpenedAt ?? now),
                seenUpToCommentTime: Value(existing?.seenUpToCommentTime),
                collapsedIds: Value(encodeIds(ids)),
              ),
            );
      });
}
