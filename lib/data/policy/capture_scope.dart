import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';

const maxPageBytes = 25 * 1024 * 1024;
const failedCaptureRetryAfter = Duration(hours: 6);

const _captureDepth = {
  FeedKind.top: 60,
  FeedKind.best: 60,
  FeedKind.ask: 30,
  FeedKind.show: 30,
};

bool exceedsPageLimit(int bytes) => bytes > maxPageBytes;

class RankedStory {
  const RankedStory(this.id, this.url);

  final int id;
  final String? url;
}

class ExistingPage {
  const ExistingPage(this.status, this.capturedAt);

  final PageStatus status;
  final DateTime capturedAt;
}

/// Feeds are interleaved by rank so the front pages of all of them are
/// captured before the tail of any one. A failed capture is retried, but not
/// on every run.
List<int> selectCaptureTargets({
  required Map<FeedKind, List<RankedStory>> rankings,
  required Map<int, ExistingPage> existing,
  required DateTime now,
}) {
  final chosen = <int>{};
  final deepest = _captureDepth.values.reduce((a, b) => a > b ? a : b);
  for (var rank = 0; rank < deepest; rank++) {
    for (final kind in FeedKind.values) {
      final list = rankings[kind];
      if (list == null || rank >= list.length || rank >= _captureDepth[kind]!) {
        continue;
      }
      final story = list[rank];
      if (story.url != null && _needsCapture(existing[story.id], now)) {
        chosen.add(story.id);
      }
    }
  }
  return chosen.toList();
}

bool _needsCapture(ExistingPage? page, DateTime now) => switch (page?.status) {
  null => true,
  PageStatus.ok || PageStatus.tooLarge => false,
  PageStatus.failed =>
    now.difference(page!.capturedAt) >= failedCaptureRetryAfter,
};
