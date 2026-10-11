import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/comment_order.dart';
import 'package:offline_hn/data/model/open_thread.dart';
import 'package:offline_hn/data/policy/comment_arrangement.dart';

CommentRow _comment(
  int id, {
  int? parent,
  required int position,
  int depth = 0,
  int minute = 0,
  String? html = 'text',
  bool deleted = false,
}) => CommentRow(
  id: id,
  storyId: 1,
  parentId: parent ?? 1,
  author: 'a$id',
  html: html,
  time: DateTime.utc(2026, 10, 10, 6, minute),
  position: position,
  depth: depth,
  dead: false,
  deleted: deleted,
);

// Stored in HN order: 10 (replies 11, 12 -> 13), 20, 30 (reply 31).
List<CommentRow> _thread() => [
  _comment(10, position: 0, minute: 5),
  _comment(11, parent: 10, position: 1, depth: 1, minute: 6),
  _comment(12, parent: 10, position: 2, depth: 1, minute: 7),
  _comment(13, parent: 12, position: 3, depth: 2, minute: 8),
  _comment(20, position: 4, minute: 1),
  _comment(30, position: 5, minute: 9),
  _comment(31, parent: 30, position: 6, depth: 1, minute: 10),
];

List<int> _ids(List<ArrangedComment> list) => [for (final c in list) c.row.id];

void main() {
  group('arranging a thread', () {
    test('HN order is the stored order', () {
      expect(_ids(arrangeComments(_thread(), CommentOrder.hn)), [
        10,
        11,
        12,
        13,
        20,
        30,
        31,
      ]);
    });

    test('oldest first moves whole top-level subtrees by time', () {
      expect(_ids(arrangeComments(_thread(), CommentOrder.oldest)), [
        20,
        10,
        11,
        12,
        13,
        30,
        31,
      ]);
    });

    test('newest first reverses the top level but not the replies', () {
      expect(_ids(arrangeComments(_thread(), CommentOrder.newest)), [
        30,
        31,
        10,
        11,
        12,
        13,
        20,
      ]);
    });

    test('a subtree knows how many comments it holds', () {
      final arranged = arrangeComments(_thread(), CommentOrder.hn);
      expect([for (final c in arranged) c.descendants], [3, 0, 1, 0, 0, 1, 0]);
    });

    test('a removed comment with replies stays, one without goes', () {
      final rows = [
        _comment(10, position: 0, html: null, deleted: true),
        _comment(11, parent: 10, position: 1, depth: 1),
        _comment(20, position: 2, html: null, deleted: true),
        _comment(30, position: 3),
        _comment(
          31,
          parent: 30,
          position: 4,
          depth: 1,
          html: null,
          deleted: true,
        ),
      ];
      final arranged = arrangeComments(rows, CommentOrder.hn);
      expect(_ids(arranged), [10, 11, 30]);
      expect(arranged.first.isPlaceholder, isTrue);
      expect(arranged.first.descendants, 1);
      expect(arranged.last.descendants, 0);
    });

    test('a reply whose parent is missing is not lost', () {
      final rows = [
        _comment(10, position: 0),
        _comment(12, parent: 99, position: 1, depth: 2),
      ];
      expect(_ids(arrangeComments(rows, CommentOrder.hn)), [10, 12]);
    });
  });

  group('a thread that is open', () {
    test('the first comments to arrive are shown at once', () {
      final open = OpenThread()..receive(_thread());
      expect(open.shown, hasLength(7));
      expect(open.pendingCount, 0);
    });

    test('later ones wait until asked for', () {
      final open = OpenThread()..receive(_thread());
      open.receive([..._thread(), _comment(40, position: 7, minute: 20)]);
      expect(open.shown, hasLength(7));
      expect(open.pendingCount, 1);
      open.show();
      expect(open.shown, hasLength(8));
      expect(open.pendingCount, 0);
    });

    test('a refresh that adds nothing is not announced', () {
      final open = OpenThread()..receive(_thread());
      open.receive(_thread().reversed.toList());
      expect(open.pendingCount, 0);
    });

    test('an empty thread takes the comments that arrive later', () {
      final open = OpenThread()..receive(const []);
      open.receive(_thread());
      expect(open.shown, hasLength(7));
    });
  });
}
