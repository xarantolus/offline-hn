import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/ui/selection_guard.dart';

void main() {
  test('dismiss clears an active selection once', () {
    final guard = SelectionGuard();
    var cleared = 0;
    guard.changed('a', selected: true, clear: () => cleared++);
    expect(guard.dismiss(), isTrue);
    expect(guard.dismiss(), isFalse);
    expect(cleared, 1);
  });

  test('nothing selected means nothing to dismiss', () {
    expect(SelectionGuard().dismiss(), isFalse);
  });

  test('a selection that ended by itself is not dismissed', () {
    final guard = SelectionGuard();
    var cleared = 0;
    guard.changed('a', selected: true, clear: () => cleared++);
    guard.changed('a', selected: false);
    expect(guard.active, isFalse);
    expect(guard.dismiss(), isFalse);
    expect(cleared, 0);
  });

  test('selecting in another area clears the previous one', () {
    final guard = SelectionGuard();
    var first = 0;
    guard.changed('a', selected: true, clear: () => first++);
    guard.changed('b', selected: true, clear: () {});
    expect(first, 1);
    guard.changed('a', selected: false);
    expect(guard.active, isTrue);
  });
}
