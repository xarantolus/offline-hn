import 'package:flutter/material.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

enum CopyState { saved, none, tooLarge, failed, noLink }

class SavedCopyInfo {
  const SavedCopyInfo.saved({required String size, required String fetched})
    : state = CopyState.saved,
      detail = 'Saved copy · $size · fetched $fetched';

  const SavedCopyInfo.none()
    : state = CopyState.none,
      detail = 'No saved copy · live site only';

  const SavedCopyInfo.tooLarge()
    : state = CopyState.tooLarge,
      detail = 'Too large to save · live site only';

  const SavedCopyInfo.failed()
    : state = CopyState.failed,
      detail = 'Could not be saved · live site only';

  const SavedCopyInfo.noLink() : state = CopyState.noLink, detail = '';

  final CopyState state;
  final String detail;
}

class ThreadHeader extends StatelessWidget {
  const ThreadHeader({
    super.key,
    required this.title,
    required this.source,
    required this.author,
    required this.points,
    required this.comments,
    required this.newComments,
    required this.copy,
    required this.saved,
    required this.offline,
    this.body,
    this.onOpenSaved,
    this.onOpenLive,
    this.onToggleSaved,
    this.onShare,
  });

  final String title;
  final String source;
  final String? author;
  final int? points;
  final int comments;
  final int newComments;
  final SavedCopyInfo copy;
  final bool saved;
  final bool offline;
  final Widget? body;
  final VoidCallback? onOpenSaved;
  final VoidCallback? onOpenLive;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final facts = [
      if (author != null) 'By $author',
      if (points != null) pluralize(points!, 'point'),
      pluralize(comments, 'comment'),
    ].join(' · ');
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
          SmallCaps(source, color: t.accent),
          const SizedBox(height: Spacing.sm),
          Text(title, style: t.threadTitle),
          const SizedBox(height: Spacing.md),
          Text.rich(
            TextSpan(
              style: t.smallCaps,
              children: [
                TextSpan(text: facts.toUpperCase()),
                if (newComments > 0)
                  TextSpan(
                    text: ' · $newComments NEW',
                    style: TextStyle(color: t.marker),
                  ),
              ],
            ),
          ),
          if (body != null) ...[const SizedBox(height: Spacing.lg), body!],
          const SizedBox(height: Spacing.lg),
          _CopyPanel(
            copy: copy,
            saved: saved,
            offline: offline,
            onOpenSaved: onOpenSaved,
            onOpenLive: onOpenLive,
            onToggleSaved: onToggleSaved,
            onShare: onShare,
          ),
        ],
      ),
    );
  }
}

class _CopyPanel extends StatelessWidget {
  const _CopyPanel({
    required this.copy,
    required this.saved,
    required this.offline,
    this.onOpenSaved,
    this.onOpenLive,
    this.onToggleSaved,
    this.onShare,
  });

  final SavedCopyInfo copy;
  final bool saved;
  final bool offline;
  final VoidCallback? onOpenSaved;
  final VoidCallback? onOpenLive;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasCopy = copy.state == CopyState.saved;
    final hasLink = copy.state != CopyState.noLink;
    final detail = !hasCopy && offline
        ? '${copy.detail} · offline'
        : copy.detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Hairline(),
        if (hasLink) ...[
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Icon(
                hasCopy ? Icons.offline_pin_outlined : Icons.cloud_outlined,
                size: 17,
                color: hasCopy ? t.accent : t.muted,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  detail,
                  style: TextStyle(fontSize: 13, color: t.muted),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            if (hasLink)
              Expanded(
                child: hasCopy
                    ? FilledButton.icon(
                        onPressed: onOpenSaved,
                        icon: const Icon(Icons.offline_pin_outlined, size: 18),
                        label: const Text('Open saved copy'),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: onOpenLive,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open live site'),
                      ),
              )
            else
              const Spacer(),
            const SizedBox(width: Spacing.xs),
            if (hasCopy)
              IconButton(
                tooltip: 'Open live site',
                onPressed: onOpenLive,
                icon: const Icon(Icons.open_in_new),
              ),
            IconButton(
              tooltip: saved ? 'Remove bookmark' : 'Bookmark',
              onPressed: onToggleSaved,
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              color: saved ? t.accent : null,
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
