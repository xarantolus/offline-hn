import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/pages/feed/empty_feed.dart';
import 'package:offline_hn/pages/feed/story_entry_tile.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

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

  /// Null lists the bookmarked stories, whatever the day.
  final FeedKind? kind;
  final LocalDay? day;
  final bool storeEmpty;
  final Future<void> Function() onRefresh;

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  late Stream<List<FeedEntry>> _entries = _watch();

  Stream<List<FeedEntry>> _watch() {
    final kind = widget.kind;
    final day = widget.day;
    return kind == null || day == null
        ? widget.services.stories.watchSaved()
        : widget.services.stories.watchFeed(kind, dayBoundsUtc(day));
  }

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
        return entries.isEmpty
            ? LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: box.maxHeight,
                    child: widget.kind == null
                        ? EmptyMessage(
                            title: 'Nothing saved',
                            hint:
                                'Bookmark a story to keep it here, even '
                                'after it leaves the feeds.',
                            tokens: context.tokens,
                          )
                        : EmptyFeed(
                            services: widget.services,
                            storeEmpty: widget.storeEmpty,
                            onFetch: () => unawaited(widget.onRefresh()),
                          ),
                  ),
                ),
              )
            : _stories(entries);
      },
    );
  }

  Widget _stories(List<FeedEntry> entries) {
    final now = DateTime.now();
    return ListView.separated(
      key: PageStorageKey<(FeedKind?, LocalDay?)>((widget.kind, widget.day)),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Hairline(inset: 22),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return StoryEntryTile(
          key: ValueKey(entry.story.id),
          services: widget.services,
          entry: entry,
          entries: entries,
          now: now,
        );
      },
    );
  }
}
