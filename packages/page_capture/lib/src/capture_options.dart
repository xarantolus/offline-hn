class CaptureViewport {
  const CaptureViewport({this.width = 412, this.height = 915});

  /// Density-independent pixels.
  final int width;
  final int height;
}

class CaptureTimeouts {
  const CaptureTimeouts({
    this.idle = const Duration(milliseconds: 1500),
    this.overall = const Duration(seconds: 60),
    this.save = const Duration(seconds: 30),
    this.settle = const Duration(milliseconds: 600),
  });

  /// No new resource for this long counts as the page being quiet.
  final Duration idle;

  /// The page must have finished loading by then. After it, scrolling and
  /// waiting for quiet stop and the page is saved as it stands.
  final Duration overall;
  final Duration save;
  final Duration settle;
}

class CaptureCleanup {
  const CaptureCleanup({
    this.blockRequests = true,
    this.hideElements = true,
    this.rejectConsent = true,
  });

  const CaptureCleanup.none()
    : blockRequests = false,
      hideElements = false,
      rejectConsent = false;

  final bool blockRequests;
  final bool hideElements;
  final bool rejectConsent;
}

class CaptureOptions {
  const CaptureOptions({
    this.viewport = const CaptureViewport(),
    this.timeouts = const CaptureTimeouts(),
    this.cleanup = const CaptureCleanup(),
    this.maxBytes = 25 * 1024 * 1024,
    this.filterListsDirectory,
  });

  final CaptureViewport viewport;
  final CaptureTimeouts timeouts;
  final CaptureCleanup cleanup;
  final int maxBytes;

  /// Directory holding downloaded filter lists. The capture uses a file from
  /// there only when it is newer than the bundled snapshot.
  final String? filterListsDirectory;

  Map<String, Object?> toMap() => {
    'viewportWidth': viewport.width,
    'viewportHeight': viewport.height,
    'idleMillis': timeouts.idle.inMilliseconds,
    'overallMillis': timeouts.overall.inMilliseconds,
    'saveMillis': timeouts.save.inMilliseconds,
    'settleMillis': timeouts.settle.inMilliseconds,
    'blockRequests': cleanup.blockRequests,
    'hideElements': cleanup.hideElements,
    'rejectConsent': cleanup.rejectConsent,
    'maxBytes': maxBytes,
    'filterListsDirectory': filterListsDirectory,
  };
}
