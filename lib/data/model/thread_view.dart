/// Entries hidden because an ancestor is collapsed. The collapsed comment
/// itself stays visible.
List<T> visibleEntries<T>(
  List<T> entries, {
  required Set<int> collapsed,
  required int Function(T) idOf,
  required int Function(T) depthOf,
}) {
  final out = <T>[];
  int? hiddenBelow;
  for (final entry in entries) {
    final depth = depthOf(entry);
    if (hiddenBelow != null) {
      if (depth > hiddenBelow) continue;
      hiddenBelow = null;
    }
    out.add(entry);
    if (collapsed.contains(idOf(entry))) hiddenBelow = depth;
  }
  return out;
}

int countNewComments(Iterable<DateTime?> times, DateTime? seenUpTo) {
  if (seenUpTo == null) return 0;
  return times.where((t) => t != null && t.isAfter(seenUpTo)).length;
}

/// The ancestors of [id] in [collapsed], which hide it. [parentOf] answers
/// null at the top of the thread.
Set<int> collapsedAbove(
  int id,
  Set<int> collapsed, {
  required int? Function(int) parentOf,
}) {
  final out = <int>{};
  final seen = <int>{id};
  for (var at = parentOf(id); at != null && seen.add(at); at = parentOf(at)) {
    if (collapsed.contains(at)) out.add(at);
  }
  return out;
}
