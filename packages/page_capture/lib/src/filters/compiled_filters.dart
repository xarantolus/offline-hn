class FilterStats {
  const FilterStats({
    required this.networkRules,
    required this.cosmeticRules,
    required this.skipped,
  });

  final int networkRules;
  final int cosmeticRules;

  /// Skipped rule counts keyed by reason, for reporting what is not supported.
  final Map<String, int> skipped;
}

class CompiledFilters {
  const CompiledFilters({
    required this.text,
    required this.generated,
    required this.stats,
  });

  final String text;
  final DateTime generated;
  final FilterStats stats;
}
