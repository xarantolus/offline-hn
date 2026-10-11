import 'package:offline_hn/data/api/algolia_json.dart';
import 'package:offline_hn/data/api/endpoints.dart';
import 'package:offline_hn/data/api/hn_http.dart';
import 'package:offline_hn/data/api/models.dart';

class AlgoliaClient {
  const AlgoliaClient(this._http);

  final HnHttp _http;

  /// Stories Algolia has not indexed yet are simply absent from the result.
  Future<List<RemoteStory>> stories(List<int> ids) async {
    if (ids.isEmpty) return const [];
    return parseSearchHits(
      await _http.getJson(HnEndpoints.algoliaStories(ids)),
    );
  }

  /// Null when Algolia does not know the item (404).
  Future<RemoteThread?> thread(int id) async {
    try {
      return parseThread(await _http.getJson(HnEndpoints.algoliaItem(id)));
    } on HnApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }
}
