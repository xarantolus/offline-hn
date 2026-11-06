import 'package:offline_hn/data/api/hn_reader.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/model/comment_tree.dart';
import 'package:offline_hn/data/repository/story_repository.dart';

/// Fetches one thread and stores it: Algolia's tree, with the top level in
/// HN's own order. The update and the refresh button both go through here.
class ThreadFetcher {
  const ThreadFetcher(this._source, this._stories);

  static const worstCase = Duration(seconds: 60);

  final HnReader _source;
  final StoryRepository _stories;

  /// The error text, or null when the thread was stored.
  Future<String?> refresh(int id, DateTime now) async {
    try {
      final thread = await _load(id).timeout(worstCase);
      if (thread == null) return 'not found';
      if (thread.comments.isEmpty && (thread.story.commentCount ?? 0) > 0) {
        return 'comments not indexed yet';
      }
      await _stories.replaceThread(thread, now);
      return null;
    } on Exception catch (e) {
      return '$e';
    }
  }

  Future<RemoteThread?> _load(int id) async {
    final thread = await _source.thread(id);
    return thread == null ? null : inHnOrder(thread);
  }

  Future<RemoteThread> inHnOrder(RemoteThread thread) async {
    final id = thread.story.id;
    final ranked = thread.comments.length < 2
        ? const <int>[]
        : await _rankedOrEmpty(id);
    return RemoteThread(
      story: thread.story,
      comments: orderTopLevel(thread.comments, ranked),
    );
  }

  Future<List<int>> _rankedOrEmpty(int id) async {
    try {
      return await _source.rankedTopLevel(id);
    } on Exception {
      return const [];
    }
  }
}
