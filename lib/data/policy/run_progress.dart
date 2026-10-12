import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';

const _rankingEnd = 2;
const _metadataEnd = 5;
const _commentsEnd = 25;
const _pagesEnd = 80;

/// Whole-run progress, 0 to 100. Text is quick and pages take most of the
/// time, so the weights follow that rather than the item counts: articles
/// 55%, linked pages the last 20%.
int runPercent(SyncProgress progress) {
  if (progress.trigger.textOnly) return _lightPercent(progress);
  double within(int from, int to) {
    final fraction = progress.total == 0
        ? 0.0
        : (progress.done / progress.total).clamp(0.0, 1.0);
    return from + (to - from) * fraction;
  }

  final percent = switch (progress.phase) {
    SyncPhase.ranking => 0.0,
    SyncPhase.metadata => _rankingEnd.toDouble(),
    SyncPhase.comments => within(_metadataEnd, _commentsEnd),
    SyncPhase.pages => within(_commentsEnd, _pagesEnd),
    SyncPhase.links => within(_pagesEnd, 100),
    SyncPhase.done => 100.0,
  };
  return percent.floor();
}

/// A light refresh has no pages, so its comments take the rest of the bar.
int _lightPercent(SyncProgress progress) {
  final fraction = progress.commentsTotal == 0
      ? 0.0
      : (progress.commentsDone / progress.commentsTotal).clamp(0.0, 1.0);
  return switch (progress.phase) {
    SyncPhase.ranking => 0,
    SyncPhase.metadata => _rankingEnd,
    SyncPhase.comments =>
      (_metadataEnd + (100 - _metadataEnd) * fraction).floor(),
    SyncPhase.pages || SyncPhase.links || SyncPhase.done => 100,
  };
}

/// What the notification says, without counts.
String runStageText(SyncPhase phase) => switch (phase) {
  SyncPhase.pages => 'Saving pages',
  SyncPhase.links => 'Saving linked pages',
  _ => 'Updating stories',
};

/// Decides which progress readings become notification updates: never
/// backwards within a run, only when the whole percent changed, and no more
/// than once per [minGap].
class NotifyPace {
  NotifyPace({this.minGap = const Duration(seconds: 1)});

  final Duration minGap;
  int? _runId;
  int _percent = -1;
  DateTime? _at;

  bool allow(int runId, int percent, DateTime now) {
    if (runId != _runId) {
      _runId = runId;
      _percent = -1;
      _at = null;
    }
    final last = _at;
    if (percent <= _percent) return false;
    if (last != null && now.difference(last) < minGap) return false;
    _percent = percent;
    _at = now;
    return true;
  }

  void reset() {
    _runId = null;
    _percent = -1;
    _at = null;
  }
}
