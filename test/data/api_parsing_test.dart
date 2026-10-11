import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/api/algolia_json.dart';
import 'package:offline_hn/data/api/endpoints.dart';
import 'package:offline_hn/data/api/firebase_json.dart';
import 'package:offline_hn/data/api/models.dart';
import 'package:offline_hn/data/model/domain.dart';
import 'package:offline_hn/data/model/feed_kind.dart';

import 'fixtures.dart';

void main() {
  group('Algolia search hits', () {
    final stories = parseSearchHits(fixture('algolia_search.json'));

    test('reads the story fields the feed needs', () {
      final first = stories.first;
      expect(first.id, 49977979);
      expect(first.title, 'Mistral Large 4');
      expect(first.by, 'Philpax');
      expect(first.commentCount, 1211);
      expect(first.time, DateTime.utc(2026, 10, 6, 13, 15, 49));
      expect(first.url?.host, 'mistral.ai');
      expect(first.type, ItemType.story);
    });

    test('an Ask HN hit carries its text and no url', () {
      final ask = stories.last;
      expect(ask.id, 50031461);
      expect(ask.url, isNull);
      expect(ask.text, contains('pitch decks'));
    });

    test('garbage degrades to an empty list', () {
      expect(parseSearchHits('nope'), isEmpty);
      expect(parseSearchHits({'hits': 'x'}), isEmpty);
      expect(
        parseSearchHits({
          'hits': [
            {'title': 'no id'},
            7,
          ],
        }),
        isEmpty,
      );
    });
  });

  group('Algolia item tree', () {
    final thread = parseThread(fixture('algolia_item.json'))!;

    test('keeps the nesting and the comment order of the response', () {
      expect(thread.story.id, 50031269);
      expect(thread.comments.length, 3);
      final first = thread.comments.first;
      expect(first.parentId, 50031269);
      expect(first.by, isNotNull);
      expect(first.time, isNotNull);
      expect(thread.comments.map((c) => c.id), [50031374, 50031379, 50031382]);
    });

    test('counts every comment in the tree', () {
      int count(List<RemoteComment> nodes) =>
          nodes.fold(0, (sum, c) => sum + 1 + count(c.children));
      expect(thread.story.commentCount, count(thread.comments));
      expect(thread.story.commentCount, greaterThan(thread.comments.length));
    });

    test('a node without id or a non-object root yields nothing', () {
      expect(parseThread({'children': <Object?>[]}), isNull);
      expect(parseThread(null), isNull);
    });

    test('a comment with neither text nor author is deleted', () {
      final parsed = parseThread({
        'id': 1,
        'title': 't',
        'children': [
          {'id': 2, 'text': null, 'author': null, 'children': <Object?>[]},
          {'id': 3, 'text': 'hi', 'author': 'a', 'children': <Object?>[]},
        ],
      })!;
      expect(parsed.comments.map((c) => c.deleted), [true, false]);
    });
  });

  group('Firebase items', () {
    test('ranking is a list of ids and ignores junk entries', () {
      expect(parseRanking(fixture('firebase_topstories.json')).length, 12);
      expect(parseRanking([1, 'x', null, 2]), [1, 2]);
      expect(parseRanking(null), isEmpty);
    });

    test('story maps score and descendants', () {
      final story = parseFirebaseStory(fixture('firebase_story.json'))!;
      expect(story.points, 147);
      expect(story.commentCount, 89);
      expect(story.time, DateTime.utc(2026, 10, 10, 9, 51, 49));
    });

    test('an Ask HN item carries its text', () {
      final ask = parseFirebaseStory(fixture('firebase_ask.json'))!;
      expect(ask.url, isNull);
      expect(ask.text, isNotEmpty);
    });

    test('a missing item (JSON null) is null', () {
      expect(parseFirebaseStory(null), isNull);
    });

    test('deleted and dead stories are dropped', () {
      expect(
        parseFirebaseStory({'id': 1, 'deleted': true, 'type': 'story'}),
        isNull,
      );
      expect(
        parseFirebaseStory({'id': 1, 'dead': true, 'type': 'story'}),
        isNull,
      );
    });

    test('comment flags are read', () {
      final comment = parseFirebaseComment(fixture('firebase_comment.json'))!;
      expect(comment.parentId, 50031269);
      expect(comment.text, 'not ideal');
      expect(
        parseFirebaseComment(fixture('firebase_deleted_comment.json'))!.deleted,
        isTrue,
      );
      expect(
        parseFirebaseComment(fixture('firebase_dead_comment.json'))!.dead,
        isTrue,
      );
    });
  });

  group('Endpoints', () {
    test('batch search names every id and asks for as many hits', () {
      final uri = HnEndpoints.algoliaStories([1, 2, 3]);
      expect(uri.host, 'hn.algolia.com');
      expect(uri.queryParameters['tags'], 'story,(story_1,story_2,story_3)');
      expect(uri.queryParameters['hitsPerPage'], '3');
    });

    test('each feed has its own distinct path', () {
      final paths = {for (final k in FeedKind.values) HnEndpoints.feed(k).path};
      expect(paths.length, FeedKind.values.length);
      expect(HnEndpoints.feed(FeedKind.ask).path, endsWith('askstories.json'));
    });
  });

  group('wrong types in other people\'s JSON', () {
    test('a field of the wrong type becomes null, the rest survives', () {
      final story = parseFirebaseStory({
        'id': 7,
        'type': 'story',
        'title': 42,
        'url': ['x'],
        'by': {'a': 1},
        'score': 'twelve',
        'descendants': '5',
        'time': 'yesterday',
        'kids': [1, 'x', null, 2],
      })!;
      expect(story.id, 7);
      expect(story.title, isNull);
      expect(story.url, isNull);
      expect(story.by, isNull);
      expect(story.points, isNull);
      expect(story.commentCount, 5);
      expect(story.time, isNull);
      expect(story.kids, [1, 2]);
    });

    test('an unknown item type falls back to a story', () {
      expect(parseFirebaseStory({'id': 1, 'type': 'x'})!.type, ItemType.story);
      expect(parseFirebaseStory({'id': 1, 'type': 5})!.type, ItemType.story);
      expect(parseFirebaseStory({'id': 1, 'type': 'job'})!.type, ItemType.job);
    });

    test('an unusable url is dropped', () {
      expect(parseFirebaseStory({'id': 1, 'url': 'not a url'})!.url, isNull);
      expect(parseFirebaseStory({'id': 1, 'url': '/relative'})!.url, isNull);
    });

    test('an item without a usable id is dropped, not thrown on', () {
      expect(parseFirebaseStory({'id': 'abc'}), isNull);
      expect(parseFirebaseStory({'id': null}), isNull);
      expect(parseFirebaseStory([1, 2]), isNull);
      expect(parseFirebaseComment('x'), isNull);
    });

    test('one bad hit never costs the others', () {
      final hits = parseSearchHits({
        'hits': [
          {'objectID': 'x', 'title': 1},
          {'objectID': '9', 'title': 5, 'points': 'many', '_tags': 'job'},
          <Object?>[],
          {
            'objectID': 10,
            '_tags': ['job'],
          },
        ],
      });
      expect(hits.map((h) => h.id), [9, 10]);
      expect(hits.first.title, isNull);
      expect(hits.first.points, isNull);
      expect(hits.last.type, ItemType.job);
    });

    test('a bad node drops its subtree and nothing else', () {
      final thread = parseThread({
        'id': 1,
        'children': [
          {
            'id': 'bad',
            'children': [
              {'id': 5},
            ],
          },
          {'id': 2, 'author': 3, 'text': 'hi', 'created_at_i': 'x'},
          'junk',
        ],
      })!;
      expect(thread.comments.map((c) => c.id), [2]);
      expect(thread.comments.single.by, isNull);
      expect(thread.comments.single.time, isNull);
      expect(thread.story.commentCount, 1);
    });
  });

  group('domainOf', () {
    test('strips www and ignores the path', () {
      expect(
        domainOf(Uri.parse('https://www.example.com/a/b?c=d')),
        'example.com',
      );
      expect(
        domainOf(Uri.parse('https://blog.example.com/x')),
        'blog.example.com',
      );
    });

    test('is null without a usable url', () {
      expect(domainOf(null), isNull);
      expect(domainOf(Uri.parse('')), isNull);
    });
  });
}
