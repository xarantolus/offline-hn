import 'package:flutter/material.dart';
import 'package:offline_hn/debug/looks/look_format.dart';
import 'package:offline_hn/debug/looks/look_kit.dart';
import 'package:offline_hn/debug/looks/look_palette.dart';
import 'package:offline_hn/debug/looks/look_widgets.dart';
import 'package:offline_hn/debug/mock_data.dart';

const _serif = 'serif';
const _gutter = 22.0;

const _light = LookPalette(
  page: Color(0xFFFBF9F4),
  surface: Color(0xFFFBF9F4),
  hairline: Color(0xFFDAD4C6),
  text: Color(0xFF1C1B18),
  muted: Color(0xFF5C584E),
  accent: Color(0xFFB03F00),
  accentWash: Color(0xFFFCE8DA),
  marker: Color(0xFF00695C),
  codeBackground: Color(0xFFF1EDE3),
  brightness: Brightness.light,
);

const _dark = LookPalette(
  page: Color(0xFF1A1917),
  surface: Color(0xFF1A1917),
  hairline: Color(0xFF3A3731),
  text: Color(0xFFECE8DF),
  muted: Color(0xFFABA598),
  accent: Color(0xFFFF9A5C),
  accentWash: Color(0xFF3A2A1F),
  marker: Color(0xFF4DD0C0),
  codeBackground: Color(0xFF242320),
  brightness: Brightness.dark,
);

class EditorialLook extends LookKit {
  const EditorialLook();

  @override
  String get name => 'Editorial';

