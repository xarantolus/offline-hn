import 'package:flutter_test/flutter_test.dart';
import 'package:page_capture/filters.dart';

final _at = DateTime.utc(2026, 10, 10, 12, 30, 15, 123, 456);

String _list(List<String> rules) =>
    '[Adblock Plus 2.0]\n! Title: t\n${rules.join('\n')}\n';

void main() {
  group('FilterCompiler', () {
    test('writes a stamped header and one record per distinct rule', () {
      final compiled = FilterCompiler.compile([
        _list(['||a.com^', '||a.com^', '##.ad', '! comment']),
        _list(['||b.com^\$script', 'example.org##.promo']),
      ], generated: _at);
      final lines = compiled.text.trimRight().split('\n');
      expect(lines.first, '#offline-hn-filters\t1\t2026-10-10T12:30:15.000Z');
      expect(lines.skip(1), [
        'B\t||a.com^\t\t',
        'H\t\t.ad',
        'B\t||b.com^\ts\t',
        'H\texample.org\t.promo',
      ]);
      expect(compiled.stats.networkRules, 2);
      expect(compiled.stats.cosmeticRules, 2);
    });

    test('counts what it skipped by reason', () {
      final compiled = FilterCompiler.compile([
        _list([
          '||a.com^',
          '||b.com^\$popup',
          '||c.com^\$popup',
          'x.com##p:has-text(y)',
        ]),
      ], generated: _at);
      expect(compiled.stats.skipped, {
        'option:popup': 2,
        'cosmetic:procedural': 1,
      });
    });

    test('rejects text that is not an Adblock list', () {
      expect(
        () => FilterCompiler.compile([
          '<html>429 Too Many Requests</html>',
        ], generated: _at),
        throwsA(isA<FilterListException>()),
      );
    });

    test('rejects a list with no network rules and honours a minimum', () {
      expect(
        () => FilterCompiler.compile([
          _list(['##.ad']),
        ], generated: _at),
        throwsA(isA<FilterListException>()),
      );
      expect(
        () => FilterCompiler.compile(
          [
            _list(['||a.com^']),
          ],
          generated: _at,
          minNetworkRulesPerList: 2,
        ),
        throwsA(isA<FilterListException>()),
      );
    });
  });
}
