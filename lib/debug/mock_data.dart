import 'package:flutter/foundation.dart';

enum FeedKind { top, best, ask, show }

enum StoryKind { news, ask, show }

@immutable
class MockSavedCopy {
  const MockSavedCopy({required this.sizeMb, required this.fetchedAt});

  final double sizeMb;
  final String fetchedAt;
}

@immutable
class MockStory {
  const MockStory({
    required this.id,
    required this.title,
    required this.domain,
    required this.points,
    required this.comments,
    required this.author,
    required this.age,
    required this.rank,
    this.kind = StoryKind.news,
    this.read = false,
    this.saved = false,
    this.savedCopy,
  });

  final int id;
  final String title;
  final String? domain;
  final int points;
  final int comments;
  final String author;
  final Duration age;
  final int rank;
  final StoryKind kind;
  final bool read;
  final bool saved;
  final MockSavedCopy? savedCopy;
}

@immutable
sealed class CommentBlock {
  const CommentBlock();
}

class Paragraph extends CommentBlock {
  const Paragraph(this.text);

  final String text;
}

class Quote extends CommentBlock {
  const Quote(this.text);

  final String text;
}

class CodeBlock extends CommentBlock {
  const CodeBlock(this.code);

  final String code;
}

@immutable
class MockComment {
  const MockComment({
    required this.id,
    required this.author,
    required this.age,
    required this.depth,
    required this.blocks,
    this.isOp = false,
    this.isNew = false,
    this.startsCollapsed = false,
  });

  final int id;
  final String author;
  final Duration age;
  final int depth;
  final List<CommentBlock> blocks;
  final bool isOp;
  final bool isNew;
  final bool startsCollapsed;
}

@immutable
class MockThread {
  const MockThread({required this.story, required this.comments});

  final MockStory story;
  final List<MockComment> comments;

  int get newCount => comments.where((c) => c.isNew).length;

  int get maxDepth => comments.fold(0, (m, c) => c.depth > m ? c.depth : m);

  int descendantCount(int index) {
    final depth = comments[index].depth;
    var count = 0;
    for (var i = index + 1; i < comments.length; i++) {
      if (comments[i].depth <= depth) break;
      count++;
    }
    return count;
  }

  Set<int> get initiallyCollapsed => {
    for (final c in comments)
      if (c.startsCollapsed) c.id,
  };

  /// Comments in order, minus everything below a collapsed one.
  List<VisibleComment> visible(Set<int> collapsed) {
    final result = <VisibleComment>[];
    var skipBelow = -1;
    for (var i = 0; i < comments.length; i++) {
      final c = comments[i];
      if (skipBelow >= 0) {
        if (c.depth > skipBelow) continue;
        skipBelow = -1;
      }
      final isCollapsed = collapsed.contains(c.id);
      result.add(
        VisibleComment(
          comment: c,
          collapsed: isCollapsed,
          hiddenCount: isCollapsed ? descendantCount(i) : 0,
          hasChildren:
              i + 1 < comments.length && comments[i + 1].depth > c.depth,
        ),
      );
      if (isCollapsed) skipBelow = c.depth;
    }
    return result;
  }
}

@immutable
class VisibleComment {
  const VisibleComment({
    required this.comment,
    required this.collapsed,
    required this.hiddenCount,
    required this.hasChildren,
  });

  final MockComment comment;
  final bool collapsed;
  final int hiddenCount;
  final bool hasChildren;
}

const mockUpdatedAt = '06:12';
const mockConnection = 'wifi';

