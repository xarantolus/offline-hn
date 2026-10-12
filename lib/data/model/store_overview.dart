import 'package:offline_hn/data/model/feed_kind.dart';

/// What the app holds right now.
class StoreOverview {
  const StoreOverview({
    required this.stories,
    required this.oldestStory,
    required this.newestStory,
    required this.perFeed,
    required this.threads,
    required this.comments,
    required this.articles,
    required this.articleBytes,
    required this.linkedPages,
    required this.linkedBytes,
    required this.linkedThreads,
    required this.bookmarked,
  });

  final int stories;
  final DateTime? oldestStory;
  final DateTime? newestStory;

  /// Stories that appeared in each feed's stored rankings.
  final Map<FeedKind, int> perFeed;

  /// Stories whose comments are stored.
  final int threads;
  final int comments;
  final int articles;
  final int articleBytes;
  final int linkedPages;
  final int linkedBytes;
  final int linkedThreads;
  final int bookmarked;

  int get copyBytes => articleBytes + linkedBytes;
}
