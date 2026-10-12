import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:offline_hn/comments/bare_links.dart';
import 'package:offline_hn/comments/comment_block.dart';

const _maxLinkLabel = 44;
final _quoteMark = RegExp(r'^(>(?!=)\s*)+');
final _whitespace = RegExp(r'\s+');

/// HN comment markup is `<p>`, `<i>`, `<a>` and `<pre><code>`; quoting is the
/// convention of starting a paragraph with ">".
List<CommentBlock> parseCommentHtml(String? source) {
  if (source == null || source.trim().isEmpty) return const [];
  final blocks = <CommentBlock>[];
  var inlines = <Inline>[];

  void flush() {
    final line = _trimmed(inlines);
    inlines = [];
    if (line.isEmpty) return;
    final quoted = _unquoted(line);
    if (quoted == null) {
      blocks.add(Paragraph(line));
    } else if (quoted.isNotEmpty) {
      if (blocks.isNotEmpty && blocks.last is Quote) {
        final last = blocks.removeLast() as Quote;
        blocks.add(Quote([...last.paragraphs, quoted]));
      } else {
        blocks.add(Quote([quoted]));
      }
    }
  }

  for (final node in html_parser.parseFragment(source).nodes) {
    if (node is Element && node.localName == 'pre') {
      flush();
      final code = dedent(node.text);
      if (code.isNotEmpty) blocks.add(CodeBlock(code));
    } else if (node is Element && node.localName == 'p') {
      flush();
      _collect(node, inlines, italic: false);
      flush();
    } else {
      _collect(node, inlines, italic: false);
    }
  }
  flush();
  return blocks;
}

void _collect(
  Node node,
  List<Inline> out, {
  required bool italic,
  bool linkify = true,
}) {
  if (node is Text) {
    final text = node.data.replaceAll(_whitespace, ' ');
    if (text.isEmpty) return;
    if (!linkify) {
      out.add(TextRun(text, italic: italic));
      return;
    }
    for (final part in splitBareLinks(text)) {
      final uri = part.isLink ? Uri.tryParse(part.text) : null;
      out.add(
        uri == null
            ? TextRun(part.text, italic: italic)
            : LinkRun(uri: uri, label: part.text, itemId: hnItemId(uri)),
      );
    }
    return;
  }
  if (node is! Element) return;
  switch (node.localName) {
    case 'a':
      final uri = Uri.tryParse(node.attributes['href'] ?? '');
      final label = node.text.replaceAll(_whitespace, ' ');
      if (uri == null || !uri.hasScheme) {
        out.add(TextRun(label, italic: italic));
      } else {
        out.add(
          LinkRun(
            uri: uri,
            label: shortLinkLabel(uri, label),
            itemId: hnItemId(uri),
          ),
        );
      }
    case 'code':
      for (final child in node.nodes) {
        _collect(child, out, italic: italic, linkify: false);
      }
    case 'br':
      out.add(const TextRun('\n'));
    case 'i' || 'em':
      for (final child in node.nodes) {
        _collect(child, out, italic: true);
      }
    default:
      for (final child in node.nodes) {
        _collect(child, out, italic: italic);
      }
  }
}

/// Trimmed at both ends, with runs of the same style joined.
List<Inline> _trimmed(List<Inline> runs) {
  final joined = <Inline>[];
  for (final run in runs) {
    final last = joined.isEmpty ? null : joined.last;
    if (run is TextRun && last is TextRun && last.italic == run.italic) {
      joined[joined.length - 1] = TextRun(
        last.text + run.text,
        italic: run.italic,
      );
    } else {
      joined.add(run);
    }
  }
  if (joined.isNotEmpty && joined.first is TextRun) {
    final first = joined.first as TextRun;
    joined[0] = TextRun(first.text.trimLeft(), italic: first.italic);
  }
  if (joined.isNotEmpty && joined.last is TextRun) {
    final last = joined.last as TextRun;
    joined[joined.length - 1] = TextRun(
      last.text.trimRight(),
      italic: last.italic,
    );
  }
  return [
    for (final run in joined)
      if (run is! TextRun || run.text.isNotEmpty) run,
  ];
}

/// The paragraph without its ">" marks, or null when it is not a quote.
List<Inline>? _unquoted(List<Inline> line) {
  final first = line.first;
  if (first is! TextRun || !_quoteMark.hasMatch(first.text)) return null;
  final rest = first.text.replaceFirst(_quoteMark, '');
  return [
    if (rest.isNotEmpty) TextRun(rest, italic: first.italic),
    ...line.skip(1),
  ];
}

/// Removes the indentation every non-blank line shares, and blank lines at
/// both ends.
String dedent(String code) {
  final lines = code.replaceAll('\r', '').split('\n');
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  while (lines.isNotEmpty && lines.first.trim().isEmpty) {
    lines.removeAt(0);
  }
  var shared = -1;
  for (final line in lines.where((l) => l.trim().isNotEmpty)) {
    final indent = line.length - line.trimLeft().length;
    if (shared < 0 || indent < shared) shared = indent;
  }
  if (shared <= 0) return lines.join('\n');
  return lines
      .map((l) => l.trim().isEmpty ? '' : l.substring(shared))
      .join('\n');
}

/// Every address a reader can tap, in order: the links the markup carries and
/// the bare ones in its text.
List<Uri> linksInHtml(String? source) => [
  for (final block in parseCommentHtml(source))
    ...switch (block) {
      Paragraph(:final inlines) => _linksOf(inlines),
      Quote(:final paragraphs) => paragraphs.expand(_linksOf),
      CodeBlock() => const <Uri>[],
    },
];

Iterable<Uri> _linksOf(List<Inline> inlines) =>
    inlines.whereType<LinkRun>().map((run) => run.uri);

int? hnItemId(Uri uri) {
  final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
  if (host != 'news.ycombinator.com' || uri.path != '/item') return null;
  return int.tryParse(uri.queryParameters['id'] ?? '');
}

/// HN cuts long link text at 70 characters and adds "...", which can end
/// mid-word; the real address is shown instead, shortened to fit a line.
String shortLinkLabel(Uri uri, String label) {
  if (!label.endsWith('...') && !label.endsWith('…')) return label;
  final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
  var shown = '$host${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
  if (shown.endsWith('/')) shown = shown.substring(0, shown.length - 1);
  if (shown.length <= _maxLinkLabel) return shown;
  return '${shown.substring(0, _maxLinkLabel - 1)}…';
}
