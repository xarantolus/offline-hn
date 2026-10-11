import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:offline_hn/comments/comment_block.dart';
import 'package:offline_hn/ui/comment_body.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/reveal.dart';
import 'package:offline_hn/ui/selection_guard.dart';
import 'package:offline_hn/ui/tokens.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({
    super.key,
    required this.author,
    required this.age,
    required this.depth,
    required this.blocks,
    this.isOp = false,
    this.isNew = false,
    this.startsGroup = false,
    this.collapsed = false,
    this.hiddenCount = 0,
    this.textSize = 15,
    this.onToggle,
    this.onLink,
    this.selectionGuard,
  });

  final String author;
  final Duration age;
  final int depth;
  final List<CommentBlock> blocks;
  final bool isOp;
  final bool isNew;
  final bool startsGroup;
  final bool collapsed;
  final int hiddenCount;
  final double textSize;
  final VoidCallback? onToggle;
  final LinkHandler? onLink;
  final SelectionGuard? selectionGuard;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  final _area = GlobalKey<SelectionAreaState>();

  void _selectionChanged(SelectedContent? content) {
    widget.selectionGuard?.changed(
      this,
      selected: content != null && content.plainText.isNotEmpty,
      clear: () => _area.currentState?.selectableRegion.clearSelection(),
    );
  }

  void _tap() {
    if (widget.selectionGuard?.dismiss() ?? false) return;
    widget.onToggle?.call();
  }

  @override
  void dispose() {
    widget.selectionGuard?.changed(this, selected: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = DepthRails(
      depth: widget.depth.clamp(0, 6),
      child: SelectionArea(
        key: _area,
        onSelectionChanged: _selectionChanged,
        child: InkWell(
          onTap: _tap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              widget.depth == 0 ? Spacing.gutter : Spacing.sm,
              widget.startsGroup ? Spacing.md : Spacing.sm,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Byline(row: widget),
                Reveal(
                  open: !widget.collapsed,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: CommentBody(
                      blocks: widget.blocks,
                      textSize: widget.textSize - 1,
                      onLink: widget.onLink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!widget.startsGroup) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.sm),
        Divider(height: 1, thickness: 1, color: context.tokens.divider),
        tile,
      ],
    );
  }
}

class _Byline extends StatelessWidget {
  const _Byline({required this.row});

  final CommentTile row;

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
        if (row.collapsed && row.hiddenCount > 0)
          _Pill(label: '+${row.hiddenCount}', size: 11.5, radius: 8)
        else
          Icon(
            row.collapsed ? Icons.expand_more : Icons.expand_less,
            size: 16,
            color: t.muted,
          ),
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
