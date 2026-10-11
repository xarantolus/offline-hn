import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:page_capture/page_capture.dart';

void main() {
  test('a success carries the measurements the capture reported', () {
    final result = CaptureResult.fromMap({
      'ok': true,
      'millis': 12345,
      'bytes': 2048,
      'resources': 90,
      'blocked': 14,
      'removed': 3,
      'consent': ['onetrust'],
      'finalUrl': 'https://example.com/a',
    });
    expect(result, isA<CaptureSuccess>());
    final success = result as CaptureSuccess;
    expect(success.duration, const Duration(milliseconds: 12345));
    expect(success.bytes, 2048);
    expect(success.resourceCount, 90);
    expect(success.blockedRequests, 14);
    expect(success.removedElements, 3);
    expect(success.consentHandlers, ['onetrust']);
    expect(success.finalUrl, Uri.parse('https://example.com/a'));
  });

  test('each failure kind maps to its type and details', () {
    for (final kind in CaptureFailureKind.values) {
      final result = CaptureResult.fromMap({
        'ok': false,
        'error': kind.name,
        'message': 'why',
        'millis': 5,
      });
      expect((result as CaptureFailure).kind, kind);
      expect(result.message, 'why');
    }
  });

  test('an HTTP failure keeps the status', () {
    final failure = CaptureResult.fromMap({
      'ok': false,
      'millis': 5,
      'error': 'http',
      'httpStatus': 403,
    }) as CaptureFailure;
    expect(failure.kind, CaptureFailureKind.http);
    expect(failure.httpStatus, 403);
  });

  test('a PDF is recognised from the content type the browser saw', () {
    final failure = CaptureResult.fromMap({
      'ok': false,
      'millis': 5,
      'error': 'unsupportedContent',
      'contentType': 'application/pdf',
    }) as CaptureFailure;
    expect(failure.isPdf, isTrue);
    expect(
      const CaptureFailure(
        duration: Duration.zero,
        kind: CaptureFailureKind.unsupportedContent,
        contentType: 'application/zip',
      ).isPdf,
      isFalse,
    );
  });

  test('a payload that does not match throws', () {
    expect(
      () => CaptureResult.fromMap({'ok': false, 'error': 'brand-new'}),
      throwsA(isA<CheckedFromJsonException>()),
    );
    expect(
      () => CaptureResult.fromMap({'ok': true, 'millis': '5', 'bytes': 1}),
      throwsA(isA<CheckedFromJsonException>()),
    );
    expect(
      () => CaptureResult.fromMap({
        'ok': true,
        'millis': 5,
        'bytes': 1,
        'resources': 1,
        'phases': {'load': 'slow'},
      }),
      throwsA(isA<CheckedFromJsonException>()),
    );
    expect(() => CaptureResult.fromMap({}), throwsFormatException);
  });

  test('options describe the cleanup layers the native side reads', () {
    final map = const CaptureOptions(
      cleanup: CaptureCleanup(hideElements: false),
    ).toMap();
    expect(map['blockRequests'], isTrue);
    expect(map['hideElements'], isFalse);
    expect(map['rejectConsent'], isTrue);
    expect(
      const CaptureOptions(cleanup: CaptureCleanup.none())
          .toMap()['blockRequests'],
      isFalse,
    );
  });

  test('phase timings arrive in milliseconds, missing ones as zero', () {
    final result = CaptureResult.fromMap({
      'ok': true,
      'millis': 9000,
      'bytes': 1,
      'resources': 1,
      'phases': {'load': 3000, 'idle': 1500, 'scroll': 4000, 'save': 400},
    }) as CaptureSuccess;
    expect(result.timings.load, const Duration(seconds: 3));
    expect(result.timings.idle, const Duration(milliseconds: 1500));
    expect(result.timings.scroll, const Duration(seconds: 4));
    expect(result.timings.cleanup, Duration.zero);
    expect(result.timings.save, const Duration(milliseconds: 400));
  });
}
