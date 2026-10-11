import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/story_source.dart';

void main() {
  test('a story with a link is labelled by its domain', () {
    expect(
      storySource(domain: 'example.com', title: 'Ask HN: x'),
      'example.com',
    );
  });

  test('a story without one is labelled by the kind of post', () {
    expect(
      storySource(domain: null, title: 'Ask HN: Who is hiring?'),
      'Ask HN',
    );
    expect(storySource(domain: null, title: 'SHOW HN: my thing'), 'Show HN');
    expect(storySource(domain: null, title: 'Tell HN: a PSA'), 'Tell HN');
    expect(storySource(domain: null, title: 'Something else'), 'Hacker News');
  });

  test('only a real prefix counts', () {
    expect(storySource(domain: null, title: 'Asking HN things'), 'Hacker News');
  });
}
