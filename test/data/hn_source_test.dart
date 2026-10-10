import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offline_hn/data/api/hn_http.dart';
import 'package:offline_hn/data/api/hn_source.dart';
import 'package:offline_hn/data/model/feed_kind.dart';

import 'fixtures.dart';

http.Response _json(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

HnSource _source(
  Future<http.Response> Function(http.Request) handler, {
  Duration timeout = const Duration(seconds: 15),
}) => HnSource.create(
  http: HnHttp(client: MockClient(handler), timeout: timeout),
);

void main() {
  test('ids Algolia lacks come from Firebase, in the order asked', () async {
    final requested = <Uri>[];
    final source = _source((request) async {
      requested.add(request.url);
      if (request.url.host == 'hn.algolia.com') {
        return _json(fixture('algolia_search.json'));
      }
      return _json({
        'id': int.parse(request.url.pathSegments.last.split('.').first),
        'title': 'from firebase',
        'type': 'story',
      });
    });

    final stories = await source.stories([50031461, 777, 49977979]);

    expect(stories.map((s) => s.id), [50031461, 777, 49977979]);
    expect(stories[1].title, 'from firebase');
    expect(requested.where((u) => u.host == 'hn.algolia.com'), hasLength(1));
    expect(requested.where((u) => u.path == '/v0/item/777.json'), hasLength(1));
  });

  test('a story neither source knows is simply absent', () async {
    final source = _source((request) async {
      if (request.url.host == 'hn.algolia.com') {
        return _json({'hits': <Object?>[]});
      }
      return http.Response('null', 200);
    });
    expect(await source.stories([1, 2]), isEmpty);
  });

  test('more than one search page worth of ids is split', () async {
    var searches = 0;
    final source = _source((request) async {
      if (request.url.host == 'hn.algolia.com') {
        searches++;
        return _json({'hits': <Object?>[]});
      }
      return http.Response('null', 200);
    });
    await source.stories(List.generate(250, (i) => i + 1));
    expect(searches, 3);
  });

  test('an Algolia failure is not hidden behind Firebase requests', () async {
    var firebaseCalls = 0;
    final source = _source((request) async {
      if (request.url.host == 'hn.algolia.com') return http.Response('', 503);
      firebaseCalls++;
      return http.Response('null', 200);
    });
    await expectLater(source.stories([1, 2]), throwsA(isA<HnApiException>()));
    expect(firebaseCalls, 0);
  });

  test(
    'a thread Algolia has not indexed falls back to the bare story',
    () async {
      final source = _source((request) async {
        if (request.url.host == 'hn.algolia.com') {
          return http.Response('{}', 404);
        }
        return _json(fixture('firebase_story.json'));
      });
      final thread = await source.thread(50031269);
      expect(thread!.story.id, 50031269);
      expect(thread.comments, isEmpty);
    },
  );

  test('a thread nobody knows is null', () async {
    final source = _source((request) async {
      if (request.url.host == 'hn.algolia.com') return http.Response('{}', 404);
      return http.Response('null', 200);
    });
    expect(await source.thread(1), isNull);
  });

  test(
    'a request that outlasts the timeout fails instead of hanging',
    () async {
      final source = _source(
        (request) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        source.ranking(FeedKind.top),
        throwsA(isA<HnApiException>()),
      );
    },
  );
}
