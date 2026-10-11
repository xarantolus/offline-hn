import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/thread_header.dart';

/// What the header says about a story's saved copy. [fetched] words the time
/// the copy was made for the reader.
SavedCopyInfo copyInfoFor(
  StoryRow story,
  PageCopyRow? page,
  String Function(DateTime) fetched,
) {
  if (story.url == null) return const SavedCopyInfo.noLink();
  if (page == null) return const SavedCopyInfo.none();
  return switch (page.status) {
    PageStatus.ok when page.relativePath != null => SavedCopyInfo.saved(
      size: formatSize(page.bytes),
      fetched: fetched(page.capturedAt),
    ),
    PageStatus.ok => const SavedCopyInfo.none(),
    PageStatus.tooLarge => const SavedCopyInfo.tooLarge(),
    PageStatus.failed => const SavedCopyInfo.failed(),
  };
}

DateTime? latestCommentTime(Iterable<CommentRow> rows) {
  DateTime? latest;
  for (final row in rows) {
    final time = row.time;
    if (time != null && (latest == null || time.isAfter(latest))) latest = time;
  }
  return latest;
}
