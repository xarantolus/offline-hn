import 'package:json_annotation/json_annotation.dart';
import 'package:offline_hn/data/api/lenient.dart';
import 'package:offline_hn/data/api/models.dart';

part 'firebase_json.g.dart';

@JsonSerializable(createToJson: false)
class FirebaseItem {
  const FirebaseItem({
    this.id,
    this.type,
    this.title,
    this.url,
    this.by,
    this.score,
    this.descendants,
    this.time,
    this.text,
    this.parent,
    this.kids = const [],
    this.dead = false,
    this.deleted = false,
  });

  factory FirebaseItem.fromJson(Map<String, Object?> json) =>
      _$FirebaseItemFromJson(json);

  @JsonKey(fromJson: lenientInt)
  final int? id;
  @JsonKey(fromJson: lenientItemType)
  final ItemType? type;
  @JsonKey(fromJson: lenientString)
  final String? title;
  @JsonKey(fromJson: lenientUri)
  final Uri? url;
  @JsonKey(fromJson: lenientString)
  final String? by;
  @JsonKey(fromJson: lenientInt)
  final int? score;
  @JsonKey(fromJson: lenientInt)
  final int? descendants;
  @JsonKey(fromJson: epochSeconds)
  final DateTime? time;
  @JsonKey(fromJson: lenientString)
  final String? text;
  @JsonKey(fromJson: lenientInt)
  final int? parent;
  @JsonKey(fromJson: lenientIds)
  final List<int> kids;
  @JsonKey(fromJson: lenientBool)
  final bool dead;
  @JsonKey(fromJson: lenientBool)
  final bool deleted;

  RemoteStory? toStory() {
    final id = this.id;
    if (id == null || dead || deleted) return null;
    return RemoteStory(
      id: id,
      title: title,
      url: url,
      by: by,
      points: score,
      commentCount: descendants,
      time: time,
      type: type ?? ItemType.story,
      text: text,
      kids: kids,
    );
  }

  RemoteComment? toComment() {
    final id = this.id;
    if (id == null) return null;
    return RemoteComment(
      id: id,
      parentId: parent,
      by: by,
      text: text,
      time: time,
      dead: dead,
      deleted: deleted,
    );
  }
}

List<int> parseRanking(Object? json) => lenientIds(json);

FirebaseItem? _item(Object? json) =>
    json is Map<String, Object?> ? FirebaseItem.fromJson(json) : null;

RemoteStory? parseFirebaseStory(Object? json) => _item(json)?.toStory();

RemoteComment? parseFirebaseComment(Object? json) => _item(json)?.toComment();
