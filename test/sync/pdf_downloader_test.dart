import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offline_hn/sync/pdf_downloader.dart';

const _pdf = [0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x37];
final _url = Uri.parse('https://example.com/paper.pdf');

void main() {
  late Directory directory;
  late File target;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('pdf_downloader_test');
    target = File('${directory.path}/1.pdf');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  PdfDownloader downloader(
    Future<http.StreamedResponse> Function() respond, {
    Duration timeout = const Duration(seconds: 5),
    Duration connectTimeout = const Duration(seconds: 5),
    Duration stallTimeout = const Duration(seconds: 5),
  }) => PdfDownloader(
    client: MockClient.streaming((request, body) => respond()),
    timeout: timeout,
    connectTimeout: connectTimeout,
    stallTimeout: stallTimeout,
  );

  http.StreamedResponse reply(
    List<List<int>> chunks, {
    int status = 200,
    Map<String, String> headers = const {},
    int? length,
  }) => http.StreamedResponse(
    Stream.fromIterable(chunks),
    status,
    headers: headers,
    contentLength: length,
  );

  Future<PdfResult> run(PdfDownloader d, {int maxBytes = 1000}) =>
      d.download(_url, target, maxBytes: maxBytes);

  void expectNothingLeft() {
    expect(target.existsSync(), isFalse);
    expect(File('${target.path}.part').existsSync(), isFalse);
  }

  test('saves a PDF and reports its size', () async {
    final result = await run(downloader(() async => reply([_pdf, _pdf])));
    expect(result, isA<PdfSaved>());
    expect((result as PdfSaved).bytes, 16);
    expect(target.lengthSync(), 16);
  });

  test('the content type does not matter, the bytes do', () async {
    for (final type in [null, 'text/html', 'application/octet-stream']) {
      final result = await run(
        downloader(() async => reply([_pdf], headers: {'content-type': ?type})),
      );
      expect(result, isA<PdfSaved>(), reason: '$type');
      target.deleteSync();
    }
  });

  test('HTML served for a .pdf address is refused', () async {
    final result = await run(
      downloader(
        () async => reply(
          ['<html><body>Please log in</body></html>'.codeUnits],
          headers: {'content-type': 'application/pdf'},
        ),
      ),
    );
    expect(result, isA<PdfFailed>());
    expectNothingLeft();
  });

  test('a signature split across tiny chunks is still found', () async {
    final result = await run(
      downloader(
        () async => reply([
          for (final b in _pdf) [b],
        ]),
      ),
    );
    expect(result, isA<PdfSaved>());
    expect(target.lengthSync(), _pdf.length);
  });

  test('a little junk before the signature is accepted', () async {
    final result = await run(
      downloader(
        () async => reply([
          [0x0a, 0x0a],
          _pdf,
        ]),
      ),
    );
    expect(result, isA<PdfSaved>());
  });

  test('a body too short to hold the signature fails', () async {
    final result = await run(
      downloader(
        () async => reply([
          [0x25, 0x50],
        ]),
      ),
    );
    expect(result, isA<PdfFailed>());
    expectNothingLeft();
  });

  test('an empty body fails', () async {
    final result = await run(downloader(() async => reply([])));
    expect((result as PdfFailed).reason, 'empty response');
    expectNothingLeft();
  });

  group('status codes', () {
    for (final status in [
      204,
      206,
      301,
      302,
      304,
      400,
      401,
      403,
      404,
      429,
      500,
      503,
    ]) {
      test('$status is a failure and leaves nothing', () async {
        final result = await run(
          downloader(() async => reply([_pdf], status: status)),
        );
        expect(result, isA<PdfFailed>());
        expectNothingLeft();
      });
    }

    test('204 says there was no content', () async {
      final result = await run(downloader(() async => reply([], status: 204)));
      expect((result as PdfFailed).reason, 'no content');
    });
  });

  test(
    'redirects are asked to be followed, a bounded number of times',
    () async {
      late http.BaseRequest seen;
      final d = PdfDownloader(
        client: MockClient.streaming((request, body) async {
          seen = request;
          return reply([_pdf]);
        }),
      );
      await run(d);
      expect(seen.followRedirects, isTrue);
      expect(seen.maxRedirects, lessThanOrEqualTo(10));
    },
  );

  group('size limit', () {
    test('a declared size over the limit is refused before any body', () async {
      var pulled = false;
      final result = await run(
        downloader(
          () async => http.StreamedResponse(
            Stream.fromFuture(() async {
              pulled = true;
              return _pdf;
            }()),
            200,
            contentLength: 5000,
          ),
        ),
      );
      expect(result, isA<PdfTooLarge>());
      expect(pulled, isTrue, reason: 'the stream is created, never written');
      expectNothingLeft();
    });

    test('a body over the limit stops at once and leaves no file', () async {
      var chunksRead = 0;
      Stream<List<int>> body() async* {
        yield _pdf;
        for (var i = 0; i < 1000; i++) {
          chunksRead++;
          yield List.filled(100, 0);
        }
      }

      final result = await run(
        downloader(() async => http.StreamedResponse(body(), 200)),
        maxBytes: 250,
      );
      expect(result, isA<PdfTooLarge>());
      expect(chunksRead, lessThan(10));
      expectNothingLeft();
    });

    test('exactly the limit is accepted', () async {
      final result = await run(
        downloader(() async => reply([_pdf, List.filled(92, 0)])),
        maxBytes: 100,
      );
      expect(result, isA<PdfSaved>());
    });
  });

  group('failures while streaming', () {
    test('a connection that breaks midway leaves no file', () async {
      Stream<List<int>> body() async* {
        yield _pdf;
        yield List.filled(50, 0);
        throw const SocketException('connection reset');
      }

      final result = await run(
        downloader(() async => http.StreamedResponse(body(), 200)),
      );
      expect(result, isA<PdfFailed>());
      expectNothingLeft();
    });

    test('fewer bytes than declared is an incomplete download', () async {
      final result = await run(
        downloader(() async => reply([_pdf], length: 500)),
      );
      expect((result as PdfFailed).reason, 'incomplete download');
      expectNothingLeft();
    });

    test('a request that throws is a failure', () async {
      final result = await run(
        downloader(() async => throw const SocketException('no route')),
      );
      expect(result, isA<PdfFailed>());
      expectNothingLeft();
    });
  });

  group('timeouts', () {
    test('no answer within the connect timeout fails', () async {
      final result = await run(
        downloader(
          () => Completer<http.StreamedResponse>().future,
          connectTimeout: const Duration(milliseconds: 50),
        ),
      );
      expect((result as PdfFailed).reason, 'timed out');
      expectNothingLeft();
    });

    test('a body that stalls fails and leaves no file', () async {
      final controller = StreamController<List<int>>()..add(_pdf);
      Stream<List<int>> body() => controller.stream;

      final result = await run(
        downloader(
          () async => http.StreamedResponse(body(), 200),
          stallTimeout: const Duration(milliseconds: 50),
        ),
      );
      expect((result as PdfFailed).reason, 'timed out');
      expectNothingLeft();
    });

    test('a body that trickles past the overall timeout fails', () async {
      Stream<List<int>> body() async* {
        yield _pdf;
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          yield [0];
        }
      }

      final result = await run(
        downloader(
          () async => http.StreamedResponse(body(), 200),
          timeout: const Duration(milliseconds: 100),
        ),
      );
      expect((result as PdfFailed).reason, 'timed out');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expectNothingLeft();
    });
  });
}
