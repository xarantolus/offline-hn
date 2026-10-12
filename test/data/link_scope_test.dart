import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
import 'package:offline_hn/data/policy/link_scope.dart';

String _a(String url) => '<a href="$url">x</a>';

List<String> _links(
  List<String?> comments, {
  int storyId = 1,
  String? storyUrl,
}) => [
  for (final uri in linksInComments(
    comments,
    storyId: storyId,
    storyUrl: storyUrl,
  ))
    uri.toString(),
];

void main() {
  group('links in comments', () {
    test('only the first three comments count', () {
      expect(
        _links([
          _a('https://a.example/1'),
          _a('https://a.example/2'),
          _a('https://a.example/3'),
          _a('https://a.example/4'),
        ]),
        ['https://a.example/1', 'https://a.example/2', 'https://a.example/3'],
      );
    });

    test('a comment gives at most three distinct links', () {
      expect(
        _links([
          '${_a('https://a.example/1')}${_a('https://a.example/1')}'
              '${_a('https://a.example/2')}${_a('https://a.example/3')}'
              '${_a('https://a.example/4')}',
        ]),
        ['https://a.example/1', 'https://a.example/2', 'https://a.example/3'],
      );
    });

    test('entities in the address are decoded and fragments dropped', () {
      expect(
        _links(['<a href="https:&#x2F;&#x2F;a.example&#x2F;p#top">x</a>']),
        ['https://a.example/p'],
      );
    });

    test('video hosts, other schemes and the story itself are skipped', () {
      for (final skipped in [
        'https://www.youtube.com/watch?v=1',
        'https://youtu.be/1',
        'https://m.vimeo.com/2',
        'mailto:me@example.com',
        'https://a.example/story',
        'https://news.ycombinator.com/item?id=1',
      ]) {
        expect(
          _links([_a(skipped)], storyUrl: 'https://a.example/story#x'),
          isEmpty,
          reason: skipped,
        );
      }
      expect(_links([_a('https://notyoutube.com/ok')]), [
        'https://notyoutube.com/ok',
      ]);
    });

    test('a hacker news discussion elsewhere is kept', () {
      expect(_links([_a('https://news.ycombinator.com/item?id=2')]), [
        'https://news.ycombinator.com/item?id=2',
      ]);
    });

    test('a comment without text is passed over', () {
      expect(_links([null, _a('https://a.example/1')]), [
        'https://a.example/1',
      ]);
    });
  });

  group('plan', () {
    test('takes the front of each feed and every bookmark', () {
      final plan = planLinks(
        ranked: {
          FeedKind.top: [for (var i = 1; i <= 40; i++) i],
          FeedKind.ask: [100],
        },
        bookmarked: [500],
        topComments: {
          1: [_a('https://a.example/1')],
          30: [_a('https://a.example/30')],
          31: [_a('https://a.example/31')],
          100: [_a('https://a.example/100')],
          500: [_a('https://a.example/500')],
        },
        storyUrls: const {},
      );
      expect(plan.byStory.keys, containsAll([1, 30, 100, 500]));
      expect(plan.byStory.keys, isNot(contains(31)));
    });

    test('a link shared by stories is one address', () {
      final plan = planLinks(
        ranked: {
          FeedKind.top: [1, 2],
        },
        bookmarked: const [],
        topComments: {
          1: [_a('https://a.example/p#a')],
          2: [_a('https://a.example/p#b'), _a('https://a.example/q')],
        },
        storyUrls: const {},
      );
      expect(
        [for (final u in plan.addresses) u.toString()],
        ['https://a.example/p', 'https://a.example/q'],
      );
      expect(plan.byStory[2], hasLength(2));
    });

    test('feeds are interleaved by rank', () {
      final plan = planLinks(
        ranked: {
          FeedKind.top: [1, 2],
          FeedKind.best: [3, 4],
        },
        bookmarked: [9],
        topComments: const {},
        storyUrls: const {},
      );
      expect(plan.byStory.keys.toList(), [1, 3, 2, 4, 9]);
    });
  });

  group('needing a copy', () {
    final now = DateTime.utc(2026, 10, 10, 12);
    final uris = [
      for (final s in ['ok', 'big', 'pending', 'fresh', 'old', 'new'])
        Uri.parse('https://a.example/$s'),
    ];
    final existing = {
      'https://a.example/ok': ExistingLink(LinkStatus.ok, now),
      'https://a.example/big': ExistingLink(LinkStatus.tooLarge, now),
      'https://a.example/pending': ExistingLink(LinkStatus.pending, now),
      'https://a.example/fresh': ExistingLink(
        LinkStatus.failed,
        now.subtract(failedCaptureRetryAfter - const Duration(minutes: 1)),
      ),
      'https://a.example/old': ExistingLink(
        LinkStatus.failed,
        now.subtract(failedCaptureRetryAfter),
      ),
    };

    test('new, interrupted and overdue ones only', () {
      expect(
        [
          for (final u in linksNeedingCopy(uris, existing, now))
            u.pathSegments.last,
        ],
        ['pending', 'old', 'new'],
      );
    });
  });
}
