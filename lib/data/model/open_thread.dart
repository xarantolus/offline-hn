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
}
