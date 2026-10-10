import 'package:offline_hn/data/api/models.dart';

class FlatComment {
  const FlatComment({
    required this.comment,
    required this.depth,
    required this.position,
  });

  final RemoteComment comment;
  final int depth;
  final int position;
}

List<FlatComment> flattenComments(List<RemoteComment> roots) {
  final out = <FlatComment>[];
  void visit(RemoteComment comment, int depth) {
    out.add(FlatComment(comment: comment, depth: depth, position: out.length));
    for (final child in comment.children) {
      visit(child, depth + 1);
    }
  }

  for (final root in roots) {
    visit(root, 0);
  }
  return out;
}

/// [roots] in the order of [ranked]; comments it does not list keep their
/// relative order after the listed ones.
List<RemoteComment> orderTopLevel(List<RemoteComment> roots, List<int> ranked) {
  final place = {for (var i = 0; i < ranked.length; i++) ranked[i]: i};
  final indexed = [for (var i = 0; i < roots.length; i++) (i, roots[i])];
  indexed.sort((a, b) {
    final left = place[a.$2.id];
    final right = place[b.$2.id];
    if (left != null && right != null) return left.compareTo(right);
    if (left != null) return -1;
    if (right != null) return 1;
    return a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}
