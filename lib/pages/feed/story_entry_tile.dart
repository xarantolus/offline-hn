import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/story_source.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/pages/feed/story_menu.dart';
import 'package:offline_hn/pages/story_opener.dart';
import 'package:offline_hn/pages/thread/thread_pager.dart';
import 'package:offline_hn/ui/story_tile.dart';

/// A story in a list, with what tapping and long-pressing it does. Opening a
/// thread pages through [entries], the list it was opened from.
class StoryEntryTile extends StatelessWidget {
  const StoryEntryTile({
    super.key,
    required this.services,
    required this.entry,
    required this.entries,
    required this.now,
    this.onOpen,
    this.onViewed,
  });

  final AppServices services;
  final FeedEntry entry;
  final List<FeedEntry> entries;
  final DateTime now;

  /// Runs before a thread opens.
  final VoidCallback? onOpen;

  /// Told each story the opened thread is swiped to.
  final ValueChanged<int>? onViewed;

  @override
  Widget build(BuildContext context) {
    final story = entry.story;
    final time = story.time;
    return StoryTile(
      title: story.title,
      source: storySource(domain: story.domain, title: story.title),
      points: story.points,
      comments: story.commentCount,
      author: story.by,
      age: time == null ? Duration.zero : now.difference(time),
      read: story.read,
      saved: story.saved,
      hasCopy: entry.hasCopy,
      onTap: () => _open(context, openArticle: true),
      onOpenComments: () => _open(context),
      onLongPress: () => unawaited(_menu(context)),
    );
  }

  void _open(BuildContext context, {bool openArticle = false}) {
    onOpen?.call();
    openThread(
      context,
      services,
      storyId: entry.story.id,
      storyIds: [for (final e in entries) e.story.id],
      openArticle: openArticle,
      onStoryChanged: onViewed,
    );
  }

  Future<void> _menu(BuildContext context) async {
    final story = entry.story;
    final stories = services.stories;
    final messenger = ScaffoldMessenger.of(context);
    final action = await showStoryMenu(context, story);
    if (action == null || !context.mounted) return;
    switch (action) {
      case StoryAction.comments:
        _open(context);
      case StoryAction.bookmark:
        await stories.setSaved(story.id, value: !story.saved);
      case StoryAction.read:
        await stories.setRead(story.id, value: !story.read);
      case StoryAction.share:
        final url = story.url == null ? null : Uri.tryParse(story.url!);
        await StoryOpener(services)
            .share(story.title, url ?? StoryOpener.discussionUri(story.id));
      case StoryAction.hide:
        await stories.setHidden(story.id, value: true);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Story hidden'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () =>
                    unawaited(stories.setHidden(story.id, value: false)),
              ),
            ),
          );
    }
  }
}
