import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/ui/story_list_place.dart';

void main() {
  group('extrapolatedRowOffset', () {
    test('counts rows from the anchor by their average height', () {
      expect(
        extrapolatedRowOffset(
          index: 14,
          anchorIndex: 10,
          anchorOffset: 3000,
          average: 300,
        ),
        4200,
      );
    });

    test('works backwards from a row below', () {
      expect(
        extrapolatedRowOffset(
          index: 8,
          anchorIndex: 10,
          anchorOffset: 3000,
          average: 300,
        ),
        2400,
      );
    });
  });

  group('alignmentOf', () {
    test('is the fraction of the viewport above the row', () {
      expect(alignmentOf(top: 250, viewport: 1000), 0.25);
    });

    test('keeps a row that was low on the screen from landing off it', () {
      expect(alignmentOf(top: 950, viewport: 1000), 0.6);
      expect(alignmentOf(top: -40, viewport: 1000), 0);
    });
  });
}
