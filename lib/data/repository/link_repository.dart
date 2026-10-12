import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/link_scope.dart';

class LinkRepository {
  const LinkRepository(this._db);

  final AppDatabase _db;

  /// The addresses that have a copy to open.
  Stream<Set<String>> watchSavedUrls() =>
      (_db.select(_db.linkCopies)
            ..where((l) => l.status.equalsValue(LinkStatus.ok)))
          .watch()
          .map((rows) => {for (final row in rows) row.url})
          .distinct(setEquals);

  Future<LinkCopyRow?> copyFor(Uri uri) => (_db.select(
    _db.linkCopies,
  )..where((l) => l.url.equals(linkKey(uri)))).getSingleOrNull();

  Future<LinkCopyRow?> byId(int id) => (_db.select(
    _db.linkCopies,
  )..where((l) => l.id.equals(id))).getSingleOrNull();

  Future<Map<String, ExistingLink>> existing(Iterable<Uri> uris) async {
    final keys = [for (final uri in uris) linkKey(uri)];
    final rows = <LinkCopyRow>[];
    for (var i = 0; i < keys.length; i += 500) {
      rows.addAll(
        await (_db.select(_db.linkCopies)..where(
              (l) =>
                  l.url.isIn(keys.sublist(i, (i + 500).clamp(0, keys.length))),
            ))
            .get(),
      );
    }
    return {for (final r in rows) r.url: ExistingLink(r.status, r.capturedAt)};
  }

  /// Makes sure every address has a row waiting for its attempt, resetting a
  /// failed one that is due for another. Returns the ids by address.
  Future<Map<String, int>> prepare(Iterable<Uri> uris) =>
      _db.transaction(() async {
        final keys = [for (final uri in uris) linkKey(uri)];
        final ids = <String, int>{};
        for (final key in keys) {
          await _db
              .into(_db.linkCopies)
              .insert(
                LinkCopiesCompanion.insert(url: key),
                mode: InsertMode.insertOrIgnore,
              );
          final row = await (_db.select(
            _db.linkCopies,
          )..where((l) => l.url.equals(key))).getSingle();
          ids[key] = row.id;
          if (row.status == LinkStatus.failed) {
            await (_db.update(
              _db.linkCopies,
            )..where((l) => l.id.equals(row.id))).write(
              const LinkCopiesCompanion(status: Value(LinkStatus.pending)),
            );
          }
        }
        return ids;
      });

  /// Ids of the addresses that already have a row, for the stories whose
  /// links were not all in need of a copy.
  Future<Map<String, int>> idsFor(Iterable<Uri> uris) async {
    final found = await existing(uris);
    if (found.isEmpty) return const {};
    final rows = await (_db.select(
      _db.linkCopies,
    )..where((l) => l.url.isIn(found.keys.toList()))).get();
    return {for (final row in rows) row.url: row.id};
  }

  /// Replaces what each story links to.
  Future<void> replaceReferences(Map<int, Set<int>> linkIdsByStory) =>
      _db.transaction(() async {
        for (final entry in linkIdsByStory.entries) {
          await (_db.delete(
            _db.linkReferences,
          )..where((r) => r.storyId.equals(entry.key))).go();
          await _db.batch((batch) {
            batch.insertAll(_db.linkReferences, [
              for (final id in entry.value)
                LinkReferencesCompanion.insert(storyId: entry.key, linkId: id),
            ], mode: InsertMode.insertOrIgnore);
          });
        }
      });

  /// Top-level comments in display order, without deleted or dead ones, as
  /// many as links are taken from.
  Future<Map<int, List<String?>>> topComments(Iterable<int> storyIds) async {
    final comments = _db.comments;
    final rows =
        await (_db.select(comments)
              ..where(
                (c) =>
                    c.storyId.isIn(storyIds.toList()) &
                    c.depth.equals(0) &
                    c.deleted.equals(false) &
                    c.dead.equals(false),
              )
              ..orderBy([
                (c) => OrderingTerm.asc(c.storyId),
                (c) => OrderingTerm.asc(c.position),
              ]))
            .get();
    final byStory = <int, List<String?>>{};
    for (final row in rows) {
      final list = byStory.putIfAbsent(row.storyId, () => []);
      if (list.length < linkedComments) list.add(row.html);
    }
    return byStory;
  }

  Future<Set<int>> bookmarkedStoryIds() async => {
    for (final row in await (_db.select(
      _db.stories,
    )..where((s) => s.saved.equals(true))).get())
      row.id,
  };

  Future<Map<int, String?>> storyUrls(Iterable<int> ids) async => {
    for (final row in await (_db.select(
      _db.stories,
    )..where((s) => s.id.isIn(ids.toList()))).get())
      row.id: row.url,
  };

  Future<void> recordCaptured({
    required int id,
    required PageKind kind,
    required String relativePath,
    required int bytes,
    required DateTime now,
  }) => _write(
    id,
    LinkCopiesCompanion(
      kind: Value(kind),
      relativePath: Value(relativePath),
      bytes: Value(bytes),
      capturedAt: Value(now),
      status: const Value(LinkStatus.ok),
      error: const Value(null),
    ),
  );

  /// A discussion stored with the stories, so there is no file.
  Future<void> recordThread({required int id, required DateTime now}) => _write(
    id,
    LinkCopiesCompanion(
      kind: const Value(PageKind.thread),
      relativePath: const Value(null),
      bytes: const Value(0),
      capturedAt: Value(now),
      status: const Value(LinkStatus.ok),
      error: const Value(null),
    ),
  );

  Future<void> recordTooLarge({
    required int id,
    required PageKind kind,
    required DateTime now,
  }) => _write(
    id,
    LinkCopiesCompanion(
      kind: Value(kind),
      relativePath: const Value(null),
      bytes: const Value(0),
      capturedAt: Value(now),
      status: const Value(LinkStatus.tooLarge),
      error: const Value(null),
    ),
  );

  Future<void> recordFailed({
    required int id,
    required PageKind kind,
    required String error,
    required DateTime now,
  }) => _write(
    id,
    LinkCopiesCompanion(
      kind: Value(kind),
      relativePath: const Value(null),
      bytes: const Value(0),
      capturedAt: Value(now),
      status: const Value(LinkStatus.failed),
      error: Value(error),
    ),
  );

  Future<void> markOpened(int id, DateTime now) =>
      _write(id, LinkCopiesCompanion(lastOpenedAt: Value(now)));

  Future<void> _write(int id, LinkCopiesCompanion change) =>
      (_db.update(_db.linkCopies)..where((l) => l.id.equals(id))).write(change);
}
