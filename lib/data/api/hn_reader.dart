import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/model/feed_kind.dart';

abstract interface class HnReader {
  Future<List<int>> ranking(FeedKind kind);

  Future<List<RemoteStory>> stories(List<int> ids);

  Future<RemoteThread?> thread(int id);

  /// Top-level comment ids in HN's order; empty when Firebase does not know
  /// the story.
  Future<List<int>> rankedTopLevel(int storyId);
}
