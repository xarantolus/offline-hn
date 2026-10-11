// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FirebaseItem _$FirebaseItemFromJson(Map<String, dynamic> json) => FirebaseItem(
  id: lenientInt(json['id']),
  type: lenientItemType(json['type']),
  title: lenientString(json['title']),
  url: lenientUri(json['url']),
  by: lenientString(json['by']),
  score: lenientInt(json['score']),
  descendants: lenientInt(json['descendants']),
  time: epochSeconds(json['time']),
  text: lenientString(json['text']),
  parent: lenientInt(json['parent']),
  kids: json['kids'] == null ? const [] : lenientIds(json['kids']),
  dead: json['dead'] == null ? false : lenientBool(json['dead']),
  deleted: json['deleted'] == null ? false : lenientBool(json['deleted']),
);
