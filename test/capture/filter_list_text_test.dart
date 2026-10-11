import 'package:flutter_test/flutter_test.dart';
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
    test('accepts a list of named resources', () {
      FilterSources.checkResources('[{"name":"a.js","content":"eA=="}]');
    });

    test('rejects anything else', () {
      for (final bad in ['[]', '{}', '[{"content":"x"}]', 'oops', '<html>']) {
        expect(
          () => FilterSources.checkResources(bad),
          throwsA(isA<FilterListException>()),
          reason: bad,
        );
      }
    });
  });
}
