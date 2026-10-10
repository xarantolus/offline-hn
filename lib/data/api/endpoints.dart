import 'package:offline_hn/data/model/feed_kind.dart';

abstract final class HnEndpoints {
  static const firebaseHost = 'hacker-news.firebaseio.com';
  static const algoliaHost = 'hn.algolia.com';

  static const maxIdsPerSearch = 100;

  static Uri feed(FeedKind kind) => Uri.https(
    firebaseHost,
    '/v0/${switch (kind) {
      FeedKind.top => 'topstories',
      FeedKind.best => 'beststories',
      FeedKind.ask => 'askstories',
      FeedKind.show => 'showstories',
    }}.json',
  );

  static Uri firebaseItem(int id) =>
      Uri.https(firebaseHost, '/v0/item/$id.json');

  static Uri algoliaItem(int id) => Uri.https(algoliaHost, '/api/v1/items/$id');

  static Uri algoliaStories(List<int> ids) {
    assert(ids.length <= maxIdsPerSearch);
    return Uri.https(algoliaHost, '/api/v1/search', {
      'tags': 'story,(${ids.map((id) => 'story_$id').join(',')})',
      'hitsPerPage': '${ids.length}',
    });
  }
}
