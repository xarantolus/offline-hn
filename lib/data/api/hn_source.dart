import 'package:offline_hn/data/api/algolia_client.dart';
import 'package:offline_hn/data/api/endpoints.dart';
import 'package:offline_hn/data/api/firebase_client.dart';
import 'package:offline_hn/data/api/hn_http.dart';
import 'package:offline_hn/data/api/hn_reader.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/model/feed_kind.dart';

class HnSource implements HnReader {
  const HnSource({required this.algolia, required this.firebase});

  factory HnSource.create({HnHttp? http}) {
    final shared = http ?? HnHttp();
    return HnSource(
      algolia: AlgoliaClient(shared),
      firebase: FirebaseClient(shared),
    );
  }

  static const _fallbackConcurrency = 8;

  final AlgoliaClient algolia;
  final FirebaseClient firebase;

  @override
  Future<List<int>> ranking(FeedKind kind) => firebase.ranking(kind);

  /// Metadata in the order of [ids]. Ids neither source knows are omitted;
  /// an Algolia failure propagates rather than costing one Firebase request
  /// per id.
  @override
  Future<List<RemoteStory>> stories(List<int> ids) async {
    final found = <int, RemoteStory>{};
    for (var i = 0; i < ids.length; i += HnEndpoints.maxIdsPerSearch) {
      final chunk = ids.sublist(
        i,
        (i + HnEndpoints.maxIdsPerSearch).clamp(0, ids.length),
      );
      for (final story in await algolia.stories(chunk)) {
        found[story.id] = story;
      }
    }

    final missing = ids.where((id) => !found.containsKey(id)).toList();
    for (var i = 0; i < missing.length; i += _fallbackConcurrency) {
      final batch = missing.skip(i).take(_fallbackConcurrency);
      final fetched = await Future.wait(batch.map(firebase.story));
      for (final story in fetched) {
        if (story != null) found[story.id] = story;
      }
    }

    return [for (final id in ids) ?found[id]];
  }

  /// A story Algolia has not indexed yet comes back from Firebase with no
  /// comments: its tree would take one request per comment.
  @override
  Future<RemoteThread?> thread(int id) async {
    final indexed = await algolia.thread(id);
    if (indexed != null) return indexed;
    final story = await firebase.story(id);
    if (story == null) return null;
    return RemoteThread(story: story, comments: const []);
  }

  @override
  Future<List<int>> rankedTopLevel(int storyId) async =>
      (await firebase.story(storyId))?.kids ?? const [];
}
