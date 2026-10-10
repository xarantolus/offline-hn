import 'package:page_capture/src/filters/resource_type.dart';

enum PartyRestriction {
  any(''),
  thirdPartyOnly('3'),
  firstPartyOnly('1');

  const PartyRestriction(this.code);

  final String code;
}

class NetworkRule {
  const NetworkRule({
    required this.exception,
    required this.pattern,
    this.types = const {},
    this.party = PartyRestriction.any,
    this.important = false,
    this.domains = const [],
  });

  final bool exception;
  final String pattern;

  /// Empty means every type.
  final Set<ResourceType> types;
  final PartyRestriction party;
  final bool important;

  /// Page domains the rule applies to; a leading `~` excludes one.
  final List<String> domains;

  String toRecord() {
    final flags = StringBuffer(party.code);
    if (important) flags.write('!');
    for (final type in types) {
      flags.write(type.code);
    }
    return [
      exception ? 'A' : 'B',
      pattern,
      flags,
      domains.join('|'),
    ].join('\t');
  }
}
