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
    SyncPhase.done => 'Finishing',
  };
}

/// The quiet line under the feed switcher. [updatedAt] is the clock time of
/// the last successful sync, already formatted for the reader.
String syncStatusText({
  required SyncProgress? progress,
  required String? updatedAt,
  required ConnectionKind? connection,
}) {
  if (progress != null) return progressLabel(progress);
  final link = connection == null ? null : connectionLabel(connection);
  final updated = updatedAt == null ? 'Not updated yet' : 'Updated $updatedAt';
  return link == null ? updated : '$updated · $link';
}
