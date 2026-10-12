import 'package:linkify/linkify.dart';

const _trailing = '.,;:!?\'"';
final _scheme = RegExp(r'^https?://', caseSensitive: false);

class TextPart {
  const TextPart(this.text, {this.isLink = false});

  final String text;
  final bool isLink;
}

/// Splits plain text into text and http(s) addresses. Punctuation that ends
/// the sentence stays outside the address, and so does a closing bracket that
/// has no opening one inside it.
List<TextPart> splitBareLinks(String text) {
  final parts = <TextPart>[];
  void add(String value, {bool isLink = false}) {
    if (value.isEmpty) return;
    final last = parts.isEmpty ? null : parts.last;
    if (!isLink && last != null && !last.isLink) {
      parts[parts.length - 1] = TextPart(last.text + value);
    } else {
      parts.add(TextPart(value, isLink: isLink));
    }
  }

  final elements = linkify(
    text,
    options: const LinkifyOptions(humanize: false),
    linkifiers: const [UrlLinkifier()],
  );
  for (final element in elements) {
    if (element is! UrlElement) {
      add(element.text);
      continue;
    }
    if (!_scheme.hasMatch(element.originText)) {
      add(element.originText);
      continue;
    }
    final address = _addressEnd(element.text);
    add(address, isLink: true);
    add(element.text.substring(address.length));
  }
  return parts;
}

String _addressEnd(String candidate) {
  var end = candidate.length;
  while (end > 0) {
    final last = candidate[end - 1];
    if (_trailing.contains(last) ||
        (last == ')' && _unbalanced(candidate.substring(0, end)))) {
      end--;
    } else {
      break;
    }
  }
  return candidate.substring(0, end);
}

bool _unbalanced(String value) =>
    ')'.allMatches(value).length > '('.allMatches(value).length;
