import 'package:drift/drift.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';

class PageUsage {
  const PageUsage({required this.bytes, required this.count});

  final int bytes;
  final int count;
}

class PageRepository {
  const PageRepository(this._db);

  final AppDatabase _db;

  Stream<PageCopyRow?> watch(int storyId) => (_db.select(
    _db.pageCopies,
  )..where((p) => p.storyId.equals(storyId))).watchSingleOrNull();

  /// Articles and linked pages together: both count against the budget.
  Stream<PageUsage> watchUsage() => _db
      .customSelect(
        'SELECT '
        '(SELECT COALESCE(SUM(bytes), 0) FROM page_copies WHERE status = ?1) '
        '+ (SELECT COALESCE(SUM(bytes), 0) FROM link_copies WHERE status = ?2) '
        'AS bytes, '
        '(SELECT COUNT(*) FROM page_copies WHERE status = ?1) '
        '+ (SELECT COUNT(*) FROM link_copies WHERE status = ?2 '
        'AND kind <> ?3) AS count',
        variables: [
          Variable.withString(PageStatus.ok.name),
          Variable.withString(LinkStatus.ok.name),
          Variable.withString(PageKind.thread.name),
        ],
        readsFrom: {_db.pageCopies, _db.linkCopies},
      )
      .watchSingle()
      .map(
        (row) => PageUsage(
          bytes: row.read<int>('bytes'),
          count: row.read<int>('count'),
        ),
      );

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
