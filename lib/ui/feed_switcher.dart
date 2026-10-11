import 'package:flutter/material.dart';
import 'package:offline_hn/data/model/feed_tab.dart';
import 'package:offline_hn/ui/tokens.dart';

class FeedSwitcher extends StatelessWidget {
  const FeedSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
    this.tabs = FeedTab.values,
    this.status,
  });

  final FeedTab selected;
  final ValueChanged<FeedTab> onSelected;
  final List<FeedTab> tabs;
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
          SegmentedButton<FeedTab>(
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
              for (final tab in tabs)
                ButtonSegment(value: tab, label: Text(tab.label)),
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
