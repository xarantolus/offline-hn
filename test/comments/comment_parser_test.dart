import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/comments/comment_block.dart';
import 'package:offline_hn/comments/comment_parser.dart';

String _inline(Inline i) => switch (i) {
  TextRun(:final text, :final italic) => italic ? '_${text}_' : text,
  LinkRun(:final label, :final itemId) =>
    itemId == null ? '[$label]' : '[$label#$itemId]',
};

List<String> _describe(List<CommentBlock> blocks) => [
  for (final block in blocks)
    switch (block) {
      Paragraph(:final inlines) => 'P ${inlines.map(_inline).join()}',
      Quote(:final paragraphs) =>
        'Q ${paragraphs.map((p) => p.map(_inline).join()).join(' | ')}',
      CodeBlock(:final code) => 'C $code',
    },
];

void main() {
  test('paragraphs are split on <p> and entities are decoded', () {
    expect(
      _describe(
        parseCommentHtml(
          'It&#x27;s &quot;fine&quot; &amp; done<p>Second &lt;one&gt;',
        ),
      ),
      ['P It\'s "fine" & done', 'P Second <one>'],
    );
  });

  test('a paragraph starting with > is a quote and consecutive ones join', () {
    expect(
      _describe(
        parseCommentHtml(
          '&gt; The average person cannot name one.<p>&gt; Nor can I.'
          '<p>Agreed, I think she was in <i>The Simpsons</i>.',
        ),
      ),
      [
        'Q The average person cannot name one. | Nor can I.',
        'P Agreed, I think she was in _The Simpsons_.',
      ],
    );
  });

  test('a quote inside italics keeps its style', () {
    expect(_describe(parseCommentHtml('<i>&gt; slanted</i><p>reply')), [
      'Q _slanted_',
      'P reply',
    ]);
  });

  test('>= and a lone > are not quotes', () {
    expect(_describe(parseCommentHtml('&gt;= 5 works<p>&gt;')), [
      'P >= 5 works',
    ]);
  });

  test('code is a block, dedented, with its trailing blank lines gone', () {
    final blocks = parseCommentHtml(
      'Try this:<p><pre><code>  if (x) {\n    run();\n  }\n\n</code></pre>'
      '<p>That is it.',
    );
    expect(_describe(blocks), [
      'P Try this:',
      'C if (x) {\n  run();\n}',
      'P That is it.',
    ]);
  });

  test('a single-line code block loses its indentation', () {
    expect(
      _describe(parseCommentHtml('<pre><code>    5.1&#x2F;5.5</code></pre>')),
      ['C 5.1/5.5'],
    );
  });

  test('truncated link text is replaced by the address, shortened', () {
    final blocks = parseCommentHtml(
      '<a href="https:&#x2F;&#x2F;wikimediafoundation.org&#x2F;news&#x2F;2026'
      '&#x2F;10&#x2F;05&#x2F;openai-rogue-agent-activities-found-on-wikimedia-'
      'projects&#x2F;" rel="nofollow">https:&#x2F;&#x2F;wikimediafoundation.org'
      '&#x2F;news&#x2F;2026&#x2F;10&#x2F;05&#x2F;openai-rogue...</a>',
    );
    final link = (blocks.single as Paragraph).inlines.single as LinkRun;
    expect(link.uri.host, 'wikimediafoundation.org');
    expect(link.label, startsWith('wikimediafoundation.org/news/2026/10/05'));
    expect(link.label, endsWith('…'));
    expect(link.label.length, lessThanOrEqualTo(44));
  });

  test('link text that is complete is left alone', () {
    expect(
      _describe(
        parseCommentHtml(
          'see <a href="https:&#x2F;&#x2F;agentdrop.lol&#x2F;">'
          'https:&#x2F;&#x2F;agentdrop.lol&#x2F;</a>',
        ),
      ),
      ['P see [https://agentdrop.lol/]'],
    );
  });

  test('links to HN items carry the item id', () {
    final blocks = parseCommentHtml(
      '<a href="https:&#x2F;&#x2F;news.ycombinator.com&#x2F;item?id=41072330">'
      'https:&#x2F;&#x2F;news.ycombinator.com&#x2F;item?id=41072330</a>',
    );
    expect(
      ((blocks.single as Paragraph).inlines.single as LinkRun).itemId,
      41072330,
    );
  });

  test('other news.ycombinator.com pages are ordinary links', () {
    expect(
      hnItemId(Uri.parse('https://news.ycombinator.com/newsguidelines.html')),
      isNull,
    );
    expect(
      hnItemId(Uri.parse('https://news.ycombinator.com/item?id=abc')),
      isNull,
    );
    expect(hnItemId(Uri.parse('https://example.com/item?id=5')), isNull);
    expect(
      hnItemId(Uri.parse('https://news.ycombinator.com/item?id=7&p=2')),
      7,
    );
  });

  test('empty and missing text give no blocks', () {
    expect(parseCommentHtml(null), isEmpty);
    expect(parseCommentHtml('  '), isEmpty);
    expect(parseCommentHtml('<p><p>'), isEmpty);
  });

  test('line breaks inside text are collapsed outside code', () {
    expect(_describe(parseCommentHtml('one\ntwo   three')), [
      'P one two three',
    ]);
  });

  group('bare addresses', () {
    test('the story text from the API becomes a link', () {
      expect(
        _describe(
          parseCommentHtml(
            'Source: https:&#x2F;&#x2F;x.com&#x2F;karpathy&#x2F;status&#x2F;2109361546505966046',
          ),
        ),
        ['P Source: [https://x.com/karpathy/status/2109361546505966046]'],
      );
    });

    test('closing punctuation and quotes stay outside the address', () {
      expect(
        _describe(
          parseCommentHtml(
            'see (https://a.com/x), "https://b.org/y." and https://c.io/z!',
          ),
        ),
        [
          'P see ([https://a.com/x]), "[https://b.org/y]." and [https://c.io/z]!',
        ],
      );
    });

    test('a bracket inside the address stays with it', () {
      expect(linksInHtml('https://en.wikipedia.org/wiki/Foo_(bar).'), [
        Uri.parse('https://en.wikipedia.org/wiki/Foo_(bar)'),
      ]);
    });

    test('an address inside a link is not found twice', () {
      expect(
        linksInHtml('<a href="https://a.com/x">https://a.com/x</a> and more'),
        [Uri.parse('https://a.com/x')],
      );
    });

    test('code is left alone', () {
      expect(
        linksInHtml(
          '<pre><code>curl https://a.com/x</code></pre>'
          'use <code>https://b.com/y</code>',
        ),
        isEmpty,
      );
    });

    test('several addresses are found in order, and hn items are marked', () {
      expect(
        _describe(
          parseCommentHtml(
            'https://a.com/1 then https://news.ycombinator.com/item?id=42',
          ),
        ),
        [
          'P [https://a.com/1] then [https://news.ycombinator.com/item?id=42#42]',
        ],
      );
    });

    test('a word without a scheme is not an address', () {
      expect(linksInHtml('see example.com or www.example.com'), isEmpty);
    });
  });
}
