import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/comment_order.dart';

class ArrangedComment {
  const ArrangedComment({required this.row, required this.descendants});

  final CommentRow row;
  final int descendants;

  int get depth => row.depth;

  /// A comment with nothing to show: deleted or flagged, without text.
  bool get isPlaceholder => row.html == null || row.deleted || row.dead;
}

/// The thread in reading order. Only the top level moves with [order]; replies
/// stay in the order they were written, which is how HN shows them.
///
/// A removed comment is kept as a stub while something replies to it, and
/// dropped otherwise.
List<ArrangedComment> arrangeComments(
  List<CommentRow> rows,
  CommentOrder order,
) {
  final ids = {for (final row in rows) row.id};
  final replies = <int, List<CommentRow>>{};
  final roots = <CommentRow>[];
  for (final row in rows) {
    final parent = row.parentId;
    if (row.depth == 0 || parent == null || !ids.contains(parent)) {
      roots.add(row);
    } else {
      (replies[parent] ??= []).add(row);
    }
  }
  roots.sort(_topLevelComparator(order));
  for (final list in replies.values) {
    list.sort((a, b) => a.position.compareTo(b.position));
  }

  final out = <ArrangedComment>[];
  void visit(CommentRow row) {
    final at = out.length;
    out.add(ArrangedComment(row: row, descendants: 0));
    for (final reply in replies[row.id] ?? const <CommentRow>[]) {
      visit(reply);
    }
    out[at] = ArrangedComment(row: row, descendants: out.length - at - 1);
  }

  for (final root in roots) {
    visit(root);
  }
  return _withoutEmptyStubs(out);
}

int Function(CommentRow, CommentRow) _topLevelComparator(CommentOrder order) {
  int byTime(CommentRow a, CommentRow b) {
    final left = a.time?.millisecondsSinceEpoch ?? 0;
    final right = b.time?.millisecondsSinceEpoch ?? 0;
    final c = left.compareTo(right);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  return switch (order) {
    CommentOrder.hn => (a, b) => a.position.compareTo(b.position),
    CommentOrder.oldest => byTime,
    CommentOrder.newest => (a, b) => byTime(b, a),
  };
}

/// Removing a stub also shrinks the counts above it, so counts are redone.
List<ArrangedComment> _withoutEmptyStubs(List<ArrangedComment> all) {
  final kept = <ArrangedComment>[];
  for (var i = 0; i < all.length; i++) {
    final entry = all[i];
    if (!entry.isPlaceholder || _hasLiveReply(all, i)) kept.add(entry);
  }
  final result = <ArrangedComment>[];
  for (var i = 0; i < kept.length; i++) {
    var below = 0;
    while (i + 1 + below < kept.length &&
        kept[i + 1 + below].depth > kept[i].depth) {
      below++;
    }
    result.add(ArrangedComment(row: kept[i].row, descendants: below));
  }
  return result;
}

bool _hasLiveReply(List<ArrangedComment> all, int index) {
  final depth = all[index].depth;
  for (var i = index + 1; i < all.length && all[i].depth > depth; i++) {
    if (!all[i].isPlaceholder) return true;
  }
  return false;
}
