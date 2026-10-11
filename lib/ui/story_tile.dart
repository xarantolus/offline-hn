import 'package:flutter/material.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

class StoryTile extends StatelessWidget {
  const StoryTile({
    super.key,
    required this.title,
    required this.source,
    required this.points,
    required this.comments,
    required this.author,
    required this.age,
    this.read = false,
    this.saved = false,
    this.hasCopy = false,
    this.onTap,
    this.onLongPress,
    this.onOpenComments,
  });

  final String title;
  final String source;
  final int? points;
  final int comments;
  final String? author;
  final Duration age;
  final bool read;
  final bool saved;
  final bool hasCopy;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpenComments;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final byline = ['${formatAge(age)} ago', ?author].join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.gutter,
                  20,
                  Spacing.md,
                  Spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: read ? t.storyTitleRead : t.storyTitle),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: SmallCaps(
                            [
                              source,
                              if (points != null) pluralize(points!, 'point'),
                            ].join(' · '),
                          ),
                        ),
                        if (hasCopy)
                          Padding(
                            padding: const EdgeInsets.only(left: Spacing.sm),
                            child: Icon(
                              Icons.offline_pin_outlined,
                              size: 16,
                              color: t.muted,
                              semanticLabel: 'Saved copy',
                            ),
                          ),
                        if (saved)
                          Padding(
                            padding: const EdgeInsets.only(left: Spacing.sm),
                            child: Icon(
                              Icons.bookmark,
                              size: 16,
                              color: t.accent,
                              semanticLabel: 'Bookmarked',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    SmallCaps(byline),
                  ],
                ),
              ),
            ),
          ),
          _CommentsButton(count: comments, onTap: onOpenComments),
        ],
      ),
    );
  }
}

class _CommentsButton extends StatelessWidget {
  const _CommentsButton({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: pluralize(count, 'comment'),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: t.hairline)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                Icon(Icons.mode_comment_outlined, size: 20, color: t.accent),
                Text(
                  formatCount(count),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
