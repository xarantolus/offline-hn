import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/pages/thread/thread_pager.dart';

void main() {
  test('starts on the opened story, keeping the list order', () {
    final start = pagerFor([5, 9, 2, 7], 2);
    expect(start.ids, [5, 9, 2, 7]);
    expect(start.index, 2);
  });

  test('a story missing from the list opens alone', () {
    final start = pagerFor([5, 9], 3);
    expect(start.ids, [3]);
    expect(start.index, 0);
  });
}