const mockStories = <MockStory>[
  MockStory(
    id: 1,
    title: 'SQLite 3.52 ships a built-in vector index',
    domain: 'sqlite.org',
    points: 1284,
    comments: 402,
    author: 'drh_fan',
    age: Duration(hours: 3),
    rank: 1,
    saved: true,
    savedCopy: MockSavedCopy(sizeMb: 0.8, fetchedAt: '05:12'),
  ),
  MockStory(
    id: 2,
    title: 'The cost of a hundred small abstractions',
    domain: 'danluu.com',
    points: 861,
    comments: 237,
    author: 'luu',
    age: Duration(hours: 5),
    rank: 2,
    read: true,
  ),
  MockStory(
    id: 3,
    title: 'Show HN: A job queue in 200 lines of Go on top of SQLite',
    domain: 'github.com',
    points: 642,
    comments: 61,
    author: 'ksimons',
    age: Duration(hours: 6),
    rank: 3,
    kind: StoryKind.show,
    saved: true,
    savedCopy: MockSavedCopy(sizeMb: 2.3, fetchedAt: '05:12'),
  ),
  MockStory(
    id: 4,
    title: 'Why our DNS outage lasted four hours and not four minutes',
    domain: 'blog.cloudflare.com',
    points: 598,
    comments: 188,
    author: 'zackbloom',
    age: Duration(hours: 7),
    rank: 4,
  ),
  MockStory(
    id: 5,
    title: 'Linux 7.2 will drop support for the last i486 code paths',
    domain: 'lwn.net',
    points: 533,
    comments: 164,
    author: 'corbet',
    age: Duration(hours: 4),
    rank: 5,
    read: true,
  ),
  MockStory(
    id: 6,
    title: 'Ask HN: How do you keep notes you will actually find again?',
    domain: null,
    points: 489,
    comments: 8,
    author: 'marginalia',
    age: Duration(hours: 8),
    rank: 6,
    kind: StoryKind.ask,
  ),
  MockStory(
    id: 7,
    title: 'A field guide to rate limiting without a central store',
    domain: 'fly.io',
    points: 455,
    comments: 97,
    author: 'tptacek',
    age: Duration(hours: 9),
    rank: 7,
  ),
  MockStory(
    id: 8,
    title: 'Hubble spots a rogue planet drifting between two stars',
    domain: 'arstechnica.com',
    points: 431,
    comments: 120,
    author: 'rbanffy',
    age: Duration(hours: 10),
    rank: 8,
  ),
  MockStory(
    id: 9,
    title: 'Show HN: I built a keyboard-first RSS reader that works offline',
    domain: 'github.com',
    points: 402,
    comments: 143,
    author: 'nilsb',
    age: Duration(hours: 11),
    rank: 9,
    kind: StoryKind.show,
    saved: true,
    savedCopy: MockSavedCopy(sizeMb: 1.1, fetchedAt: '05:12'),
  ),
  MockStory(
    id: 10,
    title: 'What I learned maintaining a 20-year-old Perl codebase',
    domain: 'rachelbythebay.com',
    points: 388,
    comments: 211,
    author: 'rachelbythebay',
    age: Duration(hours: 12),
    rank: 10,
  ),
  MockStory(
    id: 11,
    title: 'Ask HN: What are you working on this weekend?',
    domain: null,
    points: 351,
    comments: 502,
    author: 'weekender',
    age: Duration(hours: 13),
    rank: 11,
    kind: StoryKind.ask,
  ),
  MockStory(
    id: 12,
    title: 'Mozilla open-sources its on-device translation models',
    domain: 'mozilla.org',
    points: 340,
    comments: 76,
    author: 'cheeaun',
    age: Duration(hours: 14),
    rank: 12,
  ),
  MockStory(
    id: 13,
    title: 'Notes on building a tiny garbage collector in Rust',
    domain: 'jvns.ca',
    points: 322,
    comments: 58,
    author: 'b0rk',
    age: Duration(hours: 15),
    rank: 13,
    read: true,
  ),
  MockStory(
    id: 14,
    title: 'The long tail of SSD firmware bugs',
    domain: 'theverge.com',
    points: 309,
    comments: 134,
    author: 'chmaynard',
    age: Duration(hours: 16),
    rank: 14,
  ),
  MockStory(
    id: 15,
    title: 'Show HN: Draw a circuit, get a working SPICE netlist',
    domain: 'circuitdraw.app',
    points: 296,
    comments: 49,
    author: 'elecnoob',
    age: Duration(hours: 17),
    rank: 15,
    kind: StoryKind.show,
  ),
  MockStory(
    id: 16,
    title: 'Postgres 19 beta: what changed in the planner',
    domain: 'postgresql.org',
    points: 287,
    comments: 92,
    author: 'petergeoghegan',
    age: Duration(hours: 18),
    rank: 16,
  ),
  MockStory(
    id: 17,
    title: 'How a small library town built its own fiber network',
    domain: 'nytimes.com',
    points: 274,
    comments: 203,
    author: 'paulg',
    age: Duration(hours: 19),
    rank: 17,
  ),
  MockStory(
    id: 18,
    title: 'Ask HN: Is anyone else tired of dashboards nobody reads?',
    domain: null,
    points: 263,
    comments: 171,
    author: 'dashfatigue',
    age: Duration(hours: 20),
    rank: 18,
    kind: StoryKind.ask,
  ),
  MockStory(
    id: 19,
    title: 'An argument for boring technology, ten years on',
    domain: 'boringtechnology.club',
    points: 251,
    comments: 88,
    author: 'mckenney',
    age: Duration(hours: 21),
    rank: 19,
  ),
  MockStory(
    id: 20,
    title: 'Reverse engineering a thermostat protocol over a weekend',
    domain: 'hackaday.com',
    points: 244,
    comments: 41,
    author: 'phooky',
    age: Duration(hours: 22),
    rank: 20,
    saved: true,
    savedCopy: MockSavedCopy(sizeMb: 3.4, fetchedAt: '05:12'),
  ),
  MockStory(
    id: 21,
    title: 'Show HN: Plain-text accounting for people who hate spreadsheets',
    domain: 'ledger.example.org',
    points: 231,
    comments: 105,
    author: 'cashflow',
    age: Duration(hours: 23),
    rank: 21,
    kind: StoryKind.show,
  ),
  MockStory(
    id: 22,
    title: 'The surprising maths behind good font hinting',
    domain: 'nature.com',
    points: 219,
    comments: 37,
    author: 'kerning',
    age: Duration(days: 1),
    rank: 22,
  ),
  MockStory(
    id: 23,
    title: 'Retrospective: five years of running a Mastodon instance',
    domain: 'simonwillison.net',
    points: 208,
    comments: 129,
    author: 'simonw',
    age: Duration(days: 1, hours: 2),
    rank: 23,
    read: true,
  ),
  MockStory(
    id: 24,
    title: 'WebAssembly components are finally boring, and that is good',
    domain: 'bytecodealliance.org',
    points: 197,
    comments: 63,
    author: 'lukewagner',
    age: Duration(days: 1, hours: 3),
    rank: 24,
  ),
  MockStory(
    id: 25,
    title: 'Ask HN: Which book changed how you write code?',
    domain: null,
    points: 189,
    comments: 340,
    author: 'bookshelf',
    age: Duration(days: 1, hours: 5),
    rank: 25,
    kind: StoryKind.ask,
  ),
  MockStory(
    id: 26,
    title: 'Why the 1970s mainframe still runs the airline schedule',
    domain: 'bbc.com',
    points: 181,
    comments: 94,
    author: 'planespotter',
    age: Duration(days: 1, hours: 7),
    rank: 26,
  ),
  MockStory(
    id: 27,
    title: 'A gentle introduction to CRDTs for the impatient',
    domain: 'antirez.com',
    points: 174,
    comments: 52,
    author: 'antirez',
    age: Duration(days: 1, hours: 9),
    rank: 27,
  ),
  MockStory(
    id: 28,
    title: 'Show HN: Offline-first maps for hiking, 40 MB per country',
    domain: 'trailmaps.io',
    points: 166,
    comments: 78,
    author: 'peakbagger',
    age: Duration(days: 1, hours: 11),
    rank: 28,
    kind: StoryKind.show,
    saved: true,
    savedCopy: MockSavedCopy(sizeMb: 1.7, fetchedAt: '05:12'),
  ),
  MockStory(
    id: 29,
    title: 'The quiet comeback of the desktop application',
    domain: 'overreacted.io',
    points: 158,
    comments: 110,
    author: 'dan_abramov',
    age: Duration(days: 1, hours: 13),
    rank: 29,
  ),
  MockStory(
    id: 30,
    title: 'Debugging a 3 ms stall in a Kubernetes sidecar',
    domain: 'medium.com',
    points: 149,
    comments: 33,
    author: 'sre_lead',
    age: Duration(days: 1, hours: 15),
    rank: 30,
  ),
  MockStory(
    id: 31,
    title: 'Ask HN: How do you onboard a new engineer in a week?',
    domain: null,
    points: 141,
    comments: 87,
    author: 'newhire',
    age: Duration(days: 1, hours: 17),
    rank: 31,
    kind: StoryKind.ask,
  ),
  MockStory(
    id: 32,
    title: 'Solar cell efficiency record broken for the third time this year',
    domain: 'wired.com',
    points: 133,
    comments: 56,
    author: 'sunseeker',
    age: Duration(days: 1, hours: 19),
    rank: 32,
  ),
  MockStory(
    id: 33,
    title: 'Writing a compiler backend in a weekend with QBE',
    domain: 'c9x.me',
    points: 127,
    comments: 29,
    author: 'qbe_user',
    age: Duration(days: 1, hours: 21),
    rank: 33,
  ),
  MockStory(
    id: 34,
    title: 'Show HN: Terminal UI for exploring Git history as a graph',
    domain: 'github.com',
    points: 119,
    comments: 24,
    author: 'gitgraph',
    age: Duration(days: 2),
    rank: 34,
    kind: StoryKind.show,
  ),
  MockStory(
    id: 35,
    title: 'Open letter: please stop shipping 4 MB of JavaScript for a form',
    domain: 'kottke.org',
    points: 112,
    comments: 148,
    author: 'webminimal',
    age: Duration(days: 2, hours: 2),
    rank: 35,
    read: true,
  ),
  MockStory(
    id: 36,
    title: 'The Voyager probes, and the people keeping them alive',
    domain: 'nasa.gov',
    points: 104,
    comments: 45,
    author: 'jpl_watcher',
    age: Duration(days: 2, hours: 4),
    rank: 36,
  ),
  MockStory(
    id: 37,
    title: 'Ask HN: Freelancers, how do you price a fixed-scope project?',
    domain: null,
    points: 97,
    comments: 120,
    author: 'solo_dev',
    age: Duration(days: 2, hours: 6),
    rank: 37,
    kind: StoryKind.ask,
  ),
  MockStory(
    id: 38,
    title: 'Memory safety in the Linux kernel: two years of Rust',
    domain: 'kernel.org',
    points: 91,
    comments: 71,
    author: 'gregkh',
    age: Duration(days: 2, hours: 8),
    rank: 38,
  ),
  MockStory(
    id: 39,
    title: 'Show HN: A calm, no-notification habit tracker',
    domain: 'calmhabits.app',
    points: 84,
    comments: 19,
    author: 'slowliving',
    age: Duration(days: 2, hours: 10),
    rank: 39,
    kind: StoryKind.show,
  ),
  MockStory(
    id: 40,
    title: 'How to read a paper in twenty minutes',
    domain: 'arxiv.org',
    points: 76,
    comments: 26,
    author: 'grad_student',
    age: Duration(days: 2, hours: 12),
    rank: 40,
  ),
];

