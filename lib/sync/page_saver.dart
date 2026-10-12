import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:offline_hn/capture/capture_settings.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
import 'package:offline_hn/data/repository/link_repository.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/sync/connection_probe.dart';
import 'package:offline_hn/sync/page_files.dart';
import 'package:offline_hn/sync/pdf_downloader.dart';
import 'package:page_capture/page_capture.dart';

typedef CaptureFn = Future<CaptureResult> Function(
  Uri url,
  String outputPath,
  CaptureOptions options,
  CaptureCancellation cancellation,
);

Future<CaptureResult> captureWithPlugin(
  Uri url,
  String outputPath,
  CaptureOptions options,
  CaptureCancellation cancellation,
) => PageCapture.capture(
  url,
  outputPath,
  options: options,
  cancellation: cancellation,
);

abstract interface class StoryPageSaver {
  /// Null when nothing was recorded because the save was cancelled or the
  /// connection is gone: the page is still owed, not failed.
  Future<PageStatus?> save(StoryRow story, AppSettings settings);

  /// The same for a page linked from a comment, under the smaller limit.
  Future<PageStatus?> saveLink(LinkCopyRow link, AppSettings settings);

  void cancel();
}

/// Where one save is filed: its path, its size limit and how its outcome is
/// recorded.
class _Target {
  const _Target({
    required this.label,
    required this.pathFor,
    required this.maxBytes,
    required this.captured,
    required this.tooLarge,
    required this.failed,
  });

  final String label;
  final String Function(PageKind kind) pathFor;
  final int maxBytes;
  final Future<void> Function(PageKind kind, String path, int bytes) captured;
  final Future<void> Function(PageKind kind) tooLarge;
  final Future<void> Function(PageKind kind, String error) failed;
}

/// Saves one page and records the outcome. A failure is a recorded result,
/// not an exception.
class PageSaver implements StoryPageSaver {
  PageSaver({
    required this.files,
    required this.pages,
    required this.links,
    required this.capture,
    required this.pdf,
    required this.probe,
    required this.filterListsDirectory,
    DateTime Function()? clock,
    this.watchdog = const Duration(seconds: 70),
  }) : _clock = clock ?? DateTime.now;

  final PageFiles files;
  final PageRepository pages;
  final LinkRepository links;
  final CaptureFn capture;
  final PdfDownloader pdf;
  final ConnectionProbe probe;
  final String filterListsDirectory;
  final Duration watchdog;
  final DateTime Function() _clock;

  final _inFlight = <CaptureCancellation>{};

  @override
  void cancel() {
    for (final cancellation in _inFlight.toList()) {
      cancellation.cancel();
    }
  }

  @override
  Future<PageStatus?> save(StoryRow story, AppSettings settings) => _save(
    _Target(
      label: '${story.id}',
      pathFor: (kind) => files.relativePathFor(story.id, kind),
      maxBytes: maxPageBytes,
      captured: (kind, path, bytes) => pages.recordCaptured(
        storyId: story.id,
        kind: kind,
        relativePath: path,
        bytes: bytes,
        now: _clock(),
      ),
      tooLarge: (kind) =>
          pages.recordTooLarge(storyId: story.id, kind: kind, now: _clock()),
      failed: (kind, error) => pages.recordFailed(
        storyId: story.id,
        kind: kind,
        error: error,
        now: _clock(),
      ),
    ),
    story.url,
    settings,
  );

  @override
  Future<PageStatus?> saveLink(LinkCopyRow link, AppSettings settings) => _save(
    _Target(
      label: 'link ${link.id}',
      pathFor: (kind) => files.relativeLinkPathFor(link.id, kind),
      maxBytes: maxLinkPageBytes,
      captured: (kind, path, bytes) => links.recordCaptured(
        id: link.id,
        kind: kind,
        relativePath: path,
        bytes: bytes,
        now: _clock(),
      ),
      tooLarge: (kind) =>
          links.recordTooLarge(id: link.id, kind: kind, now: _clock()),
      failed: (kind, error) => links.recordFailed(
        id: link.id,
        kind: kind,
        error: error,
        now: _clock(),
      ),
    ),
    link.url,
    settings,
  );

