import 'package:flutter/foundation.dart';

@immutable
sealed class CommentBlock {
  const CommentBlock();
}

class Paragraph extends CommentBlock {
  const Paragraph(this.text);

  final String text;
}

class Quote extends CommentBlock {
  const Quote(this.text);

  final String text;
}

class CodeBlock extends CommentBlock {
  const CodeBlock(this.code);

  final String code;
}
