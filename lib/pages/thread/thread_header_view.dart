import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/comments/comment_parser.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/story_source.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/pages/story_opener.dart';
import 'package:offline_hn/pages/thread/copy_info.dart';
import 'package:offline_hn/ui/comment_body.dart';
import 'package:offline_hn/ui/thread_header.dart';

/// The header, fed live: toggling the bookmark or finishing a page capture
/// changes it without touching the comments below.
class ThreadHeaderView extends StatefulWidget {
  const ThreadHeaderView({
    super.key,
    required this.storyId,
    required this.newComments,
    required this.textSize,
    required this.onLink,
  });

  final int storyId;
  final int newComments;
  final double textSize;
  final LinkHandler onLink;

  @override
  State<ThreadHeaderView> createState() => _ThreadHeaderViewState();
}

class _ThreadHeaderViewState extends State<ThreadHeaderView> {
  late final AppServices _services = AppServicesScope.of(context);
  late final Stream<StoryRow?> _story = _services.stories.watchStory(
    widget.storyId,
  );
  late final Stream<PageCopyRow?> _page = _services.pages.watch(widget.storyId);
  late final Stream<ConnectionKind> _connection = _services.sync.connection;

  String _fetched(DateTime at) {
    final l10n = MaterialLocalizations.of(context);
    final time = l10n.formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final sameDay = DateUtils.isSameDay(at, DateTime.now());
    return sameDay ? time : '${l10n.formatShortDate(at)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StoryRow?>(
      stream: _story,
      builder: (context, story) {
        final row = story.data;
        if (row == null) return const SizedBox.shrink();
        return StreamBuilder<PageCopyRow?>(
          stream: _page,
          builder: (context, page) => StreamBuilder<ConnectionKind>(
            stream: _connection,
            builder: (context, connection) =>
                _build(row, page.data, connection.data),
          ),
        );
      },
    );
  }

  Widget _build(StoryRow story, PageCopyRow? page, ConnectionKind? connection) {
    final opener = StoryOpener(_services);
    final url = story.url == null ? null : Uri.tryParse(story.url!);
    final body = parseCommentHtml(story.body);
    final copy = copyInfoFor(story, page, _fetched);
    return ThreadHeader(
      title: story.title,
      source: storySource(domain: story.domain, title: story.title),
      author: story.by,
      points: story.points,
      comments: story.commentCount,
      newComments: widget.newComments,
      copy: copy,
      saved: story.saved,
      offline: connection == ConnectionKind.none,
      body: body.isEmpty
          ? null
          : CommentBody(
              blocks: body,
              textSize: widget.textSize,
              onLink: widget.onLink,
            ),
      onOpenSaved: copy.state == CopyState.saved && page != null
          ? () => unawaited(opener.openSavedCopy(context, story, page))
          : null,
      onOpenLive: url == null
          ? null
          : () => unawaited(opener.openWeb(context, url)),
      onToggleSaved: () =>
          unawaited(_services.stories.setSaved(story.id, value: !story.saved)),
      onShare: () => unawaited(
        opener.share(story.title, url ?? StoryOpener.discussionUri(story.id)),
      ),
    );
  }
}
