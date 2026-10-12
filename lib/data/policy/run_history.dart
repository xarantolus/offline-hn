import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/policy/run_policy.dart';
import 'package:offline_hn/data/policy/sync_status_text.dart';
import 'package:offline_hn/ui/format.dart';

/// One kind of item and how it ended, counted.
class ItemGroup {
  const ItemGroup({
    required this.kind,
    required this.status,
    required this.asThread,
    required this.count,
    required this.bytes,
  });

  final SyncItemKind kind;
  final SyncItemStatus status;
  final bool asThread;
  final int count;
  final int bytes;
}

class RunTally {
  const RunTally({
    this.threads = 0,
    this.threadsFailed = 0,
    this.articles = 0,
    this.articlesTooLarge = 0,
    this.articlesFailed = 0,
    this.links = 0,
    this.linksTooLarge = 0,
    this.linksFailed = 0,
    this.linkedThreads = 0,
    this.bytes = 0,
  });

  final int threads;
  final int threadsFailed;
  final int articles;
  final int articlesTooLarge;
  final int articlesFailed;
  final int links;
  final int linksTooLarge;
  final int linksFailed;
  final int linkedThreads;

  /// Weight of the pages saved.
  final int bytes;
}

RunTally tallyItems(Iterable<ItemGroup> groups) {
  var threads = 0, threadsFailed = 0;
  var articles = 0, articlesTooLarge = 0, articlesFailed = 0;
  var links = 0, linksTooLarge = 0, linksFailed = 0, linkedThreads = 0;
  var bytes = 0;
  for (final g in groups) {
    if (g.status == SyncItemStatus.pending) continue;
    final ok = g.status == SyncItemStatus.done;
    final large = g.status == SyncItemStatus.tooLarge;
    final failed = g.status == SyncItemStatus.failed;
    bytes += g.bytes;
    switch (g.kind) {
      case SyncItemKind.comments:
        if (ok) threads += g.count;
        if (failed) threadsFailed += g.count;
      case SyncItemKind.page:
        if (ok) articles += g.count;
        if (large) articlesTooLarge += g.count;
        if (failed) articlesFailed += g.count;
      case SyncItemKind.link:
        if (ok && g.asThread) linkedThreads += g.count;
        if (ok && !g.asThread) links += g.count;
        if (large) linksTooLarge += g.count;
        if (failed) linksFailed += g.count;
    }
  }
  return RunTally(
    threads: threads,
    threadsFailed: threadsFailed,
    articles: articles,
    articlesTooLarge: articlesTooLarge,
    articlesFailed: articlesFailed,
    links: links,
    linksTooLarge: linksTooLarge,
    linksFailed: linksFailed,
    linkedThreads: linkedThreads,
    bytes: bytes,
  );
}

class RunRecord {
  const RunRecord({
    required this.id,
    required this.trigger,
    required this.startedAt,
    required this.heartbeatAt,
    this.finishedAt,
    this.outcome,
    this.error,
    this.connection,
    this.storiesUpdated = 0,
    this.listsRefreshed = false,
    this.prunedCopies = 0,
    this.prunedStories = 0,
    this.prunedBytes = 0,
    this.tally = const RunTally(),
  });

  final int id;
  final SyncTrigger trigger;
  final DateTime startedAt;
  final DateTime heartbeatAt;
  final DateTime? finishedAt;
  final SyncOutcome? outcome;
  final String? error;
  final ConnectionKind? connection;
  final int storiesUpdated;
  final bool listsRefreshed;
  final int prunedCopies;
  final int prunedStories;
  final int prunedBytes;
  final RunTally tally;
}

enum RunState { running, paused, completed, failed, stopped }

/// An open run whose process has gone quiet is waiting to be continued.
RunState runState(RunRecord run, DateTime now) => switch (run.outcome) {
  SyncOutcome.succeeded => RunState.completed,
  SyncOutcome.failed => RunState.failed,
  SyncOutcome.abandoned => RunState.stopped,
  null => runIsAlive(run.heartbeatAt, now) ? RunState.running : RunState.paused,
};

