import 'package:flutter/foundation.dart';

@immutable
sealed class Inline {
  const Inline();
}

class TextRun extends Inline {
  const TextRun(this.text, {this.italic = false});

  final String text;
  final bool italic;
}

class LinkRun extends Inline {
  const LinkRun({required this.uri, required this.label, this.itemId});

  final Uri uri;
  final String label;

  /// Set when the link points at a Hacker News item.
  final int? itemId;
}

@immutable
sealed class CommentBlock {
  const CommentBlock();
}

class Paragraph extends CommentBlock {
  const Paragraph(this.inlines);

  final List<Inline> inlines;
}

/// Consecutive quoted paragraphs share one bar.
class Quote extends CommentBlock {
  const Quote(this.paragraphs);

  final List<List<Inline>> paragraphs;
}

class CodeBlock extends CommentBlock {
  const CodeBlock(this.code);

  final String code;
}
