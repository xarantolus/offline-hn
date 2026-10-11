final _hnPrefix = RegExp(r'^(ask|show|tell|launch) hn\b', caseSensitive: false);

/// The small line above a story: where it points, or what kind of post it is
/// when it points nowhere.
String storySource({required String? domain, required String title}) {
  if (domain != null) return domain;
  final match = _hnPrefix.firstMatch(title);
  if (match == null) return 'Hacker News';
  final kind = match.group(1)!;
  return '${kind[0].toUpperCase()}${kind.substring(1).toLowerCase()} HN';
}
