class CosmeticRule {
  const CosmeticRule({
    required this.unhide,
    required this.selector,
    this.domains = const [],
  });

  final bool unhide;
  final String selector;

  /// Empty means every site; a leading `~` excludes one.
  final List<String> domains;

  String toRecord() =>
      [unhide ? 'U' : 'H', domains.join('|'), selector].join('\t');
}
