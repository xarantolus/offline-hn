import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/debug/mock_data.dart';
import 'package:offline_hn/ui/day_menu.dart';
import 'package:offline_hn/ui/feed_switcher.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/story_row.dart';

class MockFeedPage extends StatefulWidget {
  const MockFeedPage({super.key, required this.onOpenStory});

  final ValueChanged<MockStory> onOpenStory;

  @override
  State<MockFeedPage> createState() => _MockFeedPageState();
}

class _MockFeedPageState extends State<MockFeedPage> {
  late final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late final List<DateTime> _days = [
    for (final offset in mockDayOffsets)
      _today.subtract(Duration(days: offset)),
  ];
  late DateTime _day = _today;
  FeedKind _kind = FeedKind.top;
  bool _refreshing = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _stopAfter(const Duration(seconds: 45));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _stopAfter(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, () {
      if (mounted) setState(() => _refreshing = false);
    });
  }

  void _refresh() {
    setState(() => _refreshing = true);
    _stopAfter(const Duration(seconds: 3));
  }

  @override
  Widget build(BuildContext context) {
    final offset = _today.difference(_day).inDays;
    final stories = storiesFor(_kind, offset);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline HN'),
        actions: [
          DayMenu(
            days: _days,
            selected: _day,
            today: _today,
            onSelected: (d) => setState(() => _day = d),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          FeedSwitcher(
            selected: _kind,
            onSelected: (k) => setState(() => _kind = k),
            status: 'Updated $mockUpdatedAt · $mockConnection',
          ),
          SizedBox(
            height: 2,
            child: _refreshing ? const LinearProgressIndicator() : null,
          ),
          Expanded(
            child: ListView.separated(
              key: PageStorageKey<(FeedKind, DateTime)>((_kind, _day)),
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom,
              ),
              itemCount: stories.length,
              separatorBuilder: (_, _) => const Hairline(inset: 22),
              itemBuilder: (_, i) {
                final s = stories[i];
                return StoryRow(
                  title: s.title,
                  domain: s.domain,
                  points: s.points,
                  comments: s.comments,
                  author: s.author,
                  age: s.age,
                  read: s.read,
                  saved: s.saved,
                  onTap: () => widget.onOpenStory(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
