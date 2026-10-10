import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:offline_hn/capture/capture_settings.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
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

  void cancel();
}

/// Saves one story's page and records the outcome. A failure is a recorded
/// result, not an exception.
class PageSaver implements StoryPageSaver {
  PageSaver({
    required this.files,
    required this.pages,
    required this.capture,
    required this.pdf,
    required this.probe,
    required this.filterListsDirectory,
    DateTime Function()? clock,
    this.watchdog = const Duration(seconds: 150),
  }) : _clock = clock ?? DateTime.now;

  final PageFiles files;
  final PageRepository pages;
  final CaptureFn capture;
  final PdfDownloader pdf;
  final ConnectionProbe probe;
  final String filterListsDirectory;
  final Duration watchdog;
  final DateTime Function() _clock;

  CaptureCancellation _cancellation = CaptureCancellation();

  @override
  void cancel() => _cancellation.cancel();

  @override
  Future<PageStatus?> save(StoryRow story, AppSettings settings) async {
    final url = Uri.tryParse(story.url ?? '');
    if (url == null || !(url.isScheme('http') || url.isScheme('https'))) {
      return _failed(story.id, PageKind.mhtml, 'not an http(s) address');
    }
    await files.ensureDirectory();
    if (url.path.toLowerCase().endsWith('.pdf')) {
      return _savePdf(story.id, url);
    }
    return _saveArchive(story.id, url, settings);
  }

  Future<PageStatus?> _saveArchive(
    int id,
    Uri url,
    AppSettings settings,
  ) async {
    _cancellation = CaptureCancellation();
    final relative = files.relativePathFor(id, PageKind.mhtml);
    final file = files.fileFor(relative);
    var timedOut = false;
    final guard = Timer(watchdog, () {
      timedOut = true;
      _cancellation.cancel();
    });
    final CaptureResult result;
    try {
      result = await capture(
        url,
        file.path,
        captureOptionsFor(settings, filterListsDirectory: filterListsDirectory),
        _cancellation,
      );
    } finally {
      guard.cancel();
    }

    switch (result) {
      case CaptureSuccess(:final bytes, :final timings):
        debugPrintSynchronously(
          'capture $id ${result.duration.inMilliseconds} ms: '
          'load ${timings.load.inMilliseconds} '
          'idle ${timings.idle.inMilliseconds} '
          'scroll ${timings.scroll.inMilliseconds} '
          'cleanup ${timings.cleanup.inMilliseconds} '
          'save ${timings.save.inMilliseconds}',
        );
        if (exceedsPageLimit(bytes)) {
          await files.delete(relative);
          return _tooLarge(id, PageKind.mhtml);
        }
        await pages.recordCaptured(
          storyId: id,
          kind: PageKind.mhtml,
          relativePath: relative,
          bytes: bytes,
          now: _clock(),
        );
        return PageStatus.ok;
      case CaptureFailure(kind: CaptureFailureKind.tooLarge):
        await files.delete(relative);
        return _tooLarge(id, PageKind.mhtml);
      case CaptureFailure(isPdf: true):
        await files.delete(relative);
        return _savePdf(id, url);
      case CaptureFailure(kind: CaptureFailureKind.cancelled):
        await files.delete(relative);
        if (!timedOut) return null;
        return _failed(
          id,
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
        return _failed(id, PageKind.mhtml, '${kind.name}: $detail');
    }
  }

  bool _looksOffline(CaptureFailureKind kind) =>
      kind == CaptureFailureKind.network || kind == CaptureFailureKind.timeout;

  Future<PageStatus?> _savePdf(int id, Uri url) async {
    final relative = files.relativePathFor(id, PageKind.pdf);
    final result = await pdf.download(
      url,
      files.fileFor(relative),
      maxBytes: maxPageBytes,
    );
    switch (result) {
      case PdfSaved(:final bytes):
        await pages.recordCaptured(
          storyId: id,
          kind: PageKind.pdf,
          relativePath: relative,
          bytes: bytes,
          now: _clock(),
        );
        return PageStatus.ok;
      case PdfTooLarge():
        return _tooLarge(id, PageKind.pdf);
      case PdfFailed(:final reason):
        return _failed(id, PageKind.pdf, reason);
    }
  }

  Future<PageStatus> _tooLarge(int id, PageKind kind) async {
    await pages.recordTooLarge(storyId: id, kind: kind, now: _clock());
    return PageStatus.tooLarge;
  }

  Future<PageStatus> _failed(int id, PageKind kind, String error) async {
    await pages.recordFailed(
      storyId: id,
      kind: kind,
      error: error,
      now: _clock(),
    );
    return PageStatus.failed;
  }
}