String stateLabel(RunState state) => switch (state) {
  RunState.running => 'Running',
  RunState.paused => 'Paused, will continue',
  RunState.completed => 'Completed',
  RunState.failed => 'Failed',
  RunState.stopped => 'Stopped',
};

String triggerLabel(SyncTrigger trigger) => switch (trigger) {
  SyncTrigger.scheduled => 'Daily update',
  SyncTrigger.periodic => 'Regular update',
  SyncTrigger.catchUp => 'Catch-up on opening',
  SyncTrigger.manual => 'Update everything',
  SyncTrigger.refresh => 'Refresh button',
};

String durationLabel(Duration d) {
  if (d.inMinutes < 1) return 'under a minute';
  if (d.inHours < 1) return '${d.inMinutes} min';
  if (d.inDays < 1) {
    final minutes = d.inMinutes % 60;
    return minutes == 0 ? '${d.inHours} h' : '${d.inHours} h $minutes min';
  }
  final hours = d.inHours % 24;
  return hours == 0 ? '${d.inDays} d' : '${d.inDays} d $hours h';
}

/// "Today 05:03", "Yesterday 05:03", "Tomorrow 05:00" or "Oct 8 05:03".
/// [clock] is the time of day already formatted and [date] formats any other
/// day.
String whenLabel({
  required DateTime at,
  required DateTime now,
  required String clock,
  required String Function(DateTime) date,
  UtcOffsetAt offsetAt = deviceOffsetAt,
}) {
  final days = localDayOf(
    at,
    offsetAt: offsetAt,
  ).asUtcMidnight.difference(localDayOf(now, offsetAt: offsetAt).asUtcMidnight);
  final word = switch (days.inDays) {
    0 => 'Today',
    -1 => 'Yesterday',
    1 => 'Tomorrow',
    _ => date(at.toLocal()),
  };
  return '$word $clock';
}

/// The line that says how a run went, e.g. "Today 05:03 · 14 min · Completed".
String runHeadline(
  RunRecord run, {
  required DateTime now,
  required String when,
}) {
  final state = runState(run, now);
  final end = run.finishedAt ?? now;
  final took = durationLabel(end.difference(run.startedAt));
  final label = state == RunState.failed && run.error != null
      ? 'Failed: ${run.error}'
      : stateLabel(state);
  return '$when · $took · $label';
}

String _count(int n, String one, [String? many]) => pluralize(n, one, many);

/// What the run did, one fact per line, leaving out what did not happen.
List<String> runOverview(RunRecord run) {
  final t = run.tally;
  return [
    if (run.storiesUpdated > 0)
      '${_count(run.storiesUpdated, 'story', 'stories')} updated',
    if (t.threads + t.threadsFailed > 0)
      '${_count(t.threads, 'thread')} with comments fetched'
          '${t.threadsFailed > 0 ? ' · ${t.threadsFailed} failed' : ''}',
    if (t.articles + t.articlesTooLarge + t.articlesFailed > 0)
      'Article pages: ${t.articles} saved'
          '${t.articlesFailed > 0 ? ' · ${t.articlesFailed} failed' : ''}'
          '${t.articlesTooLarge > 0 ? ' · ${t.articlesTooLarge} too large' : ''}',
    if (t.links + t.linksTooLarge + t.linksFailed > 0)
      'Linked pages: ${t.links} saved'
          '${t.linksFailed > 0 ? ' · ${t.linksFailed} failed' : ''}'
          '${t.linksTooLarge > 0 ? ' · ${t.linksTooLarge} too large' : ''}',
    if (t.linkedThreads > 0)
      '${_count(t.linkedThreads, 'discussion')} from comment links saved',
    if (t.bytes > 0) '${formatSize(t.bytes)} of pages added',
    if (run.prunedCopies + run.prunedStories > 0) _pruned(run),
    if (run.listsRefreshed) 'Filter lists refreshed',
  ];
}

String _pruned(RunRecord run) {
  final parts = [
    if (run.prunedCopies > 0)
      _count(run.prunedCopies, 'saved copy', 'saved copies'),
    if (run.prunedStories > 0)
      _count(run.prunedStories, 'old story', 'old stories'),
  ];
  final freed = run.prunedBytes > 0 ? ' (${formatSize(run.prunedBytes)})' : '';
  return 'Removed ${parts.join(' and ')}$freed';
}

