class FilterListException implements Exception {
  const FilterListException(this.message);

  final String message;

  @override
  String toString() => 'FilterListException: $message';
}

class FilterListCounts {
  const FilterListCounts({
    required this.networkRules,
    required this.cosmeticRules,
  });

  final int networkRules;
  final int cosmeticRules;
}

abstract final class FilterListText {
  static final _cosmetic = RegExp(r'^([^/|@"!]*?)#@?[?$%]?#.+$');

  /// Counts the rules in a downloaded list. Throws [FilterListException] when
  /// the text does not look like Adblock syntax or holds no network rule.
  static FilterListCounts inspect(String text) {
    final head = text.trimLeft();
    if (!head.startsWith('[Adblock') && !head.startsWith('!')) {
      throw const FilterListException('not an Adblock-syntax list');
    }
    var network = 0;
    var cosmetic = 0;
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('!') || line.startsWith('[')) {
        continue;
      }
      if (_cosmetic.hasMatch(line)) {
        cosmetic++;
      } else {
        network++;
      }
    }
    if (network == 0) {
      throw const FilterListException('no network rules');
    }
    return FilterListCounts(networkRules: network, cosmeticRules: cosmetic);
  }
}
