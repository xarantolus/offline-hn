import 'package:page_capture/src/filters/cosmetic_rule.dart';
import 'package:page_capture/src/filters/filter_line.dart';
import 'package:page_capture/src/filters/network_rule.dart';
import 'package:page_capture/src/filters/resource_type.dart';

abstract final class FilterParser {
  static final _cosmetic = RegExp(r'^([^/|@"!]*?)#(@?)([?$%]?)#(.+)$');

  static const _proceduralMarkers = [
    ':-abp-',
    ':has-text(',
    ':contains(',
    ':xpath(',
    ':matches-',
    ':upward(',
    ':nth-ancestor(',
    ':min-text-length(',
    ':watch-attr(',
    ':remove(',
    ':style(',
    ':others(',
    ':if(',
    ':if-not(',
  ];

  static FilterLine parse(String raw) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('!') || line.startsWith('[')) {
      return const BlankLine();
    }
    final cosmetic = _cosmetic.firstMatch(line);
    if (cosmetic != null) return _parseCosmetic(cosmetic);
    return _parseNetwork(line);
  }

  static FilterLine _parseCosmetic(RegExpMatch match) {
    final kind = match.group(3)!;
    final selector = match.group(4)!.trim();
    if (kind.isNotEmpty) return const SkippedLine('cosmetic:extended');
    if (selector.startsWith('+js(') || selector.startsWith('^')) {
      return const SkippedLine('cosmetic:script');
    }
    if (selector.contains('{') || _proceduralMarkers.any(selector.contains)) {
      return const SkippedLine('cosmetic:procedural');
    }
    final domains = _splitDomains(match.group(1)!, ',');
    if (domains == null) return const SkippedLine('cosmetic:domain');
    return CosmeticLine(
      CosmeticRule(
        unhide: match.group(2) == '@',
        selector: selector,
        domains: domains,
      ),
    );
  }

  static FilterLine _parseNetwork(String line) {
    var body = line;
    final exception = body.startsWith('@@');
    if (exception) body = body.substring(2);

    var options = '';
    final split = body.lastIndexOf(r'$');
    if (split >= 0 && !_looksLikeRegexEnd(body, split)) {
      options = body.substring(split + 1);
      body = body.substring(0, split);
    }
    if (body.length > 1 && body.startsWith('/') && body.endsWith('/')) {
      return const SkippedLine('network:regex');
    }

    final parsed = _parseOptions(options);
    if (parsed.unsupported != null) {
      return SkippedLine('option:${parsed.unsupported}');
    }
    return NetworkLine(
      NetworkRule(
        exception: exception,
        pattern: body.toLowerCase(),
        types: parsed.types,
        party: parsed.party,
        important: parsed.important,
        domains: parsed.domains,
      ),
    );
  }

  static bool _looksLikeRegexEnd(String body, int dollar) =>
      body.startsWith('/') && body.substring(dollar + 1).startsWith('/');

  static List<String>? _splitDomains(String raw, String separator) {
    if (raw.isEmpty) return const [];
    final domains = <String>[];
    for (final entry in raw.toLowerCase().split(separator)) {
      if (entry.isEmpty || entry.contains('*') || entry.contains('/')) {
        return null;
      }
      domains.add(entry);
    }
    return domains;
  }

  static _Options _parseOptions(String raw) {
    if (raw.isEmpty) return const _Options();
    final included = <ResourceType>{};
    final excluded = <ResourceType>{};
    var party = PartyRestriction.any;
    var important = false;
    var domains = <String>[];

    for (final option in raw.toLowerCase().split(',')) {
      final negated = option.startsWith('~');
      final name = negated ? option.substring(1) : option;
      if (name == 'third-party' || name == '3p') {
        party = negated
            ? PartyRestriction.firstPartyOnly
            : PartyRestriction.thirdPartyOnly;
      } else if (name == 'first-party' || name == '1p') {
        party = negated
            ? PartyRestriction.thirdPartyOnly
            : PartyRestriction.firstPartyOnly;
      } else if (name == 'important') {
        important = true;
      } else if (name.startsWith('domain=')) {
        final parsed = _splitDomains(name.substring(7), '|');
        if (parsed == null) return const _Options(unsupported: 'domain');
        domains = parsed;
      } else {
        final type = ResourceType.fromOption(name);
        if (type == null) return _Options(unsupported: name.split('=').first);
        (negated ? excluded : included).add(type);
      }
    }

    final types = included.isNotEmpty
        ? included.difference(excluded)
        : excluded.isNotEmpty
        ? ResourceType.values.toSet().difference(excluded)
        : <ResourceType>{};
    if ((included.isNotEmpty || excluded.isNotEmpty) && types.isEmpty) {
      return const _Options(unsupported: 'no-types');
    }
    return _Options(
      types: types,
      party: party,
      important: important,
      domains: domains,
    );
  }
}

class _Options {
  const _Options({
    this.types = const {},
    this.party = PartyRestriction.any,
    this.important = false,
    this.domains = const [],
    this.unsupported,
  });

  final Set<ResourceType> types;
  final PartyRestriction party;
  final bool important;
  final List<String> domains;
  final String? unsupported;
}
