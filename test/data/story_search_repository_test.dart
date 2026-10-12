import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/repository/story_repository.dart';

RemoteStory story(
  int id,
  String title, {
  String? url,
  String? by,
  String? text,
  int? points,
}) => RemoteStory(
  id: id,
  title: title,
  url: url == null ? null : Uri.parse(url),
  by: by,
  text: text,
  points: points,
  time: DateTime.utc(2026, 10, 10),
);

void main() {
  late AppDatabase db;
  late StoryRepository stories;
  final t0 = DateTime.utc(2026, 10, 11);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    stories = StoryRepository(db);
    await stories.upsertStories([
      story(1, 'Rust 2.0 released', url: 'https://rust-lang.org/a', by: 'bob'),
      story(
        2,
        'Why Postgres is great',
        url: 'https://example.com/p',
        by: 'carol',
      ),
      story(
        3,
        'Ask HN: Which editor do you use?',
        text: '<p>I switched to <a href="https://helix-editor.com">helix</a>.</p>',
        by: 'dave',
      ),
      story(4, 'Go 1.30 is out', url: 'https://go.dev/blog'),
    ], t0);
  });
  tearDown(() => db.close());

  Future<List<int>> find(String query) async => [
    for (final e in await stories.watchSearch(query, now: t0).first) e.story.id,
  ];

  test('finds by title, domain, author and the text of a post', () async {
    expect(await find('rust'), [1]);
    expect(await find('example'), [2]);
    expect(await find('carol'), [2]);
    expect(await find('helix'), [3]);
  });

  test('tolerates a typo and a partial word', () async {
    expect(await find('postgers'), [2]);
    expect(await find('releas'), [1]);
  });

  test('words too short for the index still match', () async {
    expect(await find('go'), [4]);
  });

  test('markup in a post is not searchable', () async {
    expect(await find('href'), isEmpty);
  });

  test('a changed title is found under its new words only', () async {
    await stories.upsertStories([story(1, 'Zig 1.0 released')], t0);
    expect(await find('zig'), [1]);
    expect(await find('rust'), isEmpty);
  });

  test('hidden and deleted stories are not found', () async {
    await stories.setHidden(2, value: true);
    expect(await find('postgres'), isEmpty);
    await (db.delete(db.stories)..where((s) => s.id.equals(1))).go();
    expect(await find('rust'), isEmpty);
  });

  test('a story is found once however many feeds held it', () async {
    expect(await find('rust released'), [1]);
  });
}
