import 'package:offline_hn/data/api/endpoints.dart';
import 'package:offline_hn/data/api/firebase_parser.dart';
import 'package:offline_hn/data/api/hn_http.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/model/feed_kind.dart';

class FirebaseClient {
  const FirebaseClient(this._http);

  final HnHttp _http;

  Future<List<int>> ranking(FeedKind kind) async =>
      FirebaseParser.ids(await _http.getJson(HnEndpoints.feed(kind)));

  Future<RemoteStory?> story(int id) async =>
      FirebaseParser.story(await _http.getJson(HnEndpoints.firebaseItem(id)));
}
