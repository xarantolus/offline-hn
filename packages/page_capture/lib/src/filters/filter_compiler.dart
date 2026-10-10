import 'package:page_capture/src/filters/compiled_filters.dart';
import 'package:page_capture/src/filters/filter_line.dart';
import 'package:page_capture/src/filters/filter_parser.dart';
import 'package:page_capture/src/filters/list_stamp.dart';

class FilterListException implements Exception {
  const FilterListException(this.message);

  final String message;

  @override
  String toString() => 'FilterListException: $message';
}

abstract final class FilterCompiler {
  static const formatVersion = 1;
  static const headerMarker = '#offline-hn-filters';

  /// Throws [FilterListException] when a list does not look like a filter
  /// list or holds fewer than [minNetworkRulesPerList] network rules.
  static CompiledFilters compile(
    List<String> lists, {
    required DateTime generated,
    int minNetworkRulesPerList = 1000,
  }) {
    final records = <String>{};
    final skipped = <String, int>{};
    var network = 0;
    var cosmetic = 0;

    for (final list in lists) {
      if (!list.trimLeft().startsWith('[Adblock')) {
        throw const FilterListException('not an Adblock-syntax list');
      }
      var listNetwork = 0;
      for (final line in list.split('\n')) {
        switch (FilterParser.parse(line)) {
          case BlankLine():
            break;
          case SkippedLine(:final reason):
            skipped.update(reason, (n) => n + 1, ifAbsent: () => 1);
          case NetworkLine(:final rule):
            listNetwork++;
            if (records.add(rule.toRecord())) network++;
          case CosmeticLine(:final rule):
            if (records.add(rule.toRecord())) cosmetic++;
        }
      }
      if (listNetwork < minNetworkRulesPerList) {
        throw FilterListException(
          'only $listNetwork network rules, expected $minNetworkRulesPerList',
        );
      }
    }

    final header = [
      headerMarker,
      '$formatVersion',
      listStamp(generated),
    ].join('\t');
    return CompiledFilters(
      text: '$header\n${records.join('\n')}\n',
      generated: generated.toUtc(),
      stats: FilterStats(
        networkRules: network,
        cosmeticRules: cosmetic,
        skipped: skipped,
      ),
    );
  }
}
