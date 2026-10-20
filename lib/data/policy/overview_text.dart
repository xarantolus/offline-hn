import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/filter_list_status.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/store_overview.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/day_grouping.dart';
import 'package:offline_hn/data/policy/network_policy.dart';
import 'package:offline_hn/sync/schedule_policy.dart';
import 'package:offline_hn/ui/format.dart';

String feedName(FeedKind kind) => switch (kind) {
  FeedKind.top => 'Top',
  FeedKind.best => 'Best',
  FeedKind.ask => 'Ask',
  FeedKind.show => 'Show',
};

/// "1,234 stories", with the days they cover when they differ.
String storiesLine(StoreOverview store, String Function(DateTime) date) {
  final count = pluralize(store.stories, 'story', 'stories');
  final oldest = store.oldestStory;
  final newest = store.newestStory;
  if (oldest == null || newest == null) return count;
  final from = date(oldest.toLocal());
  final to = date(newest.toLocal());
  return from == to ? '$count · $from' : '$count · $from to $to';
}

/// "Top 300 · Best 120", leaving out feeds with nothing stored.
String feedsLine(Map<FeedKind, int> perFeed) => [
  for (final kind in FeedKind.values)
    if ((perFeed[kind] ?? 0) > 0)
      '${feedName(kind)} ${formatCount(perFeed[kind]!)}',
].join(' · ');

String threadsLine(StoreOverview store) =>
    '${pluralize(store.threads, 'thread')} · '
    '${pluralize(store.comments, 'comment')}';

/// "3 new stories waiting for comments", or nothing when none are.
String waitingLine(StoreOverview store) => store.waitingStories == 0
    ? ''
    : '${pluralize(store.waitingStories, 'new story', 'new stories')} '
          'waiting for comments';

String articlesLine(StoreOverview store) =>
    '${pluralize(store.articles, 'article')} · ${formatSize(store.articleBytes)}';

String linkedLine(StoreOverview store) => [
  '${pluralize(store.linkedPages, 'page')} · ${formatSize(store.linkedBytes)}',
  if (store.linkedThreads > 0) pluralize(store.linkedThreads, 'discussion'),
].join(' · ');

/// How many of [urls] have a good copy, and when the newest was stored.
({int ready, int total, DateTime? newest}) filterListSummary(
  Iterable<String> urls,
  Map<String, FilterListStatus> statuses,
) {
  var ready = 0;
  DateTime? newest;
  var total = 0;
  for (final url in urls) {
    total++;
    final updated = statuses[url]?.updatedAt;
    if (updated == null) continue;
    ready++;
    if (newest == null || updated.isAfter(newest)) newest = updated;
  }
  return (ready: ready, total: total, newest: newest);
}

/// What an automatic update may fetch over the connection there is now.
String connectionNote(ConnectionKind connection, AppSettings settings) {
  final allowance = syncAllowance(
    trigger: SyncTrigger.scheduled,
    connection: connection,
    settings: settings,
  );
  final name = switch (connection) {
    ConnectionKind.wifi => 'Wi-Fi',
    ConnectionKind.mobile => 'Mobile data',
    ConnectionKind.none => 'Offline',
  };
  final rule = switch (allowance) {
    SyncAllowance.nothing when connection == ConnectionKind.none =>
      'nothing can be fetched',
    SyncAllowance.nothing => 'automatic updates wait for Wi-Fi',
    SyncAllowance.textOnly when connection == ConnectionKind.mobile =>
      'stories and comments, saved pages wait for Wi-Fi',
    SyncAllowance.textOnly => 'stories and comments',
    SyncAllowance.textAndPages => 'stories, comments and saved pages',
  };
  return '$name · $rule';
}

/// "5 of 5 ready", and when the newest copy was stored if [when] formats it.
String filterListsLine(
  ({int ready, int total, DateTime? newest}) summary,
  String Function(DateTime) when, {
  FilterListStatus? resources,
}) {
  final newest = summary.newest;
  final ready = '${summary.ready} of ${summary.total} lists ready';
  final line = newest == null ? ready : '$ready · refreshed ${when(newest)}';
  if (summary.total == 0 || resources?.updatedAt != null) return line;
  return '$line · scriptlets missing';
}

/// When the daily update is next due, as [when] writes it.
String nextDailyText({
  required AppSettings settings,
  required DateTime now,
  required String Function(DateTime) when,
  UtcOffsetAt offsetAt = deviceOffsetAt,
}) => when(nextDailyRun(settings.dailyTime, now, offsetAt: offsetAt));

/// The next daily update, and the shorter interval when one is set.
String nextUpdateText({
  required AppSettings settings,
  required DateTime now,
  required String Function(DateTime) when,
  UtcOffsetAt offsetAt = deviceOffsetAt,
}) {
  final daily = nextDailyText(
    settings: settings,
    now: now,
    when: when,
    offsetAt: offsetAt,
  );
  final hours = settings.intervalHours;
  return hours == null ? daily : '$daily · and every $hours h';
}
