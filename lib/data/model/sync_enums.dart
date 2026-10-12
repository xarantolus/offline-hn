/// [refresh] is the light update behind the refresh button: text only, and
/// only for threads that changed. [manual] is the full update asked for.
enum SyncTrigger {
  scheduled,
  periodic,
  catchUp,
  manual,
  refresh;

  bool get userInitiated => this == manual || this == refresh;

  bool get textOnly => this == refresh;
}

enum SyncPhase { ranking, metadata, comments, pages, links, done }

enum SyncOutcome { succeeded, failed, abandoned }

/// For [link] the item's id is a `link_copies` id, not a story's.
enum SyncItemKind { comments, page, link }

enum SyncItemStatus { pending, done, failed }

enum ConnectionKind { wifi, mobile, none }
