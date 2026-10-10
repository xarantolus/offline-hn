import 'package:flutter/material.dart';
import 'package:offline_hn/debug/looks/look_format.dart';
import 'package:offline_hn/debug/looks/look_kit.dart';
import 'package:offline_hn/debug/looks/look_palette.dart';
import 'package:offline_hn/debug/looks/look_widgets.dart';
import 'package:offline_hn/debug/mock_data.dart';

const _light = LookPalette(
  page: Color(0xFFF3F4F6),
  surface: Color(0xFFFFFFFF),
  hairline: Color(0xFFD8DBE0),
  text: Color(0xFF14161A),
  muted: Color(0xFF535966),
  accent: Color(0xFFB03F00),
  accentWash: Color(0xFFFCE8DA),
  marker: Color(0xFF00695C),
  codeBackground: Color(0xFFE9ECF0),
  brightness: Brightness.light,
);

const _dark = LookPalette(
  page: Color(0xFF111215),
  surface: Color(0xFF191B1F),
  hairline: Color(0xFF2E3138),
  text: Color(0xFFE7E9EE),
  muted: Color(0xFF9CA3AF),
  accent: Color(0xFFFF9A5C),
  accentWash: Color(0xFF3A2A1F),
  marker: Color(0xFF4DD0C0),
  codeBackground: Color(0xFF22252B),
  brightness: Brightness.dark,
);

class DenseLook extends LookKit {
  const DenseLook();

  @override
  String get name => 'Dense';

  @override
  String get summary => 'Compact rows, rank numerals, count badges';

  @override
  double get progressHeight => 2;

  @override
  SettingsStyle get settingsStyle => const SettingsStyle(
    density: VisualDensity.compact,
    usageBarHeight: 6,
    usageBarRadius: 1,
    sectionGap: Spacing.lg,
  );

