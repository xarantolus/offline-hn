import 'package:page_capture/src/filters/cosmetic_rule.dart';
import 'package:page_capture/src/filters/network_rule.dart';

sealed class FilterLine {
  const FilterLine();
}

class BlankLine extends FilterLine {
  const BlankLine();
}

class NetworkLine extends FilterLine {
  const NetworkLine(this.rule);

  final NetworkRule rule;
}

class CosmeticLine extends FilterLine {
  const CosmeticLine(this.rule);

  final CosmeticRule rule;
}

class SkippedLine extends FilterLine {
  const SkippedLine(this.reason);

  final String reason;
}
