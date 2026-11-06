import 'package:offline_hn/data/db/database.dart';

/// The comments of a thread that is on screen. They are taken once and never
/// replaced while the page is open, so a refresh in the background cannot move
/// it; a thread with nothing on screen has nothing to disturb, so comments
/// that arrive later are taken as the first ones.
class OpenThread {
  List<CommentRow> _shown = const [];

  List<CommentRow> get shown => _shown;

  /// Whether [rows] became what is shown.
  bool receive(List<CommentRow> rows) {
    if (_shown.isNotEmpty || rows.isEmpty) return false;
    _shown = rows;
    return true;
  }

  /// For the refresh button, the one time the reader asks for the comments
  /// to move. Returns how many of [rows] were not shown before.
  int replace(List<CommentRow> rows) {
    final before = {for (final c in _shown) c.id};
    _shown = rows;
    return rows.where((c) => !before.contains(c.id)).length;
  }
}
