import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:offline_hn/comments/comment_block.dart';
import 'package:offline_hn/ui/saved_links.dart';
import 'package:offline_hn/ui/tokens.dart';

typedef LinkHandler = void Function(LinkRun link);

class CommentBody extends StatelessWidget {
  const CommentBody({
    super.key,
    required this.blocks,
    required this.textSize,
    this.onLink,
  });

  final List<CommentBlock> blocks;
  final double textSize;
  final LinkHandler? onLink;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = t.commentBody(textSize);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        for (final block in blocks)
          switch (block) {
            Paragraph(:final inlines) => InlineText(
              inlines: inlines,
              style: style,
              onLink: onLink,
            ),
            Quote(:final paragraphs) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: t.hairline, width: 3)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    for (final paragraph in paragraphs)
                      InlineText(
                        inlines: paragraph,
                        style: style.copyWith(color: t.muted),
                        onLink: onLink,
                      ),
                  ],
                ),
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

class InlineText extends StatefulWidget {
  const InlineText({
    super.key,
    required this.inlines,
    required this.style,
    this.onLink,
  });

  final List<Inline> inlines;
  final TextStyle style;
  final LinkHandler? onLink;

  @override
  State<InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<InlineText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final accent = context.tokens.accent;
    final link = widget.style.copyWith(
      color: accent,
      decoration: TextDecoration.underline,
      decorationColor: accent,
    );
    final spans = <InlineSpan>[];
    for (final inline in widget.inlines) {
      switch (inline) {
        case TextRun(:final text, :final italic):
          spans.add(
            TextSpan(
              text: text,
              style: italic
                  ? const TextStyle(fontStyle: FontStyle.italic)
                  : null,
            ),
          );
        case LinkRun():
          final onLink = widget.onLink;
          final recognizer = onLink == null
              ? null
              : (TapGestureRecognizer()..onTap = () => onLink(inline));
          if (recognizer != null) _recognizers.add(recognizer);
          spans.add(
            TextSpan(text: inline.label, style: link, recognizer: recognizer),
          );
          if (SavedLinks.has(context, inline.uri)) {
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Icon(
                    Icons.offline_pin_outlined,
                    size: (widget.style.fontSize ?? 14) * 0.9,
                    color: context.tokens.muted,
                    semanticLabel: 'Saved copy',
                  ),
                ),
              ),
            );
          }
      }
    }
    return Text.rich(TextSpan(children: spans), style: widget.style);
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
    this.inset = Spacing.railInset,
  });

  final int depth;
  final double inset;
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
            left: BorderSide(color: t.railColor(level), width: width),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: step - width),
          child: result,
        ),
      );
    }
    return depth == 0
        ? result
        : Padding(
            padding: EdgeInsets.only(left: inset),
            child: result,
          );
  }
}