/// A short form of [runOverview] for a list row.
String runGist(RunRecord run) {
  final t = run.tally;
  final parts = [
    if (run.storiesUpdated > 0) _count(run.storiesUpdated, 'story', 'stories'),
    if (t.threads > 0) _count(t.threads, 'thread'),
    if (t.articles + t.links > 0) _count(t.articles + t.links, 'page'),
    if (t.bytes > 0) formatSize(t.bytes),
  ];
  return parts.join(' · ');
}

/// "wifi · Update everything", the two facts that say why and how a run ran.
String runCause(RunRecord run) {
  final link = run.connection == null ? null : connectionLabel(run.connection!);
  return [triggerLabel(run.trigger), ?link].join(' · ');
}

class FailedItem {
  const FailedItem({
    required this.kind,
    required this.id,
    required this.error,
    required this.title,
    required this.asThread,
  });

  final SyncItemKind kind;

  /// A story's id, or a linked page's for [SyncItemKind.link].
  final int id;
  final String? error;
  final String? title;
  final bool asThread;

  /// The story to open, for the kinds that belong to one.
  int? get storyId => kind == SyncItemKind.link ? null : id;
}

class FailureGroup {
  const FailureGroup({required this.reason, required this.items});

  final String reason;
  final List<FailedItem> items;
}

const _httpNames = <int, String>{
  400: 'Bad request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not found',
  406: 'Not acceptable',
  410: 'Gone',
  429: 'Too many requests',
  451: 'Unavailable for legal reasons',
};

/// The reason an item failed, in words, from the text the runner stored.
String failureReason(String? error) {
  final text = error?.trim() ?? '';
  if (text.isEmpty) return 'Unknown reason';
  final lower = text.toLowerCase();
  final http = RegExp(r'http (\d{3})').firstMatch(lower);
  if (http != null) {
    final code = int.parse(http.group(1)!);
    final name = _httpNames[code] ?? (code >= 500 ? 'Server error' : null);
    return name == null ? 'HTTP $code' : '$code $name';
  }
  if (lower.contains('timeout') ||
      lower.contains('timed out') ||
      lower.contains('took too long')) {
    return 'Took too long';
  }
  if (lower.startsWith('ssl')) return 'Certificate problem';
  if (lower.startsWith('network') ||
      lower.contains('socketexception') ||
      lower.contains('clientexception')) {
    return 'Could not connect';
  }
  if (lower.startsWith('unsupportedcontent')) return 'Not a web page';
  if (lower.contains('not a pdf')) return 'Not a valid PDF';
  if (lower.contains('empty response') ||
      lower.contains('incomplete download')) {
    return 'Download incomplete';
  }
  if (lower.contains('not indexed')) return 'Comments not indexed yet';
  if (lower.startsWith('not an http')) return 'Not a web address';
  if (lower == 'not found') return 'Not found';
  final firstLine = text.split('\n').first;
  return firstLine.length <= 80 ? firstLine : '${firstLine.substring(0, 79)}…';
}

/// Failures sharing a reason, the most frequent reason first.
List<FailureGroup> groupFailures(Iterable<FailedItem> items) {
  final byReason = <String, List<FailedItem>>{};
  for (final item in items) {
    byReason.putIfAbsent(failureReason(item.error), () => []).add(item);
  }
  final groups = [
    for (final entry in byReason.entries)
      FailureGroup(reason: entry.key, items: entry.value),
  ];
  return groups..sort((a, b) {
    final bySize = b.items.length.compareTo(a.items.length);
    return bySize != 0 ? bySize : a.reason.compareTo(b.reason);
  });
}

String failureKindLabel(SyncItemKind kind, {bool asThread = false}) =>
    switch (kind) {
      SyncItemKind.comments => 'Comments',
      SyncItemKind.page => 'Article page',
      SyncItemKind.link => asThread ? 'Linked discussion' : 'Linked page',
    };
