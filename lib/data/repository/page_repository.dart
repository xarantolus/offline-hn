import 'package:drift/drift.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';

class PageRepository {
  const PageRepository(this._db);

  final AppDatabase _db;

  Stream<PageCopyRow?> watch(int storyId) => (_db.select(
    _db.pageCopies,
  )..where((p) => p.storyId.equals(storyId))).watchSingleOrNull();

  Stream<int> watchTotalBytes() {
    final total = _db.pageCopies.bytes.sum();
    final query = _db.selectOnly(_db.pageCopies)
      ..addColumns([total])
      ..where(_db.pageCopies.status.equalsValue(PageStatus.ok));
    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  Future<void> recordCaptured({
    required int storyId,
    required PageKind kind,
    required String relativePath,
    required int bytes,
    required DateTime now,
  }) => _upsert(
    PageCopiesCompanion(
      storyId: Value(storyId),
      kind: Value(kind),
      relativePath: Value(relativePath),
      bytes: Value(bytes),
      capturedAt: Value(now),
      status: const Value(PageStatus.ok),
      error: const Value(null),
    ),
  );

  Future<void> recordTooLarge({
    required int storyId,
    required PageKind kind,
    required DateTime now,
  }) => _upsert(
    PageCopiesCompanion(
      storyId: Value(storyId),
      kind: Value(kind),
      relativePath: const Value(null),
      bytes: const Value(0),
      capturedAt: Value(now),
      status: const Value(PageStatus.tooLarge),
      error: const Value(null),
    ),
  );

  Future<void> recordFailed({
    required int storyId,
    required PageKind kind,
    required String error,
    required DateTime now,
  }) => _upsert(
    PageCopiesCompanion(
      storyId: Value(storyId),
      kind: Value(kind),
      relativePath: const Value(null),
      bytes: const Value(0),
      capturedAt: Value(now),
      status: const Value(PageStatus.failed),
      error: Value(error),
    ),
  );

  Future<void> markOpened(int storyId, DateTime now) =>
      (_db.update(_db.pageCopies)..where((p) => p.storyId.equals(storyId)))
          .write(PageCopiesCompanion(lastOpenedAt: Value(now)));

  Future<Map<int, PageCopyRow>> forStories(Iterable<int> ids) async {
    final rows = await (_db.select(
      _db.pageCopies,
    )..where((p) => p.storyId.isIn(ids.toList()))).get();
    return {for (final row in rows) row.storyId: row};
  }

  Future<void> _upsert(PageCopiesCompanion row) =>
      _db.into(_db.pageCopies).insertOnConflictUpdate(row);
}
