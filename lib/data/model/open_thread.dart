import 'package:offline_hn/data/db/database.dart';

/// The comments of a thread that is on screen. What is shown only changes when
/// the reader asks, so a refresh in the background never moves the page; it
/// shows up as a count of comments the reader has not been given yet.
class OpenThread {
  List<CommentRow> _shown = const [];
  List<CommentRow> _latest = const [];
  Set<int> _shownIds = const {};

  List<CommentRow> get shown => _shown;

  /// A thread with nothing on screen has nothing to disturb, so the first
  /// comments to arrive are shown at once.
  void receive(List<CommentRow> rows) {
    _latest = rows;
    if (_shown.isEmpty) show();
  }

  int get pendingCount =>
      _latest.where((row) => !_shownIds.contains(row.id)).length;

  void show() {
    _shown = _latest;
    _shownIds = {for (final row in _shown) row.id};
  }
}
