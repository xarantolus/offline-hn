import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/api/algolia_parser.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/model/comment_tree.dart';
import 'package:offline_hn/data/model/thread_view.dart';

import 'fixtures.dart';

RemoteComment _c(int id, [List<RemoteComment> children = const []]) =>
    RemoteComment(id: id, children: children);

void main() {
  group('flattenComments', () {
    test('is depth-first with the depth of each node', () {
      final flat = flattenComments([
        _c(1, [
          _c(2, [_c(3)]),
          _c(4),
        ]),
        _c(5),
      ]);
      expect(flat.map((f) => f.comment.id), [1, 2, 3, 4, 5]);
      expect(flat.map((f) => f.depth), [0, 1, 2, 1, 0]);
      expect(flat.map((f) => f.position), [0, 1, 2, 3, 4]);
    });

    test('flattening the recorded tree keeps every comment once', () {
      final thread = AlgoliaParser.thread(fixture('algolia_item.json'))!;
      final flat = flattenComments(thread.comments);
      expect(flat.length, thread.story.commentCount);
      expect(flat.map((f) => f.comment.id).toSet().length, flat.length);
      for (final entry in flat.where((f) => f.depth > 0)) {
        final parent = flat[entry.position - 1];
        expect(entry.depth, lessThanOrEqualTo(parent.depth + 1));
      }
    });
  });

  group('visibleEntries', () {
    final flat = flattenComments([
      _c(1, [
        _c(2, [_c(3)]),
        _c(4),
      ]),
      _c(5, [_c(6)]),
    ]);

    List<int> visible(Set<int> collapsed) => visibleEntries(
      flat,
      collapsed: collapsed,
      idOf: (f) => f.comment.id,
      depthOf: (f) => f.depth,
    ).map((f) => f.comment.id).toList();

    test('nothing collapsed shows everything', () {
      expect(visible({}), [1, 2, 3, 4, 5, 6]);
    });

    test('collapsing hides the subtree but not the node or its siblings', () {
      expect(visible({2}), [1, 2, 4, 5, 6]);
      expect(visible({1}), [1, 5, 6]);
    });

    test('collapsed inside a collapsed subtree changes nothing extra', () {
      expect(visible({1, 2}), [1, 5, 6]);
    });

    test('collapsing the last top-level comment hides only its children', () {
      expect(visible({5}), [1, 2, 3, 4, 5]);
    });
  });

  group('countNewComments', () {
    final seen = DateTime.utc(2026, 10, 10, 12);

    test('counts comments strictly after the marker', () {
      expect(
        countNewComments([
          seen.subtract(const Duration(minutes: 1)),
          seen,
          seen.add(const Duration(minutes: 1)),
          null,
        ], seen),
        1,
      );
    });

    test('a thread never opened has no new comments to flag', () {
      expect(countNewComments([seen], null), 0);
    });
  });
}
