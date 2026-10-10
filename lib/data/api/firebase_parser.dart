import 'package:offline_hn/data/api/json_read.dart';
import 'package:offline_hn/data/api/models.dart';

abstract final class FirebaseParser {
  static List<int> ids(Object? json) => [
    for (final id in jsonList(json)) ?jsonInt(id),
  ];

  static RemoteStory? story(Object? json) {
    final item = jsonMap(json);
    final id = jsonInt(item?['id']);
    if (item == null || id == null) return null;
    if (jsonBool(item['deleted']) || jsonBool(item['dead'])) return null;
    return RemoteStory(
      id: id,
      title: jsonString(item['title']),
      url: jsonString(item['url']),
      by: jsonString(item['by']),
      points: jsonInt(item['score']),
      commentCount: jsonInt(item['descendants']),
      time: jsonEpochSeconds(item['time']),
      type: jsonString(item['type']) ?? 'story',
      text: jsonString(item['text']),
      kids: ids(item['kids']),
    );
  }

  static RemoteComment? comment(Object? json) {
    final item = jsonMap(json);
    final id = jsonInt(item?['id']);
    if (item == null || id == null) return null;
    return RemoteComment(
      id: id,
      parentId: jsonInt(item['parent']),
      by: jsonString(item['by']),
      text: jsonString(item['text']),
      time: jsonEpochSeconds(item['time']),
      dead: jsonBool(item['dead']),
      deleted: jsonBool(item['deleted']),
    );
  }
}
