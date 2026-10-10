import 'package:offline_hn/data/api/json_read.dart';
import 'package:offline_hn/data/api/models.dart';

abstract final class AlgoliaParser {
  static List<RemoteStory> searchHits(Object? json) {
    final hits = jsonList(jsonMap(json)?['hits']);
    return [for (final hit in hits) ?_searchHit(jsonMap(hit))];
  }

  static RemoteThread? thread(Object? json) {
    final root = jsonMap(json);
    final id = jsonInt(root?['id']);
    if (root == null || id == null) return null;
    final comments = _children(root);
    return RemoteThread(
      story: RemoteStory(
        id: id,
        title: jsonString(root['title']),
        url: jsonString(root['url']),
        by: jsonString(root['author']),
        points: jsonInt(root['points']),
        commentCount: _count(comments),
        time: jsonEpochSeconds(root['created_at_i']),
        type: jsonString(root['type']) ?? 'story',
        text: jsonString(root['text']),
      ),
      comments: comments,
    );
  }

  static RemoteStory? _searchHit(Map<String, Object?>? hit) {
    if (hit == null) return null;
    final id = jsonInt(hit['objectID']) ?? jsonInt(hit['story_id']);
    if (id == null) return null;
    final tags = jsonList(hit['_tags']);
    return RemoteStory(
      id: id,
      title: jsonString(hit['title']),
      url: jsonString(hit['url']),
      by: jsonString(hit['author']),
      points: jsonInt(hit['points']),
      commentCount: jsonInt(hit['num_comments']),
      time: jsonEpochSeconds(hit['created_at_i']),
      type: tags.contains('poll')
          ? 'poll'
          : tags.contains('job')
          ? 'job'
          : 'story',
      text: jsonString(hit['story_text']),
    );
  }

  static List<RemoteComment> _children(Map<String, Object?> node) => [
    for (final child in jsonList(node['children'])) ?_comment(jsonMap(child)),
  ];

  static RemoteComment? _comment(Map<String, Object?>? node) {
    final id = jsonInt(node?['id']);
    if (node == null || id == null) return null;
    final text = jsonString(node['text']);
    final by = jsonString(node['author']);
    return RemoteComment(
      id: id,
      parentId: jsonInt(node['parent_id']),
      by: by,
      text: text,
      time: jsonEpochSeconds(node['created_at_i']),
      deleted: text == null && by == null,
      children: _children(node),
    );
  }

  static int _count(List<RemoteComment> comments) =>
      comments.fold(0, (sum, c) => sum + 1 + _count(c.children));
}