  @override
  LookPalette paletteFor(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  @override
  Widget feedHeader(
    LookPalette p,
    FeedKind selected,
    ValueChanged<FeedKind> onSelected,
    String status,
  ) {
    return ColoredBox(
      color: p.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.sm,
          Spacing.md,
          Spacing.xs,
        ),
        child: Column(
          children: [
            SegmentedButton<FeedKind>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              style: SegmentedButton.styleFrom(
                foregroundColor: p.text,
                selectedForegroundColor: p.accent,
                selectedBackgroundColor: p.accentWash,
                side: BorderSide(color: p.hairline),
                visualDensity: const VisualDensity(vertical: -3),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                for (final k in FeedKind.values)
                  ButtonSegment(
                    value: k,
                    label: Text(k.name[0].toUpperCase() + k.name.substring(1)),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (s) => onSelected(s.first),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11.5, color: p.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget storyRow(LookPalette p, MockStory s, int position) {
    return ColoredBox(
      color: p.surface,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.sm, 7, Spacing.md, 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$position',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: s.read ? p.muted : p.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: s.domain ?? 'ask'),
                          TextSpan(
                            text:
                                ' · ${formatCount(s.points)} pts · '
                                '${formatAge(s.age)} · ${s.author}',
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              if (s.saved) ...[
                Icon(Icons.bookmark, size: 15, color: p.accent),
                const SizedBox(width: Spacing.sm),
              ],
              _CountBadge(palette: p, count: s.comments),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget feedSeparator(LookPalette p) =>
      Divider(height: 1, thickness: 1, color: p.hairline);

  @override
  Widget threadHeader(LookPalette p, MockThread thread) {
    final s = thread.story;
    return ColoredBox(
      color: p.surface,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.title,
              style: TextStyle(
                fontSize: 17,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '${s.domain ?? 'ask'} · ${formatCount(s.points)} pts · ${s.author} · '
              '${formatAge(s.age)}',
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                _Tag(
                  palette: p,
                  icon: Icons.offline_pin_outlined,
                  label: 'Offline',
                  color: p.accent,
                ),
                const SizedBox(width: Spacing.sm),
                _Tag(
                  palette: p,
                  icon: Icons.mode_comment_outlined,
                  label: '${thread.comments.length}',
                  color: p.muted,
                ),
                const SizedBox(width: Spacing.sm),
                _Tag(
                  palette: p,
                  icon: Icons.fiber_new,
                  label: '${thread.newCount} new',
                  color: p.marker,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget commentRow(
    LookPalette p,
    VisibleComment item,
    double textSize,
    VoidCallback onToggle,
  ) {
    final c = item.comment;
    final railColor = c.depth.isEven
        ? p.hairline
        : p.accent.withValues(alpha: 0.35);
    return ColoredBox(
      color: p.surface,
      child: DepthRails(
        depth: c.depth.clamp(0, 6),
        step: 11,
        width: 2,
        color: railColor,
        child: InkWell(
          onTap: item.hasChildren ? onToggle : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              c.depth == 0 ? Spacing.md : Spacing.sm,
              6,
              Spacing.md,
              6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Byline(p: p, item: item),
                if (!item.collapsed) ...[
                  const SizedBox(height: 3),
                  CommentBody(
                    blocks: c.blocks,
                    style: TextStyle(
                      fontSize: textSize - 1,
                      height: 1.33,
                      color: p.text,
                    ),
                    palette: p,
                    gap: 6,
                    codeRadius: 3,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget threadSeparator(LookPalette p) =>
      Divider(height: 1, thickness: 1, color: p.hairline);

  @override
  Widget entryBody(
    LookPalette p,
    MockStory s,
    ValueChanged<EntryAction> onAction,
  ) {
    final copy = s.savedCopy ?? mockThreadStory.savedCopy!;
    Widget fact(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(k, style: TextStyle(fontSize: 12.5, color: p.muted)),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: p.text,
              ),
            ),
          ),
        ],
      ),
    );
    Widget action(EntryAction a, {bool primary = false}) {
      final label = Text(a.label);
      final icon = Icon(a.icon, size: 18);
      final style = ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
      return SizedBox(
        width: double.infinity,
        child: primary
            ? FilledButton.icon(
                onPressed: () => onAction(a),
                icon: icon,
                label: label,
                style: style,
              )
            : OutlinedButton.icon(
                onPressed: () => onAction(a),
                icon: icon,
                label: label,
                style: style,
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: p.surface,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                fact('Source', s.domain ?? 'news.ycombinator.com'),
                Divider(height: 1, color: p.hairline),
                fact('Score', '${formatCount(s.points)} points'),
                Divider(height: 1, color: p.hairline),
                fact('Discussion', pluralize(s.comments, 'comment')),
                Divider(height: 1, color: p.hairline),
                fact('Posted', '${formatAge(s.age)} ago by ${s.author}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        ColoredBox(
          color: p.surface,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.offline_pin, size: 18, color: p.accent),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Saved copy · ${formatSize(copy.sizeMb)} · fetched ${copy.fetchedAt}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                action(EntryAction.openSaved, primary: true),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Expanded(child: action(EntryAction.openLive)),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: action(EntryAction.save)),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                action(EntryAction.share),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget settingsSection(LookPalette p, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            0,
            Spacing.md,
            Spacing.xs,
          ),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: p.muted,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: p.hairline),
        Material(
          color: p.surface,
          child: Column(children: children),
        ),
        Divider(height: 1, thickness: 1, color: p.hairline),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.palette, required this.count});

  final LookPalette palette;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: palette.accentWash,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        formatCount(count),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: palette.accent,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.palette,
    required this.icon,
    required this.label,
    required this.color,
  });

  final LookPalette palette;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: palette.hairline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Byline extends StatelessWidget {
  const _Byline({required this.p, required this.item});

  final LookPalette p;
  final VisibleComment item;

  @override
  Widget build(BuildContext context) {
    final c = item.comment;
    return Row(
      children: [
        Text(
          c.author,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.isOp ? p.accent : p.text,
          ),
        ),
        if (c.isOp) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: p.accentWash,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'OP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: p.accent,
              ),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(formatAge(c.age), style: TextStyle(fontSize: 12, color: p.muted)),
        if (c.isNew) ...[
          const SizedBox(width: 6),
          Icon(Icons.circle, size: 7, color: p.marker),
          const SizedBox(width: 3),
          Text(
            'new',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: p.marker,
            ),
          ),
        ],
        const Spacer(),
        if (item.collapsed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: p.accentWash,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${item.hiddenCount}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: p.accent,
              ),
            ),
          )
        else if (item.hasChildren)
          Icon(Icons.expand_less, size: 16, color: p.muted),
      ],
    );
  }
}
