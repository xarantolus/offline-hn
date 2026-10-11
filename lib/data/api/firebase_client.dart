import 'package:offline_hn/data/api/endpoints.dart';
import 'package:offline_hn/data/api/firebase_json.dart';
import 'package:offline_hn/data/api/hn_http.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/model/feed_kind.dart';

class FirebaseClient {
  const FirebaseClient(this._http);

  final HnHttp _http;

  Future<List<int>> ranking(FeedKind kind) async =>
      parseRanking(await _http.getJson(HnEndpoints.feed(kind)));

  Future<RemoteStory?> story(int id) async =>
      parseFirebaseStory(await _http.getJson(HnEndpoints.firebaseItem(id)));
}