MockStory get mockThreadStory => mockStories[2];

MockStory get mockShortThreadStory => mockStories[5];

List<MockStory> storiesFor(FeedKind kind) {
  return switch (kind) {
    FeedKind.top => mockStories,
    FeedKind.best => [
      ...mockStories,
    ]..sort((a, b) => b.points.compareTo(a.points)),
    FeedKind.ask => mockStories.where((s) => s.kind == StoryKind.ask).toList(),
    FeedKind.show =>
      mockStories.where((s) => s.kind == StoryKind.show).toList(),
  };
}

const _op = 'ksimons';

class _Draft {
  const _Draft(
    this.depth,
    this.author,
    this.minutes,
    this.blocks, {
    this.isNew = false,
    this.collapsed = false,
  });

  final int depth;
  final String author;
  final int minutes;
  final List<CommentBlock> blocks;
  final bool isNew;
  final bool collapsed;
}

List<MockComment> _build(String op, List<_Draft> drafts, int baseId) {
  return [
    for (var i = 0; i < drafts.length; i++)
      MockComment(
        id: baseId + i,
        author: drafts[i].author,
        age: Duration(minutes: drafts[i].minutes),
        depth: drafts[i].depth,
        blocks: drafts[i].blocks,
        isOp: drafts[i].author == op,
        isNew: drafts[i].isNew,
        startsCollapsed: drafts[i].collapsed,
      ),
  ];
}

