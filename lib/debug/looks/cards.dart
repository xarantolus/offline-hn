import 'package:flutter/material.dart';
import 'package:offline_hn/debug/looks/look_format.dart';
import 'package:offline_hn/debug/looks/look_kit.dart';
import 'package:offline_hn/debug/looks/look_palette.dart';
import 'package:offline_hn/debug/looks/look_widgets.dart';
import 'package:offline_hn/debug/mock_data.dart';

const _light = LookPalette(
  page: Color(0xFFE8ECF2),
  surface: Color(0xFFFFFFFF),
  hairline: Color(0xFFD5DBE4),
  text: Color(0xFF12161C),
  muted: Color(0xFF4F5866),
  accent: Color(0xFFB03F00),
  accentWash: Color(0xFFFCE8DA),
  marker: Color(0xFF00695C),
  codeBackground: Color(0xFFF0F3F8),
  brightness: Brightness.light,
);

const _dark = LookPalette(
  page: Color(0xFF0F1115),
  surface: Color(0xFF1B1F26),
  hairline: Color(0xFF2D333D),
  text: Color(0xFFEEF0F4),
  muted: Color(0xFFA6AEBB),
  accent: Color(0xFFFF9A5C),
  accentWash: Color(0xFF3A2A1F),
  marker: Color(0xFF4DD0C0),
  codeBackground: Color(0xFF12151A),
  brightness: Brightness.dark,
);

const _radius = 16.0;

class CardsLook extends LookKit {
  const CardsLook();

  @override
  String get name => 'Cards';

  @override
  String get summary => 'Rounded cards, source monograms, pills';

  @override
  double get progressHeight => 3;

