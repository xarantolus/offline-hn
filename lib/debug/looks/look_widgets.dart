import 'package:flutter/material.dart';
import 'package:offline_hn/debug/looks/look_palette.dart';
import 'package:offline_hn/debug/mock_data.dart';

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
  const CommentBody({
    super.key,
    required this.blocks,
    required this.style,
    required this.palette,
    this.gap = Spacing.sm,
    this.codeRadius = 6,
  });

  final List<CommentBlock> blocks;
  final TextStyle style;
  final LookPalette palette;
  final double gap;
  final double codeRadius;

  @override
  Widget build(BuildContext context) {
    final link = style.copyWith(
      color: palette.accent,
      decoration: TextDecoration.underline,
      decorationColor: palette.accent,
    );
    final children = <Widget>[];
    for (final block in blocks) {
      if (children.isNotEmpty) children.add(SizedBox(height: gap));
      children.add(switch (block) {
        Paragraph(:final text) => Text.rich(
          TextSpan(children: linkify(text, link)),
          style: style,
        ),
        Quote(:final text) => _QuoteBar(
          color: palette.hairline,
          child: Text(text, style: style.copyWith(color: palette.muted)),
        ),
        CodeBlock(:final code) => ScrollingCode(
          code: code,
          palette: palette,
          fontSize: (style.fontSize ?? 14) * 0.86,
          radius: codeRadius,
        ),
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _QuoteBar extends StatelessWidget {
  const _QuoteBar({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: Spacing.md),
        child: child,
      ),
    );
  }
}

class ScrollingCode extends StatelessWidget {
  const ScrollingCode({
    super.key,
    required this.code,
    required this.palette,
    required this.fontSize,
    this.radius = 6,
  });

  final String code;
  final LookPalette palette;
  final double fontSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.codeBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.hairline),
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
            color: palette.text,
          ),
        ),
      ),
    );
  }
}

/// Vertical guide lines, one per nesting level. The rails of consecutive rows
/// touch, so they read as continuous lines down a thread.
class DepthRails extends StatelessWidget {
  const DepthRails({
    super.key,
    required this.depth,
    required this.step,
    required this.color,
    required this.child,
    this.width = 1,
  });

  final int depth;
  final double step;
  final Color color;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var result = child;
    for (var i = 0; i < depth; i++) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: width),
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
