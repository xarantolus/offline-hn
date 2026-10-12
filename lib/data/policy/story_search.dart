import 'dart:math' as math;

class SearchDoc {
  const SearchDoc({
    required this.id,
    required this.title,
    this.domain,
    this.by,
    this.body,
    this.points,
    this.time,
    this.saved = false,
    this.read = false,
  });

  final int id;
  final String title;
  final String? domain;
  final String? by;

  /// Plain text of an Ask or Show post.
  final String? body;
  final int? points;
  final DateTime? time;
  final bool saved;
  final bool read;
}

final _wordPattern = RegExp(r'[\p{L}\p{N}]+', unicode: true);

List<String> queryWords(String query) => [
  for (final match in _wordPattern.allMatches(query.toLowerCase()))
    match.group(0)!,
];

Set<String> trigramsOf(String text) => {
  for (var i = 0; i + 3 <= text.length; i++) text.substring(i, i + 3),
};

/// Slips allowed in a word. Short words must be exact: one slip in four
/// letters is a different word.
int _allowedEdits(String word) {
  if (word.length >= 8) return 2;
  if (word.length >= 5) return 1;
  return 0;
}

/// The fewest edits turning [word] into some stretch of [text], or null when
/// it takes more than [limit].
int? _fewestEdits(String word, String text, int limit) {
  var previous = List<int>.filled(word.length + 1, 0);
  for (var i = 0; i <= word.length; i++) {
    previous[i] = i;
  }
  var best = previous[word.length];
  for (var j = 1; j <= text.length; j++) {
    final current = List<int>.filled(word.length + 1, 0);
    for (var i = 1; i <= word.length; i++) {
      final cost = word.codeUnitAt(i - 1) == text.codeUnitAt(j - 1) ? 0 : 1;
      current[i] = math.min(
        math.min(current[i - 1], previous[i]) + 1,
        previous[i - 1] + cost,
      );
    }
    best = math.min(best, current[word.length]);
    previous = current;
  }
  return best <= limit ? best : null;
}

double _wordInField(String word, String text) {
  final at = text.indexOf(word);
  if (at >= 0) {
    final atWordStart = at == 0 || !_isLetterOrDigit(text.codeUnitAt(at - 1));
    return atWordStart ? 1 : 0.85;
  }
  final limit = _allowedEdits(word);
  if (limit == 0) return 0;
  final edits = _fewestEdits(word, text, limit);
  return edits == null ? 0 : 0.7 * (1 - edits / word.length);
}

bool _isLetterOrDigit(int unit) =>
    _wordPattern.hasMatch(String.fromCharCode(unit));

const _titleWeight = 1.0;
const _domainWeight = 0.8;
const _authorWeight = 0.7;
const _bodyWeight = 0.5;

/// How well [doc] matches every one of [words], 0 to about 1.2, or null when
/// some word is nowhere in it.
double? relevance(List<String> words, SearchDoc doc) {
  if (words.isEmpty) return null;
  final fields = <(String, double)>[
    (doc.title.toLowerCase(), _titleWeight),
    if (doc.domain != null) (doc.domain!.toLowerCase(), _domainWeight),
    if (doc.by != null) (doc.by!.toLowerCase(), _authorWeight),
    if (doc.body != null) (doc.body!.toLowerCase(), _bodyWeight),
  ];
  var total = 0.0;
  for (final word in words) {
    var best = 0.0;
    for (final (text, weight) in fields) {
      best = math.max(best, weight * _wordInField(word, text));
    }
    if (best == 0) return null;
    total += best;
  }
  final queryLength = words.fold<int>(0, (sum, w) => sum + w.length);
  final tight = math.min(1, queryLength / math.max(doc.title.length, 1));
  return total / words.length + 0.2 * tight;
}

/// What a story's own standing can add on top of how well it matches.
double standingBoost(SearchDoc doc, DateTime now) {
  final points =
      math.log(1 + math.max(doc.points ?? 0, 0)) / math.log(1 + 2000);
  final time = doc.time;
  final days = time == null ? 3650 : now.difference(time).inDays;
  final recency = 1 / (1 + math.max(days, 0) / 90);
  return 0.08 * points.clamp(0, 1) +
      0.05 * recency +
      (doc.saved ? 0.04 : 0) +
      (doc.read ? 0.01 : 0);
}

/// The match dominates: standing only orders stories that match about
/// equally.
List<SearchDoc> rankStories(
  String query,
  Iterable<SearchDoc> candidates,
  DateTime now, {
  int limit = 200,
}) {
  final words = queryWords(query);
  final scored = <(SearchDoc, double)>[];
  for (final doc in candidates) {
    final match = relevance(words, doc);
    if (match != null) scored.add((doc, match + standingBoost(doc, now)));
  }
  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    return byScore != 0 ? byScore : b.$1.id.compareTo(a.$1.id);
  });
  return [for (final (doc, _) in scored.take(limit)) doc];
}

/// The SQLite FTS5 query that finds every story which could match: for each
/// word, any of its trigrams, and all words. Null when no word is long enough
/// for the trigram index.
String? ftsQueryFor(List<String> words) {
  final groups = <String>[];
  for (final word in words) {
    if (word.length < 3) continue;
    final terms = trigramsOf(word).map((t) => '"${t.replaceAll('"', '""')}"');
    groups.add('(${terms.join(' OR ')})');
  }
  return groups.isEmpty ? null : groups.join(' AND ');
}