  @override
  EdgeInsets get feedPadding =>
      const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0);

  @override
  EdgeInsets get threadPadding =>
      const EdgeInsets.symmetric(horizontal: Spacing.md);

  @override
  SettingsStyle get settingsStyle => const SettingsStyle(
    usageBarHeight: 10,
    usageBarRadius: 5,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final k in FeedKind.values)
                ChoiceChip(
                  label: Text(k.name[0].toUpperCase() + k.name.substring(1)),
                  selected: k == selected,
                  showCheckmark: false,
                  selectedColor: p.accent,
                  backgroundColor: p.surface,
                  side: BorderSide(
                    color: k == selected ? p.accent : p.hairline,
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: k == selected
                        ? (p.isDark ? p.page : Colors.white)
                        : p.text,
                  ),
                  onSelected: (_) => onSelected(k),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Icon(Icons.wifi, size: 14, color: p.muted),
              const SizedBox(width: 6),
              Text(status, style: TextStyle(fontSize: 12.5, color: p.muted)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget storyRow(LookPalette p, MockStory s, int position) {
    final domain = s.domain ?? 'news.ycombinator.com';
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Monogram(domain: domain, palette: p, size: 32),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      s.domain ?? 'Ask HN',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.muted,
                      ),
                    ),
                  ),
                  Text(
                    formatAge(s.age),
                    style: TextStyle(fontSize: 12.5, color: p.muted),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(
                s.title,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                  color: s.read ? p.muted : p.text,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  _Pill(
                    palette: p,
                    icon: Icons.arrow_upward,
                    label: formatCount(s.points),
                    tinted: true,
                  ),
                  const SizedBox(width: Spacing.sm),
                  _Pill(
                    palette: p,
                    icon: Icons.mode_comment_outlined,
                    label: formatCount(s.comments),
                  ),
                  const Spacer(),
                  if (s.saved) Icon(Icons.bookmark, size: 20, color: p.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget feedSeparator(LookPalette p) => const SizedBox(height: Spacing.md);

  @override
  Widget threadHeader(LookPalette p, MockThread thread) {
    final s = thread.story;
    final domain = s.domain ?? 'news.ycombinator.com';
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.md),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Monogram(domain: domain, palette: p, size: 36),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                          ),
                        ),
                        Text(
                          '${s.author} · ${formatAge(s.age)} ago',
                          style: TextStyle(fontSize: 12.5, color: p.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(
                s.title,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  _Pill(
                    palette: p,
                    icon: Icons.offline_pin_outlined,
                    label: 'Offline',
                    tinted: true,
                  ),
                  _Pill(
                    palette: p,
                    icon: Icons.arrow_upward,
                    label: formatCount(s.points),
                  ),
                  _Pill(
                    palette: p,
                    icon: Icons.mode_comment_outlined,
                    label: '${thread.comments.length}',
                  ),
                  _Pill(
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
    final stripe = c.isOp
        ? p.accent
        : c.isNew
        ? p.marker
        : Colors.transparent;
    return Padding(
      padding: EdgeInsets.only(left: c.depth.clamp(0, 6) * 9.0),
      child: Material(
        color: p.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: item.hasChildren ? onToggle : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: stripe, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Byline(p: p, item: item),
                  if (!item.collapsed) ...[
                    const SizedBox(height: 6),
                    CommentBody(
                      blocks: c.blocks,
                      style: TextStyle(
                        fontSize: textSize,
                        height: 1.4,
                        color: p.text,
                      ),
                      palette: p,
                      codeRadius: 8,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget threadSeparator(LookPalette p) => const SizedBox(height: 6);

  @override
  Widget entryBody(
    LookPalette p,
    MockStory s,
    ValueChanged<EntryAction> onAction,
  ) {
    final copy = s.savedCopy ?? mockThreadStory.savedCopy!;
    final domain = s.domain ?? 'news.ycombinator.com';
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(_radius + 4),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Monogram(domain: domain, palette: p, size: 48),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    s.title,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.22,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    '$domain · ${s.author} · ${formatAge(s.age)} ago',
                    style: TextStyle(fontSize: 13.5, color: p.muted),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Wrap(
                    spacing: Spacing.sm,
                    children: [
                      _Pill(
                        palette: p,
                        icon: Icons.arrow_upward,
                        label: formatCount(s.points),
                        tinted: true,
                      ),
                      _Pill(
                        palette: p,
                        icon: Icons.mode_comment_outlined,
                        label: formatCount(s.comments),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Material(
            color: p.accentWash,
            borderRadius: BorderRadius.circular(_radius),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: [
                  Icon(Icons.offline_pin, color: p.accent, size: 28),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved copy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatSize(copy.sizeMb)} · fetched ${copy.fetchedAt}',
                          style: TextStyle(fontSize: 13.5, color: p.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => onAction(EntryAction.openSaved),
            icon: Icon(EntryAction.openSaved.icon),
            label: Text(EntryAction.openSaved.label),
          ),
          const SizedBox(height: Spacing.sm),
          FilledButton.tonalIcon(
            onPressed: () => onAction(EntryAction.openLive),
            icon: Icon(EntryAction.openLive.icon),
            label: Text(EntryAction.openLive.label),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAction(EntryAction.save),
                  icon: Icon(EntryAction.save.icon),
                  label: Text(EntryAction.save.label),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAction(EntryAction.share),
                  icon: Icon(EntryAction.share.icon),
                  label: Text(EntryAction.share.label),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget settingsSection(LookPalette p, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.sm, 0, 0, Spacing.sm),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: p.muted,
              ),
            ),
          ),
          Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(_radius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Square chip carrying the first letters of a domain, tinted by a hue that
/// is derived from the domain itself so a source always looks the same.
class Monogram extends StatelessWidget {
  const Monogram({
    super.key,
    required this.domain,
    required this.palette,
    required this.size,
  });

  final String domain;
  final LookPalette palette;
  final double size;

  static int _hue(String domain) {
    var h = 0;
    for (final unit in domain.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h % 360;
  }

  static String letters(String domain) {
    final parts = domain.split('.');
    final name = parts.length > 1 ? parts[parts.length - 2] : parts.first;
    return name.substring(0, name.length < 2 ? name.length : 2);
  }

  static (Color, Color) colorsFor(String domain, bool dark) {
    final hue = _hue(domain).toDouble();
    return dark
        ? (
            HSLColor.fromAHSL(1, hue, 0.35, 0.24).toColor(),
            HSLColor.fromAHSL(1, hue, 0.85, 0.82).toColor(),
          )
        : (
            HSLColor.fromAHSL(1, hue, 0.55, 0.9).toColor(),
            HSLColor.fromAHSL(1, hue, 0.7, 0.24).toColor(),
          );
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = colorsFor(domain, palette.isDark);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        letters(domain).toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.palette,
    required this.icon,
    required this.label,
    this.tinted = false,
    this.color,
  });

  final LookPalette palette;
  final IconData icon;
  final String label;
  final bool tinted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (tinted ? palette.accent : palette.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tinted ? palette.accentWash : palette.page,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
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
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
        ),
        if (c.isOp) ...[
          const SizedBox(width: 6),
          _Chip(label: 'OP', color: p.accent, background: p.accentWash),
        ],
        const SizedBox(width: 8),
        Text(
          formatAge(c.age),
          style: TextStyle(fontSize: 12.5, color: p.muted),
        ),
        if (c.isNew) ...[
          const SizedBox(width: 6),
          Text(
            'new',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: p.marker,
            ),
          ),
        ],
        const Spacer(),
        if (item.collapsed)
          _Chip(
            label: '+${item.hiddenCount} replies',
            color: p.accent,
            background: p.accentWash,
          )
        else if (item.hasChildren)
          Icon(Icons.expand_less, size: 18, color: p.muted),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
