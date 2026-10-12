import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/repository/sync_repository.dart';

String connectionLabel(ConnectionKind kind) => switch (kind) {
  ConnectionKind.wifi => 'wifi',
  ConnectionKind.mobile => 'mobile data',
  ConnectionKind.none => 'offline',
};

/// What a run is doing, in the words of someone watching it.
String progressLabel(SyncProgress progress) {
  final counted = progress.total > 0
      ? ' ${progress.done} of ${progress.total}'
      : '';
  return switch (progress.phase) {
    SyncPhase.ranking => 'Fetching rankings',
    SyncPhase.metadata => 'Fetching stories',
    SyncPhase.comments => 'Fetching comments$counted',
    SyncPhase.pages => 'Saving pages$counted',
    SyncPhase.links => 'Saving linked pages$counted',
    SyncPhase.done => 'Finishing',
  };
}

/// The quiet line under the feed switcher. [updatedAt] is the clock time of
/// the last successful sync and [storedAt] that of the newest stored rankings,
/// both already formatted for the reader.
String syncStatusText({
  required SyncProgress? progress,
  required String? updatedAt,
  String? storedAt,
  required ConnectionKind? connection,
}) {
  if (progress != null) return progressLabel(progress);
  final link = connection == null ? null : connectionLabel(connection);
  final updated = switch ((updatedAt, storedAt)) {
    (final done?, _) => 'Updated $done',
    (null, final partial?) => 'Update unfinished · stories from $partial',
    (null, null) => 'Not updated yet',
  };
  return link == null ? updated : '$updated · $link';
}
