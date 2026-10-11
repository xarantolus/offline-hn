import 'package:offline_hn/data/model/feed_kind.dart';

/// What the feed page switches between: the four HN feeds, then the stories
/// kept by bookmark.
enum FeedTab {
  top(FeedKind.top),
  best(FeedKind.best),
  ask(FeedKind.ask),
  show(FeedKind.show),
  saved(null);

  const FeedTab(this.kind);

  /// Null for the bookmarks, which are no HN feed.
  final FeedKind? kind;

  static FeedTab of(FeedKind kind) => values.firstWhere((t) => t.kind == kind);

  String get label => name[0].toUpperCase() + name.substring(1);
}
