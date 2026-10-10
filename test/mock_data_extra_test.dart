import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/debug/mock_data.dart';
import 'package:offline_hn/ui/feed_switcher.dart';

void main() {
  test('every day has stories in every feed', () {
    for (final day in mockDayOffsets) {
      for (final kind in FeedKind.values) {
        expect(storiesFor(kind, day), isNotEmpty, reason: '$kind day $day');
      }
    }
  });

  test('days partition the stories', () {
    final total = mockDayOffsets
        .map((d) => storiesFor(FeedKind.top, d).length)
        .fold(0, (a, b) => a + b);
    expect(total, mockStories.length);
  });
}
