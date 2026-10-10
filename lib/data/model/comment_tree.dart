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
