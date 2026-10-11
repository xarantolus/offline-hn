import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/comments/comment_block.dart';
import 'package:offline_hn/comments/comment_parser.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/open_thread.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/thread_view.dart';
import 'package:offline_hn/data/policy/comment_arrangement.dart';
import 'package:offline_hn/data/repository/thread_state_repository.dart';
import 'package:offline_hn/pages/story_opener.dart';
import 'package:offline_hn/pages/thread/copy_info.dart';
import 'package:offline_hn/pages/thread/thread_header_view.dart';
import 'package:offline_hn/ui/comment_tile.dart';
import 'package:offline_hn/ui/tokens.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const _baseTextSize = 15.0;

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.storyId, this.focusCommentId});

  final int storyId;
  final int? focusCommentId;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _open = OpenThread();
  final _positions = ItemPositionsListener.create();
  final _scroll = ItemScrollController();
  final _blocks = <int, List<CommentBlock>>{};
  final _subscriptions = <StreamSubscription<Object?>>[];

  late final AppServices _services = AppServicesScope.of(context);
  late final StoryOpener _opener = StoryOpener(_services);

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

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
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
    _storyAuthor = story.by;
    _fetched = story.commentsFetchedAt != null;
    _collapsed = state?.collapsed ?? {};
    _previousSeen = state?.seenUpToCommentTime;
    _settings = settings;
    _open.receive(rows);
    _rearrange();
    _focusIndex = _indexOfComment(widget.focusCommentId);
    setState(() => _ready = true);

    _subscriptions
      ..add(_services.stories.watchComments(id).skip(1).listen(_onComments))
      ..add(_services.settings.watch().skip(1).listen(_onSettings))
      ..add(
        _services.stories.watchStory(id).listen((s) {
          final fetched = s?.commentsFetchedAt != null;
          if (fetched != _fetched && mounted) {
            setState(() => _fetched = fetched);
          }
        }),
      );
    await _markOpened();
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

  void _onComments(List<CommentRow> rows) {
    if (!_open.receive(rows)) return;
    _rearrange();
    setState(() {});
    unawaited(_markOpened());
  }

  void _onSettings(AppSettings settings) {
    final reorder = settings.commentOrder != _settings.commentOrder;
    _settings = settings;
    if (reorder) _rearrange();
    setState(() {});
  }

  void _rearrange() {
    final arranged = arrangeComments(_open.shown, _settings.commentOrder);
    _visible = visibleEntries(
      arranged,
      collapsed: _collapsed,
      idOf: (c) => c.row.id,
      depthOf: (c) => c.depth,
    );
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
    if (!_collapsed.remove(id)) _collapsed.add(id);
    _rearrange();
    setState(() {});
    unawaited(
      _services.threadStates.setCollapsed(widget.storyId, {
        ..._collapsed,
      }, DateTime.now()),
    );
  }

  Future<void> _openLink(LinkRun link) async {
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
            builder: (_) =>
                ThreadPage(storyId: storyId, focusCommentId: commentId),
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
      appBar: AppBar(title: const Text('Comments')),
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
    return SelectionArea(
      child: ScrollablePositionedList.builder(
        itemScrollController: _scroll,
        itemPositionsListener: _positions,
        initialScrollIndex: _focusIndex ?? 0,
        padding: EdgeInsets.only(bottom: bottom),
        itemCount: _visible.isEmpty ? 2 : _visible.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ThreadHeaderView(
              storyId: widget.storyId,
              newComments: newCount,
              textSize: textSize,
              onLink: (link) => unawaited(_openLink(link)),
            );
          }
          if (_visible.isEmpty) return _EmptyThread(fetched: _fetched);
          final entry = _visible[index - 1];
          final row = entry.row;
          final time = row.time;
          return CommentTile(
            key: ValueKey(row.id),
            author: row.author ?? '[removed]',
            age: time == null ? Duration.zero : now.difference(time),
            depth: entry.depth,
            blocks: _blocksOf(row),
            isOp: _storyAuthor != null && row.author == _storyAuthor,
            startsGroup: entry.depth == 0 && index > 1,
            isNew: seen != null && time != null && time.isAfter(seen),
            collapsed: _collapsed.contains(row.id),
            hiddenCount: entry.descendants,
            hasChildren: entry.descendants > 0,
            textSize: textSize,
            onToggle: () => _toggle(row.id),
            onLink: (link) => unawaited(_openLink(link)),
          );
        },
      ),
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
