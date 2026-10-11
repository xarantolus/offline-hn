import 'package:flutter/material.dart';
import 'package:offline_hn/comments/comment_block.dart';
import 'package:offline_hn/ui/comment_body.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/tokens.dart';

class CommentRow extends StatelessWidget {
  const CommentRow({
    super.key,
    required this.author,
    required this.age,
    required this.depth,
    required this.blocks,
    this.isOp = false,
    this.isNew = false,
    this.collapsed = false,
    this.hiddenCount = 0,
    this.hasChildren = false,
    this.textSize = 15,
    this.onToggle,
    this.onLink,
  });

  final String author;
  final Duration age;
  final int depth;
  final List<CommentBlock> blocks;
  final bool isOp;
  final bool isNew;
  final bool collapsed;
  final int hiddenCount;
  final bool hasChildren;
  final double textSize;
  final VoidCallback? onToggle;
  final LinkHandler? onLink;

  @override
  Widget build(BuildContext context) {
    return DepthRails(
      depth: depth.clamp(0, 6),
      child: InkWell(
        onTap: hasChildren ? onToggle : null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            depth == 0 ? Spacing.gutter : Spacing.sm,
            Spacing.sm,
            Spacing.lg,
            Spacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Byline(row: this),
              if (!collapsed) ...[
                const SizedBox(height: 3),
                CommentBody(
                  blocks: blocks,
                  textSize: textSize - 1,
                  onLink: onLink,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Byline extends StatelessWidget {
  const _Byline({required this.row});

  final CommentRow row;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Row(
            spacing: 6,
            children: [
              Flexible(
                child: Text(
                  row.author,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: row.isOp ? t.accent : t.text,
                  ),
                ),
              ),
              if (row.isOp)
                const _Pill(label: 'OP', size: 10, weight: FontWeight.w800),
              Text(
                formatAge(row.age),
                style: TextStyle(fontSize: 12, color: t.muted),
              ),
              if (row.isNew) ...[
                Icon(Icons.circle, size: 7, color: t.marker),
                Text(
                  'new',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.marker,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (row.collapsed)
          _Pill(label: '+${row.hiddenCount}', size: 11.5, radius: 8)
        else if (row.hasChildren)
          Icon(Icons.expand_less, size: 16, color: t.muted),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.size,
    this.weight = FontWeight.w700,
    this.radius = 3,
  });

  final String label;
  final double size;
  final FontWeight weight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accentWash,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          label,
          style: TextStyle(fontSize: size, fontWeight: weight, color: t.accent),
        ),
      ),
    );
  }
}
