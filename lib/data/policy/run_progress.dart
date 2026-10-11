import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';

const _rankingEnd = 2;
const _metadataEnd = 5;
const _commentsEnd = 25;

/// Whole-run progress, 0 to 100. Text is quick and pages take most of the
/// time, so the weights follow that rather than the item counts.
int runPercent(SyncProgress progress) {
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
    SyncPhase.pages => within(_commentsEnd, 100),
    SyncPhase.done => 100.0,
  };
  return percent.floor();
}

/// What the notification says, without counts.
String runStageText(SyncPhase phase) =>
    phase == SyncPhase.pages ? 'Saving pages' : 'Updating stories';

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
