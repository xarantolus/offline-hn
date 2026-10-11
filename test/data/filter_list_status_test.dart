import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:offline_hn/data/model/filter_list_status.dart';

void main() {
  test('statuses survive a round trip with UTC times', () {
    final statuses = {
      'https://a.example/l.txt': FilterListStatus(
        updatedAt: DateTime.utc(2026, 10, 10, 12, 30),
        checkedAt: DateTime.utc(2026, 10, 11, 1),
        networkRules: 7,
        cosmeticRules: 3,
        error: 'late',
      ),
    };
    final back = FilterListStatus.decodeAll(
      FilterListStatus.encodeAll(statuses),
    );
    final status = back['https://a.example/l.txt']!;
    expect(status.updatedAt, DateTime.utc(2026, 10, 10, 12, 30));
    expect(status.updatedAt!.isUtc, isTrue);
    expect(status.checkedAt, DateTime.utc(2026, 10, 11, 1));
    expect(status.networkRules, 7);
    expect(status.cosmeticRules, 3);
    expect(status.error, 'late');
  });

  test('missing counts are zero', () {
    final status = FilterListStatus.fromJson({});
    expect(status.networkRules, 0);
    expect(status.updatedAt, isNull);
  });

  test('a corrupted value throws', () {
    expect(
      () => FilterListStatus.fromJson({'networkRules': '7'}),
      throwsA(isA<CheckedFromJsonException>()),
    );
    expect(
      () => FilterListStatus.fromJson({'updatedAt': 'yesterday'}),
      throwsA(isA<CheckedFromJsonException>()),
    );
    expect(() => FilterListStatus.decodeAll('[]'), throwsA(isA<TypeError>()));
    expect(
      () => FilterListStatus.decodeAll('{"u": 1}'),
      throwsA(isA<TypeError>()),
    );
    expect(() => FilterListStatus.decodeAll('nope'), throwsFormatException);
  });
}
