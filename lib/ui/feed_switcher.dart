import 'package:flutter/material.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/ui/tokens.dart';

extension FeedKindLabel on FeedKind {
  String get label => name[0].toUpperCase() + name.substring(1);
}

class FeedSwitcher extends StatelessWidget {
  const FeedSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
    this.status,
  });

  final FeedKind selected;
  final ValueChanged<FeedKind> onSelected;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.lg,
        Spacing.gutter,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<FeedKind>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            style: SegmentedButton.styleFrom(
              foregroundColor: t.muted,
              selectedForegroundColor: t.accent,
              selectedBackgroundColor: t.accentWash,
              side: BorderSide(color: t.hairline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: t.switcher,
              visualDensity: const VisualDensity(vertical: -2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              for (final kind in FeedKind.values)
                ButtonSegment(value: kind, label: Text(kind.label)),
            ],
            selected: {selected},
            onSelectionChanged: (s) => onSelected(s.first),
          ),
          if (status != null) ...[const SizedBox(height: Spacing.md), status!],
        ],
      ),
    );
  }
}
