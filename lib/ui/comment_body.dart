import 'package:flutter/material.dart';
import 'package:offline_hn/ui/comment_block.dart';
import 'package:offline_hn/ui/tokens.dart';

final _link = RegExp(r'https?://\S+');

List<InlineSpan> linkify(String text, TextStyle linkStyle) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final m in _link.allMatches(text)) {
    var url = m.group(0)!;
    while (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
      url = url.substring(0, url.length - 1);
    }
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start)));
    }
    spans.add(TextSpan(text: url, style: linkStyle));
    cursor = m.start + url.length;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}

class CommentBody extends StatelessWidget {
  const CommentBody({super.key, required this.blocks, required this.textSize});

  final List<CommentBlock> blocks;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = t.commentBody(textSize);
    final link = style.copyWith(
      color: t.accent,
      decoration: TextDecoration.underline,
      decorationColor: t.accent,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        for (final block in blocks)
          switch (block) {
            Paragraph(:final text) => Text.rich(
              TextSpan(children: linkify(text, link)),
              style: style,
            ),
            Quote(:final text) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: t.hairline, width: 3)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: Spacing.md),
                child: Text(text, style: style.copyWith(color: t.muted)),
              ),
            ),
            CodeBlock(:final code) => ScrollingCode(
              code: code,
              fontSize: textSize * 0.86,
            ),
          },
      ],
    );
  }
}

class ScrollingCode extends StatelessWidget {
  const ScrollingCode({super.key, required this.code, required this.fontSize});

  final String code;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.codeBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: t.hairline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(Spacing.md),
        child: Text(
          code,
          softWrap: false,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            height: 1.4,
            color: t.text,
          ),
        ),
      ),
    );
  }
}

class DepthRails extends StatelessWidget {
  const DepthRails({
    super.key,
    required this.depth,
    required this.child,
    this.step = 11,
    this.width = 2,
  });

  final int depth;
  final double step;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    var result = child;
    for (var level = depth - 1; level >= 0; level--) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: level.isEven
                  ? t.hairline
                  : t.accent.withValues(alpha: 0.35),
              width: width,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: step - width),
          child: result,
        ),
      );
    }
    return result;
  }
}
