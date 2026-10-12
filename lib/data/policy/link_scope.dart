import 'package:offline_hn/comments/comment_parser.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
import 'package:offline_hn/data/policy/sync_scope.dart';

/// Stories whose top comments are searched for links: this many from the top
/// of each feed, plus every bookmarked one.
const linkedStoryDepth = 30;
const linkedComments = 3;
const linksPerComment = 3;
const linksPerBody = 5;

/// Pages that are a player and little else.
const _videoHosts = ['youtube.com', 'youtu.be', 'vimeo.com'];

/// How a link is identified: the address without its fragment.
String linkKey(Uri uri) => uri.removeFragment().toString();

bool isLinkable(Uri uri) {
  if (!(uri.isScheme('http') || uri.isScheme('https')) || uri.host.isEmpty) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return !_videoHosts.any((video) => host == video || host.endsWith('.$video'));
}

List<Uri> _linksIn(
  String html, {
  required int limit,
  required int storyId,
  Uri? own,
}) {
  final found = <Uri>[];
  final seen = <String>{};
  for (final uri in linksInHtml(html)) {
    if (seen.length >= limit) break;
    if (!isLinkable(uri)) continue;
    if (hnItemId(uri) == storyId) continue;
    if (own != null && linkKey(own) == linkKey(uri)) continue;
    if (seen.add(linkKey(uri))) found.add(uri.removeFragment());
  }
  return found;
}

/// The links of the first [linkedComments] comments, in order, at most
/// [linksPerComment] distinct ones from each. Links back to the story itself
/// are left out: its own page is already saved.
List<Uri> linksInComments(
  List<String?> commentHtml, {
  required int storyId,
  String? storyUrl,
}) {
  final own = storyUrl == null ? null : Uri.tryParse(storyUrl);
  return [
    for (final html in commentHtml.take(linkedComments))
      if (html != null)
        ..._linksIn(html, limit: linksPerComment, storyId: storyId, own: own),
  ];
}

/// Up to [linksPerBody] distinct links of the story's own text.
List<Uri> linksInBody(String? html, {required int storyId, String? storyUrl}) =>
    html == null
    ? const []
    : _linksIn(
        html,
        limit: linksPerBody,
        storyId: storyId,
        own: storyUrl == null ? null : Uri.tryParse(storyUrl),
      );

class LinkPlan {
  const LinkPlan({required this.bodyLinks, required this.commentLinks});

  final Map<int, List<Uri>> bodyLinks;
  final Map<int, List<Uri>> commentLinks;

  /// Everything each selected story links to.
  Map<int, List<Uri>> get byStory => {
    for (final id in {...bodyLinks.keys, ...commentLinks.keys})
      id: [...?bodyLinks[id], ...?commentLinks[id]],
  };

  /// Every address once: story texts first, then top comments, each in the
  /// order the stories were chosen.
  List<Uri> get addresses {
    final seen = <String>{};
    return [
      for (final links in [...bodyLinks.values, ...commentLinks.values])
        for (final uri in links)
          if (seen.add(linkKey(uri))) uri,
    ];
  }
}

/// Every story with a text gives links from it. Comment links come from the
/// front-of-feed stories, interleaved so every feed's best come before the
/// rest of any one, then bookmarked ones.
LinkPlan planLinks({
  required Map<FeedKind, List<int>> ranked,
  required Iterable<int> bookmarked,
  required Map<int, List<String?>> topComments,
  required Map<int, String?> storyUrls,
  Map<int, String> storyTexts = const {},
}) {
  final order = {
    ...interleavedByRank({
      for (final entry in ranked.entries)
        entry.key: entry.value.take(linkedStoryDepth).toList(),
    }),
    ...bookmarked,
  };
  return LinkPlan(
    bodyLinks: {
      for (final entry in storyTexts.entries)
        entry.key: linksInBody(
          entry.value,
          storyId: entry.key,
          storyUrl: storyUrls[entry.key],
        ),
    },
    commentLinks: {
      for (final id in order)
        id: linksInComments(
          topComments[id] ?? const [],
          storyId: id,
          storyUrl: storyUrls[id],
        ),
    },
  );
}

class ExistingLink {
  const ExistingLink(this.status, this.at);

  final LinkStatus status;
  final DateTime at;
}

/// The addresses that still need a copy. A failure is retried, but not on
/// every run.
List<Uri> linksNeedingCopy(
  Iterable<Uri> addresses,
  Map<String, ExistingLink> existing,
  DateTime now,
) => [
  for (final uri in addresses)
    if (_needsCopy(existing[linkKey(uri)], now)) uri,
];

bool _needsCopy(ExistingLink? link, DateTime now) => switch (link?.status) {
  null || LinkStatus.pending => true,
  LinkStatus.ok || LinkStatus.tooLarge => false,
  LinkStatus.failed => now.difference(link!.at) >= failedCaptureRetryAfter,
};
