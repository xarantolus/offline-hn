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
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.gutter,
          20,
          Spacing.sm,
          Spacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: Spacing.md),
              child: Text(title, style: read ? t.storyTitleRead : t.storyTitle),
            ),
            const SizedBox(height: Spacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: Spacing.md),
              child: Row(
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
            ),
            Row(
              children: [
                Expanded(child: SmallCaps(byline)),
                _CommentsButton(count: comments, onTap: onOpenComments),
              ],
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.mode_comment_outlined, size: 16, color: t.accent),
                const SizedBox(width: 6),
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
