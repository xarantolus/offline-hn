import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:page_capture/filters.dart';

void main() {
  test('counts network and cosmetic rules and ignores comments', () {
    final counts = FilterListText.inspect(
      '[Adblock Plus 2.0]\n! Title: t\n||a.com^\n@@||a.com/ok.js\n'
      '##.ad\nexample.org#@#.promo\nexample.org#?#div:has(p)\n'
      'x.com##+js(abort-on-property-read, y)\n/banner/*\$image\n',
    );
    expect(counts.networkRules, 3);
    expect(counts.cosmeticRules, 4);
  });

  test('a rule with ## after a path is still a network rule', () {
    final counts = FilterListText.inspect('! t\n||a.com/x##y^\n');
    expect(counts.networkRules, 1);
    expect(counts.cosmeticRules, 0);
  });

  test('rejects text that is not an Adblock list', () {
    expect(
      () => FilterListText.inspect('<html>429 Too Many Requests</html>'),
      throwsA(isA<FilterListException>()),
    );
  });

  test('rejects a list with no network rules', () {
    expect(
      () => FilterListText.inspect('[Adblock Plus 2.0]\n##.ad\n'),
      throwsA(isA<FilterListException>()),
    );
  });

  group('resources', () {
    test('accepts a file that starts with a name and a mime type', () {
      FilterSources.checkResources('noop.js application/javascript\n(x)\n');
      FilterSources.checkResources('a.mp4 video/mp4;base64\nAAAA\n');
    });

    test('rejects anything else', () {
      for (final bad in ['', '{}', '[]', '<html>', 'one two']) {
        expect(
          () => FilterSources.checkResources(bad),
          throwsA(isA<FilterListException>()),
          reason: bad,
        );
      }
    });
  });

  group('resources download', () {
    test('follows the newest revision in the index', () async {
      final asked = <String>[];
      final client = MockClient((request) async {
        asked.add(request.url.toString());
        return http.Response(
          request.url.path.endsWith('metadata.json')
              ? '{"revisions":["one","two"]}'
              : 'x.js application/javascript\n1\n',
          200,
        );
      });
      await FilterSources.downloadResources(client);
      expect(asked.last, endsWith('/ublock-resources/two/list.txt'));
    });

    test('rejects an index without revisions', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      expect(
        FilterSources.downloadResources(client),
        throwsA(isA<FilterListException>()),
      );
    });
  });
}
