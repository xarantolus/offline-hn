import 'package:offline_hn/data/repository/story_repository.dart';

/// Which stories of a feed the "hide read stories" option keeps out of sight.
///
/// Turning the option on hides what is read at that moment, and turning it off
/// shows everything. After that a story that gets read stays where it is, so
/// the list does not change under someone scrolling it; it is hidden the next
/// time a list is built from scratch. Stories arriving later (a refresh) are
/// hidden at once when they are already read.
class ReadHiding {
  ReadHiding([this._enabled = false]);

  bool _enabled;
  var _known = <int>{};
  final _hidden = <int>{};

  bool isHidden(int id) => _hidden.contains(id);

  /// Takes the list as it is now and returns the ids whose visibility
  /// changed because of the option itself, not because of new stories.
  ({Set<int> hidden, Set<int> shown}) update(
    List<FeedEntry> entries, {
    required bool enabled,
  }) {
    final ids = {for (final e in entries) e.story.id};
    final hidden = <int>{};
    final shown = <int>{};
    if (enabled != _enabled) {
      _enabled = enabled;
      if (enabled) {
        for (final e in entries) {
          if (e.story.read && _hidden.add(e.story.id)) hidden.add(e.story.id);
        }
      } else {
        shown.addAll(_hidden.intersection(ids));
        _hidden.clear();
      }
    } else if (enabled) {
      for (final e in entries) {
        if (e.story.read && !_known.contains(e.story.id)) {
          _hidden.add(e.story.id);
        }
      }
    }
    _hidden.retainAll(ids);
    _known = ids;
    return (hidden: hidden, shown: shown);
  }

  List<FeedEntry> visible(List<FeedEntry> entries) => [
    for (final e in entries)
      if (!_hidden.contains(e.story.id)) e,
  ];

  /// Whether the option hides everything there is to show.
  bool hidesAll(List<FeedEntry> entries) =>
      entries.isNotEmpty && _hidden.length == entries.length;
}
