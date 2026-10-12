import 'package:json_annotation/json_annotation.dart';
import 'package:offline_hn/data/api/lenient.dart';
import 'package:offline_hn/data/api/models.dart';

part 'algolia_json.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class AlgoliaHit {
  const AlgoliaHit({
    this.objectId,
    this.storyId,
    this.title,
    this.url,
    this.author,
    this.points,
    this.numComments,
    this.createdAtI,
    this.storyText,
    this.tags = const [],
  });

  factory AlgoliaHit.fromJson(Map<String, Object?> json) =>
      _$AlgoliaHitFromJson(json);

  @JsonKey(name: 'objectID', fromJson: lenientInt)
  final int? objectId;
  @JsonKey(fromJson: lenientInt)
  final int? storyId;
  @JsonKey(fromJson: lenientString)
  final String? title;
  @JsonKey(fromJson: lenientUri)
  final Uri? url;
  @JsonKey(fromJson: lenientString)
  final String? author;
  @JsonKey(fromJson: lenientInt)
  final int? points;
  @JsonKey(fromJson: lenientInt)
  final int? numComments;
  @JsonKey(name: 'created_at_i', fromJson: epochSeconds)
  final DateTime? createdAtI;
  @JsonKey(fromJson: lenientString)
  final String? storyText;
  @JsonKey(name: '_tags', fromJson: lenientStrings)
  final List<String> tags;

  RemoteStory? toStory() {
    final id = objectId ?? storyId;
    if (id == null) return null;
    return RemoteStory(
      id: id,
      title: title,
      url: url,
      by: author,
      points: points,
      commentCount: numComments,
      time: createdAtI,
      type: tags.contains('poll')
          ? ItemType.poll
          : tags.contains('job')
          ? ItemType.job
          : ItemType.story,
      text: storyText,
    );
  }
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class AlgoliaNode {
  const AlgoliaNode({
    this.id,
    this.type,
    this.title,
    this.url,
    this.author,
    this.points,
    this.createdAtI,
    this.text,
    this.parentId,
    this.storyId,
    this.children = const [],
  });

  factory AlgoliaNode.fromJson(Map<String, Object?> json) =>
      _$AlgoliaNodeFromJson(json);

  @JsonKey(fromJson: lenientInt)
  final int? id;
  @JsonKey(fromJson: lenientItemType)
  final ItemType? type;
  @JsonKey(fromJson: lenientString)
  final String? title;
  @JsonKey(fromJson: lenientUri)
  final Uri? url;
  @JsonKey(fromJson: lenientString)
  final String? author;
  @JsonKey(fromJson: lenientInt)
  final int? points;
  @JsonKey(name: 'created_at_i', fromJson: epochSeconds)
  final DateTime? createdAtI;
  @JsonKey(fromJson: lenientString)
  final String? text;
  @JsonKey(fromJson: lenientInt)
  final int? parentId;
  @JsonKey(fromJson: lenientInt)
  final int? storyId;
  @JsonKey(fromJson: _readChildren)
  final List<AlgoliaNode> children;

  RemoteComment? toComment() {
    final id = this.id;
    if (id == null) return null;
    return RemoteComment(
      id: id,
      parentId: parentId,
      by: author,
      text: text,
      time: createdAtI,
      deleted: text == null && author == null,
      children: _comments(children),
    );
  }

  RemoteThread? toThread() {
    final id = this.id;
    if (id == null) return null;
    final comments = _comments(children);
    return RemoteThread(
      story: RemoteStory(
        id: id,
        title: title,
        url: url,
        by: author,
        points: points,
        commentCount: _count(comments),
        time: createdAtI,
        type: type ?? ItemType.story,
        text: text,
      ),
      comments: comments,
      containingStoryId: storyId,
    );
  }
}

List<AlgoliaNode> _readChildren(Object? value) =>
    lenientObjects(value, AlgoliaNode.fromJson);

List<RemoteComment> _comments(List<AlgoliaNode> nodes) => [
  for (final node in nodes) ?node.toComment(),
];

int _count(List<RemoteComment> comments) =>
    comments.fold(0, (sum, c) => sum + 1 + _count(c.children));

List<RemoteStory> parseSearchHits(Object? json) {
  final hits = json is Map<String, Object?> ? json['hits'] : null;
  return [
    for (final hit in lenientObjects(hits, AlgoliaHit.fromJson)) ?hit.toStory(),
  ];
}

RemoteThread? parseThread(Object? json) =>
    json is Map<String, Object?> ? AlgoliaNode.fromJson(json).toThread() : null;
