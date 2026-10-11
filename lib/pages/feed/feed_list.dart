import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/story_source.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/pages/feed/empty_feed.dart';
import 'package:offline_hn/pages/feed/story_menu.dart';
import 'package:offline_hn/pages/story_opener.dart';
import 'package:offline_hn/pages/thread/thread_pager.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/story_tile.dart';

class FeedList extends StatefulWidget {
  const FeedList({
    super.key,
    required this.services,
    required this.kind,
    required this.day,
    required this.storeEmpty,
    required this.onRefresh,
  });

  final AppServices services;
  final FeedKind kind;
  final LocalDay day;
  final bool storeEmpty;
  final Future<void> Function() onRefresh;

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  late Stream<List<FeedEntry>> _entries = _watch();

  Stream<List<FeedEntry>> _watch() =>
      widget.services.stories.watchFeed(widget.kind, dayBoundsUtc(widget.day));

  @override
  void didUpdateWidget(FeedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind || oldWidget.day != widget.day) {
      _entries = _watch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedEntry>>(
      stream: _entries,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: entries.isEmpty
              ? LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: box.maxHeight,
                      child: EmptyFeed(
                        services: widget.services,
                        storeEmpty: widget.storeEmpty,
                        onFetch: () => unawaited(widget.onRefresh()),
                      ),
                    ),
                  ),
                )
              : _stories(entries),
        );
      },
    );
  }

  Widget _stories(List<FeedEntry> entries) {
    final now = DateTime.now();
    return ListView.separated(
      key: PageStorageKey<(FeedKind, LocalDay)>((widget.kind, widget.day)),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Hairline(inset: 22),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final story = entry.story;
        final time = story.time;
        final page = entry.page;
        final hasCopy =
            page != null &&
            page.status == PageStatus.ok &&
            page.relativePath != null;
        return StoryTile(
          key: ValueKey(story.id),
          title: story.title,
          source: storySource(domain: story.domain, title: story.title),
          points: story.points,
          comments: story.commentCount,
          author: story.by,
          age: time == null ? Duration.zero : now.difference(time),
          read: story.read,
          saved: story.saved,
          hasCopy: hasCopy,
          onTap: () => _openThread(story, entries, openArticle: true),
          onOpenComments: () => _openThread(story, entries),
          onLongPress: () => unawaited(_menu(story, entries)),
        );
      },
    );
  }

  void _openThread(
    StoryRow story,
    List<FeedEntry> entries, {
    bool openArticle = false,
  }) {
    unawaited(widget.services.stories.setRead(story.id, value: true));
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ThreadPager(
            storyIds: [for (final e in entries) e.story.id],
            storyId: story.id,
            openArticle: openArticle,
          ),
        ),
      ),
    );
  }

  Future<void> _menu(StoryRow story, List<FeedEntry> entries) async {
    final stories = widget.services.stories;
    final messenger = ScaffoldMessenger.of(context);
    final action = await showStoryMenu(context, story);
    if (action == null || !mounted) return;
    switch (action) {
      case StoryAction.comments:
        _openThread(story, entries);
      case StoryAction.bookmark:
        await stories.setSaved(story.id, value: !story.saved);
      case StoryAction.read:
        await stories.setRead(story.id, value: !story.read);
      case StoryAction.share:
        final url = story.url == null ? null : Uri.tryParse(story.url!);
        await StoryOpener(widget.services)
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
