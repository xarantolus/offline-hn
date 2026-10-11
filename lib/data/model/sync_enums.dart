enum SyncTrigger { scheduled, periodic, catchUp, manual }

enum SyncPhase { ranking, metadata, comments, pages, done }

enum SyncOutcome { succeeded, failed, abandoned }

enum SyncItemKind { comments, page }

enum SyncItemStatus { pending, done, failed }

enum ConnectionKind { wifi, mobile, none }
