import 'package:flutter/material.dart';
import 'package:offline_hn/comments/comment_parser.dart';
import 'package:offline_hn/data/model/comment_order.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/repository/settings_store.dart';
import 'package:offline_hn/ui/comment_tile.dart';
import 'package:offline_hn/ui/commit_slider.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';

const _baseSize = 15.0;
const _minSize = 12.0;
const _maxSize = 22.0;

final _sample = parseCommentHtml(
  'Nice write-up. The retry section is the best part, and the '
  '<i>backoff</i> reference is worth a read: '
  '<a href="https://example.org/backoff">https://example.org/backoff</a>',
);

String _orderLabel(CommentOrder order) => switch (order) {
  CommentOrder.hn => 'HN order',
  CommentOrder.oldest => 'Oldest first',
  CommentOrder.newest => 'Newest first',
};

class ReadingSection extends StatefulWidget {
  const ReadingSection({
    super.key,
    required this.store,
    required this.textScale,
    required this.order,
  });

  final SettingsStore store;
  final double textScale;
  final CommentOrder order;

  @override
  State<ReadingSection> createState() => _ReadingSectionState();
}

class _ReadingSectionState extends State<ReadingSection> {
  double? _preview;

  double get _size => _preview ?? widget.textScale * _baseSize;

  @override
  void didUpdateWidget(ReadingSection old) {
    super.didUpdateWidget(old);
    if (old.textScale != widget.textScale) _preview = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SettingsSection(
      title: 'Reading',
      children: [
        ListTile(
          title: Text('Comment text size', style: t.label),
          trailing: Text('${_size.round()} pt', style: t.label),
        ),
        CommitSlider(
          value: widget.textScale * _baseSize,
          min: _minSize,
          max: _maxSize,
          divisions: (_maxSize - _minSize).round(),
          label: (v) => '${v.round()}',
          onChanged: (v) => setState(() => _preview = v),
          onCommit: (v) => widget.store.set(
            Settings.commentTextScale,
            v.roundToDouble() / _baseSize,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: CommentTile(
            author: 'pgrunwald',
            age: const Duration(minutes: 22),
            depth: 0,
            textSize: _size,
            blocks: _sample,
          ),
        ),
        ListTile(
          title: Text('Comment order', style: t.label),
          subtitle: Text(
            'HN order is the ranking the site shows; replies '
            'always read oldest first',
            style: t.hint,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.gutter,
            0,
            Spacing.gutter,
            Spacing.lg,
          ),
          child: SegmentedButton<CommentOrder>(
            showSelectedIcon: false,
            segments: [
              for (final order in CommentOrder.values)
                ButtonSegment(value: order, label: Text(_orderLabel(order))),
            ],
            selected: {widget.order},
            onSelectionChanged: (s) =>
                widget.store.set(Settings.commentOrder, s.single),
          ),
        ),
      ],
    );
  }
}
