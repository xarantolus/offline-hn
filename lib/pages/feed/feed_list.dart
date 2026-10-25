import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/local_day.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/policy/read_hiding.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/pages/feed/empty_feed.dart';
import 'package:offline_hn/pages/feed/story_entry_tile.dart';
import 'package:offline_hn/ui/reveal.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

class FeedList extends StatefulWidget {
  const FeedList({
    super.key,
    required this.services,
    required this.kind,
    required this.day,
    required this.storeEmpty,
    required this.hideRead,
    required this.onRefresh,
    required this.onShowRead,
  });

  final AppServices services;

  /// Null lists the bookmarked stories, whatever the day.
  final FeedKind? kind;
  final LocalDay? day;
  final bool storeEmpty;

  /// Leaves out the stories already read. The saved list ignores it.
  final bool hideRead;
  final Future<void> Function() onRefresh;
  final VoidCallback onShowRead;

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  late Stream<List<FeedEntry>> _entries = _watch();
  late ReadHiding _hiding = ReadHiding(_hides);
  final _closing = <int>{};
  final _opening = <int>{};
  Timer? _settle;

  bool get _hides => widget.hideRead && widget.kind != null;

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
      _hiding = ReadHiding(_hides);
      _closing.clear();
      _opening.clear();
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  /// Applies the option to a list that is on screen, and keeps the tiles that
  /// are changing in the tree until their animation has run.
  void _applyHiding(List<FeedEntry> entries) {
    final changed = _hiding.update(entries, enabled: _hides);
    if (changed.hidden.isEmpty && changed.shown.isEmpty) return;
    _closing
      ..clear()
      ..addAll(changed.hidden);
    _opening
      ..clear()
      ..addAll(changed.shown);
    _settle?.cancel();
    _settle = Timer(revealDuration + const Duration(milliseconds: 60), () {
      if (!mounted) return;
      setState(() {
        _closing.clear();
        _opening.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedEntry>>(
      stream: _entries,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null) return const SizedBox.shrink();
        _applyHiding(entries);
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
    final shown = _hiding.visible(entries);
    final allRead = _hiding.hidesAll(entries);
    return LayoutBuilder(
      builder: (context, box) => ListView.builder(
        key: PageStorageKey<(FeedKind?, LocalDay?)>((widget.kind, widget.day)),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        itemCount: entries.length + 1,
        itemBuilder: (context, index) {
          if (index == entries.length) {
            return Reveal(
              key: const ValueKey('all-read'),
              open: allRead,
              animateIn: allRead && _closing.isNotEmpty,
              child: allRead
                  ? SizedBox(height: box.maxHeight, child: _allRead())
                  : const SizedBox.shrink(),
            );
          }
          final entry = entries[index];
          final id = entry.story.id;
          final hidden = _hiding.isHidden(id);
          if (hidden && !_closing.contains(id)) {
            return SizedBox.shrink(key: ValueKey(id));
          }
          return Reveal(
            key: ValueKey(id),
            open: !hidden,
            animateIn: _opening.contains(id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StoryEntryTile(
                  services: widget.services,
                  entry: entry,
                  entries: shown,
                  now: now,
                ),
                const Hairline(inset: 22),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _allRead() => EmptyMessage(
    title: 'All stories here are read',
    hint: 'Hide read stories is on.',
    tokens: context.tokens,
    action: FilledButton.tonal(
      onPressed: widget.onShowRead,
      child: const Text('Show read stories'),
    ),
  );
}
