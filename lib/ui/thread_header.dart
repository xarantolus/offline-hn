import 'package:flutter/material.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

class SavedCopyInfo {
  const SavedCopyInfo({required this.sizeMb, required this.fetchedAt});

  final double sizeMb;
  final String fetchedAt;
}

class ThreadHeader extends StatelessWidget {
  const ThreadHeader({
    super.key,
    required this.title,
    required this.domain,
    required this.author,
    required this.points,
    required this.comments,
    required this.newComments,
    required this.savedCopy,
    this.onOpenSaved,
    this.onOpenLive,
    this.onSave,
    this.onShare,
  });

  final String title;
  final String? domain;
  final String author;
  final int points;
  final int comments;
  final int newComments;
  final SavedCopyInfo? savedCopy;
  final VoidCallback? onOpenSaved;
  final VoidCallback? onOpenLive;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

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
          SmallCaps(domain ?? 'Ask HN', color: t.accent),
          const SizedBox(height: Spacing.sm),
          Text(title, style: t.threadTitle),
          const SizedBox(height: Spacing.md),
          Text.rich(
            TextSpan(
              style: t.smallCaps,
              children: [
                TextSpan(
                  text:
                      'By $author · ${formatCount(points)} points · '
                              '${formatCount(comments)} comments'
                          .toUpperCase(),
                ),
                if (newComments > 0)
                  TextSpan(
                    text: ' · $newComments NEW',
                    style: TextStyle(color: t.marker),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          _CopyPanel(
            savedCopy: savedCopy,
            onOpenSaved: onOpenSaved,
            onOpenLive: onOpenLive,
            onSave: onSave,
            onShare: onShare,
          ),
        ],
      ),
    );
  }
}

class _CopyPanel extends StatelessWidget {
  const _CopyPanel({
    required this.savedCopy,
    this.onOpenSaved,
    this.onOpenLive,
    this.onSave,
    this.onShare,
  });

  final SavedCopyInfo? savedCopy;
  final VoidCallback? onOpenSaved;
  final VoidCallback? onOpenLive;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final copy = savedCopy;
    final style = TextStyle(fontSize: 13, color: t.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Hairline(),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Icon(
              copy == null ? Icons.cloud_outlined : Icons.offline_pin_outlined,
              size: 17,
              color: copy == null ? t.muted : t.accent,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                copy == null
                    ? 'No saved copy · live site only'
                    : 'Saved copy · ${formatSize(copy.sizeMb)} · '
                          'fetched ${copy.fetchedAt}',
                style: style,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: copy == null
                  ? FilledButton.tonalIcon(
                      onPressed: onOpenLive,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open live site'),
                    )
                  : FilledButton.icon(
                      onPressed: onOpenSaved,
                      icon: const Icon(Icons.offline_pin_outlined, size: 18),
                      label: const Text('Open saved copy'),
                    ),
            ),
            const SizedBox(width: Spacing.xs),
            if (copy != null)
              IconButton(
                tooltip: 'Open live site',
                onPressed: onOpenLive,
                icon: const Icon(Icons.open_in_new),
              ),
            IconButton(
              tooltip: 'Save',
              onPressed: onSave,
              icon: const Icon(Icons.bookmark_border),
            ),
            IconButton(
              tooltip: 'Share',
              onPressed: onShare,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        const Hairline(),
      ],
    );
  }
}
