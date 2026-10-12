import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/comments/comment_block.dart';
import 'package:offline_hn/comments/comment_parser.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/open_thread.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/thread_view.dart';
import 'package:offline_hn/data/policy/comment_arrangement.dart';
import 'package:offline_hn/data/repository/thread_state_repository.dart';
import 'package:offline_hn/pages/story_opener.dart';
import 'package:offline_hn/pages/thread/copy_info.dart';
import 'package:offline_hn/pages/thread/thread_header_view.dart';
import 'package:offline_hn/pages/thread/thread_pager.dart';
import 'package:offline_hn/ui/comment_tile.dart';
import 'package:offline_hn/ui/reveal.dart';
import 'package:offline_hn/ui/saved_links.dart';
import 'package:offline_hn/ui/selection_guard.dart';
import 'package:offline_hn/ui/tokens.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const _baseTextSize = 15.0;

class ThreadPage extends StatefulWidget {
  const ThreadPage({
    super.key,
    required this.storyId,
    this.focusCommentId,
    this.openArticle = false,
    this.onArticleOpened,
    this.active = true,
  });

  final int storyId;
  final int? focusCommentId;
  final bool openArticle;
  final VoidCallback? onArticleOpened;

  /// False for a page a pager builds beside the one on screen: it loads, but
  /// nothing counts as opened until it is active.
  final bool active;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _open = OpenThread();
  final _positions = ItemPositionsListener.create();
  final _scroll = ItemScrollController();
  final _blocks = <int, List<CommentBlock>>{};
  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<List<CommentRow>>? _comments;
  final _selection = SelectionGuard();
  Timer? _settle;
  Set<int> _closing = {};
  Set<int> _entering = {};

  late final AppServices _services = AppServicesScope.of(context);
  late final StoryOpener _opener = StoryOpener(_services);
  late final Stream<Set<String>> _savedLinks = _services.links.watchSavedUrls();

