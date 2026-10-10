import 'package:flutter/material.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

class StoryRow extends StatelessWidget {
  const StoryRow({
    super.key,
    required this.title,
    required this.domain,
    required this.points,
    required this.comments,
    required this.author,
    required this.age,
    this.read = false,
    this.saved = false,
    this.onTap,
  });

  final String title;
  final String? domain;
  final int points;
  final int comments;
  final String author;
  final Duration age;
  final bool read;
  final bool saved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.gutter,
          vertical: 20,
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
                    '${domain ?? 'Ask HN'} · ${formatCount(points)} points · '
                    '${formatCount(comments)} comments',
                  ),
                ),
                if (saved) Icon(Icons.bookmark, size: 16, color: t.accent),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            SmallCaps('${formatAge(age)} ago · $author'),
          ],
        ),
      ),
    );
  }
}
