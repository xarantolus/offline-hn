import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/debug/mock_data.dart';

void main() {
  test('story count and thread size agree', () {
    expect(mockStories.length, 40);
    expect(mockThread.comments.length, mockThreadStory.comments);
    expect(mockShortThread.comments.length, mockShortThreadStory.comments);
  });

  test('threads nest without skipping a level', () {
    for (final t in [mockThread, mockShortThread]) {
      expect(t.comments.first.depth, 0);
      for (var i = 1; i < t.comments.length; i++) {
        expect(t.comments[i].depth <= t.comments[i - 1].depth + 1, isTrue);
      }
    }
    expect(mockThread.maxDepth, greaterThanOrEqualTo(6));
  });

  test('collapsing hides exactly the descendants', () {
    final collapsedId = mockThread.initiallyCollapsed.first;
    final all = mockThread.visible({});
    final some = mockThread.visible({collapsedId});
    final row = some.firstWhere((v) => v.comment.id == collapsedId);
    expect(row.hiddenCount, greaterThan(0));
    expect(all.length - some.length, row.hiddenCount);
  });

  test('every initially collapsed comment has children', () {
    for (final v in mockThread.visible(mockThread.initiallyCollapsed)) {
      if (v.collapsed) expect(v.hasChildren, isTrue);
    }
  });
}
