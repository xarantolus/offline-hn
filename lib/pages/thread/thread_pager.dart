import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/pages/thread/thread_page.dart';

/// The stories to page through and where to start, for a story that is open
/// from a list. A story that is not in the list opens alone.
({List<int> ids, int index}) pagerFor(List<int> ids, int storyId) {
  final index = ids.indexOf(storyId);
  return index < 0 ? (ids: [storyId], index: 0) : (ids: ids, index: index);
}

void openThread(
  BuildContext context,
  AppServices services, {
  required int storyId,
  required List<int> storyIds,
  bool openArticle = false,
}) {
  unawaited(services.stories.setRead(storyId, value: true));
  unawaited(
    Navigator.of(context).push(
      _threadRoute(
        ThreadPager(
          storyIds: storyIds,
          storyId: storyId,
          openArticle: openArticle,
        ),
        instant: openArticle,
      ),
    ),
  );
}

/// The article opens on top of the comments straight away, so the comments
/// arrive without a transition and only the article's own animation plays.
/// Going back still fades.
Route<void> _threadRoute(Widget page, {required bool instant}) {
  if (!instant) return MaterialPageRoute<void>(builder: (_) => page);
  return PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, secondary, child) =>
        FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondary,
          child: child,
        ),
  );
}

/// Swipes between the threads of the list a story was opened from. Only the
/// settled page counts as opened.
class ThreadPager extends StatefulWidget {
  ThreadPager({
    super.key,
    required List<int> storyIds,
    required int storyId,
    this.openArticle = false,
    this.focusCommentId,
  }) : _start = pagerFor(storyIds, storyId);

  final ({List<int> ids, int index}) _start;
  final bool openArticle;
  final int? focusCommentId;

  @override
  State<ThreadPager> createState() => _ThreadPagerState();
}

class _ThreadPagerState extends State<ThreadPager> {
  late final PageController _controller = PageController(
    initialPage: widget._start.index,
  );
  late int _current = widget._start.index;
  late bool _articlePending = widget.openArticle;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _settled(ScrollEndNotification notification) {
    final metrics = notification.metrics;
    if (notification.depth != 0 || metrics is! PageMetrics) return false;
    final page = metrics.page?.round();
    if (page != null && page != _current) setState(() => _current = page);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget._start.ids;
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: NotificationListener<ScrollEndNotification>(
        onNotification: _settled,
        child: PageView.builder(
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          itemCount: ids.length,
          itemBuilder: (context, index) => ThreadPage(
            key: ValueKey(ids[index]),
            storyId: ids[index],
            focusCommentId: index == widget._start.index
                ? widget.focusCommentId
                : null,
            active: index == _current,
            openArticle: _articlePending && index == widget._start.index,
            onArticleOpened: () => _articlePending = false,
          ),
        ),
      ),
    );
  }
}