  Future<PageStatus?> _save(
    _Target target,
    String? address,
    AppSettings settings,
  ) async {
    final url = Uri.tryParse(address ?? '');
    if (url == null || !(url.isScheme('http') || url.isScheme('https'))) {
      return _failed(target, PageKind.mhtml, 'not an http(s) address');
    }
    await files.ensureDirectory();
    if (url.path.toLowerCase().endsWith('.pdf')) {
      return _savePdf(target, url);
    }
    return _saveArchive(target, url, settings);
  }

  Future<PageStatus?> _saveArchive(
    _Target target,
    Uri url,
    AppSettings settings,
  ) async {
    final cancellation = CaptureCancellation();
    _inFlight.add(cancellation);
    final relative = target.pathFor(PageKind.mhtml);
    final file = files.fileFor(relative);
    var timedOut = false;
    final guard = Timer(watchdog, () {
      timedOut = true;
      cancellation.cancel();
    });
    final CaptureResult result;
    try {
      result = await capture(
        url,
        file.path,
        captureOptionsFor(
          settings,
          filterListsDirectory: filterListsDirectory,
          maxBytes: target.maxBytes,
        ),
        cancellation,
      );
    } finally {
      guard.cancel();
      _inFlight.remove(cancellation);
    }

    switch (result) {
      case CaptureSuccess(:final bytes, :final timings):
        debugPrintSynchronously(
          'capture ${target.label} ${result.duration.inMilliseconds} ms: '
          'load ${timings.load.inMilliseconds} '
          'idle ${timings.idle.inMilliseconds} '
          'scroll ${timings.scroll.inMilliseconds} '
          'cleanup ${timings.cleanup.inMilliseconds} '
          'save ${timings.save.inMilliseconds}',
        );
        if (exceedsPageLimit(bytes, limit: target.maxBytes)) {
          await files.delete(relative);
          return _tooLarge(target, PageKind.mhtml);
        }
        await target.captured(PageKind.mhtml, relative, bytes);
        return PageStatus.ok;
      case CaptureFailure(kind: CaptureFailureKind.tooLarge):
        await files.delete(relative);
        return _tooLarge(target, PageKind.mhtml);
      case CaptureFailure(isPdf: true):
        await files.delete(relative);
        return _savePdf(target, url);
      case CaptureFailure(kind: CaptureFailureKind.cancelled):
        await files.delete(relative);
        if (!timedOut) return null;
        return _failed(
          target,
          PageKind.mhtml,
          'timeout: over ${watchdog.inSeconds} s',
        );
      case CaptureFailure(:final kind, :final message, :final httpStatus):
        await files.delete(relative);
        if (_looksOffline(kind) &&
            await probe.current() == ConnectionKind.none) {
          return null;
        }
        final detail = httpStatus == null ? message : 'HTTP $httpStatus';
        return _failed(target, PageKind.mhtml, '${kind.name}: $detail');
    }
  }

  bool _looksOffline(CaptureFailureKind kind) =>
      kind == CaptureFailureKind.network || kind == CaptureFailureKind.timeout;

  Future<PageStatus?> _savePdf(_Target target, Uri url) async {
    final relative = target.pathFor(PageKind.pdf);
    final result = await pdf.download(
      url,
      files.fileFor(relative),
      maxBytes: target.maxBytes,
    );
    switch (result) {
      case PdfSaved(:final bytes):
        await target.captured(PageKind.pdf, relative, bytes);
        return PageStatus.ok;
      case PdfTooLarge():
        return _tooLarge(target, PageKind.pdf);
      case PdfFailed(:final reason):
        return _failed(target, PageKind.pdf, reason);
    }
  }

  Future<PageStatus> _tooLarge(_Target target, PageKind kind) async {
    await target.tooLarge(kind);
    return PageStatus.tooLarge;
  }

  Future<PageStatus> _failed(
    _Target target,
    PageKind kind,
    String error,
  ) async {
    await target.failed(kind, error);
    return PageStatus.failed;
  }
}
