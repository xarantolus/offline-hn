import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/pages/thread/copy_info.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/thread_header.dart';

StoryRow _story({String? url = 'https://example.com'}) => StoryRow(
  id: 1,
  title: 't',
  url: url,
  commentCount: 0,
  type: 'story',
  firstSeen: DateTime.utc(2026),
  lastSeen: DateTime.utc(2026),
  read: false,
  saved: false,
  hidden: false,
);

PageCopyRow _page(
  PageStatus status, {
  String? path = 'pages/1.mhtml',
  int bytes = 2411724,
}) => PageCopyRow(
  storyId: 1,
  kind: PageKind.mhtml,
  relativePath: path,
  bytes: bytes,
  capturedAt: DateTime.utc(2026, 10, 10, 5, 12),
  status: status,
);

String _at(DateTime t) => '05:12';

void main() {
  test('a stored page reports its size and when it was made', () {
    final info = copyInfoFor(_story(), _page(PageStatus.ok), _at);
    expect(info.state, CopyState.saved);
    expect(info.detail, 'Saved copy · 2.3 MB · fetched 05:12');
  });

  test('every other outcome says why there is no copy', () {
    expect(copyInfoFor(_story(), null, _at).state, CopyState.none);
    expect(
      copyInfoFor(_story(), _page(PageStatus.tooLarge, path: null), _at).state,
      CopyState.tooLarge,
    );
    expect(
      copyInfoFor(_story(), _page(PageStatus.failed, path: null), _at).state,
      CopyState.failed,
    );
  });

  test('a record without a file is not a copy', () {
    expect(
      copyInfoFor(_story(), _page(PageStatus.ok, path: null), _at).state,
      CopyState.none,
    );
  });

  test('a story without a link has nothing to save or open', () {
    expect(
      copyInfoFor(_story(url: null), _page(PageStatus.ok), _at).state,
      CopyState.noLink,
    );
  });

  test('sizes read in the unit that fits', () {
    expect(formatSize(350 * 1024), '350 KB');
    expect(formatSize(2411724), '2.3 MB');
  });
}