  AppSettings _settings = AppSettings.defaults();
  Set<int> _collapsed = {};
  DateTime? _previousSeen;
  String? _storyAuthor;
  bool _ready = false;
  bool _missing = false;
  bool _fetched = false;
  List<ArrangedComment> _visible = const [];
  List<int> _topLevel = const [];
  int? _focusIndex;
  StoryRow? _story;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void didUpdateWidget(ThreadPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) unawaited(_activate());
  }

  @override
  void dispose() {
    _settle?.cancel();
    unawaited(_comments?.cancel());
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  Future<void> _start() async {
    final id = widget.storyId;
    final story = await _services.stories.story(id);
    final state = await _services.threadStates.watch(id).first;
    final settings = await _services.settings.load();
    final rows = await _services.stories.watchComments(id).first;
    if (!mounted) return;
    if (story == null) {
      setState(() => _missing = true);
      return;
    }
    _story = story;
    _storyAuthor = story.by;
    _fetched = story.commentsFetchedAt != null;
    _collapsed = state?.collapsed ?? {};
    _previousSeen = state?.seenUpToCommentTime;
    _settings = settings;
    _open.receive(rows);
    _rearrange();
    _focusIndex = _indexOfComment(widget.focusCommentId);
    setState(() => _ready = true);

    if (_open.shown.isEmpty) {
      _comments = _services.stories.watchComments(id).listen(_onComments);
    }
    _subscriptions
      ..add(_services.settings.watch().skip(1).listen(_onSettings))
      ..add(
        _services.stories.watchStory(id).listen((s) {
          final fetched = s?.commentsFetchedAt != null;
          if (fetched != _fetched && mounted) {
            setState(() => _fetched = fetched);
          }
        }),
      );
    await _activate();
  }

  Future<void> _activate() async {
    final story = _story;
    if (!widget.active || !_ready || _opened || story == null) return;
    _opened = true;
    await _markOpened();
    if (widget.openArticle && mounted) {
      widget.onArticleOpened?.call();
      await _opener.openArticle(context, story);
    }
  }

  Future<void> _markOpened() async {
    final now = DateTime.now();
    await _services.threadStates.markOpened(
      widget.storyId,
      now,
      seenUpToCommentTime: latestCommentTime(_open.shown),
    );
    await _services.pages.markOpened(widget.storyId, now);
    await _services.stories.setRead(widget.storyId, value: true);
  }

  /// Watched only until the thread has comments: they are never replaced
  /// while it is open.
  void _onComments(List<CommentRow> rows) {
    if (!_open.receive(rows)) return;
    unawaited(_comments?.cancel());
    _comments = null;
    _rearrange();
    setState(() {});
    if (_opened) unawaited(_markOpened());
  }

  void _onSettings(AppSettings settings) {
    final reorder = settings.commentOrder != _settings.commentOrder;
    _settings = settings;
    if (reorder) _rearrange();
    setState(() {});
  }

  void _rearrange() {
    final arranged = arrangeComments(_open.shown, _settings.commentOrder);
    _show(
      visibleEntries(
        arranged,
        collapsed: _collapsed,
        idOf: (c) => c.row.id,
        depthOf: (c) => c.depth,
      ),
    );
  }

  void _show(List<ArrangedComment> visible) {
    _visible = visible;
    _topLevel = [
      for (var i = 0; i < _visible.length; i++)
        if (_visible[i].depth == 0) i + 1,
    ];
  }

  int? _indexOfComment(int? id) {
    if (id == null) return null;
    final at = _visible.indexWhere((c) => c.row.id == id);
    return at < 0 ? null : at + 1;
  }

  void _toggle(int id) {
    _finishSettling();
    final before = _visible;
    final collapsing = !_collapsed.remove(id);
    if (collapsing) _collapsed.add(id);
    _rearrange();
    final ids = {for (final c in _visible) c.row.id};
    final beforeIds = {for (final c in before) c.row.id};
    final rows = _rowsOnScreen;
    if (collapsing) {
      final leaving = [
        for (final c in before)
          if (!ids.contains(c.row.id)) c.row.id,
      ];
      _closing = leaving.take(rows).toSet();
      final dropped = leaving.skip(rows).toSet();
      _show([
        for (final c in before)
          if (!dropped.contains(c.row.id)) c,
      ]);
      _keepBylineInView(id);
    } else {
      _entering = [
        for (final c in _visible)
          if (!beforeIds.contains(c.row.id)) c.row.id,
      ].take(rows).toSet();
    }
    _settle = Timer(revealDuration, _finishSettling);
    setState(() {});
    unawaited(
      _services.threadStates.setCollapsed(widget.storyId, {
        ..._collapsed,
      }, DateTime.now()),
    );
  }

  int get _rowsOnScreen => _positions.itemPositions.value.length + 1;

  void _finishSettling() {
    final pending = _settle;
    if (pending == null) return;
    pending.cancel();
    _settle = null;
    final wasClosing = _closing.isNotEmpty;
    _closing = {};
    _entering = {};
    if (wasClosing) _rearrange();
    if (mounted) setState(() {});
  }

  void _keepBylineInView(int id) {
    final index = _visible.indexWhere((c) => c.row.id == id) + 1;
    final position = _positions.itemPositions.value
        .where((p) => p.index == index)
        .firstOrNull;
    if (position == null || position.itemLeadingEdge >= 0) return;
    unawaited(
      _scroll.scrollTo(
        index: index,
        duration: revealDuration,
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _openLink(LinkRun link) async {
    final copy = await _services.links.copyFor(link.uri);
    if (!mounted) return;
    if (copy != null &&
        copy.status == LinkStatus.ok &&
        await _opener.openLinkCopy(context, link.uri, copy)) {
      return;
    }
    if (!mounted) return;
    final itemId = link.itemId;
    if (itemId != null) {
      final found = await _services.stories.locateItem(itemId);
      if (!mounted) return;
      if (found != null) {
        _goTo(found.storyId, found.commentId);
        return;
      }
    }
    await _opener.openWeb(context, link.uri);
  }

  void _goTo(int storyId, int? commentId) {
    if (storyId != widget.storyId) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ThreadPager(
              storyIds: [storyId],
              storyId: storyId,
              focusCommentId: commentId,
            ),
          ),
        ),
      );
      return;
    }
    final index = _indexOfComment(commentId) ?? 0;
    unawaited(
      _scroll.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  int get _firstVisibleIndex {
    final onScreen = _positions.itemPositions.value.where(
      (p) => p.itemTrailingEdge > 0.02,
    );
    if (onScreen.isEmpty) return 0;
    return onScreen.map((p) => p.index).reduce((a, b) => a < b ? a : b);
  }

  int? get _nextTopLevel {
    final first = _firstVisibleIndex;
    for (final index in _topLevel) {
      if (index > first) return index;
    }
    return null;
  }

  void _jumpToNextTopLevel() {
    final next = _nextTopLevel;
    if (next == null) return;
    unawaited(
      _scroll.scrollTo(
        index: next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  List<CommentBlock> _blocksOf(CommentRow row) => _blocks.putIfAbsent(
    row.id,
    () => row.html == null
        ? const [
            Paragraph([TextRun('[removed]', italic: true)]),
          ]
        : parseCommentHtml(row.html),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _ready ? _jumpButton() : null,
      body: _body(),
    );
  }

  Widget _jumpButton() {
    return ValueListenableBuilder<Iterable<ItemPosition>>(
      valueListenable: _positions.itemPositions,
      builder: (context, _, _) => _nextTopLevel == null
          ? const SizedBox.shrink()
          : FloatingActionButton.small(
              tooltip: 'Next top-level comment',
              onPressed: _jumpToNextTopLevel,
              child: const Icon(Icons.keyboard_double_arrow_down),
            ),
    );
  }

  Widget _body() {
    if (_missing) {
      return const Center(child: Text('This story is no longer stored.'));
    }
    if (!_ready) return const SizedBox.shrink();
    final textSize = _baseTextSize * _settings.commentTextScale;
    final seen = _previousSeen;
    final newCount = countNewComments(_open.shown.map((c) => c.time), seen);
    final now = DateTime.now();
    final bottom = MediaQuery.viewPaddingOf(context).bottom + 88;
    return StreamBuilder<Set<String>>(
      stream: _savedLinks,
      initialData: const {},
      builder: (context, saved) => SavedLinks(
        urls: saved.data ?? const {},
        child: _commentList(textSize, seen, newCount, now, bottom),
      ),
    );
  }

  Widget _commentList(
    double textSize,
    DateTime? seen,
    int newCount,
    DateTime now,
    double bottom,
  ) {
    return ScrollablePositionedList.builder(
      itemScrollController: _scroll,
      itemPositionsListener: _positions,
      initialScrollIndex: _focusIndex ?? 0,
      padding: EdgeInsets.only(bottom: bottom),
      itemCount: _visible.isEmpty ? 2 : _visible.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return SelectionArea(
            child: ThreadHeaderView(
              storyId: widget.storyId,
              newComments: newCount,
              textSize: textSize,
              onLink: (link) => unawaited(_openLink(link)),
            ),
          );
        }
        if (_visible.isEmpty) return _EmptyThread(fetched: _fetched);
        final entry = _visible[index - 1];
        final row = entry.row;
        final time = row.time;
        final tile = CommentTile(
          key: ValueKey(row.id),
          author: row.author ?? '[removed]',
          age: time == null ? Duration.zero : now.difference(time),
          depth: entry.depth,
          blocks: _blocksOf(row),
          isOp: _storyAuthor != null && row.author == _storyAuthor,
          startsGroup: entry.depth == 0 && index > 1,
          startsSibling:
              index > 1 &&
              entry.depth > 0 &&
              _visible[index - 2].depth >= entry.depth,
          isNew: seen != null && time != null && time.isAfter(seen),
          collapsed: _collapsed.contains(row.id),
          hiddenCount: entry.descendants,
          textSize: textSize,
          selectionGuard: _selection,
          onToggle: () => _toggle(row.id),
          onLink: (link) => unawaited(_openLink(link)),
        );
        final closing = _closing.contains(row.id);
        if (!closing && !_entering.contains(row.id)) return tile;
        return Reveal(
          key: ValueKey(row.id),
          open: !closing,
          animateIn: !closing,
          child: tile,
        );
      },
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.fetched});

  final bool fetched;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.gutter),
      child: Text(
        fetched
            ? 'No comments yet.'
            : 'The comments have not been fetched yet. They arrive with the '
                  'next update.',
        style: context.tokens.hint,
      ),
    );
  }
}