  @override
  String get summary => 'Serif headlines, whitespace, hairlines';

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
        _gutter,
        Spacing.lg,
        _gutter,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final kind in FeedKind.values)
                _Section(
                  palette: p,
                  label: kind.name,
                  selected: kind == selected,
                  onTap: () => onSelected(kind),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SmallCaps(status, p),
        ],
      ),
    );
  }

  @override
  Widget storyRow(LookPalette p, MockStory s, int position) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _gutter, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.title,
              style: TextStyle(
                fontFamily: _serif,
                fontSize: 21,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: s.read ? p.muted : p.text,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: SmallCaps(
                    '${s.domain ?? 'Ask HN'} · ${formatCount(s.points)} points · '
                    '${formatCount(s.comments)} comments',
                    p,
                  ),
                ),
                if (s.saved) Icon(Icons.bookmark, size: 16, color: p.accent),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            SmallCaps('${formatAge(s.age)} ago · ${s.author}', p),
          ],
        ),
      ),
    );
  }

  @override
  Widget feedSeparator(LookPalette p) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _gutter),
    child: Divider(height: 1, thickness: 1, color: p.hairline),
  );

  @override
  Widget threadHeader(LookPalette p, MockThread thread) {
    final s = thread.story;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _gutter,
        Spacing.xl,
        _gutter,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmallCaps(s.domain ?? 'Ask HN', p),
          const SizedBox(height: Spacing.sm),
          Text(
            s.title,
            style: TextStyle(
              fontFamily: _serif,
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          const SizedBox(height: Spacing.md),
          SmallCaps(
            'By ${s.author} · ${formatCount(s.points)} points · '
            '${pluralize(thread.comments.length, 'comment')}',
            p,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Icon(Icons.offline_pin_outlined, size: 16, color: p.accent),
              const SizedBox(width: Spacing.sm),
              SmallCaps(
                'Available offline · ${thread.newCount} new',
                p,
                color: p.accent,
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Divider(height: 1, thickness: 1, color: p.hairline),
        ],
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
    final body = TextStyle(
      fontFamily: _serif,
      fontSize: textSize + 1,
      height: 1.5,
      color: p.text,
    );
    return DepthRails(
      depth: c.depth.clamp(0, 6),
      step: 16,
      color: p.hairline,
      child: InkWell(
        onTap: item.hasChildren || item.collapsed ? onToggle : null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            c.depth == 0 ? _gutter : Spacing.md,
            Spacing.md,
            _gutter,
            Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentByline(p: p, item: item),
              if (!item.collapsed) ...[
                const SizedBox(height: Spacing.sm),
                CommentBody(
                  blocks: c.blocks,
                  style: body,
                  palette: p,
                  gap: Spacing.md,
                  codeRadius: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget threadSeparator(LookPalette p) => const SizedBox.shrink();

  @override
  Widget entryBody(
    LookPalette p,
    MockStory s,
    ValueChanged<EntryAction> onAction,
  ) {
    final copy = s.savedCopy ?? mockThreadStory.savedCopy!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, Spacing.xl, _gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmallCaps(s.domain ?? 'Ask HN', p),
          const SizedBox(height: Spacing.md),
          Text(
            s.title,
            style: TextStyle(
              fontFamily: _serif,
              fontSize: 30,
              height: 1.18,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SmallCaps(
            'By ${s.author} · ${formatAge(s.age)} ago · '
            '${formatCount(s.points)} points',
            p,
          ),
          const SizedBox(height: Spacing.xl),
          Divider(height: 1, thickness: 1, color: p.hairline),
          const SizedBox(height: Spacing.lg),
          SmallCaps('Saved copy', p, color: p.accent),
          const SizedBox(height: Spacing.sm),
          Text(
            '${formatSize(copy.sizeMb)} · fetched ${copy.fetchedAt}',
            style: TextStyle(fontFamily: _serif, fontSize: 19, color: p.text),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Readable without a connection.',
            style: TextStyle(fontFamily: _serif, fontSize: 15, color: p.muted),
          ),
          const SizedBox(height: Spacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onAction(EntryAction.openSaved),
              icon: Icon(EntryAction.openSaved.icon),
              label: Text(EntryAction.openSaved.label),
            ),
          ),
          const SizedBox(height: Spacing.md),
          for (final a in const [
            EntryAction.openLive,
            EntryAction.save,
            EntryAction.share,
          ])
            _ActionRow(palette: p, action: a, onTap: () => onAction(a)),
        ],
      ),
    );
  }

  @override
  Widget settingsSection(LookPalette p, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _gutter),
          child: SmallCaps(title, p, color: p.accent),
        ),
        const SizedBox(height: Spacing.sm),
        Divider(height: 1, thickness: 1, color: p.hairline),
        Material(
          color: Colors.transparent,
          child: Column(children: children),
        ),
        Divider(height: 1, thickness: 1, color: p.hairline),
      ],
    );
  }
}

class SmallCaps extends StatelessWidget {
  const SmallCaps(this.text, this.palette, {super.key, this.color});

  final String text;
  final LookPalette palette;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        height: 1.3,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
        color: color ?? palette.muted,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final LookPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: Spacing.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? palette.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label[0].toUpperCase() + label.substring(1),
            style: TextStyle(
              fontFamily: _serif,
              fontSize: 18,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? palette.accent : palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentByline extends StatelessWidget {
  const _CommentByline({required this.p, required this.item});

  final LookPalette p;
  final VisibleComment item;

  @override
  Widget build(BuildContext context) {
    final c = item.comment;
    return Row(
      children: [
        Flexible(child: SmallCaps(c.author, p, color: p.text)),
        if (c.isOp) ...[
          const SizedBox(width: Spacing.sm),
          SmallCaps('Author', p, color: p.accent),
        ],
        const SizedBox(width: Spacing.sm),
        SmallCaps(formatAge(c.age), p),
        if (c.isNew) ...[
          const SizedBox(width: Spacing.sm),
          SmallCaps('New', p, color: p.marker),
        ],
        const Spacer(),
        if (item.collapsed)
          SmallCaps(
            '+${pluralize(item.hiddenCount, 'reply', 'replies')}',
            p,
            color: p.accent,
          )
        else if (item.hasChildren)
          Icon(Icons.expand_less, size: 18, color: p.muted),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.palette,
    required this.action,
    required this.onTap,
  });

  final LookPalette palette;
  final EntryAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: palette.hairline),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Row(
              children: [
                Icon(action.icon, size: 20, color: palette.accent),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Text(
                    action.label,
                    style: TextStyle(
                      fontFamily: _serif,
                      fontSize: 18,
                      color: palette.text,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
