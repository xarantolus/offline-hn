/// [thread] is a linked Hacker News discussion, stored as text rather than as
/// a file.
enum PageKind { mhtml, pdf, thread }

enum PageStatus { ok, tooLarge, failed }

/// A linked page's state; [pending] until the first attempt has finished.
enum LinkStatus { pending, ok, tooLarge, failed }