final mockThread = MockThread(
  story: mockThreadStory,
  comments: _build(_op, _longThread, 5000),
);

final mockShortThread = MockThread(
  story: mockShortThreadStory,
  comments: _build('marginalia', _shortThread, 7000),
);

const _claimQuery = '''
UPDATE jobs
SET state = 'running', claimed_by = :worker, claimed_at = unixepoch()
WHERE id = (
  SELECT id FROM jobs
  WHERE state = 'queued' AND run_at <= unixepoch()
  ORDER BY priority DESC, run_at
  LIMIT 1
)
RETURNING id, kind, payload;''';

const _shortThread = <_Draft>[
  _Draft(0, 'plainwriter', 420, [
    Paragraph(
      'Plain markdown files in a single folder, synced with whatever you '
      'already use. I tried five apps and the folder outlived all of them.',
    ),
  ]),
  _Draft(1, 'marginalia', 433, [
    Paragraph(
      'Same here. The part that finally made it findable was a daily file '
      'with a short title on the first line, so grep tells me what each one is.',
    ),
  ]),
  _Draft(2, 'plainwriter', 440, [
    Paragraph('A one-line summary at the top is underrated. Do you date them?'),
  ], isNew: true),
  _Draft(0, 'olivia_t', 452, [
    Quote('Notes you will actually find again'),
    Paragraph(
      'I write fewer notes. The act of deciding what is worth keeping is most '
      'of the benefit, and search is much better on a small pile.',
    ),
  ]),
  _Draft(1, 'karl_p', 460, [
    Paragraph('This. My archive of 4,000 notes is write-only.'),
  ]),
  _Draft(0, 'a_librarian', 471, [
    Paragraph(
      'Librarian here. Whatever you do, name things by what they are about, '
      'not by where you happened to be when you wrote them.',
    ),
  ], isNew: true),
  _Draft(1, 'marginalia', 480, [
    Paragraph('That is the best advice in the thread, thank you.'),
  ]),
  _Draft(0, 'tinkerer42', 490, [
    Paragraph(
      'Org-mode with a capture template. Everything lands in one inbox and I '
      'refile it weekly. https://orgmode.org/manual/Capture.html',
    ),
  ]),
];

