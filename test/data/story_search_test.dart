import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/policy/story_search.dart';

final now = DateTime.utc(2026, 10, 11);

SearchDoc doc(
  int id,
  String title, {
  String? domain,
  String? by,
  String? body,
  int? points,
  int daysOld = 1,
  bool saved = false,
}) => SearchDoc(
  id: id,
  title: title,
  domain: domain,
  by: by,
  body: body,
  points: points,
  time: now.subtract(Duration(days: daysOld)),
  saved: saved,
);

List<int> find(String query, List<SearchDoc> docs) => [
  for (final d in rankStories(query, docs, now)) d.id,
];

void main() {
  final docs = [
    doc(1, 'Show HN: A tiny SQLite browser', domain: 'github.com', by: 'alice'),
    doc(
      2,
      'Rust 2.0 released',
      domain: 'rust-lang.org',
      by: 'bob',
      points: 900,
    ),
    doc(3, 'Why Postgres is great', domain: 'example.com', by: 'carol'),
    doc(4, 'Ask HN: Which editor do you use?', body: 'I switched to helix.'),
    doc(5, 'Kubernetes networking explained', domain: 'blog.dev'),
  ];

  group('matching', () {
    test('an empty query matches nothing', () {
      expect(find('  ', docs), isEmpty);
    });

    test('finds a prefix and the middle of a word', () {
      expect(find('kuber', docs), [5]);
      expect(find('network', docs), [5]);
      expect(find('lite', docs), [1]);
    });

    test('finds despite a typo in a longer word', () {
      expect(find('postgers', docs), [3]);
      expect(find('kubernetis', docs), [5]);
    });

    test('scattered letters are not a typo', () {
      expect(find('postgers', [doc(9, 'I posted HN: Centers')]), isEmpty);
    });

    test('a short word has to be exact', () {
      expect(find('rsut', docs), isEmpty);
    });

    test('finds by domain and by author', () {
      expect(find('github', docs), [1]);
      expect(find('carol', docs), [3]);
    });

    test('finds in the text of a post', () {
      expect(find('helix', docs), [4]);
    });

    test('every word has to match, in any order', () {
      expect(find('rust kubernetes', docs), isEmpty);
      expect(find('browser sqlite', docs), [1]);
    });

    test('unrelated words match nothing', () {
      expect(find('zzzqqq', docs), isEmpty);
    });

    test('ignores case and punctuation in the query', () {
      expect(find('  RUST, 2.0! ', docs), [2]);
    });
  });

  group('ranking', () {
    test('a title beats the same word elsewhere', () {
      final ranked = find('helix', [
        doc(10, 'Ask HN: editors', body: 'I use helix'),
        doc(11, 'Helix 25.01 released'),
      ]);
      expect(ranked, [11, 10]);
    });

    test('a title that is the query beats a longer one', () {
      expect(
        find('sqlite', [
          doc(10, 'Sqlite internals deep dive'),
          doc(11, 'Sqlite'),
        ]),
        [11, 10],
      );
    });

    test('points and recency order equal matches', () {
      final ranked = find('rust tips', [
        doc(20, 'Rust tips', points: 5, daysOld: 400),
        doc(21, 'Rust tips', points: 800, daysOld: 400),
        doc(22, 'Rust tips', points: 5, daysOld: 2),
      ]);
      expect(ranked.last, 20);
    });

    test('standing never outweighs a much better match', () {
      expect(
        find('rust', [
          doc(30, 'Rust', points: 1, daysOld: 900),
          doc(
            31,
            'Ask HN: gardening',
            body: 'rust on my tools',
            points: 2000,
            saved: true,
          ),
        ]),
        [30, 31],
      );
    });

    test('saved nudges a tie', () {
      expect(
        find('zig', [
          doc(40, 'Zig news', daysOld: 5),
          doc(41, 'Zig news', daysOld: 5, saved: true),
        ]),
        [41, 40],
      );
    });
  });

  group('index query', () {
    test('any trigram of a word, and every word', () {
      expect(ftsQueryFor(['rust']), '("rus" OR "ust")');
      expect(
        ftsQueryFor(['rust', 'go', 'lang']),
        '("rus" OR "ust") AND ("lan" OR "ang")',
      );
    });

    test('words under three letters cannot use the index', () {
      expect(ftsQueryFor(['go', 'ai']), isNull);
    });
  });
}
