// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algolia_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlgoliaHit _$AlgoliaHitFromJson(Map<String, dynamic> json) => AlgoliaHit(
  objectId: lenientInt(json['objectID']),
  storyId: lenientInt(json['story_id']),
  title: lenientString(json['title']),
  url: lenientUri(json['url']),
  author: lenientString(json['author']),
  points: lenientInt(json['points']),
  numComments: lenientInt(json['num_comments']),
  createdAtI: epochSeconds(json['created_at_i']),
  storyText: lenientString(json['story_text']),
  tags: json['_tags'] == null ? const [] : lenientStrings(json['_tags']),
);

AlgoliaNode _$AlgoliaNodeFromJson(Map<String, dynamic> json) => AlgoliaNode(
  id: lenientInt(json['id']),
  type: lenientItemType(json['type']),
  title: lenientString(json['title']),
  url: lenientUri(json['url']),
  author: lenientString(json['author']),
  points: lenientInt(json['points']),
  createdAtI: epochSeconds(json['created_at_i']),
  text: lenientString(json['text']),
  parentId: lenientInt(json['parent_id']),
  storyId: lenientInt(json['story_id']),
  children: json['children'] == null
      ? const []
      : _readChildren(json['children']),
);
