import 'package:flutter_test/flutter_test.dart';
import 'package:page_capture/filters.dart';

String? _record(String line) => switch (FilterParser.parse(line)) {
  NetworkLine(:final rule) => rule.toRecord(),
  CosmeticLine(:final rule) => rule.toRecord(),
  _ => null,
};

String? _skipped(String line) => switch (FilterParser.parse(line)) {
  SkippedLine(:final reason) => reason,
  _ => null,
};

void main() {
  group('network rules', () {
    test('a host anchor with no options', () {
      expect(_record('||ads.example.com^'), 'B\t||ads.example.com^\t\t');
    });

    test('options become flags, types and domains', () {
      expect(
        _record(r'||cdn.net^$third-party,script,domain=a.com|~b.a.com'),
        'B\t||cdn.net^\t3s\ta.com|~b.a.com',
      );
    });

    test('an exception, important and first-party', () {
      expect(_record(r'@@||x.org/ok^$image'), 'A\t||x.org/ok^\ti\t');
      expect(_record(r'||x.org^$important'), 'B\t||x.org^\t!\t');
      expect(_record(r'||x.org^$~third-party'), 'B\t||x.org^\t1\t');
    });

    test('negated types mean every other type', () {
      final record = _record(r'||x.org^$~script,~image')!;
      final flags = record.split('\t')[2];
      expect(flags.split('')..sort(), ['c', 'f', 'm', 'o', 't', 'x']);
    });

    test('patterns are lowercased', () {
      expect(_record('||Ads.Example.COM^'), 'B\t||ads.example.com^\t\t');
    });

    test('rules this matcher cannot honour are skipped, and say why', () {
      expect(_skipped(r'||x.org^$popup'), 'option:popup');
      expect(_skipped(r'@@||x.org^$document'), 'option:document');
      expect(_skipped(r'||x.org^$redirect=noopjs'), 'option:redirect');
      expect(_skipped(r'/ads\d+/$script'), 'network:regex');
      expect(_skipped('/banner[0-9]+/'), 'network:regex');
    });
  });

  group('cosmetic rules', () {
    test('generic, per domain and excluded domains', () {
      expect(_record('##.ad-banner'), 'H\t\t.ad-banner');
      expect(
        _record('example.com,Other.org##.promo'),
        'H\texample.com|other.org\t.promo',
      );
      expect(
        _record('~docs.example.com##.promo'),
        'H\t~docs.example.com\t.promo',
      );
    });

    test('an unhide rule', () {
      expect(_record('example.com#@#.ad-banner'), 'U\texample.com\t.ad-banner');
    });

    test('selectors with attribute dollars are not mistaken for options', () {
      expect(_record('##a[href\$="/ad"]'), 'H\t\ta[href\$="/ad"]');
    });

    test('procedural, scriptlet and wildcard-domain rules are skipped', () {
      expect(
        _skipped('example.com##div:has-text(Sponsored)'),
        'cosmetic:procedural',
      );
      expect(
        _skipped('example.com##+js(abort-on-property-read, x)'),
        'cosmetic:script',
      );
      expect(_skipped('example.com#?#div:-abp-has(.x)'), 'cosmetic:extended');
      expect(_skipped('example.*##.ad'), 'cosmetic:domain');
    });
  });

  test('comments, headers and blank lines produce nothing', () {
    for (final line in ['! Title: EasyList', '[Adblock Plus 2.0]', '   ', '']) {
      expect(FilterParser.parse(line), isA<BlankLine>());
    }
  });
}
