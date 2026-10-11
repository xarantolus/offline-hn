import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/policy/filter_list_url.dart';

void main() {
  test('a web address is stored trimmed', () {
    final checked = checkFilterListUrl('  https://example.org/list.txt \n', []);
    expect(checked.url, 'https://example.org/list.txt');
    expect(checked.problem, isNull);
  });

  test('text that is not an address is refused', () {
    expect(
      checkFilterListUrl('easylist', []).problem,
      FilterListUrlProblem.notAnAddress,
    );
    expect(
      checkFilterListUrl('https://', []).problem,
      FilterListUrlProblem.notAnAddress,
    );
  });

  test('only http and https are accepted', () {
    expect(
      checkFilterListUrl('ftp://example.org/list.txt', []).problem,
      FilterListUrlProblem.notWeb,
    );
  });

  test('an address already in the list is refused', () {
    expect(
      checkFilterListUrl('https://example.org/a.txt', [
        'https://example.org/a.txt',
      ]).problem,
      FilterListUrlProblem.alreadyListed,
    );
  });
}
