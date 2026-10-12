import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/repository/link_repository.dart';
import 'package:offline_hn/data/repository/page_repository.dart';
import 'package:offline_hn/sync/page_files.dart';
import 'package:offline_hn/sync/page_saver.dart';
import 'package:offline_hn/sync/pdf_downloader.dart';
import 'package:page_capture/page_capture.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late PageRepository pages;
  late PageFiles files;
  late List<(Uri, String, CaptureOptions)> captures;
  late CaptureFn capture;
  late http.Client client;
  late FakeProbe probe;
  final settings = AppSettings.defaults();
  final at = DateTime.utc(2026, 10, 10, 6);

  StoryRow story(int id, String? url) => StoryRow(
    id: id,
    title: 'Story $id',
    url: url,
    commentCount: 0,
    type: 'story',
    firstSeen: at,
    lastSeen: at,
    read: false,
    saved: false,
    hidden: false,
  );

  PageSaver saver({Duration watchdog = const Duration(seconds: 70)}) =>
      PageSaver(
        files: files,
        pages: pages,
        links: LinkRepository(db),
        capture: capture,
        pdf: PdfDownloader(client: client),
        probe: probe,
        filterListsDirectory: '/lists',
        clock: () => at,
        watchdog: watchdog,
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    pages = PageRepository(db);
    files = tempPageFiles();
    probe = FakeProbe();
    captures = [];
    client = MockClient.streaming(
      (request, body) async => http.StreamedResponse(
        Stream.value([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31]),
        200,
      ),
    );
    capture = (url, path, options, cancellation) async {
      captures.add((url, path, options));
      File(path).writeAsStringSync('mhtml');
      return const CaptureSuccess(
        duration: Duration(seconds: 3),
        bytes: 5,
        resourceCount: 2,
      );
    };
  });
  tearDown(() => db.close());

  Future<PageCopyRow> stored(int id) async =>
      (await pages.forStories([id]))[id]!;

  test('a captured page is recorded under pages/ with its size', () async {
    final status = await saver().save(
      story(1, 'https://example.com/a'),
      settings,
    );

    expect(status, PageStatus.ok);
    final row = await stored(1);
    expect(row.relativePath, 'pages/1.mhtml');
    expect(row.kind, PageKind.mhtml);
    expect(row.bytes, 5);
    expect(files.fileFor(row.relativePath!).existsSync(), isTrue);
    expect(captures.single.$3.filterListsDirectory, '/lists');
  });

  test('the cleanup settings reach the capture', () async {
    final off = AppSettings.fromRaw({
      Settings.adBlocking.key: 'false',
      Settings.rejectCookiePopups.key: 'false',
    });
    await saver().save(story(1, 'https://example.com/a'), off);
    final cleanup = captures.single.$3.cleanup;
    expect(cleanup.blockRequests, isFalse);
    expect(cleanup.rejectConsent, isFalse);
  });

  test('a page over the limit is recorded as too large and removed', () async {
    capture = (url, path, options, cancellation) async {
      File(path).writeAsStringSync('big');
      return const CaptureSuccess(
        duration: Duration.zero,
        bytes: 26 * 1024 * 1024,
        resourceCount: 1,
      );
    };
    expect(
      await saver().save(story(1, 'https://example.com/a'), settings),
      PageStatus.tooLarge,
    );
    expect((await stored(1)).status, PageStatus.tooLarge);
    expect(files.fileFor('pages/1.mhtml').existsSync(), isFalse);
  });

  test('the plugin refusing a big page is the same', () async {
    capture = (url, path, options, cancellation) async => const CaptureFailure(
      duration: Duration.zero,
      kind: CaptureFailureKind.tooLarge,
    );
    expect(
      await saver().save(story(1, 'https://example.com/a'), settings),
      PageStatus.tooLarge,
    );
  });

  test('a failure is recorded with its kind and status', () async {
    capture = (url, path, options, cancellation) async => const CaptureFailure(
      duration: Duration.zero,
      kind: CaptureFailureKind.http,
      httpStatus: 403,
    );
    expect(
      await saver().save(story(1, 'https://example.com/a'), settings),
      PageStatus.failed,
    );
    final row = await stored(1);
    expect(row.status, PageStatus.failed);
    expect(row.error, 'http: HTTP 403');
  });

  test('a network failure with no connection is owed, not failed', () async {
    probe.kind = ConnectionKind.none;
    capture = (url, path, options, cancellation) async => const CaptureFailure(
      duration: Duration.zero,
      kind: CaptureFailureKind.network,
      message: '-2 net::ERR_NAME_NOT_RESOLVED',
    );
    expect(
      await saver().save(story(1, 'https://example.com/a'), settings),
      isNull,
    );
    expect(await pages.forStories([1]), isEmpty);
  });

  test('the same failure with a connection is the page failing', () async {
    capture = (url, path, options, cancellation) async => const CaptureFailure(
      duration: Duration.zero,
      kind: CaptureFailureKind.network,
      message: '-2 net::ERR_NAME_NOT_RESOLVED',
    );
    expect(
      await saver().save(story(1, 'https://example.com/a'), settings),
      PageStatus.failed,
    );
  });

  test('a download response is fetched as a PDF instead', () async {
    capture = (url, path, options, cancellation) async => const CaptureFailure(
      duration: Duration.zero,
      kind: CaptureFailureKind.unsupportedContent,
      contentType: 'application/pdf',
    );
    expect(
      await saver().save(story(1, 'https://example.com/paper'), settings),
      PageStatus.ok,
    );
    final row = await stored(1);
    expect(row.kind, PageKind.pdf);
    expect(row.relativePath, 'pages/1.pdf');
    expect(files.fileFor('pages/1.pdf').readAsBytesSync().length, 6);
  });

  test('a link that ends in .pdf skips the WebView', () async {
    await saver().save(story(1, 'https://example.com/a/b.PDF'), settings);
    expect(captures, isEmpty);
    expect((await stored(1)).kind, PageKind.pdf);
  });

  test(
    'an address that is not http(s) fails without loading anything',
    () async {
      expect(
        await saver().save(story(1, 'ftp://example.com/a'), settings),
        PageStatus.failed,
      );
      expect(await saver().save(story(2, null), settings), PageStatus.failed);
      expect(captures, isEmpty);
    },
  );

  test('a capture cancelled from outside records nothing', () async {
    final started = Completer<void>();
    capture = (url, path, options, cancellation) async {
      started.complete();
      await cancellation.whenCancelled;
      return const CaptureFailure(
        duration: Duration.zero,
        kind: CaptureFailureKind.cancelled,
      );
    };
    final s = saver();
    final result = s.save(story(1, 'https://example.com/a'), settings);
    await started.future;
    s.cancel();
    expect(await result, isNull);
    expect(await pages.forStories([1]), isEmpty);
  });

  test('cancelling reaches every capture in flight', () async {
    var started = 0;
    final both = Completer<void>();
    capture = (url, path, options, cancellation) async {
      if (++started == 2) both.complete();
      await cancellation.whenCancelled;
      return const CaptureFailure(
        duration: Duration.zero,
        kind: CaptureFailureKind.cancelled,
      );
    };
    final s = saver();
    final first = s.save(story(1, 'https://example.com/a'), settings);
    final second = s.save(story(2, 'https://example.com/b'), settings);
    await both.future;
    s.cancel();
    expect(await Future.wait([first, second]), [isNull, isNull]);
  });

  test(
    'a capture that never ends is cut off and recorded as a timeout',
    () async {
      capture = (url, path, options, cancellation) async {
        await cancellation.whenCancelled;
        return const CaptureFailure(
          duration: Duration.zero,
          kind: CaptureFailureKind.cancelled,
        );
      };
      final status = await saver(watchdog: const Duration(milliseconds: 50))
          .save(story(1, 'https://example.com/a'), settings);
      expect(status, PageStatus.failed);
      expect((await stored(1)).error, startsWith('timeout'));
    },
  );

  group('PDF download', () {
    PdfDownloader downloader(http.Client client) =>
        PdfDownloader(client: client, timeout: const Duration(seconds: 1));

    test('something that is not a PDF is refused', () async {
      final result =
          await downloader(
            MockClient.streaming(
              (request, body) async =>
                  http.StreamedResponse(Stream.value('<html>'.codeUnits), 200),
            ),
          ).download(
            Uri.parse('https://e.com/x.pdf'),
            files.fileFor('pages/1.pdf'),
            maxBytes: 100,
          );
      expect(result, isA<PdfFailed>());
      expect(files.fileFor('pages/1.pdf').existsSync(), isFalse);
    });

    test('a declared size over the limit is not downloaded', () async {
      final result =
          await downloader(
            MockClient.streaming(
              (request, body) async => http.StreamedResponse(
                const Stream<List<int>>.empty(),
                200,
                contentLength: 500,
              ),
            ),
          ).download(
            Uri.parse('https://e.com/x.pdf'),
            files.fileFor('pages/1.pdf'),
            maxBytes: 100,
          );
      expect(result, isA<PdfTooLarge>());
    });

    test('a body that grows past the limit leaves no file', () async {
      final result =
          await downloader(
            MockClient.streaming(
              (request, body) async => http.StreamedResponse(
                Stream.fromIterable([
                  [0x25, 0x50, 0x44, 0x46],
                  List.filled(200, 0),
                ]),
                200,
              ),
            ),
          ).download(
            Uri.parse('https://e.com/x.pdf'),
            files.fileFor('pages/1.pdf'),
            maxBytes: 100,
          );
      expect(result, isA<PdfTooLarge>());
      expect(files.fileFor('pages/1.pdf').existsSync(), isFalse);
      expect(
        File('${files.fileFor('pages/1.pdf').path}.part').existsSync(),
        isFalse,
      );
    });

    test('an error status is a failure', () async {
      final result =
          await downloader(
            MockClient.streaming(
              (request, body) async =>
                  http.StreamedResponse(const Stream<List<int>>.empty(), 404),
            ),
          ).download(
            Uri.parse('https://e.com/x.pdf'),
            files.fileFor('pages/1.pdf'),
            maxBytes: 100,
          );
      expect((result as PdfFailed).reason, contains('404'));
    });

    test('a download that stalls is cut off', () async {
      final result =
          await downloader(
            MockClient.streaming((request, body) async {
              await Future<void>.delayed(const Duration(seconds: 5));
              return http.StreamedResponse(
                const Stream<List<int>>.empty(),
                200,
              );
            }),
          ).download(
            Uri.parse('https://e.com/x.pdf'),
            files.fileFor('pages/1.pdf'),
            maxBytes: 100,
          );
      expect(result, isA<PdfFailed>());
    });
  });
}