const _longThread = <_Draft>[
  _Draft(0, _op, 14, [
    Paragraph(
      'Author here. I had a handful of cron scripts that kept stepping on each '
      'other, and every queue I looked at wanted a second service to babysit. '
      'This is the part that matters, the claim query:',
    ),
    CodeBlock(_claimQuery),
    Paragraph(
      'Source and a longer write-up: https://github.com/ksimons/sqlq. Happy to '
      'answer questions.',
    ),
  ]),
  _Draft(1, 'pgrunwald', 22, [
    Paragraph(
      'Nice write-up. We went down the same road two years ago and what bit '
      'us was long-running writers starving the claim query. Did you set a '
      'busy timeout, or do workers just retry?',
    ),
  ]),
  _Draft(2, _op, 28, [
    Paragraph(
      'WAL plus a 5 s busy timeout. The claim is one UPDATE ... RETURNING, so '
      'the write lock is held for microseconds. The starvation case I did hit '
      'was an analytics job holding a read transaction open, which blocks '
      'checkpoints and lets the WAL grow.',
    ),
  ]),
  _Draft(3, 'pgrunwald', 35, [
    Paragraph(
      'Ah, WAL growth. We found out when a small disk filled up on a Friday.',
    ),
  ]),
  _Draft(4, _op, 41, [
    Paragraph(
      'Ha, same. There is now a watchdog that logs a warning when the WAL '
      'passes 64 MB. Not elegant, but it has caught two bad deploys.',
    ),
  ], isNew: true),
  _Draft(5, 'tmarlow', 47, [
    Quote('a watchdog that logs a warning when the WAL passes 64 MB'),
    Paragraph(
      'Do you also run wal_checkpoint(TRUNCATE) from the watchdog, or just '
      'warn? I always wonder whether auto-truncating is safe under load.',
    ),
  ]),
  _Draft(6, _op, 52, [
    Paragraph(
      'Just warn. TRUNCATE blocks until readers finish, so I would rather '
      'page a human than stall the workers.',
    ),
  ], isNew: true),
  _Draft(6, 'tmarlow', 58, [
    Paragraph('Fair. Blocking the queue to save disk is a bad trade.'),
  ]),
  _Draft(0, 'dang_it_all', 30, [
    Paragraph(
      'What does this give you over Postgres with SKIP LOCKED? Genuinely '
      'asking. You already need a database in production.',
    ),
  ], collapsed: true),
  _Draft(1, _op, 37, [
    Paragraph(
      'Nothing, if you already run Postgres and are happy with it. Here there '
      'is one binary and one file on disk, so backup is a copy and the whole '
      'thing runs on a Raspberry Pi in a closet.',
    ),
  ]),
  _Draft(2, 'dang_it_all', 43, [
    Paragraph('That is a fair point. Single-file deploys are underrated.'),
  ]),
  _Draft(2, 'mhartl', 49, [
    Paragraph(
      'Also no network hop. Our enqueue latency dropped from about 2 ms to '
      '40 microseconds when we moved the queue in-process.',
    ),
  ]),
  _Draft(3, 'rbaines', 57, [
    Paragraph(
      'Careful comparing those, though: you gave up multi-machine workers. '
      'Pick the constraint you can live with.',
    ),
  ]),
  _Draft(4, 'mhartl', 65, [
    Paragraph(
      'Totally. We are one machine and will be for a long time. If that '
      'changes, the queue interface is small enough to swap.',
    ),
  ]),
  _Draft(5, 'rbaines', 71, [
    Paragraph('That is the right instinct. Keep the interface narrow.'),
  ]),
  _Draft(0, 'oldschool_dba', 54, [
    Paragraph(
      'Two things I would check: a partial index on (priority, run_at) where '
      'state is queued, and what happens when two workers run the claim at '
      'the same instant. SQLite serialises writers so you are fine, but only '
      'because of that.',
    ),
  ]),
  _Draft(1, _op, 60, [
    Paragraph(
      'Partial index, yes. Writers are serialised so it is correct by '
      'construction, and there is a test that hammers it with 32 goroutines '
      'for ten seconds.',
    ),
  ]),
  _Draft(2, 'oldschool_dba', 66, [Paragraph('One connection or a pool?')]),
  _Draft(3, _op, 70, [
    Paragraph(
      'Separate handles: four readers and one writer. The writer handle has '
      'SetMaxOpenConns(1), which is what made the "database is locked" '
      'errors go away.',
    ),
  ], isNew: true),
  _Draft(4, 'oldschool_dba', 76, [
    Paragraph(
      'That is the trick people miss. One open connection on the writer is '
      'basically a mutex you get for free.',
    ),
  ]),
  _Draft(5, 'gophernick', 84, [
    Paragraph(
      'Does that survive a transaction that spans a network call? Someone '
      'will do it eventually.',
    ),
  ], isNew: true),
  _Draft(6, _op, 90, [
    Paragraph(
      'It survives, it just stalls everyone else until the call returns. '
      'There is a transaction timeout that kills it at 2 s and logs the '
      'stack of whoever opened it.',
    ),
  ]),
  _Draft(0, 'quietcoder', 62, [
    Paragraph(
      'The retry and backoff section is the best part. Everyone writes '
      '"retry three times" and then discovers thundering herds.',
    ),
  ]),
  _Draft(1, 'jwatts', 69, [
    Paragraph(
      'Guilty. Exponential backoff with full jitter fixed a whole class of '
      'incidents for us. The best explanation is still this one: '
      'https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/',
    ),
  ]),
  _Draft(2, 'quietcoder', 75, [
    Paragraph(
      'Same post, yes. Full jitter beats equal jitter by a surprising margin '
      'in their simulation.',
    ),
  ]),
  _Draft(0, 'sleepyadmin', 80, [
    Paragraph(
      'Backups: how are you handling them? Copying a live WAL database is '
      'not safe.',
    ),
  ]),
  _Draft(1, _op, 86, [
    Paragraph(
      'Good catch, that is a typo in the README. It uses VACUUM INTO '
      'nightly and Litestream for continuous replication to object storage.',
    ),
  ]),
  _Draft(2, 'sleepyadmin', 93, [
    Paragraph(
      'Litestream is great. Mind the restore time for large WALs, though.',
    ),
  ]),
  _Draft(3, 'felixr', 99, [
    Paragraph(
      'Seconded. We restore weekly in CI to prove it works. A backup you '
      'have not restored is a hope.',
    ),
  ]),
  _Draft(4, 'sleepyadmin', 105, [
    Paragraph('Restore drills are the whole game.'),
  ]),
  _Draft(0, 'anon_penguin', 111, [
    Paragraph(
      'Is there a reason not to use an existing library like River or '
      'Faktory?',
    ),
  ], collapsed: true),
  _Draft(1, _op, 117, [
    Paragraph(
      'None really. I wanted to understand the problem and the surface I '
      'needed was small. If you need cron, unique jobs and a UI, use River.',
    ),
  ]),
  _Draft(2, 'anon_penguin', 121, [
    Paragraph('Fair. Learning by building is underrated.'),
  ]),
  _Draft(1, 'ellis_k', 124, [
    Paragraph(
      'River is excellent but it is Postgres only. That is the actual '
      'differentiator here.',
    ),
  ]),
  _Draft(2, 'anon_penguin', 131, [
    Paragraph('Oh, I missed that. That changes the calculation.'),
  ], isNew: true),
  _Draft(3, 'ellis_k', 135, [
    Paragraph('Different tool for a different deployment shape.'),
  ]),
  _Draft(0, 'maria_ostrowski', 141, [
    Paragraph(
      'Minor nit: unixepoch() needs SQLite 3.38 or newer. Debian stable '
      'ships a recent one but some LTS distributions do not.',
    ),
  ]),
  _Draft(1, _op, 150, [
    Paragraph(
      'Thanks, added a note. The Go driver I use bundles its own SQLite so '
      'it was invisible to me.',
    ),
  ]),
  _Draft(2, 'maria_ostrowski', 158, [
    Paragraph(
      'Right, with a CGO-free driver you get whatever the module pins.',
    ),
  ]),
  _Draft(3, 'tl_quinn', 163, [
    Paragraph(
      'modernc.org/sqlite? How is its write performance next to the CGO one?',
    ),
  ]),
  _Draft(4, 'maria_ostrowski', 171, [
    Paragraph(
      'Roughly 20 to 30 percent slower on inserts in my benchmarks. Nothing '
      'you would notice for a queue.',
    ),
  ], isNew: true),
  _Draft(5, 'tl_quinn', 178, [
    Paragraph('Good enough. Cross-compiling without CGO is worth it for me.'),
  ]),
  _Draft(6, _op, 184, [
    Paragraph(
      'Same reason I picked it. One GOOS=linux GOARCH=arm64 go build and I '
      'am done.',
    ),
  ], isNew: true),
  _Draft(0, 'benwhitt', 190, [
    Paragraph(
      'I have been burned by this approach when payloads got large. SQLite '
      'is happy with 100 KB blobs, but your WAL is not.',
    ),
  ], collapsed: true),
  _Draft(1, _op, 196, [
    Paragraph(
      'Payloads over 4 KB go to a blobs table keyed by hash and the job '
      'holds the key. It keeps the hot table small.',
    ),
  ]),
  _Draft(2, 'benwhitt', 203, [
    Paragraph('Smart. That also dedupes retries of the same payload.'),
  ]),
  _Draft(0, 'iamreader', 210, [
    Paragraph('Can we talk about how good the diagrams are? What did you use?'),
  ]),
  _Draft(1, _op, 214, [Paragraph('Excalidraw, exported as SVG.')]),
  _Draft(0, 'skeptic_sam', 225, [
    Paragraph(
      'Every few months someone rediscovers that you can build a queue on a '
      'database. It works until it does not. What is the failure mode at '
      'ten times the load?',
    ),
  ]),
  _Draft(1, _op, 232, [
    Paragraph(
      'Honest answer: the single writer. I measured about 9k claims a second '
      'on a laptop SSD before latency got ugly. Past that you want a real '
      'broker. Most apps never get near it.',
    ),
  ]),
  _Draft(2, 'skeptic_sam', 240, [
    Paragraph(
      '9k a second is more than most queues I have operated ever saw. '
      'Withdrawn.',
    ),
  ]),
  _Draft(2, 'distsys_dave', 246, [
    Paragraph(
      'Worth saying that fsync cost dominates. With synchronous=NORMAL in '
      'WAL mode you trade a tiny durability window for a big throughput '
      'jump.',
    ),
  ]),
  _Draft(3, _op, 252, [
    Paragraph(
      'I run NORMAL. The README has a section called "What can you lose": '
      'the last few milliseconds of commits on power loss, never corruption.',
    ),
  ]),
  _Draft(4, 'distsys_dave', 258, [
    Paragraph('Acceptable for jobs that are idempotent. Are they?'),
  ], isNew: true),
  _Draft(5, _op, 264, [
    Paragraph(
      'They are required to be. The runner passes an idempotency key and I '
      'recommend using it for anything with side effects.',
    ),
  ]),
  _Draft(6, 'distsys_dave', 270, [
    Paragraph(
      'Good. At-least-once plus idempotency is the only honest contract.',
    ),
  ]),
  _Draft(0, 'cassiopeia', 280, [
    Paragraph(
      'Thank you for including the test suite. Reading it taught me more '
      'than the post.',
    ),
  ]),
  _Draft(0, 'vintage_unix', 295, [
    Paragraph('This is just cron and a table with extra steps.'),
  ]),
  _Draft(1, 'mhartl', 300, [
    Paragraph(
      'It is cron and a table with retries, visibility, priorities and a '
      'dead-letter queue. The extra steps are the product.',
    ),
  ]),
  _Draft(2, 'vintage_unix', 305, [
    Paragraph('Heh, point taken. I would still keep the table.'),
  ]),
  _Draft(1, 'jwatts', 310, [
    Paragraph('Also, cron does not know that the last run is still going.'),
  ], isNew: true),
];
