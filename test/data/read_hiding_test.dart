import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/policy/read_hiding.dart';
import 'package:offline_hn/data/repository/story_repository.dart';

FeedEntry _entry(int id, {bool read = false}) => FeedEntry(
  bestRank: id,
  story: StoryRow(
    id: id,
    title: 'Story $id',
    commentCount: 0,
    type: 'story',
    firstSeen: DateTime.utc(2026, 10, 1),
    lastSeen: DateTime.utc(2026, 10, 1),
    read: read,
    saved: false,
    hidden: false,
  ),
);

List<int> _ids(List<FeedEntry> entries) => [
  for (final e in entries) e.story.id,
];

void main() {
  final list = [_entry(1, read: true), _entry(2), _entry(3, read: true)];

  test('turning the option on hides what is read and says which', () {
    final hiding = ReadHiding();
    hiding.update(list, enabled: false);
    final changed = hiding.update(list, enabled: true);
    expect(changed.hidden, {1, 3});
    expect(_ids(hiding.visible(list)), [2]);
  });

  test('turning it off shows everything again and says which came back', () {
    final hiding = ReadHiding(true)..update(list, enabled: true);
    final changed = hiding.update(list, enabled: false);
    expect(changed.shown, {1, 3});
    expect(_ids(hiding.visible(list)), [1, 2, 3]);
  });

  test('a list built with the option on starts without the read ones', () {
    final hiding = ReadHiding(true);
    final changed = hiding.update(list, enabled: true);
    expect(_ids(hiding.visible(list)), [2]);
    expect(changed.hidden, isEmpty);
  });

  test('a story read while the list is open stays until the next build', () {
    final hiding = ReadHiding(true)..update(list, enabled: true);
    final after = [
      _entry(1, read: true),
      _entry(2, read: true),
      _entry(3, read: true),
    ];
    hiding.update(after, enabled: true);
    expect(_ids(hiding.visible(after)), [2]);
    final rebuilt = ReadHiding(true)..update(after, enabled: true);
    expect(_ids(rebuilt.visible(after)), isEmpty);
  });

  test('a new story that is already read is hidden at once', () {
    final hiding = ReadHiding(true)..update(list, enabled: true);
    final more = [...list, _entry(4, read: true), _entry(5)];
    hiding.update(more, enabled: true);
    expect(_ids(hiding.visible(more)), [2, 5]);
  });

  test('says when everything is hidden', () {
    final allRead = [_entry(1, read: true), _entry(2, read: true)];
    final hiding = ReadHiding(true)..update(allRead, enabled: true);
    expect(hiding.hidesAll(allRead), isTrue);
    expect(hiding.hidesAll(list), isFalse);
    expect(hiding.hidesAll(const []), isFalse);
  });
}
